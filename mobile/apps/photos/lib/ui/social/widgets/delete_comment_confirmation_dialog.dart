import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/gradient_button.dart";

/// Shows a bottom sheet confirmation dialog for deleting a comment.
/// Returns true if confirmed, null if cancelled.
Future<bool?> showDeleteCommentConfirmationDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => const _DeleteCommentConfirmationSheet(),
  );
}

class _DeleteCommentConfirmationSheet extends StatelessWidget {
  const _DeleteCommentConfirmationSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        border: Border(top: BorderSide(color: colorScheme.strokeFaint)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: colorScheme.backgroundElevated,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: colorScheme.textBase,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Delete comment?",
                style: textTheme.h3Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "This comment will be permanently deleted.",
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: () => Navigator.of(context).pop(true),
                  text: "Delete",
                  linearGradientColors: [
                    colorScheme.warning400,
                    colorScheme.warning400,
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
