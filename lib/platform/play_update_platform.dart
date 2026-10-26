import 'package:flutter/services.dart';

import '../application/updates/required_update_controller.dart';

/// Google Play update operations and the small native persistence boundary.
class PlayUpdatePlatform implements UpdatePlatform {
  const PlayUpdatePlatform({
    this.channel = const MethodChannel(
      'ratedwhats.appstatusdownloader/updates',
    ),
  });

  final MethodChannel channel;

  @override
  Future<int> installedVersionCode() async {
    final value = await channel.invokeMethod<Object>('getInstalledVersionCode');
    return _positiveVersionCode(value);
  }

  @override
  Future<int?> readRequiredVersionCode() async {
    final value = await channel.invokeMethod<Object>('getRequiredVersionCode');
    return value == null ? null : _positiveVersionCode(value);
  }

  @override
  Future<void> writeRequiredVersionCode(int? versionCode) async {
    if (versionCode != null && versionCode <= 0) {
      throw ArgumentError.value(
        versionCode,
        'versionCode',
        'Must be positive.',
      );
    }
    await channel.invokeMethod<void>('setRequiredVersionCode', {
      'versionCode': versionCode,
    });
  }

  @override
  Future<PlayUpdateStatus> checkForUpdate() async {
    final info = await channel.invokeMapMethod<String, Object?>(
      'checkForUpdate',
    );
    if (info == null ||
        info['available'] is! bool ||
        info['inProgress'] is! bool ||
        info['immediateAllowed'] is! bool) {
      throw const FormatException('Invalid Google Play update response.');
    }
    final version = info['availableVersionCode'];
    return PlayUpdateStatus(
      available: info['available'] as bool,
      availableVersionCode: version == null
          ? null
          : _positiveVersionCode(version),
      inProgress: info['inProgress'] as bool,
      immediateAllowed: info['immediateAllowed'] as bool,
    );
  }

  /// The controller must obtain fresh update information before each attempt.
  @override
  Future<UpdateAttempt> performImmediateUpdate() async {
    final result = await channel.invokeMethod<Object>('performImmediateUpdate');
    return switch (result) {
      'success' => UpdateAttempt.success,
      'cancelled' => UpdateAttempt.cancelled,
      'failed' => UpdateAttempt.failed,
      _ => throw const FormatException('Invalid Google Play update result.'),
    };
  }

  @override
  Future<bool> openStore() async {
    final value = await channel.invokeMethod<Object>('openStore');
    if (value is! bool) {
      throw const FormatException('Invalid store launch response.');
    }
    return value;
  }

  static int _positiveVersionCode(Object? value) {
    if (value is! int || value <= 0) {
      throw const FormatException('Invalid Android version code.');
    }
    return value;
  }
}
