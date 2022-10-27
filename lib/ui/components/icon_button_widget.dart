import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class IconButtonWidget extends StatelessWidget {
  final bool isPrimary;
  final bool isSecondary;
  final bool isRounded;
  final IconData icon;
  const IconButtonWidget({
    this.isPrimary = true,
    this.isSecondary = false,
    this.isRounded = false,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.close_outlined,
          color: isSecondary ? colorTheme.strokeMuted : colorTheme.strokeBase,
        ),
      ),
    );
  }
}
