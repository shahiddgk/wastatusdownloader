package ratedwhats.appstatusdownloader

import org.junit.Assert.*
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

    private fun permission(document: Document, name: String): Element {
        val declarations = document.getElementsByTagName("uses-permission")
        val matching = (0 until declarations.length).map { declarations.item(it) as Element }
            .filter { it.getAttributeNS(androidNamespace, "name") == name }
        assertEquals("$name must be declared exactly once", 1, matching.size)
        val declaration = matching.single()
        val mergeAction = declaration.getAttributeNS(toolsNamespace, "node")
        assertFalse("$name must not be removed during manifest merging",
            mergeAction == "remove" || mergeAction == "removeAll")
        return declaration
    }

    @Test fun declaresAllFilesAccessForAndroid11AndLater() {
        val permission = permission(manifest(), "android.permission.MANAGE_EXTERNAL_STORAGE")
        assertFalse("All files access must remain available on newer Android versions",
            permission.hasAttributeNS(androidNamespace, "maxSdkVersion"))
    }

    @Test fun declaresLegacyRuntimePermissionsOnlyThroughAndroid10() {
        val document = manifest()
        for (name in listOf("READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE")) {
            val permission = permission(document, "android.permission.$name")
            assertEquals("$name is needed by the legacy permission flow through API 29",
                "29", permission.getAttributeNS(androidNamespace, "maxSdkVersion"))
        }
    }

    @Test fun enablesDirectStatusDiscoveryOnAndroid10() {
        val application = manifest().getElementsByTagName("application").item(0) as Element
        assertEquals("Android 10 needs legacy storage for direct status file discovery",
            "true", application.getAttributeNS(androidNamespace, "requestLegacyExternalStorage"))
    }
}
