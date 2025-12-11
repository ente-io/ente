import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/ui/components/gradient_button.dart";

Future<bool?> showAlertBottomSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String assetPath,
  required String confirmButtonText,
  required VoidCallback onConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AlertBottomSheet(
      title: title,
      message: message,
      assetPath: assetPath,
      confirmButtonText: confirmButtonText,
      onConfirm: onConfirm,
    ),
  );
}

class AlertBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String assetPath;
  final String confirmButtonText;
  final VoidCallback onConfirm;

  const AlertBottomSheet({
    required this.title,
    required this.message,
    required this.assetPath,
    required this.confirmButtonText,
    required this.onConfirm,
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
        top: false,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: confirmButtonText,
                  backgroundColor: colorScheme.warning400,
                  onTap: () {
                    onConfirm();
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
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
            onTap: () => Navigator.of(context).pop(false),
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
