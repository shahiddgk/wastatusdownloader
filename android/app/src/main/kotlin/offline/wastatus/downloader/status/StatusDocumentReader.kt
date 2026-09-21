package offline.wastatus.downloader.status

import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.util.Log
import java.io.File
import java.io.InputStream
import java.nio.charset.StandardCharsets
import java.util.concurrent.ConcurrentHashMap

data class StatusDocument(
    val id: String, // Opaque identifier across platform boundary
    val documentId: String, // Internal SAF document ID
    val displayName: String,
    val mimeType: String,
    val sizeBytes: Long,
    val lastModified: Long,
    val isVideo: Boolean,
    val documentUri: Uri,
    val isSaved: Boolean = false
) {
    fun toMap(): Map<String, Any> = mapOf(
        "id" to id,
        "fileName" to displayName,
        "displayName" to displayName, // Backward compatibility with POC
        "mimeType" to mimeType,
        "sizeBytes" to sizeBytes,
        "lastModified" to lastModified,
        "isVideo" to isVideo,
        "isSaved" to isSaved,
        "uri" to id // Backward compatibility: POC expects 'uri' property, returns opaque ID
    )
}

/**
 * Handles WhatsApp Status media discovery, projection querying,
 * opaque identifier creation, and safe stream access via ContentResolver.
 */
class StatusDocumentReader(private val context: Context) {

    companion object {
        private const val TAG = "StatusDocumentReader"
        private const val OPAQUE_ID_PREFIX = "stat_"

        private val PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )

        /**
         * Encodes a SAF document ID into a URL-safe opaque identifier.
         */
        fun encodeOpaqueId(documentId: String): String {
            val bytes = documentId.toByteArray(StandardCharsets.UTF_8)
            val base64 = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
            return "$OPAQUE_ID_PREFIX$base64"
        }

        /**
         * Decodes an opaque identifier back into the original SAF document ID.
         */
        fun decodeOpaqueId(opaqueId: String): String? {
            return try {
                val cleanToken = if (opaqueId.startsWith(OPAQUE_ID_PREFIX)) {
                    opaqueId.substring(OPAQUE_ID_PREFIX.length)
                } else {
                    opaqueId
                }
                val bytes = java.util.Base64.getUrlDecoder().decode(cleanToken)
                String(bytes, StandardCharsets.UTF_8)
            } catch (e: Exception) {
                null
            }
        }
    }

    // In-memory registry for fast resolution of opaque ID -> StatusDocument
    private val documentCache = ConcurrentHashMap<String, StatusDocument>()

    /** Registers only media discovered inside the selected WhatsApp source directories. */
    fun scanFiles(roots: List<File>, targetPackage: String): List<StatusDocument> {
        return registerFiles(StatusFileCatalog.scan(roots, targetPackage))
    }

    fun scanSavedFiles(roots: List<File>): List<StatusDocument> {
        val directories = roots.flatMap { root -> listOf(
            File(root, MediaStoreSaver.IMAGE_RELATIVE_PATH),
            File(root, MediaStoreSaver.VIDEO_RELATIVE_PATH)
        ) }
        return registerFiles(StatusFileCatalog.mediaFiles(directories), saved = true)
    }

    private fun registerFiles(files: List<File>, saved: Boolean = false): List<StatusDocument> {
        val savedPrefs = context.getSharedPreferences("keeva_saved_status", Context.MODE_PRIVATE)
        return files.map { file ->
            val mime = requireNotNull(StatusFileCatalog.mimeType(file.name))
            val id = "file_" + ThumbnailManager.getSafeCacheKey(file.canonicalPath)
            val document = StatusDocument(
                id = id,
                documentId = id,
                displayName = file.name,
                mimeType = mime,
                sizeBytes = file.length(),
                lastModified = file.lastModified(),
                isVideo = mime.startsWith("video/"),
                documentUri = Uri.fromFile(file),
                isSaved = saved || savedPrefs.getBoolean(id, false) || savedPrefs.getBoolean(file.name, false)
            )
            documentCache[id] = document
            document
        }
    }

    /**
     * Enumerates status files from the specified .Statuses document ID within the tree URI.
     */
    fun scanStatuses(treeUri: Uri, statusesDocId: String): List<StatusDocument> {
        val resultList = mutableListOf<StatusDocument>()
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, statusesDocId)

        val savedPrefs = context.getSharedPreferences("keeva_saved_status", Context.MODE_PRIVATE)
        val picturesDir = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES), "SavedStatus")
        val moviesDir = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MOVIES), "SavedStatus")

        try {
            context.contentResolver.query(childrenUri, PROJECTION, null, null, null)?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_SIZE)
                val modCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

                while (cursor.moveToNext()) {
                    val docId = cursor.getString(idCol) ?: continue
                    val name = cursor.getString(nameCol) ?: ""
                    val mime = cursor.getString(mimeCol) ?: ""
                    val size = if (cursor.isNull(sizeCol)) 0L else cursor.getLong(sizeCol)
                    val lastMod = if (cursor.isNull(modCol)) 0L else cursor.getLong(modCol)

                    // Skip directories and sentinel files
                    if (name.equals(".nomedia", ignoreCase = true) ||
                        mime == DocumentsContract.Document.MIME_TYPE_DIR
                    ) {
                        continue
                    }

                    val lowerName = name.lowercase(java.util.Locale.ROOT)
                        // WhatsApp may expose temporary files while media is still being written.
                        // They must be left for a later scan instead of becoming broken statuses.
                        if (name.startsWith('.') || size <= 0L ||
                        lowerName.endsWith(".tmp") || lowerName.endsWith(".part") ||
                        lowerName.endsWith(".pending")) {
                        continue
                        }

                    val isVideo = mime.startsWith("video/") ||
                            lowerName.endsWith(".mp4") ||
                            lowerName.endsWith(".m4v") ||
                            lowerName.endsWith(".3gp") ||
                            lowerName.endsWith(".mov") ||
                            lowerName.endsWith(".mkv") ||
                            lowerName.endsWith(".webm")

                    val isImage = mime.startsWith("image/") ||
                            lowerName.endsWith(".jpg") ||
                            lowerName.endsWith(".jpeg") ||
                            lowerName.endsWith(".png") ||
                            lowerName.endsWith(".webp") ||
                            lowerName.endsWith(".gif") ||
                            lowerName.endsWith(".heic") ||
                            lowerName.endsWith(".heif") ||
                            lowerName.endsWith(".avif")

                    // Filter out unsupported non-media entries
                    if (!isVideo && !isImage) {
                        continue
                    }

                    val normalizedMime = when {
                        mime.isNotEmpty() -> mime
                        isVideo -> when {
                            lowerName.endsWith(".3gp") -> "video/3gpp"
                            lowerName.endsWith(".mov") -> "video/quicktime"
                            lowerName.endsWith(".mkv") -> "video/x-matroska"
                            lowerName.endsWith(".webm") -> "video/webm"
                            else -> "video/mp4"
                        }
                        lowerName.endsWith(".gif") -> "image/gif"
                        lowerName.endsWith(".heic") || lowerName.endsWith(".heif") -> "image/heic"
                        lowerName.endsWith(".avif") -> "image/avif"
                        lowerName.endsWith(".png") -> "image/png"
                        lowerName.endsWith(".webp") -> "image/webp"
                        else -> "image/jpeg"
                    }

                    val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    val opaqueId = encodeOpaqueId(docId)
                    val isSaved = savedPrefs.getBoolean(opaqueId, false) ||
                            savedPrefs.getBoolean(name, false) ||
                            (if (isVideo) File(moviesDir, name).exists() else File(picturesDir, name).exists())

                    val statusDoc = StatusDocument(
                        id = opaqueId,
                        documentId = docId,
                        displayName = name,
                        mimeType = normalizedMime,
                        sizeBytes = size,
                        lastModified = lastMod,
                        isVideo = isVideo,
                        documentUri = docUri,
                        isSaved = isSaved
                    )

                    documentCache[opaqueId] = statusDoc
                    resultList.add(statusDoc)
                }
            }

            // Deterministic chronological ordering: newest status moments first
            resultList.sortByDescending { it.lastModified }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to scan statuses for treeUri: $treeUri, docId: $statusesDocId", e)
            throw e
        }

        return resultList
    }

    /**
     * Resolves an opaque identifier back to its native SAF Document URI.
     */
    fun resolveDocumentUri(opaqueOrRawId: String, fallbackTreeUri: Uri? = null): Uri? {
        // 1. Check in-memory registry
        documentCache[opaqueOrRawId]?.let { return it.documentUri }

        // 2. If already a content:// URI string (backward compatibility)
        if (opaqueOrRawId.startsWith("content://")) {
            return try {
                Uri.parse(opaqueOrRawId)
            } catch (_: Exception) {
                null
            }
        }

        // 3. Decode opaque identifier
        val docId = decodeOpaqueId(opaqueOrRawId) ?: opaqueOrRawId
        val treeUri = fallbackTreeUri ?: findPersistedTreeUri()

        return if (treeUri != null && docId.isNotEmpty()) {
            DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
        } else {
            null
        }
    }

    /**
     * Retrieves cached StatusDocument metadata by opaque ID.
     */
    fun getCachedDocument(opaqueId: String): StatusDocument? = documentCache[opaqueId]

    /**
     * Safely opens an InputStream from ContentResolver for the document URI.
     */
    fun openInputStream(documentUri: Uri): InputStream? {
        return try {
            context.contentResolver.openInputStream(documentUri)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open InputStream for $documentUri", e)
            null
        }
    }

    /**
     * Safely opens a ParcelFileDescriptor from ContentResolver for the document URI.
     */
    fun openFileDescriptor(documentUri: Uri, mode: String = "r"): ParcelFileDescriptor? {
        return try {
            context.contentResolver.openFileDescriptor(documentUri, mode)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open FileDescriptor for $documentUri", e)
            null
        }
    }

    /**
     * Returns the last persisted tree URI by checking SharedPreferences first
     * (keeva_storage_prefs / tree_uri_<pkg>) so we don't blindly return the wrong
     * package's URI. Falls back to any persisted tree URI only if prefs is empty.
     *
     * NOTE: This fallback is only used for legacy document URI resolution from cache.
     * The primary scan path always calls getPersistedReadTreeUri(targetPackage) on
     * SafStorageManager which does strict package isolation.
     */
    private fun findPersistedTreeUri(): Uri? {
        return try {
            // Prefer the Standard WhatsApp URI from prefs first, then Business, then any
            val prefs = context.getSharedPreferences("keeva_storage_prefs", Context.MODE_PRIVATE)
            val standardUri = prefs.getString("tree_uri_com.whatsapp", null)
            if (standardUri != null) {
                val uri = Uri.parse(standardUri)
                val stillValid = context.contentResolver.persistedUriPermissions
                    .any { it.isReadPermission && it.uri == uri }
                if (stillValid) {
                    Log.d(TAG, "findPersistedTreeUri → Standard WhatsApp URI from prefs: $uri")
                    return uri
                }
            }

            val businessUri = prefs.getString("tree_uri_com.whatsapp.w4b", null)
            if (businessUri != null) {
                val uri = Uri.parse(businessUri)
                val stillValid = context.contentResolver.persistedUriPermissions
                    .any { it.isReadPermission && it.uri == uri }
                if (stillValid) {
                    Log.d(TAG, "findPersistedTreeUri → Business URI from prefs: $uri")
                    return uri
                }
            }

            // Last resort: first available tree URI
            val fallback = context.contentResolver.persistedUriPermissions
                .firstOrNull { it.isReadPermission && DocumentsContract.isTreeUri(it.uri) }?.uri
            Log.d(TAG, "findPersistedTreeUri → last resort fallback: $fallback")
            fallback
        } catch (e: Exception) {
            Log.e(TAG, "findPersistedTreeUri failed", e)
            null
        }
    }
}
