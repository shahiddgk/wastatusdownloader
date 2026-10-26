package ratedwhats.appstatusdownloader

import android.content.Intent
import ratedwhats.appstatusdownloader.status.AndroidStatusScanner
import ratedwhats.appstatusdownloader.updates.UpdateRequirementChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Minimal host Activity that delegates platform channel operations
 * to the AndroidStatusScanner native facade.
 */
class MainActivity : FlutterActivity() {

    private lateinit var statusScanner: AndroidStatusScanner
    private lateinit var updateRequirementChannel: UpdateRequirementChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        statusScanner = AndroidStatusScanner(this)
        statusScanner.registerWith(flutterEngine.dartExecutor.binaryMessenger)
        updateRequirementChannel = UpdateRequirementChannel(this)
        updateRequirementChannel.registerWith(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::updateRequirementChannel.isInitialized &&
            updateRequirementChannel.onActivityResult(requestCode, resultCode)
        ) return
        if (::statusScanner.isInitialized) {
            statusScanner.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        if (::statusScanner.isInitialized) {
            statusScanner.dispose()
        }
        if (::updateRequirementChannel.isInitialized) {
            updateRequirementChannel.dispose()
        }
        super.onDestroy()
    }

}
