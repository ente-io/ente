import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

Future<T?> showAlertBottomSheet<T>(
  BuildContext context, {
  required String title,
  required String message,
  required String assetPath,
  List<Widget>? buttons,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => AlertBottomSheet<T>(
      title: title,
      message: message,
      assetPath: assetPath,
      buttons: buttons,
    ),
  );
}

class AlertBottomSheet<T> extends StatelessWidget {
  final String title;
  final String message;
  final String assetPath;
  final List<Widget>? buttons;

  const AlertBottomSheet({
    required this.title,
    required this.message,
    required this.assetPath,
    this.buttons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
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
              _buildCloseButton(context, colorScheme),
              const SizedBox(height: 12),
              Center(child: Image.asset(assetPath)),
              const SizedBox(height: 20),
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
              if (buttons != null && buttons!.isNotEmpty) ...[
                const SizedBox(height: 20),
                for (int i = 0; i < buttons!.length; i++) ...[
                  buttons![i],
                  if (i < buttons!.length - 1) const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.fillFaint,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                size: 20,
                color: colorScheme.textBase,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
