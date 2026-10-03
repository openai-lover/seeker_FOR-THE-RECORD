package app.workroom.seeker_workroom

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.OutputStream
import org.junit.Assert.*
import org.junit.Test

class JournalExportTest {
    @Test fun cancellationNeverOpensOrWrites() {
        assertFalse(completeJournalExport(false, null) { error("must not open") })
    }

    @Test fun absentStreamCannotReportSuccess() {
        assertThrows(IOException::class.java) { completeJournalExport(true, "{}") { null } }
    }

    @Test fun missingAndBlankContentNeverOpenDestination() {
        for (content in listOf(null, "", " \n")) {
            assertThrows(IOException::class.java) {
                completeJournalExport(true, content) { error("must not open") }
            }
        }
    }

    @Test fun utf8PayloadIsFlushedAndClosedBeforeSuccess() {
        var flushed = false
        var closed = false
        val stream = object : ByteArrayOutputStream() {
            override fun flush() { flushed = true }
            override fun close() { closed = true }
        }
        val content = "{\"note\":\"한국어 日本語 café\"}"
        assertTrue(completeJournalExport(true, content) { stream })
        assertEquals(content, stream.toString("UTF-8"))
        assertTrue(flushed)
        assertTrue(closed)
    }

    @Test fun openFailurePropagates() {
        assertThrows(IOException::class.java) {
            completeJournalExport(true, "{}") { throw IOException("open") }
        }
    }

    @Test fun writeFailureClosesAndPropagates() {
        var closed = false
        val stream = object : OutputStream() {
            override fun write(value: Int) { throw IOException("write") }
            override fun close() { closed = true }
        }
        assertThrows(IOException::class.java) { completeJournalExport(true, "{}") { stream } }
        assertTrue(closed)
    }

    @Test fun flushFailureCannotReportSuccess() {
        val stream = object : ByteArrayOutputStream() {
            override fun flush() { throw IOException("flush") }
        }
        assertThrows(IOException::class.java) { completeJournalExport(true, "{}") { stream } }
    }

    @Test fun closeFailureCannotReportSuccess() {
        val stream = object : ByteArrayOutputStream() {
            override fun close() { throw IOException("close") }
        }
        assertThrows(IOException::class.java) { completeJournalExport(true, "{}") { stream } }
    }
}
