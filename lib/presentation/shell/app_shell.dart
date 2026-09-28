import 'package:flutter/material.dart';
import 'package:whatsapp_status_saver/app/theme/app_theme.dart';

import 'adaptive_navigation.dart';

/// Top-level responsive layout container for WA Status Downloader.
///
/// Implements specification from docs/design/app-component-spec.md Section 2.1:
/// - Compact (< 600dp): Bottom Navigation Bar.
/// - Expanded (>= 600dp): Left Navigation Rail (80dp compact or 220dp extended).
/// - Safe area compliance via MediaQuery.viewPaddingOf(context).
class AppShell extends StatelessWidget {
  final NavDestination activeDestination;
  final ValueChanged<NavDestination> onDestinationSelected;
  final PreferredSizeWidget? topBar;
  final Widget body;

  const AppShell({
    super.key,
    required this.activeDestination,
    required this.onDestinationSelected,
    required this.body,
    this.topBar,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = width >= 600;
    final colors = AppTheme.colorsOf(context);
    final theme = Theme.of(context);

    if (isExpanded) {
      final isWide = width >= 840;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: topBar,
        body: Row(
          children: [
            AppNavRail(
              activeDestination: activeDestination,
              onDestinationSelected: onDestinationSelected,
              isExpanded: isWide,
            ),
            Container(width: 1, color: colors.borderSubtle),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: topBar,
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        activeDestination: activeDestination,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
