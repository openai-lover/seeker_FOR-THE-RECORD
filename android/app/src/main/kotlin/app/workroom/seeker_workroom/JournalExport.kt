package app.workroom.seeker_workroom

import java.io.IOException
import java.io.OutputStream

/** A successful picker selection is not a successful write until the stream closes. */
internal fun completeJournalExport(
    selected: Boolean,
    content: String?,
    openStream: () -> OutputStream?
): Boolean {
    if (!selected) return false
    if (content.isNullOrBlank()) throw IOException("Export content is missing")
    val stream = openStream() ?: throw IOException("Export destination is unavailable")
    stream.use {
        it.write(content.toByteArray(Charsets.UTF_8))
        it.flush()
    }
    return true
}
