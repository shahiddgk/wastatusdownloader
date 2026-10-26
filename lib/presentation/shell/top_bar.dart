import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_radius.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_theme.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';
import 'package:whatsapp_status_saver/presentation/common/sheets/bottom_sheet.dart';

enum TopBarVariant { brand, contextual, selection }

/// Primary application header for WA Status Downloader.
///
/// Implements specification from docs/design/app-component-spec.md Section 2.2:
/// - BrandHeader: app name + "Private" trust pill.
/// - ContextualHeader: Back button + title + optional actions.
/// - SelectionHeader: Active count ("3 selected") + batch actions.
/// - 48x48dp minimum touch targets on all interactive items.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final TopBarVariant variant;
  final String? title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final int selectedCount;
  final VoidCallback? onClearSelection;

  const TopBar.brand({super.key, this.actions})
    : variant = TopBarVariant.brand,
      title = null,
      onBack = null,
      selectedCount = 0,
      onClearSelection = null;

  const TopBar.contextual({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  }) : variant = TopBarVariant.contextual,
       selectedCount = 0,
       onClearSelection = null;

  const TopBar.selection({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    this.actions,
  }) : variant = TopBarVariant.selection,
       title = null,
       onBack = null;

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  void _showPrivacySheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final colors = AppTheme.colorsOf(context);
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return Padding(
          padding: AppSpacing.sheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.privacyShield,
                        size: 20,
                        color: colors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Private & Local-First',
                    style: AppTypography.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'WA Status Downloader reads statuses only from the WhatsApp Media folder you connect once through Android’s system picker. Saved copies are stored in your gallery. The app has no internet permission and never uploads media.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WA Status Downloader',
          style: AppTypography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPill(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: 'Privacy Information. 100% on-device storage guarantee.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showPrivacySheet(context),
        child: SizedBox(
          height: AppSpacing.minTouchTarget,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(minHeight: 26),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceLevel1,
                borderRadius: AppRadius.borderPill,
                border: Border.all(
                  color: colors.primaryLight.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.lock, size: 12, color: colors.primaryLight),
                  const SizedBox(width: AppSpacing.space4),
                  Text(
                    'Private',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return AppBar(
      backgroundColor: colors.surfaceLevel0,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.space16,
      title: switch (variant) {
        TopBarVariant.brand => _buildBrandTitle(context),
        TopBarVariant.contextual => Text(
          title ?? '',
          style: AppTypography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        TopBarVariant.selection => Text(
          '$selectedCount selected',
          style: AppTypography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      },
      leading: switch (variant) {
        TopBarVariant.contextual =>
          onBack != null
              ? IconButton(
                  icon: const Icon(AppIcons.actionBack),
                  tooltip: 'Back',
                  onPressed: onBack,
                )
              : null,
        TopBarVariant.selection => IconButton(
          icon: const Icon(AppIcons.actionClose),
          tooltip: 'Clear selection',
          onPressed: onClearSelection,
        ),
        TopBarVariant.brand => null,
      },
      actions: [
        if (variant == TopBarVariant.brand) ...[
          _buildPrivacyPill(context),
          const SizedBox(width: AppSpacing.space16),
        ],
        ...?actions,
      ],
    );
  }
}
