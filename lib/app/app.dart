import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import '../application/access/access_state.dart';
import '../application/providers.dart';
import '../domain/entities/status_item.dart';
import '../presentation/kept/kept_vault_screen.dart';
import '../presentation/moments/moments_screen.dart';
import '../presentation/onboarding/permission_onboarding_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/shell/adaptive_navigation.dart';
import '../presentation/shell/app_shell.dart';
import '../presentation/viewer/media_viewer_screen.dart';
import 'theme/app_theme.dart';

enum AppThemeChoice { system, light, dark }

/// Top-level application widget for WA Status Downloader.
///
/// Implements the complete production application flow:
/// - Verifies SAF access on startup via [accessNotifierProvider].
/// - Displays 3-step [PermissionOnboardingScreen] if access has not been granted.
/// - Transitions to [AppShell] hosting Moments, Kept Vault, and Settings once granted.
/// - Manages full-screen [MediaViewerScreen] transitions with 300ms smooth transition.
class StatusSaverApp extends ConsumerStatefulWidget {
  const StatusSaverApp({super.key});

  @override
  ConsumerState<StatusSaverApp> createState() => _StatusSaverAppState();
}

class _StatusSaverAppState extends ConsumerState<StatusSaverApp>
    with WidgetsBindingObserver {
  NavDestination _activeDestination = NavDestination.moments;
  bool _hasShownMainShell = false;
  ThemeMode _themeMode = ThemeMode.system;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreference();
    // Verify storage access on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activePkg = ref.read(selectedTargetPackageProvider);
      ref
          .read(accessNotifierProvider.notifier)
          .checkAccess(targetPackage: activePkg);
    });
  }

  Future<void> _loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final stored = preferences.getString('theme_mode');
    setState(() {
      _themeMode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('theme_mode', mode.name);
  }

  @override
  void dispose() {
    _stopStatusRefreshTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      final accessState = ref.read(accessNotifierProvider);
      if (accessState.isGranted) {
        ref
            .read(statusListNotifierProvider.notifier)
            .refresh(targetPackage: ref.read(selectedTargetPackageProvider));
      }
    });
  }

  void _stopStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final activePkg = ref.read(selectedTargetPackageProvider);
      final accessState = ref.read(accessNotifierProvider);
      _stopStatusRefreshTimer();
      ref.invalidate(savedStatusesProvider);
      if (!accessState.isRequesting) {
        ref
            .read(accessNotifierProvider.notifier)
            .checkAccess(targetPackage: activePkg);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopStatusRefreshTimer();
    }
  }

  void _openViewer(StatusItem item) {
    _navigatorKey.currentState?.push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: MediaViewerScreen(
              item: item,
              onShare: (mediaItem) async {
                final useCase = ref.read(shareStatusUseCaseProvider);
                await useCase(
                  id: mediaItem.id,
                  displayName: mediaItem.displayName,
                  mimeType: mediaItem.mimeType,
                  isVideo: mediaItem.isVideo,
                );
              },
              onNavigateToKept: () {
                setState(() => _activeDestination = NavDestination.kept);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessNotifierProvider);

    ref.listen<AccessState>(accessNotifierProvider, (previous, next) {
      if (next case AccessGranted(:final targetPackage, :final treeUri)) {
        _hasShownMainShell = true;
        _startStatusRefreshTimer();
        final activePkg = ref.read(selectedTargetPackageProvider);
        if (targetPackage == activePkg) {
          ref
              .read(statusListNotifierProvider.notifier)
              .load(targetPackage: activePkg, treeUri: treeUri);
        }
      }
      if (next is! AccessGranted) {
        _stopStatusRefreshTimer();
      }
    });

    ref.listen<String>(selectedTargetPackageProvider, (previous, next) {
      if (previous != next) {
        ref.read(statusListNotifierProvider.notifier).resetForPackage(next);
        ref
            .read(accessNotifierProvider.notifier)
            .checkAccess(targetPackage: next);
      }
    });

    final Widget content;

    final keepMainShellDuringSourceCheck =
        _hasShownMainShell &&
        (accessState.isChecking || accessState.isRequesting);

    if (accessState.isGranted || keepMainShellDuringSourceCheck) {
      final activeScreen = switch (_activeDestination) {
        NavDestination.moments => MomentsScreen(
          onStatusSelected: (item) => _openViewer(item),
          onExploreKept: () {
            setState(() => _activeDestination = NavDestination.kept);
          },
        ),
        NavDestination.kept => KeptVaultScreen(
          onStatusSelected: (item) => _openViewer(item),
          onExploreMoments: () {
            setState(() => _activeDestination = NavDestination.moments);
          },
        ),
        NavDestination.settings => SettingsScreen(
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
        ),
      };

      content = AppShell(
        activeDestination: _activeDestination,
        onDestinationSelected: (dest) {
          setState(() => _activeDestination = dest);
        },
        body: activeScreen,
      );
    } else {
      content = const PermissionOnboardingScreen();
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WA Status Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: content,
    );
  }
}
