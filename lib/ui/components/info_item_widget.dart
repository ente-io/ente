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
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    // save caption here
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return TextField(
      onEditingComplete: () {
        //save caption here
        _focusNode.unfocus();
      },
      controller: _textController,
      focusNode: _focusNode,
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
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.text,
      onChanged: (value) {
        setState(() {
          currentLength = value.length;
        });
      },
    );
  }
}
