import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class InfoItemWidget extends StatefulWidget {
  final String hintText;
  const InfoItemWidget({this.hintText = '', super.key});

  @override
  State<InfoItemWidget> createState() => _InfoItemWidgetState();
}

class _InfoItemWidgetState extends State<InfoItemWidget> {
  int maxLength = 280;
  int currentLength = 0;
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return TextField(
      decoration: InputDecoration(
        counterStyle: textTheme.mini.copyWith(color: colorScheme.textMuted),
        counterText: currentLength > 99
            ? currentLength.toString() + " / " + maxLength.toString()
            : "",
        contentPadding: const EdgeInsets.all(16),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: colorScheme.fillFaint,
        hintText: widget.hintText,
        hintStyle: getEnteTextTheme(context)
            .small
            .copyWith(color: colorScheme.textMuted),
      ),
      style: getEnteTextTheme(context).small,
      cursorWidth: 1.5,
      maxLength: maxLength,
      maxLines: null,
      onChanged: (value) {
        setState(() {
          currentLength = value.length;
        });
      },
    );
  }
}
