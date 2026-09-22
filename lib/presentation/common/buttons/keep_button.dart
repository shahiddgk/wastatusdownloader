import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:whatsapp_status_saver/app/theme/app_colors.dart';
import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_motion.dart';
import 'package:whatsapp_status_saver/app/theme/app_radius.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

enum KeepState { idle, saving, success, alreadyKept, failure }

enum KeepButtonVariant { cardOverlay, viewerAction }

/// Primary save action for a discovered status.
///
/// Shows a labelled action with a 48dp touch target on cards and in the viewer.
/// Press and success feedback respects reduced motion settings.
class KeepButton extends StatefulWidget {
  final KeepState state;
  final VoidCallback? onPressed;
  final VoidCallback? onAlreadyKeptPressed;
  final KeepButtonVariant variant;

  const KeepButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.onAlreadyKeptPressed,
    this.variant = KeepButtonVariant.cardOverlay,
  });

  @override
  State<KeepButton> createState() => _KeepButtonState();
}

class _KeepButtonState extends State<KeepButton> with TickerProviderStateMixin {
  bool _isPressed = false;
  DateTime? _lastTapTime;
  late final AnimationController _nudgeController;
  late final Animation<double> _nudgeAnimation;

  @override
  void initState() {
    super.initState();
    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _nudgeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _nudgeController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant KeepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && widget.state == KeepState.success) {
      HapticFeedback.selectionClick();
    } else if (oldWidget.state != widget.state &&
        widget.state == KeepState.failure) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _nudgeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.state == KeepState.saving) {
      return;
    }

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 400) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTap() {
    if (widget.state == KeepState.saving) {
      return;
    }

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 400) {
      return;
    }
    _lastTapTime = now;

    if (widget.state == KeepState.alreadyKept ||
        widget.state == KeepState.success) {
      HapticFeedback.selectionClick();
      if (!AppMotion.isReducedMotion(context)) {
        _nudgeController.forward(from: 0.0);
      }
      widget.onAlreadyKeptPressed?.call();
      return;
    }

    widget.onPressed?.call();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  String _semanticLabel() {
    return switch (widget.state) {
      KeepState.alreadyKept => 'Already saved',
      KeepState.success => 'Saved',
      KeepState.saving => 'Saving status',
      KeepState.failure => 'Could not save status. Tap to retry',
      KeepState.idle => 'Save this status',
    };
  }

  Widget _buildCardOverlay() {
    final isReduced = AppMotion.isReducedMotion(context);
    final isSaved =
        widget.state == KeepState.alreadyKept ||
        widget.state == KeepState.success;
    final isFailure = widget.state == KeepState.failure;
    final label = switch (widget.state) {
      KeepState.saving => 'Saving',
      KeepState.success || KeepState.alreadyKept => 'Saved',
      KeepState.failure => 'Retry',
      KeepState.idle => 'Save',
    };

    final containerColor = switch (widget.state) {
      KeepState.alreadyKept ||
      KeepState.success => AppColors.darkPrimaryContainer,
      KeepState.failure => const Color(0xFFEAA30A),
      _ => AppColors.darkPrimary,
    };
    final foregroundColor = isSaved
        ? AppColors.darkOnPrimaryContainer
        : AppColors.darkOnPrimary;

    final iconWidget = switch (widget.state) {
      KeepState.saving => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkOnPrimary),
        ),
      ),
      KeepState.success => const Icon(
        AppIcons.actionCheck,
        size: 20,
        color: AppColors.darkOnPrimaryContainer,
      ),
      KeepState.alreadyKept => const Icon(
        AppIcons.actionCheck,
        size: 18,
        color: AppColors.darkOnPrimaryContainer,
      ),
      KeepState.failure => const Icon(
        AppIcons.errorWarning,
        size: 18,
        color: AppColors.darkOnPrimary,
      ),
      KeepState.idle => const Icon(
        AppIcons.actionKeep,
        size: 18,
        color: AppColors.darkOnPrimary,
      ),
    };

    final visualAction = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailure ? AppColors.darkWarning : AppColors.darkBorderSheet,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: AppSpacing.space4),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: Center(
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: isReduced
              ? Duration.zero
              : const Duration(milliseconds: 80),
          curve: AppMotion.buttonSpring,
          child: visualAction,
        ),
      ),
    );
  }

  Widget _buildViewerAction() {
    final isSaved =
        widget.state == KeepState.alreadyKept ||
        widget.state == KeepState.success;
    final isSaving = widget.state == KeepState.saving;

    final bgColor = isSaved
        ? AppColors.darkPrimaryContainer
        : widget.state == KeepState.failure
        ? AppColors.darkWarning
        : AppColors.darkPrimary;
    final fgColor = isSaved
        ? AppColors.darkOnPrimaryContainer
        : AppColors.darkOnPrimary;

    final label = switch (widget.state) {
      KeepState.saving => 'Saving',
      KeepState.failure => 'Retry',
      KeepState.success || KeepState.alreadyKept => 'Saved',
      KeepState.idle => 'Save',
    };

    return SizedBox(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaving) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
            ] else ...[
              Icon(
                isSaved ? AppIcons.actionCheck : AppIcons.actionKeep,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: AppSpacing.space8),
            ],
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(color: fgColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = switch (widget.state) {
      KeepState.saving => false,
      KeepState.success ||
      KeepState.alreadyKept => widget.onAlreadyKeptPressed != null,
      KeepState.idle || KeepState.failure => widget.onPressed != null,
    };

    final child = widget.variant == KeepButtonVariant.cardOverlay
        ? _buildCardOverlay()
        : _buildViewerAction();

    final animatedChild = AnimatedBuilder(
      animation: _nudgeAnimation,
      builder: (context, c) {
        if (_nudgeAnimation.value == 0.0) return c!;
        return Transform.translate(
          offset: Offset(_nudgeAnimation.value, 0.0),
          child: c,
        );
      },
      child: child,
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: _semanticLabel(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: isInteractive ? _handleTapDown : null,
        onTapUp: isInteractive ? _handleTapUp : null,
        onTapCancel: isInteractive ? _handleTapCancel : null,
        onTap: isInteractive ? _handleTap : null,
        child: animatedChild,
      ),
    );
  }
}
