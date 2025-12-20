import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

/// A reusable close button for bottom sheets and dialogs.
///
/// Displays a circular button with an X icon that calls [onTap] when pressed.
/// If [onTap] is not provided, defaults to `Navigator.of(context).pop()`.
class CloseIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const CloseIconButton({
    super.key,
    this.onTap,
    this.size = 20,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? colorScheme.fillFaint,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.close,
          size: size,
          color: iconColor ?? colorScheme.textBase,
        ),
      ),
    );
  }
}
