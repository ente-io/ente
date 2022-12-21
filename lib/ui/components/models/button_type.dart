import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/components/button_widget.dart';

enum ButtonType {
  primary,
  secondary,
  neutral,
  trailingIcon,
  critical,
  tertiaryCritical,
  trailingIconPrimary,
  trailingIconSecondary,
  tertiary;

  bool get isPrimary =>
      this == ButtonType.primary || this == ButtonType.trailingIconPrimary;

  bool get hasTrailingIcon =>
      this == ButtonType.trailingIcon ||
      this == ButtonType.trailingIconPrimary ||
      this == ButtonType.trailingIconSecondary;

  bool get isSecondary =>
      this == ButtonType.secondary || this == ButtonType.trailingIconSecondary;

  bool get isCritical =>
      this == ButtonType.critical || this == ButtonType.tertiaryCritical;

  bool get isNeutral =>
      this == ButtonType.neutral || this == ButtonType.trailingIcon;

  Color defaultButtonColor(EnteColorScheme colorScheme) {
    if (isPrimary) {
      return colorScheme.primary500;
    }
    if (isSecondary) {
      return colorScheme.fillFaint;
    }
    if (this == ButtonType.neutral || this == ButtonType.trailingIcon) {
      return colorScheme.fillBase;
    }
    if (this == ButtonType.critical) {
      return colorScheme.warning700;
    }
    if (this == ButtonType.tertiaryCritical) {
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  //Returning null to fallback to default color
  Color? pressedButtonColor(EnteColorScheme colorScheme) {
    if (isPrimary) {
      return colorScheme.primary700;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledButtonColor(
    EnteColorScheme colorScheme,
    ButtonSize buttonSize,
  ) {
    if (buttonSize == ButtonSize.small &&
        (this == ButtonType.primary ||
            this == ButtonType.neutral ||
            this == ButtonType.critical)) {
      return colorScheme.fillMuted;
    }
    if (isPrimary || this == ButtonType.critical || isNeutral) {
      return colorScheme.fillFaint;
    }
    return null;
  }

  Color? defaultBorderColor(
    EnteColorScheme colorScheme,
    ButtonSize buttonSize,
  ) {
    if (this == ButtonType.tertiaryCritical && buttonSize == ButtonSize.large) {
      return colorScheme.warning700;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? pressedBorderColor({
    required EnteColorScheme colorScheme,
    required EnteColorScheme inverseColorScheme,
    required ButtonSize buttonSize,
  }) {
    if (isPrimary) {
      return colorScheme.strokeMuted;
    }
    if (buttonSize == ButtonSize.small && this == ButtonType.tertiaryCritical) {
      return null;
    }
    if (isSecondary || isCritical) {
      return colorScheme.strokeBase;
    }
    if (isNeutral) {
      return inverseColorScheme.strokeBase;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledBorderColor(
    EnteColorScheme colorScheme,
    ButtonSize buttonSize,
  ) {
    if (this == ButtonType.tertiaryCritical && buttonSize == ButtonSize.large) {
      return colorScheme.strokeMuted;
    }
    return null;
  }

  Color defaultIconColor({
    required EnteColorScheme colorScheme,
    required EnteColorScheme inverseColorScheme,
  }) {
    if (isPrimary || this == ButtonType.critical) {
      return strokeBaseDark;
    }
    if (this == ButtonType.neutral || this == ButtonType.trailingIcon) {
      return inverseColorScheme.strokeBase;
    }
    if (this == ButtonType.tertiaryCritical) {
      return colorScheme.warning500;
    }
    //fallback
    return colorScheme.strokeBase;
  }

  //Returning null to fallback to default color
  Color? pressedIconColor(EnteColorScheme colorScheme, ButtonSize buttonSize) {
    if (this == ButtonType.tertiaryCritical && buttonSize == ButtonSize.large) {
      return colorScheme.strokeBase;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledIconColor(EnteColorScheme colorScheme, ButtonSize buttonSize) {
    if (isPrimary ||
        isSecondary ||
        isNeutral ||
        buttonSize == ButtonSize.small) {
      return colorScheme.strokeMuted;
    }
    if (isCritical) {
      return colorScheme.strokeFaint;
    }
    return null;
  }

  TextStyle defaultLabelStyle({
    required EnteTextTheme textTheme,
    required EnteTextTheme inverseTextTheme,
  }) {
    if (isPrimary || this == ButtonType.critical) {
      return textTheme.bodyBold.copyWith(color: textBaseDark);
    }
    if (this == ButtonType.neutral || this == ButtonType.trailingIcon) {
      return inverseTextTheme.bodyBold;
    }
    if (this == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: warning500);
    }
    //fallback
    return textTheme.bodyBold;
  }

  //Returning null to fallback to default color
  TextStyle? pressedLabelStyle(
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
    ButtonSize buttonSize,
  ) {
    if (this == ButtonType.tertiaryCritical && buttonSize == ButtonSize.large) {
      return textTheme.bodyBold.copyWith(color: colorScheme.strokeBase);
    }
    return null;
  }

  //Returning null to fallback to default color
  TextStyle? disabledLabelStyle(
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    return textTheme.bodyBold.copyWith(color: colorScheme.textFaint);
  }

  //Returning null to fallback to default color
  Color? checkIconColor(EnteColorScheme colorScheme) {
    if (isSecondary) {
      return colorScheme.primary500;
    }
    return null;
  }
}
