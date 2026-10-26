package ratedwhats.appstatusdownloader.status

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.util.Log

enum class ValidationStatus {
    NOT_GRANTED,
    VALID,
    VALID_PARENT,
    INVALID,
    UNAVAILABLE,
    PERMISSION_REVOKED
}

data class ValidationResult(
    val status: ValidationStatus,
    val resolvedStatusesDocId: String? = null,
    val errorMessage: String? = null
)

data class AccessCheckResult(
    val hasAccess: Boolean,
    val treeUri: Uri? = null,
    val status: ValidationStatus = if (hasAccess) ValidationStatus.VALID else ValidationStatus.NOT_GRANTED,
    val resolvedStatusesDocId: String? = null,
    val targetPackage: String = "com.whatsapp",
    val errorMessage: String? = null
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "hasAccess" to hasAccess,
        "treeUri" to treeUri?.toString(),
        "status" to status.name.lowercase(),
        "resolvedStatusesDocId" to resolvedStatusesDocId,
        "targetPackage" to targetPackage,
        "error" to errorMessage
    )
}

/**
 * Manages Android Storage Access Framework (SAF) tree URI selection,
 * permission persistence, advisory initial URI construction, and
 * deterministic 7-step tree validation.
 */
class SafStorageManager(private val context: Context) {

    companion object {
        private const val TAG = "SafStorageManager"
        const val WHATSAPP_STANDARD = "com.whatsapp"
        const val WHATSAPP_BUSINESS = "com.whatsapp.w4b"
        private const val PREFS_NAME = "wa_status_downloader_storage_prefs"
        private const val EXTERNAL_STORAGE_PROVIDER = "com.android.externalstorage.documents"
    }

    /**
     * Dynamically detects whether a tree URI belongs to WhatsApp Business or Standard.
     */
    fun detectPackageFromTreeUri(treeUri: Uri): String {
        val uriStr = treeUri.toString()
        return if (uriStr.contains("com.whatsapp.w4b", ignoreCase = true) ||
            uriStr.contains("WhatsApp%20Business", ignoreCase = true) ||
            uriStr.contains("WhatsApp Business", ignoreCase = true)
        ) {
            WHATSAPP_BUSINESS
        } else {
            WHATSAPP_STANDARD
        }
    }

    /**
     * Dynamically resolves the active storage volume identifier ("primary" or UUID).
     */
    fun resolveActiveVolumeId(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val storageManager = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            val primaryVolume = storageManager?.storageVolumes?.firstOrNull { it.isPrimary }
            if (primaryVolume != null) {
                return "primary"
            }
            val firstVolume = storageManager?.storageVolumes?.firstOrNull()
            if (firstVolume != null) {
                return firstVolume.uuid ?: "primary"
            }
        }
        return "primary"
    }

    /**
     * Builds the advisory initial URI for DocumentsUI navigation.
     * Note: EXTRA_INITIAL_URI is strictly advisory; DocumentsUI may ignore it.
     */
    fun buildInitialUri(targetPackage: String = WHATSAPP_STANDARD): Uri? {
        return try {
            val volumeId = resolveActiveVolumeId()
            val relativePath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (targetPackage == WHATSAPP_BUSINESS) {
                    "Android/media/com.whatsapp.w4b/WhatsApp Business/Media"
                } else {
                    "Android/media/com.whatsapp/WhatsApp/Media"
                }
            } else if (targetPackage == WHATSAPP_BUSINESS) {
                "WhatsApp Business/Media"
            } else {
                "WhatsApp/Media"
            }
            val docId = "$volumeId:$relativePath"
            DocumentsContract.buildDocumentUri(EXTERNAL_STORAGE_PROVIDER, docId)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to build advisory initial URI", e)
            null
        }
    }

    /**
     * Constructs the ACTION_OPEN_DOCUMENT_TREE intent with persistable read flags
     * and advisory initial URI.
     */
    fun createOpenDocumentTreeIntent(targetPackage: String = WHATSAPP_STANDARD): Intent {
        return Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
            buildInitialUri(targetPackage)?.let { initialUri ->
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
            }
        }
    }

    /** Takes the transient result grant as a persisted, read-only grant. */
    fun takePersistableReadPermission(treeUri: Uri, resultFlags: Int): Boolean {
        return try {
            val readFlags = resultFlags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            if (readFlags != Intent.FLAG_GRANT_READ_URI_PERMISSION) {
                Log.w(TAG, "The picker did not return a read grant for $treeUri")
                return false
            }
            context.contentResolver.takePersistableUriPermission(
                treeUri,
                readFlags
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to take persistable URI permission", e)
            false
        }
    }

    /**
     * Records a previously validated persisted tree URI. Any prior URI for this
     * source is released only after the replacement was saved successfully.
     */
    fun saveValidatedTreeUri(treeUri: Uri, targetPackage: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = "tree_uri_$targetPackage"
        val previousUriString = prefs.getString(key, null)
        val saved = prefs.edit()
            .putString(key, treeUri.toString())
            .putString("last_active_package", targetPackage)
            .commit()
        if (!saved) {
            Log.e(TAG, "Failed to save validated tree URI for $targetPackage")
            return false
        }

        if (previousUriString != null && previousUriString != treeUri.toString()) {
            releasePersistedReadPermission(Uri.parse(previousUriString))
        }
        return true
    }

    /** Releases a persisted read grant without changing stored source metadata. */
    fun releasePersistedReadPermission(treeUri: Uri): Boolean {
        return try {
            context.contentResolver.releasePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release persistable URI permission", e)
            false
        }
    }

    /**
     * Releases the user-selected tree and removes its matching saved source metadata.
     */
    fun releasePersistablePermission(treeUri: Uri, targetPackage: String): Boolean {
        val released = releasePersistedReadPermission(treeUri)
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val key = "tree_uri_$targetPackage"
            if (prefs.getString(key, null) == treeUri.toString()) {
                prefs.edit().remove(key).commit()
            }
            released
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear stored tree URI", e)
            false
        }
    }

    /**
     * Returns the active persisted read tree URI for the specified target package.
     *
     * IMPORTANT: Normal WhatsApp (com.whatsapp) and WhatsApp Business (com.whatsapp.w4b)
     * are strictly isolated. A Business URI will NEVER be returned for Normal WhatsApp,
     * because com.whatsapp.w4b URI strings also contain "com.whatsapp" as a substring.
     *
     * URI COMPARISON NOTE: We intentionally use string comparison (toString()) rather than
     * Uri.equals() because Uri.equals() is unreliable when URIs have different encoding
     * (e.g. %2F vs /). Using Uri.equals() was incorrectly deleting valid persisted URIs.
     */
    fun getPersistedReadTreeUri(targetPackage: String = WHATSAPP_STANDARD): Uri? {
        return try {
            val persistedPerms = context.contentResolver.persistedUriPermissions
                .filter { it.isReadPermission && DocumentsContract.isTreeUri(it.uri) }

            Log.d(TAG, "========== getPersistedReadTreeUri ==========")
            Log.d(TAG, "  targetPackage: $targetPackage")
            Log.d(TAG, "  total persisted tree URIs: ${persistedPerms.size}")
            persistedPerms.forEachIndexed { i, p ->
                Log.d(TAG, "  persisted[$i]: ${p.uri}")
            }

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val savedUriString = prefs.getString("tree_uri_$targetPackage", null)
            Log.d(TAG, "  SharedPrefs[tree_uri_$targetPackage] = $savedUriString")

            if (savedUriString != null) {
                val savedUri = Uri.parse(savedUriString)
                val matchingPermission = persistedPerms.firstOrNull { permission ->
                    sameTree(permission.uri, savedUri)
                }
                if (matchingPermission != null) {
                    Log.d(TAG, "  → ✓ Returning saved URI from prefs: ${matchingPermission.uri}")
                    return matchingPermission.uri
                }
                Log.w(TAG, "  → Stored URI is no longer a persisted read grant.")
                return null
            }

            if (persistedPerms.isEmpty()) {
                Log.d(TAG, "  → No persisted URIs found, returning null")
                return null
            }

            // Fallback: scan persisted permissions for a URI that strictly matches only the
            // target package. For Normal WhatsApp we MUST reject any URI that contains
            // "com.whatsapp.w4b" because that string also contains "com.whatsapp".
            val isTargetBusiness = targetPackage == WHATSAPP_BUSINESS
            Log.d(TAG, "  Fallback scan: isTargetBusiness=$isTargetBusiness")

            val matchingPerm = persistedPerms.firstOrNull { perm ->
                val permUriStr = perm.uri.toString()
                // Classify the URI: a URI is Business if it contains any Business-specific token.
                // We check for w4b FIRST and most specific patterns to prevent substring collision.
                val isBusinessUri = permUriStr.contains("com.whatsapp.w4b", ignoreCase = true) ||
                        permUriStr.contains("WhatsApp%20Business", ignoreCase = true) ||
                        permUriStr.contains("WhatsApp Business", ignoreCase = true)

                val matches = if (isTargetBusiness) {
                    // Want Business → only accept Business URIs
                    isBusinessUri
                } else {
                    // Want Normal WhatsApp → MUST reject Business URIs even though they contain "com.whatsapp"
                    !isBusinessUri && (
                        permUriStr.contains("com.whatsapp", ignoreCase = true) ||
                        permUriStr.contains("WhatsApp", ignoreCase = true)
                    )
                }
                Log.d(TAG, "  URI: $permUriStr  isBusinessUri=$isBusinessUri  matches=$matches")
                matches
            }

            if (matchingPerm != null) {
                Log.d(TAG, "  → ✓ Fallback matched URI: ${matchingPerm.uri}")
                // Save to prefs so next lookup is fast
                prefs.edit().putString("tree_uri_$targetPackage", matchingPerm.uri.toString()).apply()
                matchingPerm.uri
            } else {
                Log.w(TAG, "  → ✗ No matching URI found for package: $targetPackage")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to query persisted URI permissions", e)
            null
        }
    }

    /**
     * Checks existing persisted folder access and validates tree readability for the package.
     */
    fun checkAccess(targetPackage: String = WHATSAPP_STANDARD): AccessCheckResult {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hasStoredUri = prefs.contains("tree_uri_$targetPackage")
        val treeUri = getPersistedReadTreeUri(targetPackage)
            ?: return AccessCheckResult(
                hasAccess = false,
                status = if (hasStoredUri) {
                    ValidationStatus.PERMISSION_REVOKED
                } else {
                    ValidationStatus.NOT_GRANTED
                },
                targetPackage = targetPackage,
                errorMessage = if (hasStoredUri) {
                    "The selected folder is no longer available. Connect it again."
                } else {
                    "Connect the WhatsApp media folder to continue."
                }
            )

        val validation = validateTreeUri(treeUri, targetPackage)
        val hasAccess = validation.status == ValidationStatus.VALID || validation.status == ValidationStatus.VALID_PARENT

        return AccessCheckResult(
            hasAccess = hasAccess,
            treeUri = if (hasAccess) treeUri else null,
            status = validation.status,
            resolvedStatusesDocId = validation.resolvedStatusesDocId,
            targetPackage = targetPackage,
            errorMessage = validation.errorMessage
        )
    }

    /**
     * Deterministic 7-step SAF validation:
     * 1. URI sanity check (scheme == content, isTreeUri == true)
     * 2. Extract tree document ID safely
     * 3. Determine logical identity (volume, path)
     * 4. Resolve WhatsApp hierarchy (.Statuses, Media, WhatsApp, com.whatsapp, Android/media)
     * 5. Locate .Statuses subfolder
     * 6. Verify query capability with minimal cursor projection
     * 7. Classify result (VALID, VALID_PARENT, INVALID, UNAVAILABLE, PERMISSION_REVOKED)
     */
    fun validateTreeUri(treeUri: Uri, targetPackage: String = WHATSAPP_STANDARD): ValidationResult {
        // Step 1: URI sanity check
        if (treeUri.scheme != "content" || !DocumentsContract.isTreeUri(treeUri)) {
            return ValidationResult(ValidationStatus.INVALID, errorMessage = "URI is not a valid content tree URI")
        }

        // Step 2: Extract tree document ID
        val treeDocId = try {
            DocumentsContract.getTreeDocumentId(treeUri)
        } catch (e: Exception) {
            return ValidationResult(ValidationStatus.INVALID, errorMessage = "Failed to extract tree document ID: ${e.message}")
        }

        // Step 3 & 4: Determine logical identity & hierarchy
        val normalizedDocId = treeDocId.replace('\\', '/')
        val isTargetBusiness = targetPackage == WHATSAPP_BUSINESS
        val expectedPkg = if (isTargetBusiness) WHATSAPP_BUSINESS else WHATSAPP_STANDARD
        val expectedFolderName = if (isTargetBusiness) "WhatsApp Business" else "WhatsApp"

        if (!isExpectedWhatsAppTree(normalizedDocId, expectedPkg, expectedFolderName)) {
            return ValidationResult(
                ValidationStatus.INVALID,
                errorMessage = "Select the WhatsApp Media folder opened by the app."
            )
        }

        // Step 5: Locate .Statuses subfolder
        val candidateStatusesDocId = resolveCandidateStatusesDocId(normalizedDocId, expectedPkg, expectedFolderName)

        // Step 6: Verify query capability on candidate doc ID
        if (candidateStatusesDocId != null) {
            val queryResult = testQueryDocId(treeUri, candidateStatusesDocId)
            if (queryResult != null) {
                return queryResult
            }
        }

        // Fallback: bounded recursive traversal is deliberately constrained to the
        // selected WhatsApp package branch. A tree grant for Android/media must not
        // accidentally resolve a .Statuses folder owned by another app.
        val searchRootDocId = when {
            normalizedDocId.endsWith("Android/media") -> "$normalizedDocId/$expectedPkg"
            else -> treeDocId
        }
        val discoveredDocId = findStatusesFolderRecursively(treeUri, searchRootDocId, depth = 0)
        if (discoveredDocId != null) {
            val queryResult = testQueryDocId(treeUri, discoveredDocId)
            if (queryResult != null) {
                return queryResult.copy(status = ValidationStatus.VALID_PARENT)
            }
        }

        return ValidationResult(
            ValidationStatus.UNAVAILABLE,
            errorMessage = "WhatsApp status folder not found. View a status in WhatsApp first."
        )
    }

    private fun sameTree(first: Uri, second: Uri): Boolean =
        first.toString() == second.toString() || try {
            first.authority == second.authority &&
                DocumentsContract.getTreeDocumentId(first) == DocumentsContract.getTreeDocumentId(second)
        } catch (_: Exception) {
            false
        }

    private fun isExpectedWhatsAppTree(
        documentId: String,
        expectedPackage: String,
        expectedFolderName: String
    ): Boolean {
        val relativePath = documentId.substringAfter(':', "").trim('/')
        if (relativePath.isEmpty()) return false

        val acceptedRoots = listOf(
            "Android/media",
            "Android/media/$expectedPackage",
            "Android/media/$expectedPackage/$expectedFolderName",
            "Android/media/$expectedPackage/$expectedFolderName/Media",
            "Android/media/$expectedPackage/$expectedFolderName/Media/.Statuses",
            expectedFolderName,
            "$expectedFolderName/Media",
            "$expectedFolderName/Media/.Statuses"
        )
        return relativePath in acceptedRoots
    }

    private fun resolveCandidateStatusesDocId(
        normalizedDocId: String,
        expectedPkg: String,
        expectedFolderName: String
    ): String? {
        return when {
            normalizedDocId.endsWith("/.Statuses") -> normalizedDocId
            normalizedDocId.endsWith("/Media") || normalizedDocId.endsWith("$expectedFolderName/Media") -> "$normalizedDocId/.Statuses"
            normalizedDocId.endsWith(expectedFolderName) -> "$normalizedDocId/Media/.Statuses"
            normalizedDocId.endsWith(expectedPkg) -> "$normalizedDocId/$expectedFolderName/Media/.Statuses"
            normalizedDocId.endsWith("Android/media") -> "$normalizedDocId/$expectedPkg/$expectedFolderName/Media/.Statuses"
            else -> "$normalizedDocId/.Statuses"
        }
    }

    private fun testQueryDocId(treeUri: Uri, statusesDocId: String): ValidationResult? {
        return try {
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, statusesDocId)
            val projection = arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE
            )
            context.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                // Query succeeded; cursor is accessible
                val isDirectStatuses = statusesDocId.endsWith("/.Statuses")
                ValidationResult(
                    status = if (isDirectStatuses) ValidationStatus.VALID else ValidationStatus.VALID_PARENT,
                    resolvedStatusesDocId = statusesDocId
                )
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException during query capability test: permission revoked", e)
            ValidationResult(ValidationStatus.PERMISSION_REVOKED, errorMessage = e.message)
        } catch (e: Exception) {
            Log.w(TAG, "Query test failed for docId: $statusesDocId", e)
            null
        }
    }

    private fun findStatusesFolderRecursively(treeUri: Uri, currentDocId: String, depth: Int): String? {
        if (depth > 4) return null
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, currentDocId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE
        )
        return try {
            context.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)

                val subDirs = mutableListOf<String>()
                while (cursor.moveToNext()) {
                    val docId = cursor.getString(idCol)
                    val name = cursor.getString(nameCol) ?: ""
                    val mime = cursor.getString(mimeCol) ?: ""

                    if (name.equals(".Statuses", ignoreCase = true)) {
                        return docId
                    }
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        subDirs.add(docId)
                    }
                }

                for (subDirDocId in subDirs) {
                    val found = findStatusesFolderRecursively(treeUri, subDirDocId, depth + 1)
                    if (found != null) return found
                }
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
