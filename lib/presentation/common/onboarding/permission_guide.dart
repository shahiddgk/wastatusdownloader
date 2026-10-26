import 'package:flutter/material.dart';

import 'package:whatsapp_status_saver/app/theme/app_colors.dart';
import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_radius.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

import 'permission_step.dart';

/// The three-step visual guide for connecting the WhatsApp Media folder.
///
/// Implements specification from docs/design/app-component-spec.md Section 2.15
/// and docs/design/app-ui-spec.md Screen A.
class PermissionGuide extends StatelessWidget {
  const PermissionGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors =
        theme.extension<AppColorsExtension>() ?? AppColorsExtension.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space12),
          child: Text(
            'WHAT HAPPENS NEXT',
            style: AppTypography.labelSmall.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const PermissionStep(
          stepNumber: 1,
          title: '1. View statuses in WhatsApp',
          description: 'Statuses only exist on your device after you have viewed them in WhatsApp.',
        ),
        const SizedBox(height: AppSpacing.space12),
        const PermissionStep(
          stepNumber: 2,
          title: '2. Tap Connect WhatsApp Media',
          description: 'Android’s system picker opens WhatsApp Media for you.',
        ),
        const SizedBox(height: AppSpacing.space12),
        const PermissionStep(
          stepNumber: 3,
          title: '3. Tap “Use this folder”, then “Allow”',
          description: 'Confirm once. The connection stays active until you change or revoke it.',
          isHighlighted: true,
        ),
        const SizedBox(height: AppSpacing.space16),

        // Privacy Guarantee Pill
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.borderPill,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.privacyShield, size: 16, color: scheme.primary),
              const SizedBox(width: AppSpacing.space8),
              Flexible(
                child: Text(
                  '100% On-Device • Zero Network • Private',
                  style: AppTypography.labelMedium.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.76),
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
