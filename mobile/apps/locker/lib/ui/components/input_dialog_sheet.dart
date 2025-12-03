import "package:ente_base/typedefs.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/ui/components/gradient_button.dart";

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
    final text = _textController.text.trim();

    if (text.isEmpty || _isSubmitting) {
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

    return SizedBox(
      width: 360,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleBarTitleWidget(
                  title: widget.title,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.backgroundElevated,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      color: colorScheme.textBase,
                      size: 20,
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
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
                onTap: !_isInputValid || _isSubmitting ? null : _onSubmit,
                text: widget.submitButtonLabel,
              ),
            ),
          ],
        ),
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
    builder: (dialogContext) {
      final colorScheme = getEnteColorScheme(dialogContext);
      return Dialog(
        backgroundColor: colorScheme.backgroundElevated2,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: InputDialogSheet(
          title: title,
          hintText: hintText,
          submitButtonLabel: submitButtonLabel,
          onSubmit: onSubmit,
          initialValue: initialValue,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
        ),
      );
    },
  );

  return result;
}
