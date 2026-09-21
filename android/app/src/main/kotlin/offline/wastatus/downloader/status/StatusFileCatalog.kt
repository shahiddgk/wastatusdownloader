package offline.wastatus.downloader.status

import java.io.File
import java.io.IOException
import java.util.Locale

/** Known WhatsApp layouts, kept at the native boundary and probed on each scan. */
object StatusFileCatalog {
    fun directories(roots: List<File>, targetPackage: String): List<File> {
        val folder = when (targetPackage) {
            "com.whatsapp" -> "WhatsApp"
            "com.whatsapp.w4b" -> "WhatsApp Business"
            else -> throw IllegalArgumentException("Unsupported status source")
        }
        return roots.flatMap { root ->
            listOf(
                File(root, "Android/media/$targetPackage/$folder/Media/.Statuses"),
                File(root, "$folder/Media/.Statuses")
            )
        }.distinctBy { it.absolutePath }
    }

    fun mimeType(name: String): String? {
        if (name.startsWith('.')) return null
        return when (name.substringAfterLast('.', "").lowercase(Locale.ROOT)) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            "heic" -> "image/heic"
            "heif" -> "image/heif"
            "avif" -> "image/avif"
            "mp4", "m4v" -> "video/mp4"
            "3gp" -> "video/3gpp"
            "mov" -> "video/quicktime"
            "mkv" -> "video/x-matroska"
            "webm" -> "video/webm"
            else -> null
        }
    }

    fun scan(roots: List<File>, targetPackage: String): List<File> =
        mediaFiles(directories(roots, targetPackage))

    fun mediaFiles(directories: List<File>): List<File> =
        directories.flatMap { directory ->
            if (!directory.exists()) return@flatMap emptyList()
            val files = directory.listFiles()
                ?: throw IOException("Could not read status folder")
            files.filter { file ->
                file.isFile && file.canRead() && file.length() > 0 &&
                    file.canonicalFile.parentFile == directory.canonicalFile &&
                    mimeType(file.name) != null
            }
        }.distinctBy { it.canonicalPath }.sortedByDescending { it.lastModified() }
}
