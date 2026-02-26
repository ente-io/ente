import 'package:ente_ui/components/text_input_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A form-compatible wrapper that uses Ente UI TextInputWidget when possible,
/// or falls back to custom implementation for advanced features
class FormTextInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final bool showValidationErrors;
  final bool shouldUseTextInputWidget;

  const FormTextInputWidget({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.showValidationErrors = false,
    this.shouldUseTextInputWidget = true,
  });

  @override
  State<FormTextInputWidget> createState() => _FormTextInputWidgetState();
}

class _FormTextInputWidgetState extends State<FormTextInputWidget> {
  final GlobalKey<FormFieldState> _formFieldKey = GlobalKey<FormFieldState>();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
    // Only validate if we should show validation errors
    if (widget.showValidationErrors) {
      _formFieldKey.currentState?.validate();
    }
  }

  // Check if we can use the UI package's TextInputWidget
  bool get _canUseTextInputWidget {
    return widget.suffixIcon == null &&
        (widget.maxLines ?? 1) == 1 &&
        widget.enabled &&
        widget.shouldUseTextInputWidget;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_canUseTextInputWidget) ...[
          // Use the UI package's TextInputWidget for simple cases
          TextInputWidget(
            label: widget.labelText,
            hintText: widget.hintText,
            initialValue: widget.controller.text,
            isPasswordInput: widget.obscureText,
            textCapitalization: widget.textCapitalization,
            autoFocus: widget.autofocus,
            maxLength: widget.maxLength,
            shouldSurfaceExecutionStates: false,
            onChange: (value) {
              if (widget.controller.text != value) {
                widget.controller.text = value;
              }
            },
          ),
        ] else ...[
          // Custom implementation for advanced features
          if (widget.labelText.isNotEmpty) ...[
            Text(
              widget.labelText,
              style: textTheme.body,
            ),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Material(
              color: Colors.transparent,
              child: TextFormField(
                controller: widget.controller,
                validator: (value) => null, // Handled separately
                obscureText: widget.obscureText,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                textCapitalization: widget.textCapitalization,
                keyboardType: widget.keyboardType,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                inputFormatters: widget.maxLength != null
                    ? [LengthLimitingTextInputFormatter(widget.maxLength!)]
                    : null,
                style: textTheme.body,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle:
                      textTheme.body.copyWith(color: colorScheme.textFaint),
                  filled: true,
                  fillColor: colorScheme.fillFaint,
                  contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.strokeFaint,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.warning500,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.warning500,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: widget.suffixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: widget.suffixIcon,
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 24,
                    maxWidth: 48,
                    minHeight: 24,
                    minWidth: 48,
                  ),
                  errorStyle: const TextStyle(fontSize: 0, height: 0),
                ),
              ),
            ),
          ),
        ],

        // Custom validation error display (for both cases)
        if (_errorText != null && widget.showValidationErrors) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _errorText!,
              style: textTheme.mini.copyWith(
                color: colorScheme.warning500,
              ),
            ),
          ),
        ],

        // Invisible FormField for validation integration
        SizedBox(
          height: 0,
          child: FormField<String>(
            key: _formFieldKey,
            validator: (value) {
              final error = widget.validator?.call(widget.controller.text);
              if (mounted && widget.showValidationErrors) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _errorText = error;
                    });
                  }
                });
              }
              return error;
            },
            builder: (FormFieldState<String> field) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
