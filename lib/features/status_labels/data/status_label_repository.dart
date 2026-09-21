import 'package:shared_preferences/shared_preferences.dart';

class StatusLabelRepository {
  final SharedPreferencesAsync _preferences;

  StatusLabelRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<String?> read(String statusId) =>
      _preferences.getString('status_label.$statusId');

  Future<void> write(String statusId, String label) async {
    final value = label.trim();
    final key = 'status_label.$statusId';
    if (value.isEmpty) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, value);
    }
  }
}
