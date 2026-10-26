package ratedwhats.appstatusdownloader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import ratedwhats.appstatusdownloader.status.StatusFileCatalog

class StatusFileCatalogTest {
    @Test fun supportsImageAndVideoMimeTypesCaseInsensitively() {
        assertEquals("image/jpeg", StatusFileCatalog.mimeType("photo.JpEg"))
        assertEquals("image/heif", StatusFileCatalog.mimeType("image.HEIF"))
        assertEquals("video/quicktime", StatusFileCatalog.mimeType("video.mov"))
        assertEquals("video/x-matroska", StatusFileCatalog.mimeType("video.MKV"))
        assertNull(StatusFileCatalog.mimeType("file.txt"))
    }

    @Test fun rejectsHiddenAndExtensionlessFiles() {
        assertNull(StatusFileCatalog.mimeType(".nomedia"))
        assertNull(StatusFileCatalog.mimeType(".hidden.jpg"))
        assertNull(StatusFileCatalog.mimeType("no-extension"))
    }
}
