import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/access/access_state.dart';
import '../../application/providers.dart';
import '../../core/widgets/ke_app_app_bar.dart';
import '../../core/widgets/neon_widgets.dart';

class PermissionOnboardingScreen extends ConsumerWidget {
  final VoidCallback? onAccessGranted;

  const PermissionOnboardingScreen({super.key, this.onAccessGranted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessNotifierProvider);
    ref.listen<AccessState>(accessNotifierProvider, (previous, next) {
      if (next.isGranted) onAccessGranted?.call();
    });
    final busy = access.isChecking || access.isRequesting;
    final message = switch (access) {
      AccessInvalid() ||
      AccessRevoked() => 'Allow access to see your statuses.',
      AccessUnavailable() => 'Status access is unavailable on this device.',
      AccessFailure() => 'Could not get access. Please try again.',
      _ => 'Allow file access to find viewed WhatsApp statuses automatically.',
    };
    return Scaffold(
      appBar: const KeAppAppBar(screenName: 'Status'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.perm_media_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(message, textAlign: TextAlign.center),
                if (access is! AccessUnavailable) ...[
                  const SizedBox(height: 12),
                  Text(
                    'If All files access opens, enable the switch and return here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                NeonButton(
                  label: busy ? 'Checking access…' : 'Allow access',
                  isLoading: busy,
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(accessNotifierProvider.notifier)
                            .requestAccess(
                              targetPackage: ref.read(
                                selectedTargetPackageProvider,
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
