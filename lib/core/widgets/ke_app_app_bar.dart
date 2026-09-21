import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class KeAppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenName;
  final List<Widget> actions;
  final VoidCallback? onAvatarPressed;

  const KeAppAppBar({
    super.key,
    required this.screenName,
    this.actions = const [],
    this.onAvatarPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              _KeAppMark(color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  screenName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...actions,
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAvatarPressed,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: scheme.brightness == Brightness.dark
                        ? NeonVaultColors.softGlow
                        : null,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeAppMark extends StatelessWidget {
  final Color color;

  const _KeAppMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? NeonVaultColors.softGlow
            : null,
      ),
      child: CustomPaint(painter: _DownloadRingPainter(color)),
    );
  }
}

class _DownloadRingPainter extends CustomPainter {
  final Color color;

  const _DownloadRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.5,
      4.9,
      false,
      paint,
    );
    final arrowY = center.dy - 7;
    canvas.drawLine(
      Offset(center.dx, arrowY),
      Offset(center.dx, center.dy + 6),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx - 4, center.dy + 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx + 4, center.dy + 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
