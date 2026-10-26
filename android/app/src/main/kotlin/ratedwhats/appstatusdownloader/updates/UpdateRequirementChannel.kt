package ratedwhats.appstatusdownloader.updates

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Version codes are positive integers. A nullable versionCode explicitly clears
 * a requirement after Dart verifies that the installed version satisfies it.
 */
class UpdateRequirementChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private val updateManager by lazy { AppUpdateManagerFactory.create(activity) }
    private var currentInfo: AppUpdateInfo? = null
    private var pendingUpdate: MethodChannel.Result? = null
    private val pendingChecks = mutableSetOf<MethodChannel.Result>()
    private var checkGeneration = 0

    companion object {
        private const val UPDATE_REQUEST_CODE = 4305
    }
    private val requirements = UpdateRequirementStore(
        activity.getSharedPreferences("required_play_update", Context.MODE_PRIVATE),
    )

    fun registerWith(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "ratedwhats.appstatusdownloader/updates")
            .also { it.setMethodCallHandler(this) }
    }

    fun dispose() {
        currentInfo = null
        checkGeneration++
        finishUpdate("failed")
        val abandonedChecks = pendingChecks.toList()
        pendingChecks.clear()
        abandonedChecks.forEach {
            it.error("UPDATE_UNAVAILABLE", "The update screen was closed.", null)
        }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getInstalledVersionCode" -> result.success(installedVersionCode())
                "getRequiredVersionCode" -> result.success(requirements.read())
                "setRequiredVersionCode" -> {
                    val arguments = call.arguments as? Map<*, *>
                    require(arguments != null && arguments.containsKey("versionCode")) {
                        "A nullable versionCode is required."
                    }
                    requirements.write(parseRequiredVersionCode(arguments["versionCode"]))
                    result.success(null)
                }
                "checkForUpdate" -> checkForUpdate(result)
                "performImmediateUpdate" -> performImmediateUpdate(result)
                "openStore" -> result.success(openStore())
                else -> result.notImplemented()
            }
        } catch (_: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", "A positive integer versionCode is required.", null)
        } catch (_: Exception) {
            result.error("UPDATE_PLATFORM_ERROR", "The update operation could not be completed.", null)
        }
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        currentInfo = null
        val generation = ++checkGeneration
        pendingChecks.add(result)
        try {
            updateManager.appUpdateInfo
                .addOnSuccessListener { info ->
                    if (!pendingChecks.remove(result)) return@addOnSuccessListener
                    if (generation != checkGeneration) {
                        result.error("CHECK_SUPERSEDED", "Please check for updates again.", null)
                        return@addOnSuccessListener
                    }
                    currentInfo = info
                    val inProgress = info.updateAvailability() ==
                        UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                    val available = inProgress ||
                        info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                    result.success(
                        mapOf(
                            "available" to available,
                            "inProgress" to inProgress,
                            "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                            "availableVersionCode" to if (available && info.availableVersionCode() > 0) {
                                info.availableVersionCode()
                            } else null,
                        ),
                    )
                }
                .addOnFailureListener {
                    if (pendingChecks.remove(result)) {
                        result.error("PLAY_UPDATE_UNAVAILABLE", "Google Play could not check for updates.", null)
                    }
                }
        } catch (_: Exception) {
            if (pendingChecks.remove(result)) {
                result.error("PLAY_UPDATE_UNAVAILABLE", "Google Play could not check for updates.", null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun performImmediateUpdate(result: MethodChannel.Result) {
        if (pendingUpdate != null) {
            result.error("UPDATE_IN_PROGRESS", "An update is already in progress.", null)
            return
        }
        // Play permits one use of each AppUpdateInfo. A retry requires a fresh query.
        val info = currentInfo
        currentInfo = null
        if (info == null) {
            result.success("failed")
            return
        }
        val inProgress = info.updateAvailability() ==
            UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
        if (!inProgress && (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE ||
            !info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE))
        ) {
            result.success("failed")
            return
        }
        pendingUpdate = result
        try {
            val started = updateManager.startUpdateFlowForResult(
                info,
                activity,
                AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(),
                UPDATE_REQUEST_CODE,
            )
            if (!started) finishUpdate("failed")
        } catch (_: Exception) {
            finishUpdate("failed")
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != UPDATE_REQUEST_CODE) return false
        finishUpdate(immediateUpdateResult(resultCode))
        return true
    }

    private fun finishUpdate(value: String) {
        val result = pendingUpdate ?: return
        pendingUpdate = null
        result.success(value)
    }

    @Suppress("DEPRECATION")
    private fun installedVersionCode(): Long {
        val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
        return info.longVersionCode.also { check(it > 0) }
    }

    private fun openStore(): Boolean {
        val packageName = activity.packageName
        val marketIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("market://details?id=$packageName"),
        ).setPackage("com.android.vending")
        if (launch(marketIntent)) return true
        return launch(
            Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=$packageName"),
            ),
        )
    }

    private fun launch(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }
}

internal fun immediateUpdateResult(resultCode: Int): String = when (resultCode) {
    Activity.RESULT_OK -> "success"
    Activity.RESULT_CANCELED -> "cancelled"
    else -> "failed"
}

internal fun parseRequiredVersionCode(value: Any?): Long? = when (value) {
    null -> null
    is Int -> value.toLong().also { require(it > 0) }
    is Long -> value.also { require(it > 0) }
    else -> throw IllegalArgumentException("A positive integer versionCode is required.")
}

/** A discovered requirement survives process death and cannot be downgraded. */
internal class UpdateRequirementStore(private val preferences: SharedPreferences) {
    fun read(): Long? = if (preferences.contains(KEY_REQUIRED_VERSION)) {
        preferences.getLong(KEY_REQUIRED_VERSION, 0).also { check(it > 0) }
    } else {
        null
    }

    fun write(versionCode: Long?) {
        require(versionCode == null || versionCode > 0)
        val editor = preferences.edit()
        if (versionCode == null) {
            editor.remove(KEY_REQUIRED_VERSION)
        } else {
            editor.putLong(KEY_REQUIRED_VERSION, maxOf(read() ?: versionCode, versionCode))
        }
        // commit reports persistence failure; do not acknowledge an in-memory-only latch.
        check(editor.commit()) { "The required update could not be persisted." }
    }

    companion object {
        private const val KEY_REQUIRED_VERSION = "required_version_code"
    }
}
