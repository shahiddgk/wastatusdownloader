import 'package:flutter/material.dart';

import '../../../domain/entities/status_item.dart';

import 'package:whatsapp_status_saver/app/theme/app_colors.dart';
import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_radius.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// Modal bottom sheet launcher for WA Status Downloader.
///
/// Implements specification from docs/design/app-component-spec.md Section 2.17.
abstract final class AppBottomSheet {
  /// Displays a modal bottom sheet with top radius 24dp, drag handle, and dark surface.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.darkSurfaceLevel2,
      barrierColor: AppColors.darkScrim,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTop,
        side: BorderSide(color: AppColors.darkBorderSheet, width: 1),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: AppSpacing.space12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextTertiary.withValues(alpha: 0.4),
                  borderRadius: AppRadius.borderPill,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Flexible(child: builder(context)),
            ],
          ),
        );
      },
    );
  }

  /// Displays the Local-First & Privacy modal sheet.
  static Future<void> showTrustDetails(BuildContext context) {
    return show(
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
                    decoration: const BoxDecoration(
                      color: AppColors.darkPrimaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        AppIcons.privacyShield,
                        size: 20,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Private & Local-First',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'WA Status Downloader reads statuses only from the WhatsApp Media folder you connect once through Android’s system picker. Saved copies are stored in your gallery. The app has no internet permission and never uploads media.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.darkTextSecondary,
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

  /// Displays the Already Saved options modal sheet.
  static Future<void> showAlreadyKeptOptions({
    required BuildContext context,
    required StatusItem item,
    required VoidCallback onViewInVault,
    required VoidCallback onSaveCopy,
  }) {
    return show(
      context: context,
      builder: (context) {
        return Padding(
          padding: AppSpacing.sheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.darkPrimaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        AppIcons.actionCheck,
                        size: 20,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Already Saved',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          'This status is safely preserved in your Saved Vault.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),
              PrimaryButton(
                label: 'View in Saved Vault',
                leadingIcon: AppIcons.navKept,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewInVault();
                },
              ),
              const SizedBox(height: AppSpacing.space12),
              SecondaryButton(
                label: 'Save Copy',
                leadingIcon: AppIcons.actionKeep,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onSaveCopy();
                },
              ),
              const SizedBox(height: AppSpacing.space16),
            ],
          ),
        );
      },
    );
  }
}
