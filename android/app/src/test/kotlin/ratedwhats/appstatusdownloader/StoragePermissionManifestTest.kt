package ratedwhats.appstatusdownloader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.w3c.dom.Document
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

class StoragePermissionManifestTest {
    private val androidNamespace = "http://schemas.android.com/apk/res/android"
    private val toolsNamespace = "http://schemas.android.com/tools"

    private fun manifest(): Document {
        // Gradle runs app unit tests from android/app; also support IDE/root runs.
        val file = listOf(
            File("src/main/AndroidManifest.xml"),
            File("app/src/main/AndroidManifest.xml"),
            File("android/app/src/main/AndroidManifest.xml")
        ).firstOrNull { it.isFile }
            ?: error("Could not locate the app's source AndroidManifest.xml")
        return DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = true
        }.newDocumentBuilder().parse(file)
    }

    private fun permissions(document: Document, name: String): List<Element> {
        val declarations = document.getElementsByTagName("uses-permission")
        return (0 until declarations.length).map { declarations.item(it) as Element }
            .filter { it.getAttributeNS(androidNamespace, "name") == name }
    }

    @Test fun removesAllFilesAccessDuringManifestMerging() {
        val permissions = permissions(manifest(), "android.permission.MANAGE_EXTERNAL_STORAGE")
        assertEquals("All files access must have one defensive removal rule", 1, permissions.size)
        assertEquals(
            "All files access must be removed from the final merged manifest",
            "remove",
            permissions.single().getAttributeNS(toolsNamespace, "node")
        )
    }

    @Test fun omitsBroadAndLegacyStoragePermissions() {
        val document = manifest()
        for (name in listOf(
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE",
            "android.permission.READ_MEDIA_IMAGES",
            "android.permission.READ_MEDIA_VIDEO"
        )) {
            assertTrue("$name must not be declared for the scoped folder flow", permissions(document, name).isEmpty())
        }
    }

    @Test fun doesNotEnableLegacyExternalStorage() {
        val application = manifest().getElementsByTagName("application").item(0) as Element
        assertFalse(
            "Scoped folder access must not opt out of Android scoped storage",
            application.hasAttributeNS(androidNamespace, "requestLegacyExternalStorage")
        )
    }
}
