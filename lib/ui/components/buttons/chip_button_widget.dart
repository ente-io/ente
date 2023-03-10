import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class ChipButtonWidget extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  const ChipButtonWidget(
    this.label, {
    this.leadingIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leadingIcon != null
              ? Icon(
                  leadingIcon,
                  size: 17,
                )
              : const SizedBox.shrink(),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: getEnteTextTheme(context).smallBold,
            ),
          )
        ],
      ),
    );
  }
}
