import 'package:flutter/material.dart';

/// Dark Neon Vault color tokens.
abstract final class NeonVaultColors {
  static const scaffoldBackground = Color(0xFF070A09);
  static const surface = Color(0xFF121715);
  static const elevatedSurface = Color(0xFF161C19);
  static const appBarSurface = Color(0xFF0E1412);
  static const navigationSurface = Color(0xFF0C110F);
  static const cardBorder = Color(0x0FFFFFFF);
  static const accent = Color(0xFF00E676);
  static const accentDark = Color(0xFF22C55E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF5B6470);
  static const darkText = Color(0xFF06100A);
  static const scrim = Color(0xCC000000);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF4ADE80)],
  );

  static const neonGlow = <BoxShadow>[
    BoxShadow(color: Color(0x7300E676), blurRadius: 30),
  ];

  static const softGlow = <BoxShadow>[
    BoxShadow(color: Color(0x4000E676), blurRadius: 18),
  ];
}
