import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";

class VideoEditorNavigationOptions extends StatelessWidget {
  const VideoEditorNavigationOptions({
    super.key,
    this.primaryText,
    this.onPrimaryPressed,
    this.color,
    required this.secondaryText,
    required this.onSecondaryPressed,
  });

  final String? primaryText;
  final VoidCallback? onPrimaryPressed;
  final String secondaryText;
  final VoidCallback? onSecondaryPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "video-editor-navigation-options",
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const SizedBox(width: 28),
            TextButton(
              onPressed: onPrimaryPressed?.call ?? Navigator.of(context).pop,
              child: Text(primaryText ?? S.of(context).cancel),
            ),
            const Spacer(),
            TextButton(
              onPressed: onSecondaryPressed,
              style: TextButton.styleFrom(
                foregroundColor: color,
              ),
              child: Text(
                secondaryText,
                style: TextStyle(color: color),
              ),
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}
