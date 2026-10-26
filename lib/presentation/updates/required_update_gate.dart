import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/updates/required_update_controller.dart';
import '../../core/constants/app_constants.dart';

/// Covers the entire root Navigator, including viewers and open dialogs.
class RequiredUpdateGate extends StatefulWidget {
  const RequiredUpdateGate({
    super.key,
    required this.controller,
    required this.child,
  });

  final RequiredUpdateController controller;
  final Widget child;

  @override
  State<RequiredUpdateGate> createState() => _RequiredUpdateGateState();
}

class _RequiredUpdateGateState extends State<RequiredUpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.controller.refresh());
    });
  }

  @override
  void didUpdateWidget(covariant RequiredUpdateGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      unawaited(widget.controller.refresh());
    }
  }

  void _onChanged() {
    if (!mounted) return;
    if (widget.controller.blocksApp) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.refresh());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final blocked = controller.blocksApp;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: TickerMode(
            enabled: !blocked,
            child: ExcludeFocus(
              excluding: blocked,
              child: ExcludeSemantics(
                excluding: blocked,
                child: IgnorePointer(ignoring: blocked, child: widget.child),
              ),
            ),
          ),
        ),
        if (blocked)
          Material(
            key: const Key('required_update_gate'),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.system_update_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          controller.required
                              ? 'Update required'
                              : controller.checking
                              ? 'Checking for updates'
                              : 'Could not check for updates',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.required
                              ? 'Update ${AppConstants.appName} in Google Play to continue.'
                              : controller.checking
                              ? 'Please wait while we check Google Play.'
                              : 'Please try again to check for app updates.',
                          textAlign: TextAlign.center,
                        ),
                        if (controller.message.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(controller.message, textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 24),
                        if (controller.busy || controller.checking)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          FilledButton.icon(
                            key: const Key('required_update_button'),
                            onPressed: () => unawaited(
                              controller.required
                                  ? controller.update()
                                  : controller.refresh(),
                            ),
                            icon: const Icon(Icons.system_update_alt_rounded),
                            label: Text(
                              controller.required ? 'Update now' : 'Try again',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
