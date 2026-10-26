import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/widgets/ke_app_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SettingsScreen({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessNotifierProvider);
    final busy = access.isChecking || access.isRequesting;
    return Scaffold(
      appBar: const KeAppAppBar(screenName: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.perm_media_outlined),
            title: const Text('Status access'),
            subtitle: Text(
              access.isGranted
                  ? 'WhatsApp Media connected'
                  : 'Connect WhatsApp Media',
            ),
            trailing: busy
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (access.isGranted) const Icon(Icons.check),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
            onTap: busy
                ? null
                : () => ref
                      .read(accessNotifierProvider.notifier)
                      .requestAccess(
                        targetPackage: ref.read(selectedTargetPackageProvider),
                      ),
          ),
          const Divider(),
          for (final option in const [
            (ThemeMode.system, 'System theme', Icons.brightness_auto),
            (ThemeMode.light, 'Light theme', Icons.light_mode_outlined),
            (ThemeMode.dark, 'Dark theme', Icons.dark_mode_outlined),
          ])
            ListTile(
              leading: Icon(option.$3),
              title: Text(option.$2),
              trailing: themeMode == option.$1 ? const Icon(Icons.check) : null,
              selected: themeMode == option.$1,
              onTap: onThemeModeChanged == null
                  ? null
                  : () => onThemeModeChanged!(option.$1),
            ),
        ],
      ),
    );
  }
}
