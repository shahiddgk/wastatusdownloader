import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../domain/entities/status_item.dart';
import '../common/buttons/keep_button.dart';
import '../common/controls/filter_control.dart';
import '../common/feedback/empty_state.dart';
import '../moments/status_grid.dart';

/// Screen E: Kept Media Vault.
///
/// Implements specification from docs/design/keeva-ui-spec.md Section Screen E:
/// - Reuses [StatusCard] and [StatusGrid] for high performance.
/// - Product vocabulary strictly uses "Kept", "Vault", and "Safely Preserved".
/// - Displays total storage footprint and album location.
/// - Filter chips (All, Photos, Videos).
/// - Dedicated [EmptyScenario.vaultEmpty] with CTA to explore moments.
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

  String _formatFootprint(int totalBytes) {
    if (totalBytes <= 0) return '0 MB stored in Pictures/SavedStatus';
    final mb = totalBytes / (1024 * 1024);
    if (mb < 1.0) {
      final kb = totalBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB stored in Pictures/SavedStatus';
    }
    return '${mb.toStringAsFixed(1)} MB stored in Pictures/SavedStatus';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusListState = ref.watch(statusListNotifierProvider);
    // Filter to only kept/saved items
    final keptItems = statusListState.items.where((i) => i.isSaved).toList();
    final photosCount = keptItems.where((i) => !i.isVideo).length;
    final videosCount = keptItems.where((i) => i.isVideo).length;

    final totalBytes = keptItems.fold<int>(
      0,
      (sum, item) => sum + item.sizeBytes,
    );

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved Vault',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const KeBadge(label: 'Encrypted', showDot: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StorageSummary(
              itemCount: keptItems.length,
              footprint: _formatFootprint(totalBytes),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _VaultFilterChip(
                    label: 'All (${keptItems.length})',
                    selected: _activeFilter == MediaFilter.all,
                    onTap: () =>
                        setState(() => _activeFilter = MediaFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _VaultFilterChip(
                    label: 'Photos ($photosCount)',
                    selected: _activeFilter == MediaFilter.photos,
                    onTap: () =>
                        setState(() => _activeFilter = MediaFilter.photos),
                  ),
                  const SizedBox(width: 8),
                  _VaultFilterChip(
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
              onRefresh: () =>
                  ref.read(statusListNotifierProvider.notifier).refresh(),
              child: StatusGrid(
                items: filteredItems,
                emptyScenario:
                    _activeFilter != MediaFilter.all && keptItems.isNotEmpty
                    ? EmptyScenario.filterEmpty
                    : EmptyScenario.vaultEmpty,
                onEmptyAction: widget.onExploreMoments,
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

class _StorageSummary extends StatelessWidget {
  final int itemCount;
  final String footprint;

  const _StorageSummary({required this.itemCount, required this.footprint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return KeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: itemCount == 0 ? 0.06 : 0.72,
                    strokeWidth: 7,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
                Icon(
                  Icons.verified_user_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: '$itemCount',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' Status Saved',
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  footprint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$itemCount status safely saved',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Saved in Pictures/SavedStatus',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VaultFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NeonVaultColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
