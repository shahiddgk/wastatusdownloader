import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Presentation of the application logo.
class KeevaLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showPlate;

  const KeevaLogo({
    super.key,
    this.size = 72.0,
    this.showGlow = true,
    this.showPlate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.darkPrimary.withValues(alpha: 0.28),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.08,
                ),
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.02,
                ),
              ]
            : null,
      ),
      child: Image.asset(
        'assets/icon/logo_full.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
