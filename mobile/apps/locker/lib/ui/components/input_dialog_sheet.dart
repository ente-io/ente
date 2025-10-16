import "package:ente_base/typedefs.dart";
import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class InputDialogSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String submitButtonLabel;
  final FutureVoidCallbackParamStr onSubmit;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final int? maxLength;

  const InputDialogSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.submitButtonLabel,
    required this.onSubmit,
    this.initialValue,
    this.textCapitalization = TextCapitalization.words,
    this.maxLength = 200,
  });

  @override
  State<InputDialogSheet> createState() => _InputDialogSheetState();
}

class _InputDialogSheetState extends State<InputDialogSheet> {
  late final TextEditingController _textController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      Navigator.of(context).pop();
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: textTheme.largeBold,
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: colorScheme.iconColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            autofocus: true,
            textCapitalization: widget.textCapitalization,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
              filled: true,
              fillColor: colorScheme.fillFaint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorScheme.strokeFaint,
                ),
              ),
              counterText: "",
            ),
            style: textTheme.body.copyWith(
              color: colorScheme.textBase,
            ),
            onSubmitted: (_) => _onSubmit(),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onTap: _isSubmitting ? null : _onSubmit,
              text: widget.submitButtonLabel,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Future<dynamic> showInputDialogSheet(
  BuildContext context, {
  required String title,
  required String hintText,
  required String submitButtonLabel,
  required FutureVoidCallbackParamStr onSubmit,
  String? initialValue,
  TextCapitalization textCapitalization = TextCapitalization.words,
  int? maxLength = 200,
}) async {
  final result = await showDialog<dynamic>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: InputDialogSheet(
        title: title,
        hintText: hintText,
        submitButtonLabel: submitButtonLabel,
        onSubmit: onSubmit,
        initialValue: initialValue,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
      ),
    ),
  );

  return result;
}
