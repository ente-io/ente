import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/keyboard/keybiard_oveylay.dart';
import 'package:photos/ui/components/keyboard/keyboard_top_button.dart';
import 'package:photos/utils/magic_util.dart';

class FileCaptionWidget extends StatefulWidget {
  final File file;
  const FileCaptionWidget({required this.file, super.key});

  @override
  State<FileCaptionWidget> createState() => _FileCaptionWidgetState();
}

class _FileCaptionWidgetState extends State<FileCaptionWidget> {
  static const int maxLength = 5000;
  // counterThreshold represents the nun of char after which
  // currentLength/maxLength will show up
  static const int counterThreshold = 1000;
  int currentLength = 0;

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String? editedCaption;
  String hintText = fileCaptionDefaultHint;
  Widget? keyboardTopButtoms;

  @override
  void initState() {
    _focusNode.addListener(_focusNodeListener);
    editedCaption = widget.file.caption;
    if (editedCaption != null && editedCaption!.isNotEmpty) {
      hintText = editedCaption!;
    }
    super.initState();
  }

  @override
  void dispose() {
    if (editedCaption != null) {
      editFileCaption(null, widget.file, editedCaption);
    }
    _textController.dispose();
    _focusNode.removeListener(_focusNodeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return TextField(
      onSubmitted: (value) async {
        await _onDoneClick(context);
      },
      controller: _textController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        counterStyle: textTheme.mini.copyWith(color: colorScheme.textMuted),
        counterText: currentLength >= counterThreshold
            ? currentLength.toString() + " / " + maxLength.toString()
            : "",
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        filled: true,
        fillColor: colorScheme.fillFaint,
        hintText: hintText,
        hintStyle: hintText == fileCaptionDefaultHint
            ? textTheme.small.copyWith(color: colorScheme.textMuted)
            : textTheme.small,
      ),
      style: textTheme.small,
      cursorWidth: 1.5,
      maxLength: maxLength,
      minLines: 1,
      maxLines: 10,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      onChanged: (value) {
        setState(() {
          hintText = fileCaptionDefaultHint;
          currentLength = value.length;
          editedCaption = value;
        });
      },
    );
  }

  Future<void> _onDoneClick(BuildContext context) async {
    if (editedCaption != null) {
      final isSuccesful =
          await editFileCaption(context, widget.file, editedCaption);
      if (isSuccesful) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  void onCancelTap() {
    _textController.text = widget.file.caption ?? '';
    _focusNode.unfocus();
    editedCaption = null;
  }

  void onDoneTap() {
    _focusNode.unfocus();
    _onDoneClick(context);
  }

  void _focusNodeListener() {
    final caption = widget.file.caption;
    if (_focusNode.hasFocus && caption != null) {
      _textController.text = caption;
      editedCaption = caption;
    }
    final bool hasFocus = _focusNode.hasFocus;
    keyboardTopButtoms ??= KeyboardTopButton(
      onDoneTap: onDoneTap,
      onCancelTap: onCancelTap,
    );
    if (hasFocus) {
      KeyboardOverlay.showOverlay(context, keyboardTopButtoms!);
    } else {
      debugPrint("Removing listener");

      KeyboardOverlay.removeOverlay();
    }
  }
}
