import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';

enum ButtonType {
  primary,
  secondary,
  neutral,
  trailingIcon,
  critical,
  tertiaryCritical,
  trailingIconPrimary,
  trailingIconSecondary,
}

class LargeButtonWidget extends StatelessWidget {
  final ButtonType buttonType;
  const LargeButtonWidget({required this.buttonType, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final defaultButtonColor = _defaultButtonColor(colorScheme);
    final defaultBorderColor = _defaultBorderColor(colorScheme);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: defaultButtonColor,
        border: Border.all(color: defaultBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        //show loading or row depending on state of button
        child: _hasTrailingIcon()
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      "Button",
                      style: textTheme.bodyBold,
                    ),
                  ),
                  const Icon(
                    Icons.add_outlined,
                    size: 20,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Button",
                      style: textTheme.bodyBold,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Color _defaultButtonColor(EnteColorScheme colorScheme) {
    if (_isPrimary()) {
      return colorScheme.primary500;
    }
    if (_isSecondary()) {
      return colorScheme.fillFaint;
    }
    if (buttonType == ButtonType.neutral ||
        buttonType == ButtonType.trailingIcon) {
      return colorScheme.fillBase;
    }
    if (buttonType == ButtonType.critical) {
      return colorScheme.warning700;
    }
    if (buttonType == ButtonType.tertiaryCritical) {
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  Color _defaultBorderColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.warning700;
    }
    return Colors.transparent;
  }

  bool _hasTrailingIcon() {
    return (buttonType == ButtonType.trailingIcon ||
        buttonType == ButtonType.trailingIconPrimary ||
        buttonType == ButtonType.trailingIconSecondary);
  }

  bool _isPrimary() {
    return (buttonType == ButtonType.primary ||
        buttonType == ButtonType.trailingIconPrimary);
  }

  bool _isSecondary() {
    return (buttonType == ButtonType.secondary ||
        buttonType == ButtonType.trailingIconSecondary);
  }

  bool _isCritical() {
    return (buttonType == ButtonType.critical ||
        buttonType == ButtonType.tertiaryCritical);
  }
}
