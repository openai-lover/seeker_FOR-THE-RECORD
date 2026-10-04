package app.workroom.seeker_workroom

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Private, bounded semantic retrieval. No wallet, signing or remote inference. */
class ReflectionAssistant(context: Context) : MethodChannel.MethodCallHandler {
    private val root = File(context.noBackupFilesDir, "reflection-model").apply { mkdirs() }
    private val model = File(root, "multilingual-e5-small-q8_0.gguf")
    private val partial = File(root, "download.part")
    private val legacy = File(root, "qwen3-1.7b-int4.litertlm")
    private val oldCache = File(context.cacheDir, "reflection-engine")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private val deadlines = Executors.newSingleThreadScheduledExecutor()
    private val closed = AtomicBoolean(false)
    @Volatile private var operation: Operation? = null
    @Volatile private var downloaded = 0L
    @Volatile private var connection: HttpURLConnection? = null
    @Volatile private var handle = 0L
    private class Operation(val result: MethodChannel.Result) {
        val responded = AtomicBoolean(false)
        val cancelled = AtomicBoolean(false)
    }
    companion object {
        const val MODEL_BYTES = 132439008L
        const val MODEL_SHA = "e011debc1208e31bf7b6aebee2d9fc8bd2ca11694a77ed66ac9d0c9d0a877c93"
        const val MODEL_URL = "https://huggingface.co/TwinSunsLLC/multilingual-e5-small-gguf/resolve/b6cac9615d4ecce28d7f22539b7322d695fc2886/multilingual-e5-small-q8_0.gguf"
    }
    // Only the worker creates or releases engines. Idle/background release never
    // races a native inference; cancellation is the only cross-thread native call.
    private fun releaseEngine() {
        val previous = handle
        handle = 0
        if (previous != 0L) ReflectionNative.close(previous)
    }
    private val idleRelease = Runnable {
        if (!closed.get()) worker.execute { if (operation == null) releaseEngine() }
    }
    private fun finish(op: Operation, value: Any? = null, error: String? = null) {
        if (op.responded.compareAndSet(false, true)) main.post {
            if (error == null) op.result.success(value)
            else op.result.error(error, "The local assistant could not complete this request.", null)
        }
    }
    private fun cancelOperation(op: Operation, error: String) {
        op.cancelled.set(true)
        if (handle != 0L) ReflectionNative.cancel(handle)
        connection?.disconnect()
        finish(op, error = error)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (closed.get()) { result.error("unavailable", "Assistant closed.", null); return }
        when (call.method) {
            "status" -> result.success(mapOf(
                "supported" to Build.SUPPORTED_ABIS.contains("arm64-v8a"),
                "ready" to (model.isFile && model.length() == MODEL_BYTES),
                "busy" to (operation != null), "downloaded" to downloaded,
                "modelBytes" to MODEL_BYTES, "warm" to (handle != 0L),
            ))
            "cancel" -> { operation?.let { cancelOperation(it, "cancelled") }; result.success(null) }
            "download", "suggest", "rank", "remove" -> {
                if (operation != null) { result.error("busy", "A request is finishing.", null); return }
                if (!Build.SUPPORTED_ABIS.contains("arm64-v8a")) { result.error("unsupported", "ARM64 Android required.", null); return }
                main.removeCallbacks(idleRelease)
                val op = Operation(result)
                operation = op
                val watchdog = deadlines.schedule({ cancelOperation(op, "timeout") },
                    if (call.method == "download") 900L else 30L, TimeUnit.SECONDS)
                worker.execute {
                    try {
                        checkCancelled(op)
                        when (call.method) {
                            "download" -> { download(op); finish(op) }
                            "remove" -> {
                                releaseEngine()
                                val removed = listOf(model, partial, legacy).map { !it.exists() || it.delete() }.all { it }
                                val cacheRemoved = !oldCache.exists() || oldCache.deleteRecursively()
                                if (!removed || !cacheRemoved) error("remove-failed")
                                downloaded = 0
                                finish(op)
                            }
                            "rank" -> finish(op, rank(op, call))
                            else -> finish(op, suggest(op, call.argument<String>("context") ?: ""))
                        }
                    } catch (_: InterruptedException) { finish(op, error = "cancelled") }
                    catch (_: UnsatisfiedLinkError) { finish(op, error = "unsupported") }
                    catch (_: OutOfMemoryError) { finish(op, error = "memory") }
                    catch (e: Exception) { finish(op, error = when (e.message) {
                        "model-missing", "checksum", "storage", "empty-note", "cancelled", "remove-failed" -> e.message
                        else -> "unavailable"
                    }) }
                    finally {
                        watchdog.cancel(false); connection?.disconnect(); connection = null
                        if (op.cancelled.get()) releaseEngine()
                        operation = null
                        if (!closed.get()) main.postDelayed(idleRelease, 60_000)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }
    private fun checkCancelled(op: Operation) {
        if (op.cancelled.get() || closed.get() || Thread.currentThread().isInterrupted) throw InterruptedException()
    }
    private fun verifyModel(op: Operation) {
        if (!model.isFile || model.length() != MODEL_BYTES) error("model-missing")
        val digest = MessageDigest.getInstance("SHA-256")
        model.inputStream().use { input ->
            val buffer = ByteArray(65536)
            while (true) { checkCancelled(op); val count = input.read(buffer); if (count < 0) break; digest.update(buffer, 0, count) }
        }
        if (digest.digest().joinToString("") { "%02x".format(it) } != MODEL_SHA) error("checksum")
    }
    private fun download(op: Operation) {
        releaseEngine()
        if (model.isFile && model.length() == MODEL_BYTES) {
            try { verifyModel(op); downloaded = MODEL_BYTES; return }
            catch (e: IllegalStateException) { if (e.message != "checksum") throw e }
        }
        if (root.usableSpace < MODEL_BYTES + 50_000_000L) error("storage")
        downloaded = 0
        val digest = MessageDigest.getInstance("SHA-256")
        try {
            var url = URL(MODEL_URL)
            var accepted: HttpURLConnection? = null
            for (hop in 0..6) {
                checkCancelled(op); require(url.protocol == "https")
                val c = url.openConnection() as HttpURLConnection
                connection = c
                c.connectTimeout = 20000; c.readTimeout = 30000; c.instanceFollowRedirects = false
                val status = c.responseCode
                if (status in 300..399) {
                    url = URL(url, c.getHeaderField("Location") ?: error("download")); c.disconnect()
                } else { require(status == 200); accepted = c; break }
            }
            val c = accepted ?: error("download")
            c.inputStream.use { input -> partial.outputStream().use { output ->
                val buffer = ByteArray(65536)
                while (true) {
                    checkCancelled(op)
                    val count = input.read(buffer); if (count < 0) break
                    downloaded += count; require(downloaded <= MODEL_BYTES)
                    digest.update(buffer, 0, count); output.write(buffer, 0, count)
                }
                output.fd.sync()
            } }
            checkCancelled(op)
            val checksum = digest.digest().joinToString("") { "%02x".format(it) }
            if (downloaded != MODEL_BYTES || checksum != MODEL_SHA) error("checksum")
            if (!partial.renameTo(model)) error("storage")
            // Only obsolete AI files are removed after the replacement is verified.
            legacy.delete()
            if (oldCache.exists()) oldCache.deleteRecursively()
        } finally { if (partial.exists()) partial.delete() }
    }
    private fun suggest(op: Operation, context: String): Map<String, Any> {
        require(context.isNotBlank() && context.length <= 1800) { "empty-note" }
        val json = JSONObject(context)
        val reason = json.optString("reason").trim()
        val plan = json.optString("plan").trim()
        val reflection = json.optString("reflection").trim()
        val primary = reflection.ifBlank { reason.ifBlank { plan } }
        require(primary.isNotBlank()) { "empty-note" }
        val background = listOf(reason, plan, reflection).filter { it.isNotBlank() }.joinToString("\n")
        val start = SystemClock.elapsedRealtime()
        val cold = handle == 0L
        if (cold) {
            verifyModel(op)
            checkCancelled(op)
            handle = ReflectionNative.create(model.path)
        }
        ReflectionNative.prepare(handle)
        checkCancelled(op)
        val selected = ReflectionNative.select(handle, primary.toByteArray(Charsets.UTF_8), background.toByteArray(Charsets.UTF_8))
        checkCancelled(op)
        require(selected.size == 3 && selected[0] in 1..5 && selected[1] in 1..5)
        return mapOf("questionId" to selected[0], "alternativeId" to selected[1], "uncertain" to (selected[2] == 1),
            "cold" to cold, "durationMs" to (SystemClock.elapsedRealtime() - start))
    }
    private fun rank(op: Operation, call: MethodCall): Map<String, Any> {
        val query = call.argument<String>("query")?.trim() ?: ""
        val records = call.argument<List<String>>("records") ?: emptyList()
        require(query.isNotBlank() && query.length <= 1800 && records.size in 1..32 &&
            records.all { it.isNotBlank() && it.length <= 1800 }) { "empty-note" }
        val start = SystemClock.elapsedRealtime()
        val cold = handle == 0L
        if (cold) { verifyModel(op); checkCancelled(op); handle = ReflectionNative.create(model.path) }
        ReflectionNative.prepare(handle); checkCancelled(op)
        val scores = ReflectionNative.rank(handle, query.toByteArray(Charsets.UTF_8),
            records.map { it.toByteArray(Charsets.UTF_8) }.toTypedArray())
        checkCancelled(op)
        require(scores.size == records.size && scores.all { it.isFinite() })
        return mapOf("scores" to scores.map { it.toDouble() }, "cold" to cold,
            "durationMs" to (SystemClock.elapsedRealtime() - start))
    }
    fun background() {
        main.removeCallbacks(idleRelease)
        if (!closed.get()) worker.execute { releaseEngine() }
    }
    fun close() {
        if (!closed.compareAndSet(false, true)) return
        main.removeCallbacks(idleRelease)
        operation?.let { cancelOperation(it, "cancelled") }
        connection?.disconnect()
        worker.execute { releaseEngine() }
        worker.shutdown()
        deadlines.shutdownNow()
    }
}
