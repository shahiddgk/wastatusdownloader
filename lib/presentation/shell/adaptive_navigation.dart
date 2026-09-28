import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whatsapp_status_saver/app/theme/app_theme.dart';
import 'package:whatsapp_status_saver/app/theme/app_icons.dart';
import 'package:whatsapp_status_saver/app/theme/app_spacing.dart';
import 'package:whatsapp_status_saver/app/theme/app_typography.dart';

enum NavDestination { moments, kept, settings }

/// Adaptive navigation destination model.
class NavItem {
  final NavDestination destination;
  final String label;
  final IconData icon;

  const NavItem({
    required this.destination,
    required this.label,
    required this.icon,
  });

  static const List<NavItem> items = [
    NavItem(
      destination: NavDestination.moments,
      label: 'Status',
      icon: AppIcons.navMoments,
    ),
    NavItem(
      destination: NavDestination.kept,
      label: 'Saved',
      icon: AppIcons.navKept,
    ),
    NavItem(
      destination: NavDestination.settings,
      label: 'Settings',
      icon: AppIcons.navSettings,
    ),
  ];
}

/// Adaptive navigation controller rendering BottomNav on phones (< 600dp)
/// and NavigationRail on tablets (>= 600dp).
///
/// Implements specification from docs/design/app-component-spec.md Section 2.3.
class AppBottomNavBar extends StatelessWidget {
  final NavDestination activeDestination;
  final ValueChanged<NavDestination> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.activeDestination,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return NavigationBar(
      selectedIndex: activeDestination.index,
      onDestinationSelected: (index) {
        if (index != activeDestination.index) {
          HapticFeedback.selectionClick();
          onDestinationSelected(NavDestination.values[index]);
        }
      },
      backgroundColor:
          Theme.of(context).navigationBarTheme.backgroundColor ??
          colors.surfaceLevel0,
      indicatorColor:
          Theme.of(context).navigationBarTheme.indicatorColor ??
          colors.primaryDark,
      elevation: 0,
      height: 64,
      destinations: NavItem.items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon, color: colors.textTertiary),
          selectedIcon: Icon(item.icon, color: colors.primaryLight),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class AppNavRail extends StatelessWidget {
  final NavDestination activeDestination;
  final ValueChanged<NavDestination> onDestinationSelected;
  final bool isExpanded;

  const AppNavRail({
    super.key,
    required this.activeDestination,
    required this.onDestinationSelected,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return NavigationRail(
      selectedIndex: activeDestination.index,
      onDestinationSelected: (index) {
        if (index != activeDestination.index) {
          HapticFeedback.selectionClick();
          onDestinationSelected(NavDestination.values[index]);
        }
      },
      extended: isExpanded,
      minWidth: 80,
      minExtendedWidth: 220,
      labelType: isExpanded ? null : NavigationRailLabelType.all,
      backgroundColor: colors.surfaceLevel0,
      indicatorColor: colors.primaryDark,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space20),
        child: Text(
          isExpanded ? 'WA Status Downloader' : 'WA',
          style: AppTypography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      destinations: NavItem.items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon, color: colors.textTertiary),
          selectedIcon: Icon(item.icon, color: colors.primaryLight),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}
