import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';

enum ButtonSizeV2 {
  small,
  large;
}

enum ButtonTypeV2 {
  primary,
  secondary,
  neutral,
  critical,
  tertiaryCritical,
  link,
  trailingIcon,
  trailingIconPrimary,
  trailingIconSecondary,
  tertiary;

  bool get isPrimary =>
      this == ButtonTypeV2.primary || this == ButtonTypeV2.trailingIconPrimary;

  bool get hasTrailingIcon =>
      this == ButtonTypeV2.trailingIcon ||
      this == ButtonTypeV2.trailingIconPrimary ||
      this == ButtonTypeV2.trailingIconSecondary;

  bool get isSecondary =>
      this == ButtonTypeV2.secondary ||
      this == ButtonTypeV2.trailingIconSecondary;

  bool get isCritical =>
      this == ButtonTypeV2.critical || this == ButtonTypeV2.tertiaryCritical;

  bool get isNeutral =>
      this == ButtonTypeV2.neutral || this == ButtonTypeV2.trailingIcon;

  ButtonTheme getColorPalette(EnteColorScheme colorScheme) {
    switch (this) {
      case ButtonTypeV2.primary:
      case ButtonTypeV2.trailingIconPrimary:
        return _primaryPalette;
      case ButtonTypeV2.critical:
        return _criticalPalette;
      case ButtonTypeV2.secondary:
      case ButtonTypeV2.trailingIconSecondary:
        return _secondaryPalette(colorScheme);
      case ButtonTypeV2.neutral:
      case ButtonTypeV2.trailingIcon:
        return _neutralPalette(colorScheme);
      case ButtonTypeV2.tertiaryCritical:
        return _tertiaryCriticalPalette(colorScheme);
      case ButtonTypeV2.link:
        return _linkPalette(colorScheme);
      case ButtonTypeV2.tertiary:
        return _tertiaryPalette(colorScheme);
    }
  }
}

const _primaryPalette = ButtonTheme(
  defaultBg: green,
  hoverBg: greenDark,
  pressedBg: greenDarker,
  disabledBg: buttonDisabledBg,
  foreground: buttonTextOnColor,
  disabledForeground: buttonDisabledText,
);

const _criticalPalette = ButtonTheme(
  defaultBg: red,
  hoverBg: redDark,
  pressedBg: redDarker,
  disabledBg: buttonDisabledBg,
  foreground: buttonTextOnColor,
  disabledForeground: buttonDisabledText,
);

ButtonTheme _secondaryPalette(EnteColorScheme c) => ButtonTheme(
      defaultBg: c.fillFaint,
      hoverBg: c.fillFaintPressed,
      pressedBg: c.fillMuted,
      disabledBg: c.fillFaint,
      foreground: c.textBase,
      disabledForeground: c.textFaint,
      defaultBorder: c.strokeFaint,
      disabledBorder: c.strokeFaint,
      iconColor: c.strokeBase,
      disabledIconColor: c.strokeMuted,
    );

ButtonTheme _neutralPalette(EnteColorScheme c) {
  final inverseForeground =
      c.fillBase == fillBaseLight ? textBaseDark : textBaseLight;
  return ButtonTheme(
    defaultBg: c.fillBase,
    hoverBg: c.fillStrong,
    pressedBg: c.fillBasePressed,
    disabledBg: c.fillFaint,
    foreground: inverseForeground,
    disabledForeground: c.textFaint,
    disabledIconColor: c.strokeMuted,
    checkmarkColor: c.primary500,
  );
}

ButtonTheme _tertiaryCriticalPalette(EnteColorScheme c) => ButtonTheme(
      defaultBg: Colors.transparent,
      hoverBg: c.warning500.withValues(alpha: 0.08),
      pressedBg: c.warning700.withValues(alpha: 0.1),
      disabledBg: Colors.transparent,
      foreground: c.warning500,
      disabledForeground: c.textFaint,
      defaultBorder: c.warning500,
      disabledBorder: c.strokeMuted,
      disabledIconColor: c.strokeMuted,
    );

ButtonTheme _linkPalette(EnteColorScheme c) => ButtonTheme(
      defaultBg: Colors.transparent,
      hoverBg: Colors.transparent,
      pressedBg: Colors.transparent,
      disabledBg: Colors.transparent,
      foreground: c.primary500,
      hoverForeground: c.primary400,
      pressedForeground: c.primary700,
      disabledForeground: c.textFaint,
      disabledIconColor: c.strokeMuted,
    );

ButtonTheme _tertiaryPalette(EnteColorScheme c) => ButtonTheme(
      defaultBg: Colors.transparent,
      hoverBg: c.fillFaint,
      pressedBg: c.fillFaintPressed,
      disabledBg: Colors.transparent,
      foreground: c.textBase,
      pressedForeground: c.fillBasePressed,
      disabledForeground: c.textFaint,
      disabledIconColor: c.strokeMuted,
    );

class ButtonTheme {
  final Color defaultBg;
  final Color hoverBg;
  final Color pressedBg;
  final Color disabledBg;
  final Color foreground;
  final Color? hoverForeground;
  final Color? pressedForeground;
  final Color disabledForeground;
  final Color? iconColor;
  final Color? disabledIconColor;
  final Color? checkmarkColor;
  final Color? defaultBorder;
  final Color? disabledBorder;

  const ButtonTheme({
    required this.defaultBg,
    required this.hoverBg,
    required this.pressedBg,
    required this.disabledBg,
    required this.foreground,
    this.hoverForeground,
    this.pressedForeground,
    required this.disabledForeground,
    this.iconColor,
    this.disabledIconColor,
    this.checkmarkColor,
    this.defaultBorder,
    this.disabledBorder,
  });

  ButtonColors resolve({
    required bool isDisabled,
    required bool isPressed,
    required bool isHovered,
    required bool isLoading,
    required bool isSuccess,
    Color? iconColorOverride,
  }) {
    if (isDisabled) {
      return ButtonColors(
        backgroundColor: disabledBg,
        borderColor: disabledBorder,
        textColor: disabledForeground,
        iconColor: iconColorOverride ?? disabledIconColor ?? disabledForeground,
        spinnerColor: disabledIconColor ?? disabledForeground,
        checkmarkColor: disabledIconColor ?? disabledForeground,
      );
    }

    if (isLoading) {
      return ButtonColors(
        backgroundColor: pressedBg,
        borderColor: defaultBorder,
        textColor: pressedForeground ?? foreground,
        iconColor:
            iconColorOverride ?? iconColor ?? pressedForeground ?? foreground,
        spinnerColor: iconColor ?? pressedForeground ?? foreground,
        checkmarkColor: checkmarkColor ?? iconColor ?? foreground,
      );
    }

    if (isSuccess) {
      return ButtonColors(
        backgroundColor: defaultBg,
        borderColor: defaultBorder,
        textColor: foreground,
        iconColor: iconColorOverride ?? iconColor ?? foreground,
        spinnerColor: iconColor ?? foreground,
        checkmarkColor: checkmarkColor ?? iconColor ?? foreground,
      );
    }

    final Color bg;
    final Color fg;
    if (isPressed) {
      bg = pressedBg;
      fg = pressedForeground ?? foreground;
    } else if (isHovered) {
      bg = hoverBg;
      fg = hoverForeground ?? foreground;
    } else {
      bg = defaultBg;
      fg = foreground;
    }

    return ButtonColors(
      backgroundColor: bg,
      borderColor: defaultBorder,
      textColor: fg,
      iconColor: iconColorOverride ?? iconColor ?? fg,
      spinnerColor: iconColor ?? fg,
      checkmarkColor: checkmarkColor ?? iconColor ?? fg,
    );
  }
}

class ButtonColors {
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final Color iconColor;
  final Color spinnerColor;
  final Color checkmarkColor;

  const ButtonColors({
    required this.backgroundColor,
    this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.spinnerColor,
    required this.checkmarkColor,
  });
}
