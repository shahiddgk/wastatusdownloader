import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../application/status_label_controller.dart';

class StatusContactLabel extends ConsumerWidget {
  final String statusId;
  final StatusContactLabelStyle style;

  const StatusContactLabel({
    super.key,
    required this.statusId,
    this.style = StatusContactLabelStyle.card,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(statusLabelProvider(statusId));
    final label = labelState.asData?.value;
    final text = labelState.isLoading
        ? 'Loading label…'
        : labelState.hasError
        ? 'Retry label'
        : label ?? 'Add name / number';
    final isKnown = label != null && !labelState.hasError;
    final useCardStyle = style == StatusContactLabelStyle.card;
    final foreground = Colors.white;
    final background = useCardStyle
        ? isKnown
              ? const Color(0xD9164E43)
              : const Color(0xCC101820)
        : Colors.transparent;

    return Tooltip(
      message: labelState.hasError
          ? 'Retry loading the name or number for this status'
          : label == null
          ? 'Add the name or number to show it on this status'
          : 'Edit the name or number shown on this status',
      child: Semantics(
        button: true,
        enabled: !labelState.isLoading,
        label: labelState.hasError
            ? 'Could not load status owner. Retry'
            : label == null
            ? 'Add name or number for this status'
            : 'Name or number you added: $label. Edit',
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: labelState.isLoading
                ? null
                : () {
                    if (labelState.hasError) {
                      ref.invalidate(statusLabelProvider(statusId));
                      return;
                    }
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (context) => _ContactLabelEditor(
                        statusId: statusId,
                        initialLabel: label ?? '',
                      ),
                    );
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: useCardStyle
                        ? Colors.white.withValues(alpha: isKnown ? 0.22 : 0.16)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isKnown
                            ? Colors.white.withValues(alpha: 0.15)
                            : Theme.of(context).colorScheme.primary.withValues(
                                alpha: useCardStyle ? 0.85 : 0.15,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isKnown
                            ? Icons.person_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: isKnown
                            ? Colors.white
                            : useCardStyle
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isKnown && useCardStyle)
                            Text(
                              'YOUR LABEL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                  ),
                            ),
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isKnown ? Icons.edit_rounded : Icons.add_rounded,
                      color: foreground.withValues(alpha: 0.82),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusContactLabelStyle { card, viewer }

class _ContactLabelEditor extends ConsumerStatefulWidget {
  final String statusId;
  final String initialLabel;

  const _ContactLabelEditor({
    required this.statusId,
    required this.initialLabel,
  });

  @override
  ConsumerState<_ContactLabelEditor> createState() =>
      _ContactLabelEditorState();
}

class _ContactLabelEditorState extends ConsumerState<_ContactLabelEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await ref
        .read(statusLabelProvider(widget.statusId).notifier)
        .save(value);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = 'Could not save this label. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space24,
            0,
            AppSpacing.space24,
            AppSpacing.space24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Text(
                        'Who posted this status?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'WhatsApp does not include the sender name in the media file. Add a name or number and it will be shown on this status in this app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_saving,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Name or phone number',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onSubmitted: _save,
                ),
                const SizedBox(height: AppSpacing.space16),
                FilledButton(
                  onPressed: _saving ? null : () => _save(_controller.text),
                  child: Text(_saving ? 'Saving…' : 'Show on status'),
                ),
                if (widget.initialLabel.isNotEmpty)
                  TextButton(
                    onPressed: _saving ? null : () => _save(''),
                    child: const Text('Remove from this status'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
