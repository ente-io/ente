import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/utils/magic_util.dart';

class FileCaptionWidget extends StatefulWidget {
  final File file;
  const FileCaptionWidget({required this.file, super.key});

  @override
  State<FileCaptionWidget> createState() => _FileCaptionWidgetState();
}

class _FileCaptionWidgetState extends State<FileCaptionWidget> {
  int maxLength = 280;
  int currentLength = 0;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String editedCaption = "";

  @override
  void initState() {
    _focusNode.addListener(() {
      _focusNode.hasFocus ? _textController.text = widget.file.caption : null;
    });
    super.initState();
  }

  @override
  void dispose() {
    editFileCaption(null, widget.file, editedCaption);
    _textController.dispose();
    _focusNode.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final caption = widget.file.caption;
    return TextField(
      onEditingComplete: () {
        editFileCaption(context, widget.file, editedCaption);
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
        hintText: caption.isEmpty ? "Add a caption" : caption,
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
          editedCaption = value;
        });
      },
    );
  }
}
