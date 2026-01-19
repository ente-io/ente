import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

Future<T?> showBaseBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  bool showCloseButton = true,
  VoidCallback? onClose,
  double headerSpacing = 20,
  Color? backgroundColor,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  EdgeInsets padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
  bool isDismissible = true,
  bool enableDrag = true,
  bool isKeyboardAware = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (context) => BaseBottomSheet(
      title: title,
      showCloseButton: showCloseButton,
      onClose: onClose,
      headerSpacing: headerSpacing,
      backgroundColor: backgroundColor,
      crossAxisAlignment: crossAxisAlignment,
      padding: padding,
      isKeyboardAware: isKeyboardAware,
      child: child,
    ),
  );
}

class BaseBottomSheet extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final double headerSpacing;
  final bool isKeyboardAware;

  const BaseBottomSheet({
    required this.child,
    required this.title,
    this.showCloseButton = true,
    this.onClose,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
    this.backgroundColor,
    this.headerSpacing = 20,
    this.isKeyboardAware = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bottomInset =
        isKeyboardAware ? MediaQuery.of(context).viewInsets.bottom : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAxisAlignment,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: textTheme.largeBold),
                    if (showCloseButton)
                      GestureDetector(
                        onTap: onClose ?? () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.fillFaint,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: colorScheme.textBase,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: headerSpacing),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
