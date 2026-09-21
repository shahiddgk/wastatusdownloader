package ratedwhats.appstatusdownloader.status

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.util.Log

enum class ValidationStatus {
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
    val status: ValidationStatus = if (hasAccess) ValidationStatus.VALID else ValidationStatus.INVALID,
    val resolvedStatusesDocId: String? = null,
    val targetPackage: String = "com.whatsapp"
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "hasAccess" to hasAccess,
        "treeUri" to treeUri?.toString(),
        "status" to status.name.lowercase(),
        "resolvedStatusesDocId" to resolvedStatusesDocId,
        "targetPackage" to targetPackage
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
        private const val PREFS_NAME = "keeva_storage_prefs"
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
            val relativePath = if (targetPackage == WHATSAPP_BUSINESS) {
                "Android/media/com.whatsapp.w4b/WhatsApp Business/Media"
            } else {
                "Android/media/com.whatsapp/WhatsApp/Media"
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

    /**
     * Takes persistable read permission on the granted tree URI and records it per package.
     */
    fun takePersistablePermission(treeUri: Uri, targetPackage: String? = null): Boolean {
        return try {
            context.contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            val pkg = targetPackage ?: detectPackageFromTreeUri(treeUri)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString("tree_uri_$pkg", treeUri.toString())
                .putString("last_active_package", pkg)
                .apply()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to take persistable URI permission", e)
            false
        }
    }

    /**
     * Releases persistable read permission on the tree URI and removes from prefs.
     */
    fun releasePersistablePermission(treeUri: Uri, targetPackage: String? = null): Boolean {
        return try {
            context.contentResolver.releasePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            val pkg = targetPackage ?: detectPackageFromTreeUri(treeUri)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .remove("tree_uri_$pkg")
                .apply()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release persistable URI permission", e)
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

            if (persistedPerms.isEmpty()) {
                Log.d(TAG, "  → No persisted URIs found, returning null")
                return null
            }

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val savedUriString = prefs.getString("tree_uri_$targetPackage", null)
            Log.d(TAG, "  SharedPrefs[tree_uri_$targetPackage] = $savedUriString")

            if (savedUriString != null) {
                // Use STRING comparison, NOT Uri.equals() — Uri equality is encoding-sensitive
                // and can return false for identical URIs with different percent-encoding.
                val existsInPerms = persistedPerms.any { it.uri.toString() == savedUriString }
                Log.d(TAG, "  savedUri exists in Android persisted permissions: $existsInPerms")
                if (existsInPerms) {
                    val uri = Uri.parse(savedUriString)
                    Log.d(TAG, "  → ✓ Returning saved URI from prefs: $uri")
                    return uri
                }
                // DO NOT delete the pref here. The URI might still be valid but
                // Android may have re-encoded it differently. Fall through to fallback scan.
                Log.w(TAG, "  → savedUri not found in persistedPerms by string match. Falling through to URI scan.")
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
        val treeUri = getPersistedReadTreeUri(targetPackage)
            ?: return AccessCheckResult(hasAccess = false, targetPackage = targetPackage)

        val validation = validateTreeUri(treeUri, targetPackage)
        val hasAccess = validation.status == ValidationStatus.VALID || validation.status == ValidationStatus.VALID_PARENT

        return AccessCheckResult(
            hasAccess = hasAccess,
            treeUri = if (hasAccess) treeUri else null,
            status = validation.status,
            resolvedStatusesDocId = validation.resolvedStatusesDocId,
            targetPackage = targetPackage
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

        // Check if root or completely unrelated folder
        if (normalizedDocId.endsWith(":") || normalizedDocId == "primary" ||
            normalizedDocId.contains("DCIM", ignoreCase = true) ||
            normalizedDocId.contains("Download", ignoreCase = true) ||
            normalizedDocId.contains("Pictures", ignoreCase = true)
        ) {
            // Unrelated system folder or root
            if (!normalizedDocId.contains("WhatsApp", ignoreCase = true) &&
                !normalizedDocId.contains("media", ignoreCase = true)
            ) {
                return ValidationResult(ValidationStatus.INVALID, errorMessage = "Selected folder is not related to WhatsApp")
            }
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

        // Fallback: bounded recursive traversal from treeDocId to discover .Statuses
        val discoveredDocId = findStatusesFolderRecursively(treeUri, treeDocId, depth = 0)
        if (discoveredDocId != null) {
            val queryResult = testQueryDocId(treeUri, discoveredDocId)
            if (queryResult != null) {
                return queryResult.copy(status = ValidationStatus.VALID_PARENT)
            }
        }

        // If tree hierarchy matches WhatsApp ancestors but .Statuses was not discovered
        val isWhatsAppAncestor = normalizedDocId.contains("WhatsApp", ignoreCase = true) ||
                normalizedDocId.contains(expectedPkg, ignoreCase = true) ||
                normalizedDocId.endsWith("Android/media", ignoreCase = true)

        return if (isWhatsAppAncestor) {
            ValidationResult(
                ValidationStatus.UNAVAILABLE,
                errorMessage = "WhatsApp status folder not found. View a status in WhatsApp first."
            )
        } else {
            ValidationResult(
                ValidationStatus.INVALID,
                errorMessage = "Selected folder does not contain WhatsApp media."
            )
        }
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
