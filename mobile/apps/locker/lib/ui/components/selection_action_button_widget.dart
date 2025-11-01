import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class SelectionActionButton extends StatelessWidget {
  final IconData? icon;
  final Widget? hugeIcon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const SelectionActionButton({
    super.key,
    this.icon,
    this.hugeIcon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  }) : assert(
          icon != null || hugeIcon != null,
          'Either icon or hugeIcon must be provided',
        );

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
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 12.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hugeIcon ??
                Icon(
                  icon!,
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
