import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/models/execution_states.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/debouncer.dart";

class PasswordInputWidget extends StatefulWidget {
  final String? label;
  final String? message;
  final String? hintText;
  final IconData? prefixIcon;
  final String? initialValue;
  final Alignment? alignMessage;
  final bool? autoFocus;
  final int? maxLength;
  final double borderRadius;

  final ValueNotifier? submitNotifier;

  final FutureVoidCallbackParamStr? onSubmit;
  final VoidCallbackParamStr? onChange;
  final bool isPasswordInput;

  final FocusNode? focusNode;
  final TextEditingController? textEditingController;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? textInputFormatter;
  const PasswordInputWidget({
    Key? key,
    this.label,
    this.message,
    this.hintText,
    this.prefixIcon,
    this.initialValue,
    this.alignMessage,
    this.autoFocus,
    this.maxLength,
    this.borderRadius = 10.0,
    this.submitNotifier,
    this.onSubmit,
    this.onChange,
    required this.isPasswordInput,
    this.focusNode,
    this.textEditingController,
    this.textInputType,
    this.textInputFormatter,
  }) : super(key: key);

  @override
  State<PasswordInputWidget> createState() => _PasswordInputWidgetState();
}

class _PasswordInputWidgetState extends State<PasswordInputWidget> {
  ExecutionState executionState = ExecutionState.idle;
  late final TextEditingController _textController;
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  late final ValueNotifier<bool> _obscureTextNotifier;

  @override
  void initState() {
    super.initState();
    // widget.submitNotifier?.addListener(_onSubmit);
    // widget.cancelNotifier?.addListener(_onCancel);
    _textController = widget.textEditingController ?? TextEditingController();

    // _setInitialValue();

    if (widget.onChange != null) {
      _textController.addListener(() {
        widget.onChange!.call(_textController.text);
      });
    }
    _obscureTextNotifier = ValueNotifier(widget.isPasswordInput);
    // _obscureTextNotifier.addListener(_safeRefresh);

    // if (widget.isEmptyNotifier != null) {
    //   _textController.addListener(() {
    //     widget.isEmptyNotifier!.value = _textController.text.isEmpty;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    var textInputChildren = <Widget>[];

    return const Placeholder();
  }
}
