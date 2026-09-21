import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/access/access_state.dart';
import '../../application/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../platform/method_channel_status_scanner.dart';
import '../common/sheets/bottom_sheet.dart';

/// Settings & System Integration Screen.
///
/// Implements minimal, high-utility settings specified in Section 23:
/// - Storage Access & SAF connection status for Standard & Business WhatsApp.
/// - Folder reconnection.
/// - Privacy & Local-first explanation.
/// - Application version & diagnostics.
class SettingsScreen extends ConsumerStatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SettingsScreen({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _bitratePreservation = true;
  bool _autoPurge = true;
  String _downloadFolder = 'Pictures/SavedStatus';
  bool _isSelectingDownloadFolder = false;

  final MethodChannelStatusScanner _platform =
      const MethodChannelStatusScanner();

  @override
  void initState() {
    super.initState();
    _loadDownloadFolder();
  }

  Future<void> _loadDownloadFolder() async {
    try {
      final folder = await _platform.getDownloadFolder();
      if (mounted && folder != null && folder.isNotEmpty) {
        setState(() => _downloadFolder = folder);
      }
    } catch (_) {
      // Keep the documented default when the native layer is unavailable.
    }
  }

  Future<void> _selectDownloadFolder() async {
    if (_isSelectingDownloadFolder) return;
    setState(() => _isSelectingDownloadFolder = true);
    try {
      final folder = await _platform.requestDownloadFolder();
      if (mounted && folder != null && folder.isNotEmpty) {
        setState(() => _downloadFolder = folder);
      }
    } finally {
      if (mounted) setState(() => _isSelectingDownloadFolder = false);
    }
  }

  Widget _buildStorageCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String package,
    required bool isCurrentlyActive,
    required AccessState accessState,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isGranted =
        accessState.isGranted &&
        (accessState is AccessGranted && accessState.targetPackage == package);

    return KeCard(
      padding: const EdgeInsets.all(10),
      color: isCurrentlyActive
          ? scheme.surfaceContainer
          : scheme.surfaceContainer.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isGranted
                      ? scheme.primary.withValues(alpha: 0.12)
                      : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted
                      ? Icons.check_circle_outline_rounded
                      : Icons.folder_off_outlined,
                  size: 20,
                  color: isGranted ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isCurrentlyActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted
                          ? 'Folder Connected ($package)'
                          : 'Folder not connected yet',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NeonButton(
            label: isGranted ? 'Reconnect Folder' : 'Grant SAF Access',
            leading: Icon(
              isGranted
                  ? Icons.folder_open_rounded
                  : Icons.folder_shared_outlined,
              size: 18,
              color: scheme.onPrimary,
            ),
            compact: true,
            onPressed: () {
              ref
                  .read(selectedTargetPackageProvider.notifier)
                  .selectPackage(package);
              ref
                  .read(accessNotifierProvider.notifier)
                  .requestAccess(targetPackage: package);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessNotifierProvider);
    final activePackage = ref.watch(selectedTargetPackageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const KeAppAppBar(screenName: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _buildPageIntro(accessState),
          const SizedBox(height: 22),
          const _SettingsSectionTitle(
            title: 'Storage & Access',
            subtitle: 'Android Storage Access Framework (SAF) configuration',
          ),
          const SizedBox(height: 10),

          _buildStorageCard(
            context: context,
            ref: ref,
            title: 'WhatsApp',
            package: AppConstants.whatsappStandardPackage,
            isCurrentlyActive:
                activePackage == AppConstants.whatsappStandardPackage,
            accessState: accessState,
          ),
          const SizedBox(height: 10),

          _buildStorageCard(
            context: context,
            ref: ref,
            title: 'WhatsApp Business',
            package: AppConstants.whatsappBusinessPackage,
            isCurrentlyActive:
                activePackage == AppConstants.whatsappBusinessPackage,
            accessState: accessState,
          ),

          const SizedBox(height: 26),
          _buildPrivacySection(context),
          const SizedBox(height: 26),
          _buildPreferencesSection(context),
          const SizedBox(height: 26),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildPageIntro(AccessState accessState) {
    final isOnline = accessState.isGranted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: _SettingsSectionTitle(
            title: 'System & Vault',
            subtitle: 'Configure local storage permissions & stealth settings',
          ),
        ),
        _StatusBadge(
          label: isOnline ? 'SAF\nONLINE' : 'SAF\nOFFLINE',
          active: isOnline,
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsSectionTitle(
          title: 'Privacy & Local Architecture',
          subtitle: 'Military-grade on-device isolation & zero network traces',
        ),
        const SizedBox(height: 10),
        KeCard(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              InkWell(
                onTap: () => KeevaBottomSheet.showTrustDetails(context),
                borderRadius: BorderRadius.circular(12),
                child: KeCard(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const _SettingsIcon(icon: Icons.shield_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private & Local-First',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '100% On-Device Guaranteed',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              _settingRow(
                title: 'Original Bitrate Preservation',
                subtitle: 'Extract uncompressed high-def statuses',
                trailing: KeToggle(
                  value: _bitratePreservation,
                  onChanged: (value) =>
                      setState(() => _bitratePreservation = value),
                ),
              ),
              _settingRow(
                title: 'Auto-Purge Expired Cache',
                subtitle: 'Clear unsaved statuses after 24 hours',
                trailing: KeToggle(
                  value: _autoPurge,
                  onChanged: (value) => setState(() => _autoPurge = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsSectionTitle(
          title: 'App Preferences',
          subtitle: 'Interface behavior & sensory feedback',
        ),
        const SizedBox(height: 10),
        KeCard(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              _settingRow(
                icon: Icons.folder_copy_outlined,
                title: 'Vault Download Path',
                subtitle: _downloadFolder,
                onTap: _selectDownloadFolder,
                trailing: _isSelectingDownloadFolder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 12,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Theme',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  for (final option in options)
                    ButtonSegment(
                      value: option.$1,
                      icon: Icon(option.$3, size: 16),
                      label: Text(option.$2),
                    ),
                ],
                selected: {widget.themeMode},
                onSelectionChanged: widget.onThemeModeChanged == null
                    ? null
                    : (selection) =>
                          widget.onThemeModeChanged!(selection.first),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsSectionTitle(
          title: 'About WA Status Downloader',
          subtitle: 'Application metadata & system architecture',
        ),
        const SizedBox(height: 10),
        KeCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Row(
                children: [
                  const _SettingsIcon(icon: Icons.verified_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WA Status Downloader  PRO',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '1.0.0 (Production Release)',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _StatusBadge(label: 'Latest', active: true),
                ],
              ),
              const SizedBox(height: 18),
              _aboutRow('Engineered By', 'Rated Solution', accent: true),
              _aboutRow('Local Encryption', 'ChaCha20-Poly1305'),
              _aboutRow('Storage Architecture', 'SAF Scoped Storage API 34'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutRow(String title, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    IconData? icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (icon != null) ...[
            _SettingsIcon(icon: icon),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
    );
  }
}
