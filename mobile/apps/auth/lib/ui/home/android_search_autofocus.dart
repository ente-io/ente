import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AndroidSearchAutofocus extends StatefulWidget {
  const AndroidSearchAutofocus({
    super.key,
    required this.enabled,
    required this.focusNode,
    required this.child,
  });

  final bool enabled;
  final FocusNode focusNode;
  final Widget child;

  @override
  State<AndroidSearchAutofocus> createState() => _AndroidSearchAutofocusState();
}

class _AndroidSearchAutofocusState extends State<AndroidSearchAutofocus> {
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _scheduleFocus();
  }

  @override
  void didUpdateWidget(AndroidSearchAutofocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _scheduleFocus();
    }
  }

  @override
  void dispose() {
    _token++;
    super.dispose();
  }

  void _scheduleFocus() {
    if (!Platform.isAndroid || !widget.enabled) {
      return;
    }
    unawaited(_focusAndShowKeyboard(++_token));
  }

  Future<void> _focusAndShowKeyboard(int token) async {
    bool isValid() => mounted && token == _token && widget.enabled;

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!isValid()) return;

    widget.focusNode.requestFocus();

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!isValid() || !widget.focusNode.hasFocus) return;

    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!isValid() || !widget.focusNode.hasFocus) return;

    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
