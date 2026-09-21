import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class KeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int keptCount;

  const KeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.keptCount = 0,
  });

  static const _items = [
    (Icons.layers_rounded, 'Status'),
    (Icons.bookmark_outline_rounded, 'Saved'),
    (Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color:
              Theme.of(context).navigationBarTheme.backgroundColor ??
              scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(child: _item(context, index)),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedIndex == index;
    final item = _items[index];
    return Semantics(
      button: true,
      selected: selected,
      label: item.$2,
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? scheme.surfaceContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected && scheme.brightness == Brightness.dark
                ? NeonVaultColors.softGlow
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.$1,
                    size: 22,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (index == 1 && keptCount > 0)
                Positioned(
                  top: 1,
                  right: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$keptCount',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
