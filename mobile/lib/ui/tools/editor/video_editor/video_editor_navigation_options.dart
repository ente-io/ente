import "package:flutter/material.dart";

class VideoEditorNavigationOptions extends StatelessWidget {
  const VideoEditorNavigationOptions({
    super.key,
    this.primaryText,
    this.onPrimaryPressed,
    required this.secondaryText,
    required this.onSecondaryPressed,
  });

  final String? primaryText;
  final VoidCallback? onPrimaryPressed;
  final String secondaryText;
  final VoidCallback? onSecondaryPressed;

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
              child: Text(primaryText ?? "Cancel"),
            ),
            const Spacer(),
            TextButton(
              onPressed: onSecondaryPressed,
              child: Text(secondaryText),
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}
