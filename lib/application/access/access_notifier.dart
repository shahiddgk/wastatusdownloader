import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/storage_access_state.dart';
import '../../domain/use_cases/check_storage_access_use_case.dart';
import '../../domain/use_cases/request_storage_access_use_case.dart';
import '../providers.dart';
import 'access_state.dart';

/// Manages the application lifecycle and state transitions for WhatsApp storage access.
///
/// Coordinates [CheckStorageAccessUseCase] and [RequestStorageAccessUseCase],
/// mapping domain results and failures into immutable [AccessState] representations.
class AccessNotifier extends Notifier<AccessState> {
  final CheckStorageAccessUseCase? _checkAccessOverride;
  final RequestStorageAccessUseCase? _requestAccessOverride;
  int _requestId = 0;
  String _activePackage = AppConstants.whatsappStandardPackage;

  AccessNotifier({
    CheckStorageAccessUseCase? checkAccessUseCase,
    RequestStorageAccessUseCase? requestAccessUseCase,
  }) : _checkAccessOverride = checkAccessUseCase,
       _requestAccessOverride = requestAccessUseCase;

  CheckStorageAccessUseCase get _checkAccess =>
      _checkAccessOverride ?? ref.read(checkStorageAccessUseCaseProvider);

  RequestStorageAccessUseCase get _requestAccess =>
      _requestAccessOverride ?? ref.read(requestStorageAccessUseCaseProvider);

  String get activePackage => _activePackage;

  @override
  AccessState build() => const AccessInitial();

  /// Verifies current access permissions for [targetPackage].
  ///
  /// Concurrency guard: Ignores reentrant requests while checking or requesting.
  Future<void> checkAccess({
    String targetPackage = AppConstants.whatsappStandardPackage,
  }) async {
    if (state.isRequesting ||
        (state.isChecking && targetPackage == _activePackage)) {
      return;
    }

    final requestId = ++_requestId;
    _activePackage = targetPackage;
    state = const AccessChecking();

    try {
      final result = await _checkAccess(targetPackage: targetPackage);
      if (!ref.mounted || requestId != _requestId) return;
      state = switch (result) {
        Success(:final data) => _mapDomainAccessState(data),
        Failure(:final failure) => AccessFailure(failure),
      };
    } on AppFailure catch (failure) {
      if (!ref.mounted || requestId != _requestId) return;
      state = AccessFailure(failure);
    } catch (e) {
      if (!ref.mounted || requestId != _requestId) return;
      state = AccessFailure(
        const UnknownFailure('Could not check access. Please try again.'),
      );
    }
  }

  /// Prompts the user for Android file access to grant access to [targetPackage].
  ///
  /// Concurrency guard: Ignores reentrant requests while checking or requesting.
  Future<void> requestAccess({
    String targetPackage = AppConstants.whatsappStandardPackage,
  }) async {
    if (state.isRequesting || state.isChecking) {
      return;
    }

    final requestId = ++_requestId;
    _activePackage = targetPackage;
    state = const AccessRequesting();

    try {
      final result = await _requestAccess(targetPackage: targetPackage);
      if (!ref.mounted || requestId != _requestId) return;
      state = switch (result) {
        Success(:final data) => _mapDomainAccessState(data),
        Failure(:final failure) => AccessFailure(failure),
      };
    } on AppFailure catch (failure) {
      if (!ref.mounted || requestId != _requestId) return;
      state = AccessFailure(failure);
    } catch (e) {
      if (!ref.mounted || requestId != _requestId) return;
      state = AccessFailure(
        const UnknownFailure('Could not request access. Please try again.'),
      );
    }
  }

  /// Refreshes current access status by re-checking storage permissions.
  Future<void> refreshAccess({String targetPackage = ''}) {
    final pkg = targetPackage.isNotEmpty ? targetPackage : _activePackage;
    return checkAccess(targetPackage: pkg);
  }

  AccessState _mapDomainAccessState(StorageAccessState domainState) {
    return switch (domainState) {
      StorageAccessGranted(:final targetPackage, :final treeUri) =>
        AccessGranted(targetPackage: targetPackage, treeUri: treeUri),
      StorageAccessNotGranted() => const AccessNotGranted(),
      StorageAccessRevoked(:final reason) => AccessRevoked(reason: reason),
      StorageAccessInvalid(:final reason) => AccessInvalid(reason: reason),
      StorageAccessUnavailable(:final reason) => AccessUnavailable(
        reason: reason,
      ),
      StorageAccessInitial() => const AccessInitial(),
    };
  }
}
