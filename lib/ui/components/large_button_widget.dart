import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/models/large_button_style.dart';

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
    final buttonStyle = LargeButtonStyle(
      //Dummy default values since we need to keep these properties non-nullable
      defaultButtonColor: Colors.transparent,
      defaultBorderColor: Colors.transparent,
      defaultIconColor: Colors.transparent,
      defaultLabelStyle: textTheme.body,
    );
    buttonStyle.defaultButtonColor = buttonType.defaultButtonColor(colorScheme);
    buttonStyle.pressedButtonColor = buttonType.pressedButtonColor(colorScheme);
    buttonStyle.disabledButtonColor =
        buttonType.disabledButtonColor(colorScheme);
    buttonStyle.defaultBorderColor = buttonType.defaultBorderColor(colorScheme);
    buttonStyle.pressedBorderColor = buttonType.pressedBorderColor(colorScheme);
    buttonStyle.disabledBorderColor =
        buttonType.disabledBorderColor(colorScheme);
    buttonStyle.defaultIconColor = buttonType.defaultIconColor(
      colorScheme: colorScheme,
      inverseColorScheme: inverseColorScheme,
    );
    buttonStyle.pressedIconColor = buttonType.pressedIconColor(colorScheme);
    buttonStyle.disabledIconColor = buttonType.disabledIconColor(colorScheme);
    buttonStyle.defaultLabelStyle = buttonType.defaultLabelStyle(
      textTheme: textTheme,
      inverseTextTheme: inverseTextTheme,
    );
    buttonStyle.pressedLabelStyle =
        buttonType.pressedLabelStyle(textTheme, colorScheme);
    buttonStyle.disabledLabelStyle =
        buttonType.disabledLabelStyle(textTheme, colorScheme);

    return LargeButtonChildWidget(
      buttonStyle: buttonStyle,
      buttonType: buttonType,
      onTap: onTap,
      labelText: labelText,
      icon: icon,
    );
  }
}

class LargeButtonChildWidget extends StatefulWidget {
  final LargeButtonStyle buttonStyle;
  final VoidCallback? onTap;
  final ButtonType buttonType;
  final String? labelText;
  final IconData? icon;
  const LargeButtonChildWidget({
    required this.buttonStyle,
    required this.buttonType,
    this.onTap,
    this.labelText,
    this.icon,
    super.key,
  });

  @override
  State<LargeButtonChildWidget> createState() => _LargeButtonChildWidgetState();
}

class _LargeButtonChildWidgetState extends State<LargeButtonChildWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: widget.buttonStyle.defaultButtonColor,
          border: Border.all(color: widget.buttonStyle.defaultBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          //todo: show loading or row depending on state of button
          child: widget.buttonType.hasTrailingIcon
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.labelText == null
                        ? const SizedBox.shrink()
                        : Flexible(
                            child: Padding(
                              padding: widget.icon == null
                                  ? const EdgeInsets.symmetric(horizontal: 8)
                                  : const EdgeInsets.only(right: 16),
                              child: Text(
                                widget.labelText!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: widget.buttonStyle.defaultLabelStyle,
                              ),
                            ),
                          ),
                    widget.icon == null
                        ? const SizedBox.shrink()
                        : Icon(
                            widget.icon,
                            size: 20,
                            color: widget.buttonStyle.defaultIconColor,
                          ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.icon == null
                        ? const SizedBox.shrink()
                        : Icon(
                            widget.icon,
                            size: 20,
                            color: widget.buttonStyle.defaultIconColor,
                          ),
                    widget.icon == null || widget.labelText == null
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 8),
                    widget.labelText == null
                        ? const SizedBox.shrink()
                        : Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                widget.labelText!,
                                style: widget.buttonStyle.defaultLabelStyle,
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
