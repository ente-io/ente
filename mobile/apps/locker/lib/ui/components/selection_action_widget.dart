import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class SelectionActionWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const SelectionActionWidget({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final effectiveIconColor = iconColor ?? colorScheme.textBase;
    final effectiveTextColor = textColor ?? colorScheme.textBase;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
                color: effectiveIconColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.body.copyWith(
                  color: effectiveTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
