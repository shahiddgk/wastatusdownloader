import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/status_label_repository.dart';

final statusLabelRepositoryProvider = Provider<StatusLabelRepository>(
  (ref) => StatusLabelRepository(),
);

final statusLabelProvider =
    AsyncNotifierProvider.family<StatusLabelController, String?, String>(
      StatusLabelController.new,
    );

class StatusLabelController extends AsyncNotifier<String?> {
  final String statusId;

  StatusLabelController(this.statusId);

  @override
  Future<String?> build() =>
      ref.watch(statusLabelRepositoryProvider).read(statusId);

  Future<bool> save(String input) async {
    final label = input.trim();
    try {
      await ref.read(statusLabelRepositoryProvider).write(statusId, label);
      if (ref.mounted) {
        state = AsyncData(label.isEmpty ? null : label);
      }
      return true;
    } catch (_) {
      // Keep the current label visible; the editor shows a retryable save error.
      return false;
    }
  }
}
