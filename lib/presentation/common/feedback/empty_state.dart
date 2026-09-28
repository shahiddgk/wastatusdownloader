import 'package:flutter/material.dart';

import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

import '../buttons/primary_button.dart';

enum EmptyScenario {
  noAccess,
  noStatuses,
  filterEmpty,
  vaultEmpty,
  folderMoved,
  permissionRevoked,
  momentExpired,
}

/// Comprehensive empty states for WA Status Downloader.
///
/// Implements the 7 scenarios from docs/design/app-ui-spec.md Screen F.
class EmptyState extends StatelessWidget {
  final EmptyScenario scenario;
  final VoidCallback? onAction;
  final String? customTitle;
  final String? customSubtitle;
  final String? customActionLabel;

  const EmptyState({
    super.key,
    required this.scenario,
    this.onAction,
    this.customTitle,
    this.customSubtitle,
    this.customActionLabel,
  });

  (IconData icon, String title, String subtitle, String actionLabel)
  _scenarioConfig() {
    return switch (scenario) {
      EmptyScenario.noAccess => (
        AppIcons.privacyShield,
        'Allow status access',
        'Allow access to find viewed statuses.',
        'Allow access',
      ),
      EmptyScenario.noStatuses => (
        AppIcons.navMoments,
        'No statuses yet',
        'View a status in WhatsApp, then refresh.',
        'Refresh',
      ),
      EmptyScenario.filterEmpty => (
        AppIcons.actionSearch,
        'No matches',
        'Try another filter.',
        'Show all',
      ),
      EmptyScenario.vaultEmpty => (
        AppIcons.navKept,
        'No saved statuses',
        'Saved photos and videos appear here.',
        'View statuses',
      ),
      EmptyScenario.folderMoved => (
        AppIcons.folderOpen,
        'Media folder unavailable',
        'View a status in WhatsApp and try again.',
        'Try again',
      ),
      EmptyScenario.permissionRevoked => (
        AppIcons.errorWarning,
        'Access needs renewal',
        'Allow access again to see statuses.',
        'Allow access',
      ),
      EmptyScenario.momentExpired => (
        AppIcons.errorCircle,
        'Moment expired',
        'This moment was removed or expired before it could be saved.',
        'Return to Status',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (defaultIcon, defaultTitle, defaultSubtitle, defaultActionLabel) =
        _scenarioConfig();

    final title = customTitle ?? defaultTitle;
    final subtitle = customSubtitle ?? defaultSubtitle;
    final actionLabel = customActionLabel ?? defaultActionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with soft mint/slate aura
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
              child: Center(
                child: Icon(defaultIcon, size: 36, color: scheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.space24),
              PrimaryButton(
                label: actionLabel,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
