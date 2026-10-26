import 'package:flutter/material.dart';

import 'package:whatsapp_status_saver/app/theme/app_colors.dart';
import 'package:whatsapp_status_saver/app/theme/app_radius.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

/// Individual numbered instruction card within the permission guide.
///
/// Implements specification from docs/design/app-component-spec.md Section 2.16.
class PermissionStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final bool isHighlighted;

  const PermissionStep({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors =
        theme.extension<AppColorsExtension>() ?? AppColorsExtension.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? scheme.primary.withValues(alpha: 0.09)
            : colors.surfaceLevel1,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isHighlighted
              ? scheme.primary.withValues(alpha: 0.72)
              : colors.borderSubtle,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isHighlighted ? scheme.primary : colors.surfaceLevel2,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: AppTypography.labelMedium.copyWith(
                  color: isHighlighted ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
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
