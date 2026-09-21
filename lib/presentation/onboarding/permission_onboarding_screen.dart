import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_icons.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../application/access/access_state.dart';
import '../../application/providers.dart';
import '../common/onboarding/permission_guide.dart';
import '../common/sheets/bottom_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';

/// Screen A: Polished First-Launch & SAF Onboarding Screen.
///
/// Implements specification from Phase 2H Brand Identity & Launch Experience:
/// - Real Keeva logo mark with ambient Aurora glow.
/// - Calm, trustworthy copy emphasizing privacy and local-first storage.
/// - 3-step structured guidance for Android SAF folder selection.
/// - Inline loading indicator during system DocumentsUI picker interaction.
/// - Error and recovery feedback banners.
class PermissionOnboardingScreen extends ConsumerWidget {
  final VoidCallback? onAccessGranted;

  const PermissionOnboardingScreen({super.key, this.onAccessGranted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(accessNotifierProvider);

    ref.listen<AccessState>(accessNotifierProvider, (previous, next) {
      if (next.isGranted) {
        onAccessGranted?.call();
      }
    });

    final isLoading = accessState.isRequesting || accessState.isChecking;
    final stepLabel = switch (accessState) {
      AccessChecking() => 'Checking secure access',
      AccessRequesting() => 'Waiting for folder selection',
      AccessGranted() => 'Vault ready',
      _ => 'Ready to connect your vault',
    };
    final progress = switch (accessState) {
      AccessChecking() => 0.68,
      AccessRequesting() => 0.86,
      AccessGranted() => 1.0,
      _ => 0.25,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const KeAppAppBar(screenName: 'Status'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: const KeBadge(
                        label: 'V2.4 Pro Engine',
                        showDot: true,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildVaultMark(context),
                    const SizedBox(height: 20),
                    Text(
                      'WA Status Downloader',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status Vault & Saver',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Save status in Ultra HD. Private, silent, and local-first.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureRow(context),
                    const SizedBox(height: 24),
                    if (accessState is AccessInvalid ||
                        accessState is AccessRevoked ||
                        accessState is AccessUnavailable ||
                        accessState is AccessFailure) ...[
                      _buildFeedbackBanner(context, accessState),
                      const SizedBox(height: 16),
                    ],
                    const KeCard(child: PermissionGuide()),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 9,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stepLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    KeProgressBar(value: progress),
                    const SizedBox(height: 18),
                    KeCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sandboxed Storage • Zero Network Telemetry',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: NeonButton(
                        label: isLoading
                            ? 'Connecting Securely...'
                            : 'Connect Media Folder',
                        leading: Icon(
                          isLoading
                              ? Icons.sync_rounded
                              : Icons.folder_open_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => ref
                                  .read(accessNotifierProvider.notifier)
                                  .requestAccess(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          KeevaBottomSheet.showTrustDetails(context),
                      child: Text(
                        'Learn how Keeva protects you',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVaultMark(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: NeonVaultColors.cardBorder),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? NeonVaultColors.neonGlow
                : null,
          ),
          child: Icon(
            Icons.download_for_offline_rounded,
            size: 68,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Positioned(
          bottom: -14,
          child: const KeBadge(label: 'Zero Latency', showDot: false),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(BuildContext context) {
    const features = [
      (Icons.lock_outline_rounded, '100% Local'),
      (Icons.hd_rounded, 'Lossless'),
      (Icons.verified_user_outlined, 'No Ads'),
    ];
    return Row(
      children: [
        for (final feature in features)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: KeCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 6,
                ),
                child: Column(
                  children: [
                    Icon(
                      feature.$1,
                      color: Theme.of(context).colorScheme.primary,
                      size: 25,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      feature.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeedbackBanner(BuildContext context, AccessState state) {
    final String message;
    final IconData icon;
    final Color color;

    switch (state) {
      case AccessInvalid(:final reason):
        message = reason ?? 'Please select the WhatsApp media folder so Keeva can discover status.';
        icon = AppIcons.errorWarning;
        color = Theme.of(context).colorScheme.primary;
      case AccessRevoked(:final reason):
        message = reason ?? 'Folder access was revoked. Please reconnect your WhatsApp media folder.';
        icon = AppIcons.errorWarning;
        color = Theme.of(context).colorScheme.primary;
      case AccessUnavailable(:final reason):
        message =
            reason ?? 'WhatsApp status folder was not found on this device.';
        icon = AppIcons.errorWarning;
        color = Theme.of(context).colorScheme.primary;
      case AccessFailure(:final failure):
        message = failure.message.isNotEmpty
            ? failure.message
            : 'Unable to connect folder. Tap below to try again.';
        icon = AppIcons.errorCircle;
        color = const Color(0xFFFF6B6B);
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
