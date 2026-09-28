package ratedwhats.appstatusdownloader.status

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Native facade and MethodChannel coordinator for the WhatsApp Status Saver.
 * Coordinates file permissions, media discovery, saving, and thumbnail/video caches.
 * All heavy storage and ContentResolver operations are dispatched to Dispatchers.IO.
 */
class AndroidStatusScanner(
    private val activity: Activity,
    private val safStorageManager: SafStorageManager = SafStorageManager(activity),
    private val statusDocumentReader: StatusDocumentReader = StatusDocumentReader(activity),
    private val mediaStoreSaver: MediaStoreSaver = MediaStoreSaver(activity),
    private val thumbnailManager: ThumbnailManager = ThumbnailManager(activity),
    private val videoCacheManager: VideoCacheManager = VideoCacheManager(activity)
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "ratedwhats.appstatusdownloader/scanner"
        private const val TAG = "AndroidStatusScanner"
    }

    object ErrorCodes {
        const val ACCESS_NOT_GRANTED = "ACCESS_NOT_GRANTED"
        const val ACCESS_REVOKED = "ACCESS_REVOKED"
        const val INVALID_FOLDER = "INVALID_FOLDER"
        const val STATUSES_UNAVAILABLE = "STATUSES_UNAVAILABLE"
        const val DOCUMENT_NOT_FOUND = "DOCUMENT_NOT_FOUND"
        const val READ_FAILED = "READ_FAILED"
        const val THUMBNAIL_FAILED = "THUMBNAIL_FAILED"
        const val VIDEO_CACHE_FAILED = "VIDEO_CACHE_FAILED"
        const val MEDIASTORE_INSERT_FAILED = "MEDIASTORE_INSERT_FAILED"
        const val MEDIASTORE_COPY_FAILED = "MEDIASTORE_COPY_FAILED"
        const val MEDIASTORE_FINALIZE_FAILED = "MEDIASTORE_FINALIZE_FAILED"
        const val CACHE_WRITE_FAILED = "CACHE_WRITE_FAILED"
        const val UNKNOWN = "UNKNOWN"
    }

    private var channel: MethodChannel? = null
    private val directStorageAccess = DirectStorageAccess(activity)
    private var pendingAccessResult: MethodChannel.Result? = null
    private var pendingTargetPackage: String? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    fun registerWith(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler(this@AndroidStatusScanner)
        }
    }

    fun dispose() {
        channel?.setMethodCallHandler(null)
        channel = null
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkFolderAccess" -> handleCheckFolderAccess(call, result)
            "requestFolderAccess" -> handleRequestFolderAccess(call, result)
            "scanStatuses", "getStatuses", "getSavedStatuses" -> handleScanStatuses(call, result)
            "getThumbnail" -> handleGetThumbnail(call, result)
            "prepareVideo" -> handlePrepareVideo(call, result)
            "saveStatus" -> handleSaveStatus(call, result)
            "shareStatus" -> handleShareStatus(call, result)
            "clearCaches", "clearCache" -> handleClearCaches(result)
            "getCacheStats" -> handleGetCacheStats(result)
            "revokeAccess" -> handleRevokeAccess(call, result)
            // Backward-compatibility handlers for transitional POC
            "verifyMediaRead" -> handleVerifyMediaRead(call, result)
            "saveTestImage" -> handleSaveTestImage(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleCheckFolderAccess(call: MethodCall, result: MethodChannel.Result) {
        val targetPackage = call.argument<String>("targetPackage") ?: SafStorageManager.WHATSAPP_STANDARD
        scope.launch {
            try {
                val accessResult = withContext(Dispatchers.IO) {
                    directStorageAccess.result(targetPackage)
                }
                result.success(accessResult)
            } catch (e: Exception) {
                Log.e(TAG, "checkFolderAccess failed", e)
                result.error(ErrorCodes.UNKNOWN, e.message, null)
            }
        }
    }

    private fun handleRequestFolderAccess(call: MethodCall, result: MethodChannel.Result) {
        if (pendingAccessResult != null) {
            result.error("ALREADY_PENDING", "Another access request is active", null)
            return
        }
        val targetPackage = call.argument<String>("targetPackage") ?: SafStorageManager.WHATSAPP_STANDARD
        pendingAccessResult = result
        pendingTargetPackage = targetPackage

        try {
            if (directStorageAccess.hasAccess()) {
                completeAccessRequest()
            } else {
                directStorageAccess.request()
            }
        } catch (e: Exception) {
            pendingAccessResult = null
            pendingTargetPackage = null
            Log.e(TAG, "Could not open storage permission settings")
            result.error("LAUNCH_FAILED", "Could not open permission settings. Please try again.", null)
        }
    }

    private fun completeAccessRequest() {
        val result = pendingAccessResult ?: return
        val targetPackage = pendingTargetPackage ?: SafStorageManager.WHATSAPP_STANDARD
        pendingAccessResult = null
        pendingTargetPackage = null
        result.success(directStorageAccess.result(targetPackage))
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode == DirectStorageAccess.REQUEST_CODE) completeAccessRequest()
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == DirectStorageAccess.REQUEST_CODE) completeAccessRequest()
    }

    private fun handleScanStatuses(call: MethodCall, result: MethodChannel.Result) {
        val targetPackage = call.argument<String>("targetPackage") ?: SafStorageManager.WHATSAPP_STANDARD
        scope.launch {
            try {
                val items = withContext(Dispatchers.IO) {
                    if (!directStorageAccess.hasAccess()) {
                        throw SecurityException("Allow file access to see statuses.")
                    }
                    val roots = directStorageAccess.storageRoots()
                    if (call.method == "getSavedStatuses") {
                        statusDocumentReader.scanSavedFiles(roots)
                    } else {
                        statusDocumentReader.scanFiles(roots, targetPackage)
                    }
                }
                result.success(items.map { it.toMap() })
            } catch (e: SecurityException) {
                result.error(ErrorCodes.ACCESS_REVOKED, "Allow file access to see statuses.", null)
            } catch (e: IllegalArgumentException) {
                result.error("INVALID_ARG", "Unsupported status source.", null)
            } catch (e: Exception) {
                Log.e(TAG, "Status discovery failed")
                result.error(ErrorCodes.READ_FAILED, "Could not load statuses. Please try again.", null)
            }
        }
    }

    private fun handleGetThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
            result.error("INVALID_ARG", "id is required", null)
            return
        }
        val isVideo = call.argument<Boolean>("isVideo") ?: false
        val width = call.argument<Int>("width") ?: ThumbnailManager.TARGET_SIZE
        val height = call.argument<Int>("height") ?: ThumbnailManager.TARGET_SIZE

        scope.launch {
            try {
                val filePath = withContext(Dispatchers.IO) {
                    val docUri = statusDocumentReader.resolveDocumentUri(id)
                        ?: throw IllegalArgumentException("Document not found for id: $id")
                    val isVideoItem = isVideo || statusDocumentReader.getCachedDocument(id)?.isVideo == true
                    thumbnailManager.getThumbnail(id, docUri, isVideoItem, width, height)
                }
                result.success(mapOf("filePath" to filePath))
            } catch (e: IllegalArgumentException) {
                result.error(ErrorCodes.DOCUMENT_NOT_FOUND, e.message, null)
            } catch (e: Exception) {
                Log.e(TAG, "getThumbnail failed for id: $id", e)
                result.error(ErrorCodes.THUMBNAIL_FAILED, e.message, null)
            }
        }
    }

    private fun handlePrepareVideo(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
            result.error("INVALID_ARG", "id is required", null)
            return
        }
        val sizeBytes = call.argument<Number>("sizeBytes")?.toLong() ?: 0L

        scope.launch {
            try {
                val filePath = withContext(Dispatchers.IO) {
                    val docUri = statusDocumentReader.resolveDocumentUri(id)
                        ?: throw IllegalArgumentException("Document not found for id: $id")
                    val expectedSize = if (sizeBytes > 0L) {
                        sizeBytes
                    } else {
                        statusDocumentReader.getCachedDocument(id)?.sizeBytes ?: 0L
                    }
                    videoCacheManager.prepareVideo(id, docUri, expectedSize)
                }
                result.success(mapOf("filePath" to filePath))
            } catch (e: IllegalArgumentException) {
                result.error(ErrorCodes.DOCUMENT_NOT_FOUND, e.message, null)
            } catch (e: Exception) {
                Log.e(TAG, "prepareVideo failed for id: $id", e)
                result.error(ErrorCodes.VIDEO_CACHE_FAILED, e.message, null)
            }
        }
    }

    private fun handleSaveStatus(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
            result.error("INVALID_ARG", "id is required", null)
            return
        }

        val cachedDoc = statusDocumentReader.getCachedDocument(id)
        val displayName = call.argument<String>("displayName")
            ?: cachedDoc?.displayName
            ?: "status_${System.currentTimeMillis()}"
        val mimeType = call.argument<String>("mimeType")
            ?: cachedDoc?.mimeType
            ?: "image/jpeg"
        val isVideo = call.argument<Boolean>("isVideo")
            ?: cachedDoc?.isVideo
            ?: mimeType.startsWith("video/")

        scope.launch {
            try {
                val saveResult = withContext(Dispatchers.IO) {
                    val docUri = statusDocumentReader.resolveDocumentUri(id)
                        ?: throw IllegalArgumentException("Document not found for id: $id")
                    mediaStoreSaver.saveMedia(docUri, displayName, mimeType, isVideo)
                }

                if (saveResult.success) {
                    val savedPrefs = activity.getSharedPreferences("wa_status_downloader_saved_status", Context.MODE_PRIVATE)
                    savedPrefs.edit()
                        .putBoolean(id, true)
                        .putBoolean(displayName, true)
                        .apply()
                    result.success(saveResult.toMap())
                } else {
                    result.error(ErrorCodes.MEDIASTORE_COPY_FAILED, saveResult.error, saveResult.toMap())
                }
            } catch (e: IllegalArgumentException) {
                result.error(ErrorCodes.DOCUMENT_NOT_FOUND, e.message, null)
            } catch (e: Exception) {
                Log.e(TAG, "saveStatus failed for id: $id", e)
                result.error(ErrorCodes.MEDIASTORE_COPY_FAILED, e.message, null)
            }
        }
    }

    private fun handleShareStatus(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
            result.error("INVALID_ARG", "id is required", null)
            return
        }

        val cachedDoc = statusDocumentReader.getCachedDocument(id)
        val displayName = call.argument<String>("displayName")
            ?: cachedDoc?.displayName
            ?: "status_${System.currentTimeMillis()}"
        val mimeType = call.argument<String>("mimeType")
            ?: cachedDoc?.mimeType
            ?: "image/jpeg"
        val isVideo = call.argument<Boolean>("isVideo")
            ?: cachedDoc?.isVideo
            ?: mimeType.startsWith("video/")

        scope.launch {
            try {
                val shareFile = withContext(Dispatchers.IO) {
                    if (isVideo) {
                        val docUri = statusDocumentReader.resolveDocumentUri(id)
                            ?: throw IllegalArgumentException("Document not found for id: $id")
                        val expectedSize = cachedDoc?.sizeBytes ?: 0L
                        val path = videoCacheManager.prepareVideo(id, docUri, expectedSize)
                        java.io.File(path)
                    } else {
                        val docUri = statusDocumentReader.resolveDocumentUri(id)
                            ?: throw IllegalArgumentException("Document not found for id: $id")
                        val sharedDir = java.io.File(activity.cacheDir, "shared").apply {
                            if (!exists()) mkdirs()
                        }
                        val cleanName = if (displayName.contains(".")) displayName else "$displayName.jpg"
                        val destFile = java.io.File(sharedDir, cleanName)

                        val inputStream = statusDocumentReader.openInputStream(docUri)
                            ?: throw java.io.IOException("Failed to open inputStream for $docUri")
                        inputStream.use { input ->
                            java.io.FileOutputStream(destFile).use { output ->
                                input.copyTo(output)
                                output.flush()
                            }
                        }
                        destFile
                    }
                }

                val contentUri = androidx.core.content.FileProvider.getUriForFile(
                    activity,
                    "${activity.packageName}.fileprovider",
                    shareFile
                )

                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = mimeType
                    putExtra(Intent.EXTRA_STREAM, contentUri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }

                val chooser = Intent.createChooser(shareIntent, "Share Moment").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(chooser)

                result.success(mapOf("success" to true))
            } catch (e: IllegalArgumentException) {
                result.error(ErrorCodes.DOCUMENT_NOT_FOUND, e.message, null)
            } catch (e: Exception) {
                Log.e(TAG, "shareStatus failed for id: $id", e)
                result.error(ErrorCodes.UNKNOWN, e.message, null)
            }
        }
    }

    private fun handleClearCaches(result: MethodChannel.Result) {
        scope.launch {
            try {
                val (thumbFreed, videoFreed) = withContext(Dispatchers.IO) {
                    val t = thumbnailManager.clearCache()
                    val v = videoCacheManager.clearCache()
                    Pair(t, v)
                }
                result.success(
                    mapOf(
                        "freedBytes" to (thumbFreed + videoFreed),
                        "thumbnailFreedBytes" to thumbFreed,
                        "videoFreedBytes" to videoFreed
                    )
                )
            } catch (e: Exception) {
                result.error(ErrorCodes.UNKNOWN, e.message, null)
            }
        }
    }

    private fun handleGetCacheStats(result: MethodChannel.Result) {
        scope.launch {
            try {
                val (thumbBytes, videoBytes) = withContext(Dispatchers.IO) {
                    Pair(thumbnailManager.getCacheSizeBytes(), videoCacheManager.getCacheSizeBytes())
                }
                result.success(
                    mapOf(
                        "thumbnailCacheBytes" to thumbBytes,
                        "videoCacheBytes" to videoBytes,
                        "totalCacheBytes" to (thumbBytes + videoBytes)
                    )
                )
            } catch (e: Exception) {
                result.error(ErrorCodes.UNKNOWN, e.message, null)
            }
        }
    }

    private fun handleRevokeAccess(call: MethodCall, result: MethodChannel.Result) {
        val targetPackage = call.argument<String>("targetPackage") ?: SafStorageManager.WHATSAPP_STANDARD
        scope.launch {
            try {
                val treeUri = withContext(Dispatchers.IO) {
                    safStorageManager.getPersistedReadTreeUri(targetPackage)
                }
                val revoked = if (treeUri != null) {
                    withContext(Dispatchers.IO) {
                        safStorageManager.releasePersistablePermission(treeUri, targetPackage)
                    }
                } else {
                    false
                }
                result.success(mapOf("revoked" to revoked))
            } catch (e: Exception) {
                result.error(ErrorCodes.UNKNOWN, e.message, null)
            }
        }
    }

    // --- Backward compatibility for POC main.dart ---

    private fun handleVerifyMediaRead(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString.isNullOrEmpty()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        scope.launch {
            try {
                val (success, bytesRead, error) = withContext(Dispatchers.IO) {
                    val docUri = statusDocumentReader.resolveDocumentUri(uriString)
                        ?: Uri.parse(uriString)
                    val inputStream = statusDocumentReader.openInputStream(docUri)
                    if (inputStream == null) {
                        Triple(false, 0L, "Failed to open inputStream for $docUri")
                    } else {
                        var total = 0L
                        val buffer = ByteArray(16384)
                        inputStream.use { stream ->
                            var read: Int
                            while (stream.read(buffer).also { read = it } != -1) {
                                total += read
                            }
                        }
                        Triple(true, total, null)
                    }
                }
                result.success(
                    mapOf(
                        "success" to success,
                        "bytesRead" to bytesRead,
                        "error" to error
                    )
                )
            } catch (e: Exception) {
                result.success(
                    mapOf(
                        "success" to false,
                        "bytesRead" to 0L,
                        "error" to (e.message ?: e.toString())
                    )
                )
            }
        }
    }

    private fun handleSaveTestImage(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val displayName = call.argument<String>("displayName") ?: "status_test.jpg"
        if (uriString.isNullOrEmpty()) {
            result.error("INVALID_ARG", "URI is required", null)
            return
        }

        scope.launch {
            try {
                val saveResult = withContext(Dispatchers.IO) {
                    val docUri = statusDocumentReader.resolveDocumentUri(uriString)
                        ?: Uri.parse(uriString)
                    mediaStoreSaver.saveMedia(docUri, displayName, "image/jpeg", false)
                }
                result.success(
                    mapOf(
                        "success" to saveResult.success,
                        "insertedUri" to saveResult.insertedUri,
                        "bytesCopied" to saveResult.bytesSaved,
                        "error" to saveResult.error
                    )
                )
            } catch (e: Exception) {
                result.success(
                    mapOf(
                        "success" to false,
                        "error" to (e.message ?: e.toString())
                    )
                )
            }
        }
    }
}
