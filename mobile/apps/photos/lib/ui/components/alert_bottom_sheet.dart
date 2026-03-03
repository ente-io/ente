import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/base_bottom_sheet.dart";

Future<T?> showAlertBottomSheet<T>(
  BuildContext context, {
  required String title,
  required String message,
  String? assetPath,
  List<Widget>? buttons,
  bool isDismissible = true,
  bool showCloseButton = true,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    builder: (context) => AlertBottomSheet<T>(
      title: title,
      message: message,
      assetPath: assetPath,
      buttons: buttons,
      showCloseButton: showCloseButton,
      onClose: onClose,
    ),
  );
}

class AlertBottomSheet<T> extends StatelessWidget {
  final String title;
  final String message;
  final String? assetPath;
  final List<Widget>? buttons;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AlertBottomSheet({
    required this.title,
    required this.message,
    this.assetPath,
    this.buttons,
    this.showCloseButton = true,
    this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
              if (showCloseButton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BottomSheetCloseButton(onTap: onClose),
                  ],
                ),
              SizedBox(height: showCloseButton ? 12 : 24),
              if (assetPath != null) ...[
                Center(child: Image.asset(assetPath!)),
                const SizedBox(height: 20),
              ],
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
              ..._buildButtonsSection(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtonsSection() {
    if (buttons == null || buttons!.isEmpty) return [];

    return [
      const SizedBox(height: 20),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: buttons!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => buttons![index],
      ),
    ];
  }
}
