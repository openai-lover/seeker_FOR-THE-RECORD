package app.workroom.seeker_workroom

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.util.Base64
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import com.solana.mobilewalletadapter.clientlib.*
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class WorkroomActivity : FlutterFragmentActivity() {
    private var adapter: MobileWalletAdapter? = null
    private lateinit var sender: ActivityResultSender
    private var walletBusy = false
    private var exportResult: MethodChannel.Result? = null
    private var exportContent: String? = null
    private var notificationResult: MethodChannel.Result? = null
    private val createDocument = registerForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        val pending = exportResult
        try {
            if (uri != null) contentResolver.openOutputStream(uri)?.use { it.write((exportContent ?: "").toByteArray(Charsets.UTF_8)) }
            pending?.success(uri != null)
        } catch (e: Exception) { pending?.error("export-failed", "파일을 저장하지 못했습니다.", null) }
        exportResult = null; exportContent = null
    }
    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        notificationResult?.success(granted); notificationResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sender = ActivityResultSender(this)
        getSystemService(NotificationManager::class.java).createNotificationChannel(NotificationChannel("focus", "Focus reminders", NotificationManager.IMPORTANCE_DEFAULT))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.workroom/native").setMethodCallHandler { call, result ->
            when(call.method) {
                "setLanguage" -> {
                    val language = call.argument<String>("language") ?: "en"
                    getSharedPreferences("record", MODE_PRIVATE).edit().putString("language", language).apply()
                    val names = mapOf("en" to "Focus reminders", "ko" to "집중 알림", "ja" to "集中リマインダー", "zh" to "专注提醒", "hi" to "ध्यान सत्र की याद", "es" to "Recordatorios de enfoque", "pt" to "Lembretes de foco", "fr" to "Rappels de concentration")
                    getSystemService(NotificationManager::class.java).createNotificationChannel(NotificationChannel("focus", names[language] ?: names["en"], NotificationManager.IMPORTANCE_DEFAULT))
                    result.success(null)
                }
                "clock" -> {
                    val bootCount = Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1)
                    if (bootCount < 0) result.error("clock-unavailable", "부팅 정보를 읽지 못했습니다.", null)
                    else result.success(mapOf("elapsedMs" to SystemClock.elapsedRealtime(), "boot" to bootCount.toString(), "utcMs" to System.currentTimeMillis()))
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT < 33) result.success(true)
                    else if (notificationResult != null) result.error("busy", "권한 요청 중입니다.", null)
                    else { notificationResult = result; notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS) }
                }
                "scheduleAlarm" -> {
                    val delay = call.argument<Number>("remainingMs")?.toLong() ?: 0L
                    if (delay > 0) getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, SystemClock.elapsedRealtime()+delay, alarmIntent())
                    result.success(null)
                }
                "cancelAlarm" -> { getSystemService(AlarmManager::class.java).cancel(alarmIntent()); getSystemService(NotificationManager::class.java).cancel(17); result.success(null) }
                "export" -> {
                    if (exportResult != null) result.error("busy", "내보내기 중입니다.", null)
                    else { exportContent=call.argument<String>("content"); exportResult=result; createDocument.launch("for-the-record-${System.currentTimeMillis()}.json") }
                }
                "walletConnect", "walletSignMessage", "walletSignTransaction", "walletDisconnect" -> {
                    if (walletBusy) { result.error("wallet-busy", "지갑 요청이 진행 중입니다.", null); return@setMethodCallHandler }
                    val identity = call.argument<String>("identityUri") ?: ""
                    val uri = Uri.parse(identity)
                    if (uri.scheme != "https" || uri.host.isNullOrBlank()) { result.error("not-configured", "연결 주소를 먼저 설정해야 합니다.", null); return@setMethodCallHandler }
                    val wallet = adapter ?: MobileWalletAdapter(connectionIdentity = ConnectionIdentity(identityUri=uri, iconUri=Uri.parse("favicon.png"), identityName=call.argument<String>("identityName") ?: "FOR THE RECORD")).also { adapter=it }
                    walletBusy=true
                    lifecycleScope.launch {
                        try {
                            when(call.method) {
                                "walletConnect" -> when(val response = wallet.connect(sender)) {
                                    is TransactionResult.Success -> result.success(mapOf("publicKey" to b64(response.authResult.accounts.first().publicKey)))
                                    is TransactionResult.NoWalletFound -> result.error("no-wallet", "MWA 호환 지갑을 설치해 주세요.", null)
                                    is TransactionResult.Failure -> result.error("wallet-declined", "지갑 연결이 승인되지 않았습니다.", null)
                                }
                                "walletSignMessage" -> {
                                    val message = (call.argument<String>("message") ?: "").toByteArray(Charsets.UTF_8)
                                    val expected = call.argument<String>("publicKey") ?: ""
                                    when(val response = wallet.transact(sender) { auth ->
                                        require(b64(auth.accounts.first().publicKey) == expected) { "account-changed" }
                                        signMessagesDetached(arrayOf(message), arrayOf(auth.accounts.first().publicKey))
                                    }) {
                                        is TransactionResult.Success -> result.success(mapOf("signature" to b64(response.successPayload!!.messages.first().signatures.first()), "publicKey" to b64(response.authResult.accounts.first().publicKey)))
                                        is TransactionResult.NoWalletFound -> result.error("no-wallet", "MWA 호환 지갑이 없습니다.", null)
                                        is TransactionResult.Failure -> result.error(if(response.e.message?.contains("account-changed") == true) "account-changed" else "wallet-declined", "서명 거절 또는 계정 변경입니다. 다시 연결해 주세요.", null)
                                    }
                                }
                                "walletSignTransaction" -> {
                                    val transaction=Base64.decode(call.argument<String>("transaction"),Base64.DEFAULT)
                                    val expected=call.argument<String>("publicKey") ?: ""
                                    when(val response=wallet.transact(sender) { auth ->
                                        require(b64(auth.accounts.first().publicKey)==expected) { "account-changed" }
                                        signTransactions(arrayOf(transaction))
                                    }) {
                                        is TransactionResult.Success -> result.success(mapOf("signedTransaction" to b64(response.successPayload!!.signedPayloads.first())))
                                        is TransactionResult.NoWalletFound -> result.error("no-wallet", "MWA 호환 지갑이 없습니다.", null)
                                        is TransactionResult.Failure -> result.error("wallet-declined", "거래가 승인되지 않았습니다. 자산은 전송하지 않았습니다.", null)
                                    }
                                }
                                "walletDisconnect" -> { wallet.disconnect(sender); wallet.authToken=null; adapter=null; result.success(emptyMap<String,String>()) }
                            }
                        } catch(e:Exception) { result.error("wallet-error", "지갑 요청을 완료하지 못했습니다. 다시 연결해 주세요.", null) }
                        finally { walletBusy=false }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun b64(value:ByteArray)=Base64.encodeToString(value,Base64.NO_WRAP)
    private fun alarmIntent()=PendingIntent.getBroadcast(this,17,Intent(this,FocusAlarmReceiver::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}
