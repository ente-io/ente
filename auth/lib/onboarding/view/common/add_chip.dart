import "package:ente_auth/theme/ente_theme.dart";
import "package:flutter/material.dart";

class AddChip extends StatelessWidget {
  final VoidCallback? onTap;

  const AddChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(
          Icons.add_circle_outline,
          size: 30,
          color: getEnteColorScheme(context).iconButtonColor,
        ),
      ),
    );
  }
}
