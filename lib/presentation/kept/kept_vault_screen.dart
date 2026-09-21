import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../domain/entities/status_item.dart';
import '../common/buttons/keep_button.dart';
import '../common/controls/filter_control.dart';
import '../common/feedback/empty_state.dart';
import '../common/feedback/toast.dart';
import '../moments/status_grid.dart';

class KeptVaultScreen extends ConsumerStatefulWidget {
  final ValueChanged<StatusItem>? onStatusSelected;
  final VoidCallback? onExploreMoments;

  const KeptVaultScreen({
    super.key,
    this.onStatusSelected,
    this.onExploreMoments,
  });

  @override
  ConsumerState<KeptVaultScreen> createState() => _KeptVaultScreenState();
}

class _KeptVaultScreenState extends ConsumerState<KeptVaultScreen> {
  MediaFilter _activeFilter = MediaFilter.all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final saved = ref.watch(savedStatusesProvider);
    final keptItems = saved.asData?.value ?? const <StatusItem>[];
    final photosCount = keptItems.where((i) => !i.isVideo).length;
    final videosCount = keptItems.where((i) => i.isVideo).length;

    final filteredItems = switch (_activeFilter) {
      MediaFilter.all => keptItems,
      MediaFilter.photos => keptItems.where((i) => !i.isVideo).toList(),
      MediaFilter.videos => keptItems.where((i) => i.isVideo).toList(),
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const KeAppAppBar(screenName: 'Saved'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  KeFilterChip(
                    label: 'All (${keptItems.length})',
                    selected: _activeFilter == MediaFilter.all,
                    onTap: () =>
                        setState(() => _activeFilter = MediaFilter.all),
                  ),
                  const SizedBox(width: 8),
                  KeFilterChip(
                    label: 'Photos ($photosCount)',
                    selected: _activeFilter == MediaFilter.photos,
                    onTap: () =>
                        setState(() => _activeFilter = MediaFilter.photos),
                  ),
                  const SizedBox(width: 8),
                  KeFilterChip(
                    label: 'Videos ($videosCount)',
                    selected: _activeFilter == MediaFilter.videos,
                    onTap: () =>
                        setState(() => _activeFilter = MediaFilter.videos),
                  ),
                ],
              ),
            ),
          ),

          // Kept Media Grid
          Expanded(
            child: RefreshIndicator(
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
              onRefresh: () async {
                ref.invalidate(savedStatusesProvider);
                try {
                  await ref.read(savedStatusesProvider.future);
                } catch (_) {
                  if (context.mounted) {
                    KeevaToast.show(
                      context,
                      message: 'Could not refresh saved statuses.',
                    );
                  }
                }
              },
              child: StatusGrid(
                items: filteredItems,
                isLoading: saved.isLoading,
                failure: saved.hasError
                    ? const ReadFailedFailure('Could not load saved statuses.')
                    : null,
                onRetry: () => ref.invalidate(savedStatusesProvider),
                emptyScenario:
                    _activeFilter != MediaFilter.all && keptItems.isNotEmpty
                    ? EmptyScenario.filterEmpty
                    : EmptyScenario.vaultEmpty,
                onEmptyAction:
                    _activeFilter != MediaFilter.all && keptItems.isNotEmpty
                    ? () => setState(() => _activeFilter = MediaFilter.all)
                    : widget.onExploreMoments,
                onStatusTap: widget.onStatusSelected,
                keepStateResolver: (_) => KeepState.alreadyKept,
                thumbnailLoader: (item) async {
                  final useCase = ref.read(getThumbnailUseCaseProvider);
                  final result = await useCase(
                    id: item.id,
                    isVideo: item.isVideo,
                  );
                  return result.dataOrNull;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
