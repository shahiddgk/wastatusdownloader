import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material theme for WA Status Downloader's Dark Neon Vault visual system.
abstract final class NeonVaultTheme {
  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        .apply(
          bodyColor: NeonVaultColors.textPrimary,
          displayColor: NeonVaultColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeonVaultColors.scaffoldBackground,
      canvasColor: NeonVaultColors.scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: NeonVaultColors.accent,
        onPrimary: NeonVaultColors.darkText,
        secondary: NeonVaultColors.accentDark,
        onSecondary: NeonVaultColors.darkText,
        surface: NeonVaultColors.surface,
        onSurface: NeonVaultColors.textPrimary,
        outline: NeonVaultColors.cardBorder,
        error: Color(0xFFFF6B6B),
        onError: NeonVaultColors.darkText,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: NeonVaultColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: NeonVaultColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: NeonVaultColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: NeonVaultColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: NeonVaultColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: NeonVaultColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: NeonVaultColors.navigationSurface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        height: 64,
      ),
      dividerTheme: const DividerThemeData(
        color: NeonVaultColors.cardBorder,
        thickness: 1,
      ),
    );
  }
}
