import '../../domain/entities/status_item.dart';
import '../../platform/status_scanner_platform_interface.dart';

/// Reads saved copies from the native media library.
class SavedStatusRepository {
  final StatusScannerPlatformInterface _platform;

  const SavedStatusRepository(this._platform);

  Future<List<StatusItem>> getSavedStatuses() async {
    final items = await _platform.getSavedStatuses();
    return items.map((item) => item.toEntity()).toList();
  }
}
