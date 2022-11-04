import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/utils/magic_util.dart';

class InfoItemTextWidget extends StatefulWidget {
  final String hintText;
  final File file;
  const InfoItemTextWidget({required this.file, this.hintText = '', super.key});

  @override
  State<InfoItemTextWidget> createState() => _InfoItemTextWidgetState();
}

class _InfoItemTextWidgetState extends State<InfoItemTextWidget> {
  int maxLength = 280;
  int currentLength = 0;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String caption = "";

  @override
  void dispose() {
    editCaption(fromDispose: true);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return TextField(
      onEditingComplete: () {
        editCaption();
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
          caption = value;
        });
      },
    );
  }

  void editCaption({bool fromDispose = false}) {
    if (caption.isNotEmpty) {
      editFileCaption(fromDispose ? null : context, widget.file, caption);
    }
  }
}
