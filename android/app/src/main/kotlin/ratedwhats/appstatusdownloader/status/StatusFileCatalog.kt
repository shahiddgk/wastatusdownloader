package ratedwhats.appstatusdownloader.status

import java.util.Locale

/** Supported media filename extensions used when Android omits a MIME type. */
object StatusFileCatalog {
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
}
