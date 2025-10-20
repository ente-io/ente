import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class SelectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  final bool isTopLeftRounded;
  final bool isTopRightRounded;
  final bool isBottomLeftRounded;
  final bool isBottomRightRounded;

  const SelectionActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isTopLeftRounded = true,
    this.isTopRightRounded = true,
    this.isBottomLeftRounded = true,
    this.isBottomRightRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final color = isDestructive ? colorScheme.warning500 : colorScheme.textBase;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTopLeftRounded ? 24.0 : 0.0),
            topRight: Radius.circular(isTopRightRounded ? 24.0 : 0.0),
            bottomLeft: Radius.circular(isBottomLeftRounded ? 24.0 : 0.0),
            bottomRight: Radius.circular(isBottomRightRounded ? 24.0 : 0.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 12.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.body.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
