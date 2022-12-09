import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/components/models/button_type.dart';

class LargeButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String? labelText;
  final ButtonType buttonType;
  final VoidCallback? onTap;

  ///setting this flag to true will make the button appear like how it would
  ///on dark theme irrespective of the app's theme.
  final bool isInActionSheet;
  const LargeButtonWidget({
    required this.buttonType,
    this.icon,
    this.labelText,
    this.onTap,
    this.isInActionSheet = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        isInActionSheet ? darkScheme : getEnteColorScheme(context);
    final inverseColorScheme = isInActionSheet
        ? lightScheme
        : getEnteColorScheme(context, inverse: true);
    final textTheme =
        isInActionSheet ? darkTextTheme : getEnteTextTheme(context);
    final inverseTextTheme = isInActionSheet
        ? lightTextTheme
        : getEnteTextTheme(context, inverse: true);
    final defaultButtonColor = buttonType.defaultButtonColor(colorScheme);
    final pressedButtonColor = buttonType.pressedButtonColor(colorScheme);
    final disabledButtonColor = buttonType.disabledButtonColor(colorScheme);
    final defaultBorderColor = buttonType.defaultBorderColor(colorScheme);
    final pressedBorderColor = buttonType.pressedBorderColor(colorScheme);
    final disabledBorderColor = buttonType.disabledBorderColor(colorScheme);
    final defaultIconColor = buttonType.defaultIconColor(
      colorScheme: colorScheme,
      inverseColorScheme: inverseColorScheme,
    );
    final pressedIconColor = buttonType.pressedIconColor(colorScheme);
    final disabledIconColor = buttonType.disabledIconColor(colorScheme);
    final defaultLabelStyle = buttonType.defaultLabelStyle(
      textTheme: textTheme,
      inverseTextTheme: inverseTextTheme,
    );
    final pressedLabelStyle =
        buttonType.pressedLabelStyle(textTheme, colorScheme);
    final disabledLabelStyle =
        buttonType.disabledLabelStyle(textTheme, colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: defaultButtonColor,
          border: Border.all(color: defaultBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          //todo: show loading or row depending on state of button
          child: buttonType.hasTrailingIcon
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    labelText == null
                        ? const SizedBox.shrink()
                        : Flexible(
                            child: Padding(
                              padding: icon == null
                                  ? const EdgeInsets.symmetric(horizontal: 8)
                                  : const EdgeInsets.only(right: 16),
                              child: Text(
                                labelText!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: defaultLabelStyle,
                              ),
                            ),
                          ),
                    icon == null
                        ? const SizedBox.shrink()
                        : Icon(
                            icon,
                            size: 20,
                            color: defaultIconColor,
                          ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon == null
                        ? const SizedBox.shrink()
                        : Icon(
                            icon,
                            size: 20,
                            color: defaultIconColor,
                          ),
                    icon == null || labelText == null
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 8),
                    labelText == null
                        ? const SizedBox.shrink()
                        : Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                labelText!,
                                style: defaultLabelStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                  ],
                ),
        ),
      ),
    );
  }
}
