package app.workroom.seeker_workroom

import androidx.annotation.Keep

/** Private CPU inference. UTF-8 bytes preserve emoji and multilingual notes. */
@Keep
internal object ReflectionNative {
    init { System.loadLibrary("reflection_native") }
    external fun create(path: String): Long
    external fun prepare(handle: Long)
    external fun select(handle: Long, note: ByteArray, background: ByteArray): IntArray
    external fun cancel(handle: Long)
    external fun close(handle: Long)
}
