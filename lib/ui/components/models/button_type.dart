import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/text_style.dart';

enum ButtonType {
  primary,
  secondary,
  neutral,
  trailingIcon,
  critical,
  tertiaryCritical,
  trailingIconPrimary,
  trailingIconSecondary;

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
    if (this == ButtonType.primary) {
      return colorScheme.primary700;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledButtonColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.primary || this == ButtonType.critical) {
      return colorScheme.fillFaint;
    }
    return null;
  }

  Color defaultBorderColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.tertiaryCritical) {
      return colorScheme.warning700;
    }
    return Colors.transparent;
  }

  //Returning null to fallback to default color
  Color? pressedBorderColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.primary) {
      return colorScheme.strokeMuted;
    }
    if (this == ButtonType.secondary || this == ButtonType.tertiaryCritical) {
      return colorScheme.strokeBase;
    }
    if (this == ButtonType.critical) {
      return strokeBaseLight;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledBorderColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.primary ||
        this == ButtonType.secondary ||
        this == ButtonType.critical) {
      return Colors.transparent;
    }
    if (this == ButtonType.tertiaryCritical) {
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
    if (isSecondary) {
      return colorScheme.strokeBase;
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
  Color? pressedIconColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.tertiaryCritical) {
      return colorScheme.strokeBase;
    }
    return null;
  }

  //Returning null to fallback to default color
  Color? disabledIconColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.primary || this == ButtonType.secondary) {
      return colorScheme.strokeMuted;
    }
    if (this == ButtonType.critical || this == ButtonType.tertiaryCritical) {
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
    if (isSecondary) {
      return textTheme.bodyBold;
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
  ) {
    if (this == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: colorScheme.strokeBase);
    }
    return null;
  }

  //Returning null to fallback to default color
  TextStyle? disabledLabelStyle(
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    if (this == ButtonType.primary ||
        this == ButtonType.secondary ||
        this == ButtonType.critical ||
        this == ButtonType.tertiaryCritical) {
      return textTheme.bodyBold.copyWith(color: colorScheme.textFaint);
    }
    return null;
  }

  Color? checkIconColor(EnteColorScheme colorScheme) {
    if (this == ButtonType.secondary) {
      return colorScheme.primary500;
    }
    return null;
  }

  bool get hasExecutionStates {
    if (this == ButtonType.primary ||
        this == ButtonType.secondary ||
        this == ButtonType.neutral) {
      return true;
    } else {
      return false;
    }
  }
}
