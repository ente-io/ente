import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

///https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?node-id=8119%3A59513&t=gQa1to5jY89Qk1k7-4
class ChipButtonWidget extends StatelessWidget {
  final String? label;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool noChips;
  const ChipButtonWidget(
    this.label, {
    this.leadingIcon,
    this.onTap,
    this.noChips = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap?.call,
      child: Container(
        width: noChips ? double.infinity : null,
        decoration: BoxDecoration(
          color: getEnteColorScheme(context).fillFaint,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leadingIcon != null
                  ? Icon(
                      leadingIcon,
                      size: 16,
                    )
                  : const SizedBox.shrink(),
              if (label != null && leadingIcon != null)
                const SizedBox(width: 4),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label!,
                    style: getEnteTextTheme(context).miniBold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
