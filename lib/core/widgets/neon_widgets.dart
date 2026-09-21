import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool compact;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.compact = false,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled && Theme.of(context).brightness == Brightness.dark
                ? NeonVaultColors.accentGradient
                : null,
            color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                enabled && Theme.of(context).brightness == Brightness.dark
                ? NeonVaultColors.neonGlow
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 18,
              vertical: widget.compact ? 10 : 13,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                    ),
                  )
                else if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class KeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadiusGeometry borderRadius;

  const KeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainer,
        borderRadius: borderRadius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class KeBadge extends StatelessWidget {
  final String label;
  final bool showDot;
  final Color? color;
  final Widget? leading;
  final bool uppercase;

  const KeBadge({
    super.key,
    required this.label,
    this.showDot = false,
    this.color,
    this.leading,
    this.uppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class KeFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  const KeFilterChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const KeToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: scheme.onPrimary,
      activeTrackColor: scheme.primary,
      inactiveThumbColor: scheme.onSurfaceVariant,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

class KeSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const KeSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class KeProgressBar extends StatelessWidget {
  final double value;

  const KeProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: scheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(scheme.primary),
        ),
      ),
    );
  }
}
