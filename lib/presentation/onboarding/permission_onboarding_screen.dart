import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icons.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../application/access/access_state.dart';
import '../../application/providers.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../common/buttons/primary_button.dart';
import '../common/onboarding/permission_guide.dart';

class PermissionOnboardingScreen extends ConsumerWidget {
  final VoidCallback? onAccessGranted;

  const PermissionOnboardingScreen({super.key, this.onAccessGranted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessNotifierProvider);
    ref.listen<AccessState>(accessNotifierProvider, (previous, next) {
      if (next.isGranted) onAccessGranted?.call();
    });
    final busy = access.isChecking || access.isRequesting;
    final message = switch (access) {
      AccessInvalid() || AccessRevoked() => 'Your connection needs to be refreshed. Reconnect WhatsApp Media to see statuses.',
      AccessUnavailable() =>
        'View a status in WhatsApp first, then come back here to connect it.',
      AccessFailure() =>
        'We could not connect WhatsApp Media. Please try again.',
      _ => 'We take you straight to WhatsApp Media. You only confirm the connection once.',
    };

    return Scaffold(
      appBar: const KeAppAppBar(screenName: 'Status'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space24,
                AppSpacing.space24,
                AppSpacing.space16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FolderSetupCard(message: message),
                      const SizedBox(height: AppSpacing.space24),
                      const PermissionGuide(),
                      const SizedBox(height: AppSpacing.space24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ConnectActionBar(
            busy: busy,
            onPressed: busy
                ? null
                : () => ref
                      .read(accessNotifierProvider.notifier)
                      .requestAccess(
                        targetPackage: ref.read(selectedTargetPackageProvider),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Visual explanation of the one-time, scoped WhatsApp Media connection.
class _FolderSetupCard extends StatelessWidget {
  final String message;

  const _FolderSetupCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors =
        theme.extension<AppColorsExtension>() ?? AppColorsExtension.dark;

    return Semantics(
      container: true,
      label: 'WhatsApp Media folder setup',
      child: Container(
        key: const Key('whatsapp_media_folder_card'),
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: colors.surfaceLevel1,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
              ),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: AppSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.actionCheck, size: 14, color: scheme.primary),
                    const SizedBox(width: AppSpacing.space4),
                    Text(
                      'ONE-TIME SETUP',
                      style: AppTypography.labelSmall.copyWith(
                        color: scheme.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            ClipRRect(
              borderRadius: AppRadius.borderMd,
              child: AspectRatio(
                aspectRatio: 6 / 5,
                child: Image.asset(
                  'assets/onboarding/connect_folder.webp',
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            Text(
              'Connect WhatsApp Media',
              style: AppTypography.headlineLarge.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            const _FolderLocationPreview(),
          ],
        ),
      ),
    );
  }
}

class _FolderLocationPreview extends StatelessWidget {
  const _FolderLocationPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('whatsapp_media_folder_preview'),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              AppIcons.folderOpen,
              color: scheme.primary,
              semanticLabel: 'WhatsApp Media folder',
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp Media',
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Android opens this for you',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Icon(AppIcons.actionCheck, color: scheme.primary),
        ],
      ),
    );
  }
}

class _ConnectActionBar extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;

  const _ConnectActionBar({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors =
        theme.extension<AppColorsExtension>() ?? AppColorsExtension.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLevel0,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space24,
            AppSpacing.space12,
            AppSpacing.space24,
            AppSpacing.space12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    key: const Key('connect_whatsapp_media_button'),
                    label: busy
                        ? 'Opening WhatsApp Media…'
                        : 'Connect WhatsApp Media',
                    isFullWidth: true,
                    isLoading: busy,
                    leadingIcon: AppIcons.folderOpen,
                    onPressed: onPressed,
                    semanticLabel: busy
                        ? 'Opening WhatsApp Media'
                        : 'Connect WhatsApp Media',
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    busy
                        ? 'Opening WhatsApp Media…'
                        : 'One-time setup • Your media stays on this device',
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
