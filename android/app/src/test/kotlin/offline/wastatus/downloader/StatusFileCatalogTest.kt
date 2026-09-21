package offline.wastatus.downloader

import offline.wastatus.downloader.status.StatusFileCatalog
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class StatusFileCatalogTest {
    @get:Rule val temporary = TemporaryFolder()

    private fun media(path: String, modified: Long = 1000): File =
        File(temporary.root, path).apply {
            parentFile.mkdirs()
            writeBytes(byteArrayOf(1, 2, 3))
            setLastModified(modified)
        }

    @Test fun discoversModernAndLegacyStatusesWithoutMixingBusiness() {
        val modern = media("Android/media/com.whatsapp/WhatsApp/Media/.Statuses/new.JPG", 3000)
        val legacy = media("WhatsApp/Media/.Statuses/old.mp4", 1000)
        val business = media("Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses/business.png", 2000)
        media("Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/chat.jpg")
        assertEquals(listOf(modern, legacy), StatusFileCatalog.scan(listOf(temporary.root), "com.whatsapp"))
        assertEquals(listOf(business), StatusFileCatalog.scan(listOf(temporary.root), "com.whatsapp.w4b"))
    }

    @Test fun skipsSentinelsPartialFilesAndEmptyMedia() {
        val folder = "WhatsApp/Media/.Statuses"
        val photo = media("$folder/photo.webp")
        media("$folder/.nomedia")
        media("$folder/unfinished.mp4.tmp")
        media("$folder/image.jpg.part")
        media("$folder/.hidden.jpg")
        media("$folder/empty.jpg").writeBytes(byteArrayOf())
        media("$folder/nested/not-a-status.jpg")
        assertEquals(listOf(photo), StatusFileCatalog.scan(listOf(temporary.root), "com.whatsapp"))
    }

    @Test fun readsSecondaryVolumeAndDeduplicatesRoots() {
        val photo = media("WhatsApp Business/Media/.Statuses/photo.heif")
        val roots = listOf(temporary.newFolder("other-volume"), temporary.root, temporary.root)
        assertEquals(listOf(photo), StatusFileCatalog.scan(roots, "com.whatsapp.w4b"))
    }

    @Test fun missingFoldersAreAnEmptyLibrary() {
        assertTrue(StatusFileCatalog.scan(listOf(temporary.root), "com.whatsapp").isEmpty())
    }

    @Test fun supportsImageAndVideoMimeTypes() {
        assertEquals("image/heif", StatusFileCatalog.mimeType("image.HEIF"))
        assertEquals("video/quicktime", StatusFileCatalog.mimeType("video.mov"))
        assertNull(StatusFileCatalog.mimeType("file.txt"))
        assertNull(StatusFileCatalog.mimeType(".nomedia"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsUnknownSource() {
        StatusFileCatalog.scan(listOf(temporary.root), "../other")
    }

    @Test fun savedCopiesSurviveOriginalRemoval() {
        val original = media("WhatsApp/Media/.Statuses/photo.jpg")
        val saved = media("Pictures/SavedStatus/photo.jpg")
        original.delete()
        assertTrue(StatusFileCatalog.scan(listOf(temporary.root), "com.whatsapp").isEmpty())
        assertEquals(listOf(saved), StatusFileCatalog.mediaFiles(listOf(saved.parentFile!!)))
    }
}
