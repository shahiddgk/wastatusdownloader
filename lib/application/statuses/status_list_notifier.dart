import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failure.dart';
import '../../core/result/result.dart';
import '../../domain/use_cases/get_statuses_use_case.dart';
import '../providers.dart';
import 'status_list_state.dart';

/// Manages the state machine for discovering and refreshing WhatsApp statuses.
///
/// Coordinates with [GetStatusesUseCase] and prevents concurrent race conditions,
/// ensuring immutable data flow to presentation surfaces.
class StatusListNotifier extends Notifier<StatusListState> {
  final GetStatusesUseCase? _getStatusesOverride;
  int _activeRequestId = 0;
  String _activePackage = AppConstants.whatsappStandardPackage;
  final Map<String, String> _selectedUris = {};

  StatusListNotifier({GetStatusesUseCase? getStatusesUseCase})
    : _getStatusesOverride = getStatusesUseCase;

  GetStatusesUseCase get _getStatuses =>
      _getStatusesOverride ?? ref.read(getStatusesUseCaseProvider);

  String get activePackage => _activePackage;

  @override
  StatusListState build() => const StatusListInitial();

  /// Performs initial discovery of statuses.
  ///
  /// Concurrency guard: Ignores reentrant calls while loading or refreshing.
  Future<void> load({
    String targetPackage = AppConstants.whatsappStandardPackage,
    String? treeUri,
  }) async {
    if (state.isLoading || state.isRefreshing) {
      return;
    }

    _activePackage = targetPackage;
    if (treeUri != null && treeUri.isNotEmpty) {
      _selectedUris[targetPackage] = treeUri;
    }
    final sourceUri = treeUri ?? _selectedUris[targetPackage];
    final requestId = ++_activeRequestId;
    state = const StatusListLoading();

    try {
      final result = await _getStatuses(
        targetPackage: targetPackage,
        treeUri: sourceUri,
      );
      if (requestId != _activeRequestId) {
        return;
      }

      state = switch (result) {
        Success(:final data) =>
          data.isEmpty
              ? const StatusListEmpty()
              : StatusListSuccess(items: data),
        Failure(:final failure) => StatusListFailure(failure: failure),
      };
    } on AppFailure catch (failure) {
      if (requestId == _activeRequestId) {
        state = StatusListFailure(failure: failure);
      }
    } catch (e) {
      if (requestId == _activeRequestId) {
        state = StatusListFailure(
          failure: UnknownFailure('Unexpected failure loading statuses: $e'),
        );
      }
    }
  }

  /// Refreshes the status list in the background while preserving current items.
  ///
  /// Concurrency guard: Ignores reentrant calls while loading or refreshing.
  Future<void> refresh({String targetPackage = '', String? treeUri}) async {
    if (state.isLoading || state.isRefreshing) {
      return;
    }

    final pkg = targetPackage.isNotEmpty ? targetPackage : _activePackage;
    _activePackage = pkg;
    if (treeUri != null && treeUri.isNotEmpty) {
      _selectedUris[pkg] = treeUri;
    }
    final sourceUri = treeUri ?? _selectedUris[pkg];

    final currentItems = state.items;
    final requestId = ++_activeRequestId;
    state = StatusListRefreshing(items: currentItems);

    try {
      final result = await _getStatuses(targetPackage: pkg, treeUri: sourceUri);
      if (requestId != _activeRequestId) {
        return;
      }

      state = switch (result) {
        Success(:final data) =>
          data.isEmpty
              ? const StatusListEmpty()
              : StatusListSuccess(items: data),
        Failure(:final failure) => StatusListFailure(failure: failure),
      };
    } on AppFailure catch (failure) {
      if (requestId == _activeRequestId) {
        state = StatusListFailure(failure: failure);
      }
    } catch (e) {
      if (requestId == _activeRequestId) {
        state = StatusListFailure(
          failure: UnknownFailure('Unexpected failure refreshing statuses: $e'),
        );
      }
    }
  }

  /// Clears results from another source before a package switch starts.
  void resetForPackage(String targetPackage) {
    _activePackage = targetPackage;
    ++_activeRequestId;
    state = const StatusListInitial();
  }

  /// Updates an item in the current state to mark it as saved.
  void markItemSaved(String itemId) {
    if (state.items.isEmpty) return;
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isSaved: true);
      }
      return item;
    }).toList();

    if (state is StatusListSuccess) {
      state = StatusListSuccess(items: updatedItems);
    } else if (state is StatusListRefreshing) {
      state = StatusListRefreshing(items: updatedItems);
    }
  }
}
