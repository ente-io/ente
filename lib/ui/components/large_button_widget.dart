import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';

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
  final IconData icon;
  final String labelText;
  final ButtonType buttonType;
  const LargeButtonWidget({
    required this.icon,
    required this.labelText,
    required this.buttonType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final inverseColorScheme = getEnteColorScheme(context, inverse: true);
    final textTheme = getEnteTextTheme(context);
    final inverseTextTheme = getEnteTextTheme(context, inverse: true);
    final defaultButtonColor = _defaultButtonColor(colorScheme);
    final pressedButtonColor = _pressedButtonColor(colorScheme);
    final disabledButtonColor = _disabledButtonColor(colorScheme);
    final defaultBorderColor = _defaultBorderColor(colorScheme);
    final pressedBorderColor = _pressedBorderColor(colorScheme);
    final disabledBorderColor = _disabledBorderColor(colorScheme);
    final defaultIconColor = _defaultIconColor(
        colorScheme: colorScheme, inverseColorScheme: inverseColorScheme);
    final pressedIconColor = _pressedIconColor(colorScheme);
    final disabledIconColor = _disabledIconColor(colorScheme);
    final defaultLabelStyle = _defaultLabelStyle(
      textTheme: textTheme,
      inverseTextTheme: inverseTextTheme,
    );
    final pressedLabelStyle = _pressedLabelStyle(textTheme, colorScheme);
    final disabledLabelStyle = _disabledLabelStyle(textTheme, colorScheme);

    return GestureDetector(
      onTap: () {},
      child: Container(
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
                        labelText,
                        style: defaultLabelStyle,
                      ),
                    ),
                    Icon(
                      icon,
                      size: 20,
                      color: defaultIconColor,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: defaultIconColor,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        labelText,
                        style: defaultLabelStyle,
                      ),
                    )
                  ],
                ),
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

  //Returning null to fallback to default color
  Color? _pressedButtonColor(EnteColorScheme colorScheme) {
    if (_isPrimary()) {
      return colorScheme.primary700;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? _disabledButtonColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.primary || buttonType == ButtonType.critical) {
      return colorScheme.fillFaint;
    }
    return null;
  }

  Color _defaultBorderColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.warning700;
    }
    return Colors.transparent;
  }

  //Returning null to fallback to default color
  Color? _pressedBorderColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.primary) {
      return colorScheme.strokeMuted;
    }
    if (buttonType == ButtonType.secondary ||
        buttonType == ButtonType.critical ||
        buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.strokeBase;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? _disabledBorderColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.primary ||
        buttonType == ButtonType.secondary ||
        buttonType == ButtonType.critical) {
      return Colors.transparent;
    }
    if (buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.strokeMuted;
    }
    return null;
  }

  Color _defaultIconColor({
    required EnteColorScheme colorScheme,
    required EnteColorScheme inverseColorScheme,
  }) {
    if (_isPrimary() || buttonType == ButtonType.critical) {
      return strokeBaseDark;
    }
    if (_isSecondary()) {
      return colorScheme.strokeBase;
    }
    if (buttonType == ButtonType.neutral ||
        buttonType == ButtonType.trailingIcon) {
      return inverseColorScheme.strokeBase;
    }
    if (buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.warning500;
    }
    //fallback
    return colorScheme.strokeBase;
  }

  //Returning null to fallback to default color
  Color? _pressedIconColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.strokeBase;
    }
    return null;
  }

  Color? _disabledIconColor(EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.primary ||
        buttonType == ButtonType.secondary) {
      return colorScheme.strokeMuted;
    }
    if (buttonType == ButtonType.critical ||
        buttonType == ButtonType.tertiaryCritical) {
      return colorScheme.strokeFaint;
    }
    return null;
  }

  TextStyle _defaultLabelStyle({
    required EnteTextTheme textTheme,
    required EnteTextTheme inverseTextTheme,
  }) {
    if (_isPrimary() || buttonType == ButtonType.critical) {
      return textTheme.bodyBold.copyWith(color: textBaseDark);
    }
    if (_isSecondary()) {
      return textTheme.bodyBold;
    }
    if (buttonType == ButtonType.neutral ||
        buttonType == ButtonType.trailingIcon) {
      return inverseTextTheme.bodyBold;
    }
    if (buttonType == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: warning500);
    }
    //fallback
    return textTheme.bodyBold;
  }

  //Returning null to fallback to default color
  TextStyle? _pressedLabelStyle(
      EnteTextTheme textTheme, EnteColorScheme colorScheme) {
    if (buttonType == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: colorScheme.strokeBase);
    }
    return null;
  }

  TextStyle? _disabledLabelStyle(
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    if (buttonType == ButtonType.primary ||
        buttonType == ButtonType.secondary ||
        buttonType == ButtonType.critical ||
        buttonType == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: colorScheme.textFaint);
    }
    return null;
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
