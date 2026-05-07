import "package:ente_base/typedefs.dart";
import "package:ente_ui/components/base_bottom_sheet.dart";
import "package:ente_ui/components/buttons/button_widget_v2.dart";
import "package:ente_ui/components/text_input_widget_v2.dart";
import "package:flutter/material.dart";

class InputSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String submitButtonLabel;
  final FutureVoidCallbackParamStr onSubmit;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool isPasswordInput;

  const InputSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.submitButtonLabel,
    required this.onSubmit,
    this.initialValue,
    this.textCapitalization = TextCapitalization.words,
    this.maxLength = 200,
    this.isPasswordInput = false,
  });

  @override
  State<InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<InputSheet> {
  late final TextEditingController _textController;
  bool _isSubmitting = false;
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue ?? '');
    _isInputValid = _textController.text.trim().isNotEmpty;
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isValid = _textController.text.trim().isNotEmpty;
    if (isValid != _isInputValid) {
      setState(() {
        _isInputValid = isValid;
      });
    }
  }

  Future<void> _onSubmit() async {
    final text = widget.isPasswordInput
        ? _textController.text
        : _textController.text.trim();

    if (text.trim().isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(text);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        Navigator.of(context).pop(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInputWidgetV2(
          textEditingController: _textController,
          autoFocus: true,
          textCapitalization: widget.textCapitalization,
          maxLength: widget.maxLength,
          hintText: widget.hintText,
          isPasswordInput: widget.isPasswordInput,
          autoCorrect: !widget.isPasswordInput,
          shouldSurfaceExecutionStates: false,
          onSubmit: (_) async => _onSubmit(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ButtonWidgetV2(
            buttonType: ButtonTypeV2.primary,
            isDisabled: !_isInputValid || _isSubmitting,
            onTap: !_isInputValid || _isSubmitting ? null : _onSubmit,
            labelText: widget.submitButtonLabel,
          ),
        ),
      ],
    );
  }
}

Future<dynamic> showInputSheet(
  BuildContext context, {
  required String title,
  required String hintText,
  required String submitButtonLabel,
  required FutureVoidCallbackParamStr onSubmit,
  String? initialValue,
  TextCapitalization textCapitalization = TextCapitalization.words,
  int? maxLength = 200,
  bool isPasswordInput = false,
}) async {
  return showBaseBottomSheet<dynamic>(
    context,
    title: title,
    headerSpacing: 20,
    isKeyboardAware: true,
    child: InputSheet(
      title: title,
      hintText: hintText,
      submitButtonLabel: submitButtonLabel,
      onSubmit: onSubmit,
      initialValue: initialValue,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      isPasswordInput: isPasswordInput,
    ),
  );
}
