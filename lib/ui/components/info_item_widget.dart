import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class InfoItemWidget extends StatelessWidget {
  final String hintText;
  const InfoItemWidget({this.hintText = '', super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return TextField(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(16),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: colorScheme.fillFaint,
        hintText: hintText,
        hintStyle: getEnteTextTheme(context)
            .small
            .copyWith(color: colorScheme.textMuted),
      ),
      style: getEnteTextTheme(context).small,
      cursorWidth: 1.5,
      maxLength: 280,
      maxLines: null,
    );
  }
}
