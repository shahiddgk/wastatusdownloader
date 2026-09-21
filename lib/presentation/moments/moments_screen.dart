import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_icons.dart';
import '../../application/providers.dart';
import '../../application/saver/save_state.dart';
import '../../application/statuses/status_list_state.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../domain/entities/status_item.dart';
import '../common/buttons/keep_button.dart';
import '../common/controls/filter_control.dart';
import '../common/feedback/empty_state.dart';
import '../common/feedback/toast.dart';
import '../common/sheets/bottom_sheet.dart';
import 'status_grid.dart';

/// Screen B: Primary Status Home Screen.
///
/// Implements specification from docs/design/keeva-ui-spec.md Section Screen B:
/// - Brand Header with Private trust badge.
/// - WhatsApp / WA Business source switcher.
/// - Section header showing moment count.
/// - Filter chips (All, Photos, Videos).
/// - High-performance 9:16 media grid with virtualized slivers.
/// - Signature KeepButton integration via [saveNotifierProvider].
/// - Non-blocking pull-to-refresh.
class MomentsScreen extends ConsumerStatefulWidget {
  final ValueChanged<StatusItem>? onStatusSelected;
  final VoidCallback? onExploreKept;

  const MomentsScreen({super.key, this.onStatusSelected, this.onExploreKept});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  MediaFilter _activeFilter = MediaFilter.all;

  Widget _buildSourceSelector(BuildContext context, String activePackage) {
    final scheme = Theme.of(context).colorScheme;
    final isBusiness = activePackage == AppConstants.whatsappBusinessPackage;
    final sourceNotifier = ref.read(selectedTargetPackageProvider.notifier);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: isBusiness
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: scheme.brightness == Brightness.dark
                      ? NeonVaultColors.softGlow
                      : null,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _sourceButton(
                  context: context,
                  label: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  selected: !isBusiness,
                  onTap: () => sourceNotifier.selectPackage(
                    AppConstants.whatsappStandardPackage,
                  ),
                ),
              ),
              Expanded(
                child: _sourceButton(
                  context: context,
                  label: 'WA Business',
                  icon: Icons.business_center_outlined,
                  selected: isBusiness,
                  onTap: () => sourceNotifier.selectPackage(
                    AppConstants.whatsappBusinessPackage,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sourceButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusListState = ref.watch(statusListNotifierProvider);
    final saveState = ref.watch(saveNotifierProvider);
    final activePackage = ref.watch(selectedTargetPackageProvider);
    // Listen for save completion/failure notifications
    ref.listen<SaveState>(saveNotifierProvider, (previous, next) {
      if (next is SaveSuccess && previous is! SaveSuccess) {
        KeevaToast.show(
          context,
          message: 'Saved to gallery',
          icon: AppIcons.actionCheck,
        );
      } else if (next is SaveFailure && previous is! SaveFailure) {
        KeevaToast.show(
          context,
          message: next.failure.message,
          icon: AppIcons.errorWarning,
        );
      }
    });

    final allItems = statusListState.items;
    final photosCount = allItems.where((i) => !i.isVideo).length;
    final videosCount = allItems.where((i) => i.isVideo).length;

    final filteredItems = switch (_activeFilter) {
      MediaFilter.all => allItems,
      MediaFilter.photos => allItems.where((i) => !i.isVideo).toList(),
      MediaFilter.videos => allItems.where((i) => i.isVideo).toList(),
    };

    final isInitialOrLoading =
        statusListState.isInitial || statusListState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const KeAppAppBar(screenName: 'Status'),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(statusListNotifierProvider.notifier)
            .refresh(targetPackage: activePackage),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildSourceSelector(context, activePackage),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: KeCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Encrypted Sandbox Active',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    KeBadge(
                      label: 'On-device',
                      leading: Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 10),
                      KeBadge(label: '${allItems.length} status'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${allItems.length} status available',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    KeFilterChip(
                      label: 'All (${allItems.length})',
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
            const SizedBox(height: 8),

            // Status Grid
            Expanded(
              child: StatusGrid(
                items: filteredItems,
                isLoading: isInitialOrLoading,
                emptyScenario:
                    _activeFilter != MediaFilter.all && allItems.isNotEmpty
                    ? EmptyScenario.filterEmpty
                    : EmptyScenario.noStatuses,
                failure: statusListState is StatusListFailure
                    ? statusListState.failure
                    : null,
                onRetry: () => ref
                    .read(statusListNotifierProvider.notifier)
                    .load(targetPackage: activePackage),
                onStatusTap: widget.onStatusSelected,
                onKeepStatus: (item) {
                  ref.read(saveNotifierProvider.notifier).save(item);
                },
                onAlreadyKeptStatus: (item) {
                  KeevaBottomSheet.showAlreadyKeptOptions(
                    context: context,
                    item: item,
                    onViewInVault: () {
                      widget.onExploreKept?.call();
                    },
                    onSaveCopy: () {
                      ref.read(saveNotifierProvider.notifier).save(item);
                    },
                  );
                },
                keepStateResolver: (item) {
                  if (saveState.isInProgress &&
                      saveState.currentItemId == item.id) {
                    return KeepState.saving;
                  }
                  if (saveState.isSuccess &&
                      saveState.currentItemId == item.id) {
                    return KeepState.success;
                  }
                  if (saveState.isFailure &&
                      saveState.currentItemId == item.id) {
                    return KeepState.failure;
                  }
                  if (item.isSaved) {
                    return KeepState.alreadyKept;
                  }
                  return KeepState.idle;
                },
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
          ],
        ),
      ),
    );
  }
}
