import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class SoftIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final GestureTapDownCallback? onTapDown;

  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapDown,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }
}
