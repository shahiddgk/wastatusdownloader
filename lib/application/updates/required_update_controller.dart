import 'dart:async';

import 'package:flutter/foundation.dart';

/// The Play status is separate from the persisted minimum version. A temporary
/// Play/network failure must never discard an update we already know is needed.
@immutable
class PlayUpdateStatus {
  const PlayUpdateStatus({
    required this.available,
    this.availableVersionCode,
    this.inProgress = false,
    this.immediateAllowed = false,
  });

  final bool available;
  final int? availableVersionCode;
  final bool inProgress;
  final bool immediateAllowed;
}

enum UpdateAttempt { success, cancelled, failed }

abstract class UpdatePlatform {
  Future<int> installedVersionCode();
  Future<int?> readRequiredVersionCode();
  Future<void> writeRequiredVersionCode(int? versionCode);
  Future<PlayUpdateStatus> checkForUpdate();
  Future<UpdateAttempt> performImmediateUpdate();
  Future<bool> openStore();
}

/// Keep one instance for the lifetime of the app. Only a confirmed installation
/// can clear a known minimum; cancellation, offline use and stale Play responses
/// cannot. An unverified first launch remains usable offline after the timeout.
class RequiredUpdateController extends ChangeNotifier {
  RequiredUpdateController(
    this._platform, {
    this.queryTimeout = const Duration(seconds: 10),
  });

  final UpdatePlatform _platform;
  final Duration queryTimeout;

  bool _checking = true;
  bool _busy = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _unknownRequirement = false;
  bool _localVerificationFailed = false;
  bool _automaticAttemptUsed = false;
  int? _targetVersion;
  int? _savedVersion;
  String _message = '';
  Future<void>? _operation;

  bool get checking => _checking;
  bool get busy => _busy;
  bool get required => _targetVersion != null || _unknownRequirement;
  bool get blocksApp => !_initialized || _localVerificationFailed || required;
  String get message => _message;
  int? get targetVersion => _targetVersion;

  Future<void> refresh() => _serialize(() async {
    final status = await _refreshStatus();
    if (_disposed || _localVerificationFailed || !required) return;
    final saved = await _persistRequirement();
    if (_disposed || !saved) return;
    if (!_automaticAttemptUsed && _canUpdateImmediately(status)) {
      _automaticAttemptUsed = true;
      await _performImmediateUpdate(fallbackToStore: false);
    }
  });

  /// A user retry always obtains fresh Play information before starting an
  /// immediate update. When Play cannot offer that flow, open its store page.
  Future<void> update() => _serialize(() async {
    final status = await _refreshStatus();
    if (_disposed || _localVerificationFailed || !required) return;
    final saved = await _persistRequirement();
    if (_disposed || !saved) return;
    if (_canUpdateImmediately(status)) {
      _automaticAttemptUsed = true;
      await _performImmediateUpdate(fallbackToStore: true);
    } else {
      await _openStore();
    }
  });

  Future<void> _serialize(Future<void> Function() action) {
    if (_disposed) return Future<void>.value();
    final existing = _operation;
    if (existing != null) return existing;

    final completion = Completer<void>();
    _operation = completion.future;
    _busy = true;
    _notify();
    () async {
      try {
        await action();
      } catch (_) {
        _localVerificationFailed = true;
        _message = 'Could not verify the app update. Please try again.';
      } finally {
        _checking = false;
        _initialized = true;
        _busy = false;
        _operation = null;
        _notify();
        completion.complete();
      }
    }();
    return completion.future;
  }

  Future<PlayUpdateStatus?> _refreshStatus() async {
    _checking = true;
    _notify();
    // Start all three together, so an unverified offline launch takes at most
    // one query timeout rather than three consecutive timeouts.
    final installedRequest = _query(_platform.installedVersionCode);
    final savedRequest = _query(_platform.readRequiredVersionCode);
    final statusRequest = _query(_platform.checkForUpdate);
    final installedResult = await installedRequest;
    final installed = installedResult.value;
    final savedResult = await savedRequest;
    final saved = savedResult.value;
    final statusResult = await statusRequest;
    if (_disposed) return null;

    if (saved != null && saved > 0) {
      _savedVersion = _maximum(_savedVersion, saved);
      _targetVersion = _maximum(_targetVersion, saved);
    }

    final installedVersion = installed != null && installed > 0
        ? installed
        : null;
    _localVerificationFailed =
        installedResult.failed ||
        savedResult.failed ||
        installedVersion == null;
    await _clearSatisfiedRequirement(installedVersion);
    if (_disposed) return null;

    final status = statusResult.value;
    if (status != null && (status.available || status.inProgress)) {
      final available = status.availableVersionCode;
      if (available == null || available <= 0) {
        // Play may omit the version during an update. Do not invent a minimum
        // version: retain this gate in memory until the app restarts instead.
        _unknownRequirement = true;
      } else if (installedVersion == null || available > installedVersion) {
        _targetVersion = _maximum(_targetVersion, available);
      } else {
        // Play has supplied the previously missing target, and installation of
        // that version has now been confirmed using local package information.
        _unknownRequirement = false;
      }
    }

    _checking = false;
    _message = _localVerificationFailed
        ? 'Could not verify the installed app update. Please try again.'
        : required
        ? statusResult.failed
              ? 'An update is required. Connect to Google Play and try again.'
              : 'Update the app to continue.'
        : '';
    _notify();
    return status;
  }

  bool _canUpdateImmediately(PlayUpdateStatus? status) =>
      status != null &&
      (status.inProgress || (status.available && status.immediateAllowed));

  Future<bool> _persistRequirement() async {
    final target = _targetVersion;
    if (target == null || (_savedVersion ?? 0) >= target) return true;
    final result = await _query(
      () => _platform.writeRequiredVersionCode(target),
    );
    if (_disposed) return false;
    if (result.failed) {
      _message = 'Could not prepare the required update. Please try again.';
      _notify();
      return false;
    }
    _savedVersion = target;
    return true;
  }

  Future<void> _clearSatisfiedRequirement(int? installed) async {
    final target = _targetVersion;
    if (installed == null || target == null || installed < target) return;
    // Clearing a stale preference may fail; the installed version still meets
    // its requirement, and a later launch can safely repeat this comparison.
    await _query(() => _platform.writeRequiredVersionCode(null));
    if (_disposed) return;
    _targetVersion = null;
    _savedVersion = null;
    _unknownRequirement = false;
  }

  Future<void> _performImmediateUpdate({required bool fallbackToStore}) async {
    // Intentionally no timeout around the interactive Play installation flow.
    // Lifecycle resumes coalesce with this operation rather than opening it twice.
    UpdateAttempt result;
    try {
      result = await _platform.performImmediateUpdate();
    } catch (_) {
      result = UpdateAttempt.failed;
    }
    if (_disposed) return;
    switch (result) {
      case UpdateAttempt.success:
        final installed = await _query(_platform.installedVersionCode);
        if (_disposed) return;
        await _clearSatisfiedRequirement(installed.value);
        if (_disposed) return;
        _message = required
            ? 'Finish installing the update, then reopen the app to continue.'
            : '';
        _notify();
      case UpdateAttempt.cancelled:
        _message = 'Update cancelled. Update the app to continue.';
        _notify();
      case UpdateAttempt.failed:
        if (fallbackToStore) {
          await _openStore();
        } else {
          _message = 'Could not start the update. Please try again.';
          _notify();
        }
    }
  }

  Future<void> _openStore() async {
    final result = await _query(_platform.openStore);
    if (_disposed) return;
    _message = result.value == true
        ? 'Finish updating in Google Play, then return to the app.'
        : 'Could not open Google Play. Check your connection and try again.';
    _notify();
  }

  Future<_QueryResult<T>> _query<T>(Future<T> Function() query) async {
    try {
      return _QueryResult<T>(await query().timeout(queryTimeout), false);
    } catch (_) {
      return _QueryResult<T>(null, true);
    }
  }

  int _maximum(int? first, int second) =>
      first != null && first > second ? first : second;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _QueryResult<T> {
  const _QueryResult(this.value, this.failed);

  final T? value;
  final bool failed;
}
