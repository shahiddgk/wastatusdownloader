import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_icons.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../domain/entities/status_item.dart';
import '../common/buttons/keep_button.dart';
import '../common/media/freshness_label.dart';
import '../common/media/media_placeholder.dart';
import '../common/media/video_badge.dart';

/// Primary media thumbnail card in the Moments grid.
///
/// Implements specification from docs/design/keeva-component-spec.md Section 2.7:
/// - Fixed aspect ratio 9:16.
/// - 12dp rounded corners (`AppRadius.borderMd`).
/// - Micro-interaction scale (0.98) on press.
/// - Kept badge (top-left) when saved.
/// - VideoBadge with duration (top-right) if video.
/// - Relative freshness label (bottom-left).
/// - Signature KeepButton (bottom-right) with 48dp hit area.
/// - Linear gradient scrim at bottom to ensure 14:1 contrast.
/// - Wrapped in [RepaintBoundary] to isolate thumbnail rendering from scroll.
class StatusCard extends StatefulWidget {
  final StatusItem item;
  final VoidCallback? onTap;
  final VoidCallback? onKeep;
  final VoidCallback? onAlreadyKept;
  final KeepState keepState;
  final bool isSelected;
  final String? thumbnailPath;
  final Future<String?> Function(StatusItem)? thumbnailLoader;
  final Widget? contactLabel;

  const StatusCard({
    super.key,
    required this.item,
    this.onTap,
    this.onKeep,
    this.onAlreadyKept,
    this.keepState = KeepState.idle,
    this.isSelected = false,
    this.thumbnailPath,
    this.thumbnailLoader,
    this.contactLabel,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  bool _isPressed = false;
  String? _resolvedThumbnailPath;
  @override
  void initState() {
    super.initState();
    _resolvedThumbnailPath = widget.thumbnailPath;
    if (_resolvedThumbnailPath == null && widget.thumbnailLoader != null) {
      _loadThumbnail();
    }
  }

  @override
  void didUpdateWidget(covariant StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thumbnailPath != null &&
        widget.thumbnailPath != _resolvedThumbnailPath) {
      _resolvedThumbnailPath = widget.thumbnailPath;
    } else if (oldWidget.item.id != widget.item.id &&
        widget.thumbnailLoader != null) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.thumbnailLoader == null) return;
    try {
      final path = await widget.thumbnailLoader!(widget.item);
      if (mounted) {
        setState(() {
          _resolvedThumbnailPath = path;
        });
      }
    } catch (_) {
      // Keep placeholder if load fails
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  Widget _buildMediaContent() {
    final path = _resolvedThumbnailPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            MediaPlaceholder(isVideo: widget.item.isVideo),
      );
    }

    return MediaPlaceholder(isVideo: widget.item.isVideo);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isKept =
        widget.item.isSaved ||
        widget.keepState == KeepState.alreadyKept ||
        widget.keepState == KeepState.success;
    final mediaTypeLabel = widget.item.isVideo ? 'Video' : 'Photo';
    final freshnessText = FreshnessLabel.formatFreshness(
      widget.item.lastModified,
    );
    final semanticDescription =
        '$mediaTypeLabel status, $freshnessText. ${isKept ? 'Already saved in vault. ' : ''}Double tap to preview.';

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: semanticDescription,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: AppMotion.buttonSpring,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: widget.isSelected
                      ? Border.all(color: scheme.primary, width: 2.0)
                      : Border.all(color: scheme.outlineVariant, width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Media Image / Placeholder with Hero transition
                      Hero(
                        tag: 'status_hero_${widget.item.id}',
                        flightShuttleBuilder:
                            (
                              flightContext,
                              animation,
                              flightDirection,
                              fromHeroContext,
                              toHeroContext,
                            ) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: toHeroContext.widget,
                              );
                            },
                        child: _buildMediaContent(),
                      ),

                      // 3. Top-Left Kept Badge
                      if (isKept)
                        Positioned(
                          top: AppSpacing.space8,
                          left: AppSpacing.space8,
                          child: KeBadge(
                            label:
                                MediaQuery.textScalerOf(context).scale(11) >= 17
                                ? ''
                                : 'Saved',
                            uppercase: false,
                            leading: Icon(
                              AppIcons.actionCheck,
                              size: 13,
                              color: scheme.primary,
                            ),
                          ),
                        ),

                      if (!isKept)
                        Positioned(
                          top: AppSpacing.space8,
                          left: AppSpacing.space8,
                          child: KeBadge(
                            label:
                                MediaQuery.textScalerOf(context).scale(11) >= 17
                                ? ''
                                : widget.item.isVideo
                                ? 'Video'
                                : 'Photo',
                            leading: Icon(
                              widget.item.isVideo
                                  ? Icons.play_arrow_rounded
                                  : Icons.image_outlined,
                              size: 13,
                              color: scheme.primary,
                            ),
                          ),
                        ),

                      // 4. Top-Right Video Badge
                      if (widget.item.isVideo)
                        const Positioned(
                          top: AppSpacing.space8,
                          right: AppSpacing.space8,
                          child: VideoBadge(durationMs: 0),
                        ),

                      // The scrim grows with the label and text size.
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space8,
                            AppSpacing.space24,
                            AppSpacing.space2,
                            AppSpacing.space2,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xE6000000)],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.contactLabel != null)
                                widget.contactLabel!,
                              const SizedBox(height: AppSpacing.space4),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final stackActions =
                                      constraints.maxWidth < 150 ||
                                      MediaQuery.textScalerOf(context)
                                              .scale(14) >=
                                          21;
                                  final freshness = FreshnessLabel(
                                    timestamp: widget.item.lastModified,
                                  );
                                  final saveButton = KeepButton(
                                    state: widget.keepState,
                                    onPressed: widget.onKeep,
                                    onAlreadyKeptPressed: widget.onAlreadyKept,
                                    variant: KeepButtonVariant.cardOverlay,
                                  );

                                  if (stackActions) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        freshness,
                                        const SizedBox(
                                          height: AppSpacing.space4,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: saveButton,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(child: freshness),
                                      const SizedBox(width: AppSpacing.space8),
                                      saveButton,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
