import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";

class CollectionChip extends StatelessWidget {
  const CollectionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.backgroundColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? colorScheme.fillFaint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.small.copyWith(
                color: isSelected ? Colors.white : colorScheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
