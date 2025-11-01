import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showInfoSnackBar(BuildContext context, String message) {
    final colorScheme = getEnteColorScheme(context);
    _showSnackBar(
      context,
      message,
      backgroundColor: colorScheme.primary500,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    final colorScheme = getEnteColorScheme(context);
    _showSnackBar(
      context,
      message,
      backgroundColor: colorScheme.warning500,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;

    final colorScheme = getEnteColorScheme(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? colorScheme.primary500,
      ),
    );
  }
}
