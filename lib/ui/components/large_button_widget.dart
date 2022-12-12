import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/models/large_button_style.dart';
import 'package:photos/utils/debouncer.dart';

enum ExecutionState {
  idle,
  inProgress,
  successful,
}

typedef FutureVoidCallback = Future<void> Function();

class LargeButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String? labelText;
  final ButtonType buttonType;
  final FutureVoidCallback? onTap;
  final bool isDisabled;

  ///setting this flag to true will make the button appear like how it would
  ///on dark theme irrespective of the app's theme.
  final bool isInActionSheet;
  const LargeButtonWidget({
    required this.buttonType,
    this.icon,
    this.labelText,
    this.onTap,
    this.isInActionSheet = false,
    this.isDisabled = false,
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
      isDisabled: isDisabled,
      onTap: onTap,
      labelText: labelText,
      icon: icon,
    );
  }
}

class LargeButtonChildWidget extends StatefulWidget {
  final LargeButtonStyle buttonStyle;
  final FutureVoidCallback? onTap;
  final ButtonType buttonType;
  final String? labelText;
  final IconData? icon;
  final bool isDisabled;
  const LargeButtonChildWidget({
    required this.buttonStyle,
    required this.buttonType,
    required this.isDisabled,
    this.onTap,
    this.labelText,
    this.icon,
    super.key,
  });

  @override
  State<LargeButtonChildWidget> createState() => _LargeButtonChildWidgetState();
}

class _LargeButtonChildWidgetState extends State<LargeButtonChildWidget> {
  late Color buttonColor;
  late Color borderColor;
  late Color iconColor;
  late TextStyle labelStyle;
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  ExecutionState executionState = ExecutionState.idle;
  @override
  void initState() {
    if (widget.isDisabled) {
      buttonColor = widget.buttonStyle.disabledButtonColor ??
          widget.buttonStyle.defaultButtonColor;
      borderColor = widget.buttonStyle.disabledBorderColor ??
          widget.buttonStyle.defaultBorderColor;
      iconColor = widget.buttonStyle.disabledIconColor ??
          widget.buttonStyle.defaultIconColor;
      labelStyle = widget.buttonStyle.disabledLabelStyle ??
          widget.buttonStyle.defaultLabelStyle;
    } else {
      buttonColor = widget.buttonStyle.defaultButtonColor;
      borderColor = widget.buttonStyle.defaultBorderColor;
      iconColor = widget.buttonStyle.defaultIconColor;
      labelStyle = widget.buttonStyle.defaultLabelStyle;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _shouldRegisterGestures ? _onTap : null,
      onTapDown: _shouldRegisterGestures ? _onTapDown : null,
      onTapUp: _shouldRegisterGestures ? _onTapUp : null,
      onTapCancel: _shouldRegisterGestures ? _onTapCancel : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: buttonColor,
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: executionState == ExecutionState.idle
              ? widget.buttonType.hasTrailingIcon
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.labelText == null
                            ? const SizedBox.shrink()
                            : Flexible(
                                child: Padding(
                                  padding: widget.icon == null
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        )
                                      : const EdgeInsets.only(right: 16),
                                  child: Text(
                                    widget.labelText!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: labelStyle,
                                  ),
                                ),
                              ),
                        widget.icon == null
                            ? const SizedBox.shrink()
                            : Icon(
                                widget.icon,
                                size: 20,
                                color: iconColor,
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
                                color: iconColor,
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
                                    style: labelStyle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                      ],
                    )
              : executionState == ExecutionState.inProgress
                  ? const EnteLoadingWidget(is20pts: true)
                  : executionState == ExecutionState.successful
                      ? const Icon(
                          Icons.check_outlined,
                          size: 20,
                        )
                      : const SizedBox.shrink(), //fallback
        ),
      ),
    );
  }

  bool get _shouldRegisterGestures =>
      !widget.isDisabled &&
      (widget.onTap != null) &&
      executionState == ExecutionState.idle;

  void _onTap() async {
    _debouncer.run(
      () => Future(() {
        setState(() {
          executionState = ExecutionState.inProgress;
        });
      }),
    );
    await widget.onTap!
        .call()
        .onError((error, stackTrace) => _debouncer.cancelDebounce());
    _debouncer.cancelDebounce();
    // when the time taken by widget.onTap is approx. equal to the debounce
    // time, the callback is getting executed when/after the if condition
    // below is executing/executed which result in execution state stuck at
    // idle state. This Future is for delaying the execution of the if
    // condition so that the calback in the debouncer finishes execution before.
    await Future.delayed(const Duration(milliseconds: 5));
    if (executionState == ExecutionState.inProgress) {
      setState(() {
        executionState = ExecutionState.successful;
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            executionState = ExecutionState.idle;
          });
        });
      });
    }
  }

  void _onTapDown(details) {
    setState(() {
      buttonColor = widget.buttonStyle.pressedButtonColor ??
          widget.buttonStyle.defaultButtonColor;
      borderColor = widget.buttonStyle.pressedBorderColor ??
          widget.buttonStyle.defaultBorderColor;
      iconColor = widget.buttonStyle.pressedIconColor ??
          widget.buttonStyle.defaultIconColor;
      labelStyle = widget.buttonStyle.pressedLabelStyle ??
          widget.buttonStyle.defaultLabelStyle;
    });
  }

  void _onTapUp(details) {
    Future.delayed(
      const Duration(milliseconds: 84),
      () => setState(() {
        setAllStylesToDefault();
      }),
    );
  }

  void _onTapCancel() {
    setState(() {
      setAllStylesToDefault();
    });
  }

  void setAllStylesToDefault() {
    buttonColor = widget.buttonStyle.defaultButtonColor;
    borderColor = widget.buttonStyle.defaultBorderColor;
    iconColor = widget.buttonStyle.defaultIconColor;
    labelStyle = widget.buttonStyle.defaultLabelStyle;
  }
}
