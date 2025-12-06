import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

Future<void> showErrorBottomSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String assetPath,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ErrorBottomSheet(
      title: title,
      message: message,
      assetPath: assetPath,
    ),
  );
}

class ErrorBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String assetPath;

  const ErrorBottomSheet({
    required this.title,
    required this.message,
    required this.assetPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
              ),
              const SizedBox(height: 8),
              Center(child: Image.asset(assetPath)),
              const SizedBox(height: 24),
              Text(
                title,
                style: textTheme.h3Bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
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
