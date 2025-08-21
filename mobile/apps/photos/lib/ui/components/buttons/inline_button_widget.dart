import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import "package:photos/theme/ente_theme.dart";

class InlineButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final TextStyle? textStyle;
  const InlineButtonWidget(this.label, this.onTap, {this.textStyle, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap?.call,
      child: Text(
        label,
        style: textStyle ?? EnteTheme.getTextTheme(theme).smallMuted,
      ),
    );
  }
}
