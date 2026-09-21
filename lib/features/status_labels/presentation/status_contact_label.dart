import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../application/status_label_controller.dart';

class StatusContactLabel extends ConsumerWidget {
  final String statusId;

  const StatusContactLabel({super.key, required this.statusId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(statusLabelProvider(statusId));
    final label = labelState.asData?.value;
    final text = labelState.isLoading
        ? 'Loading label…'
        : labelState.hasError
        ? 'Retry label'
        : label ?? 'Add name / number';

    return Tooltip(
      message: label == null ? text : 'Edit name or number: $label',
      child: Semantics(
        button: true,
        label: label == null ? text : 'Name or number you added: $label. Edit',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.space8),
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
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
                Text(
                  'Name or number',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Sender details are not available with this status. Add a label to help you recognize it. This label is only used in this app.',
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
                  child: Text(_saving ? 'Saving…' : 'Save label'),
                ),
                if (widget.initialLabel.isNotEmpty)
                  TextButton(
                    onPressed: _saving ? null : () => _save(''),
                    child: const Text('Remove label'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
