import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showInfoSnackBar(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: getEnteColorScheme(context).primary500,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: getEnteColorScheme(context).warning500,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            backgroundColor ?? getEnteColorScheme(context).primary500,
      ),
    );
  }
}
