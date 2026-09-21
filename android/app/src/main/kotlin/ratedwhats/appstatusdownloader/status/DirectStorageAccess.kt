package ratedwhats.appstatusdownloader.status

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.Settings
import java.io.File

/** User-initiated Android file permission, without a directory picker. */
class DirectStorageAccess(private val activity: Activity) {
    companion object {
        const val REQUEST_CODE = 4203
    }

    fun hasAccess(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        Environment.isExternalStorageManager()
    } else {
        activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
            PackageManager.PERMISSION_GRANTED &&
            activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun request() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:${activity.packageName}")
            )
            try {
                activity.startActivityForResult(intent, REQUEST_CODE)
            } catch (_: android.content.ActivityNotFoundException) {
                activity.startActivityForResult(
                    Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION), REQUEST_CODE
                )
            }
        } else {
            val deniedPermanently = activity.getPreferences(Context.MODE_PRIVATE)
                .getBoolean("storage_requested", false) &&
                !activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_EXTERNAL_STORAGE) &&
                !activity.shouldShowRequestPermissionRationale(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            if (deniedPermanently) {
                activity.startActivityForResult(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${activity.packageName}")), REQUEST_CODE
                )
            } else {
                activity.getPreferences(Context.MODE_PRIVATE).edit()
                    .putBoolean("storage_requested", true).apply()
                activity.requestPermissions(arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                ), REQUEST_CODE)
            }
        }
    }

    @Suppress("DEPRECATION")
    fun storageRoots(): List<File> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val manager = activity.getSystemService(StorageManager::class.java)
            return manager.storageVolumes.mapNotNull { volume ->
                volume.directory?.takeIf {
                    volume.state == Environment.MEDIA_MOUNTED ||
                        volume.state == Environment.MEDIA_MOUNTED_READ_ONLY
                }
            }
        }
        // External app directories identify mounted volumes without a fixed /sdcard path.
        val roots = activity.getExternalFilesDirs(null).mapNotNull { directory ->
            directory?.parentFile?.parentFile?.parentFile?.parentFile
        }
        return (roots + Environment.getExternalStorageDirectory()).distinct()
    }

    fun result(targetPackage: String): Map<String, Any?> {
        val granted = hasAccess()
        return mapOf(
            "hasAccess" to granted,
            "granted" to granted,
            "status" to if (granted) "valid" else "not_granted",
            "targetPackage" to targetPackage
        )
    }
}
