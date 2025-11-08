import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CapsuleFormField extends StatefulWidget {
  const CapsuleFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.focusNode,
    this.validator,
    this.trailing,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.lineHeight,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Widget? trailing;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final double? lineHeight;
  final EdgeInsets contentPadding;

  @override
  State<CapsuleFormField> createState() => _CapsuleFormFieldState();
}

class _CapsuleFormFieldState extends State<CapsuleFormField> {
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _ensureFocusNode();
    widget.controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  void _ensureFocusNode() {
    if (widget.focusNode == null && _internalFocusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(CapsuleFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      _internalFocusNode?.removeListener(_handleFocusChanged);
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _ensureFocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _fieldKey.currentState?.didChange(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    _fieldKey.currentState?.didChange(widget.controller.text);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final accentBlue = Color.lerp(
      colorScheme.primary500,
      const Color(0xFF3B82F6),
      0.7,
    )!;

    final isEnabled = widget.enabled && !widget.readOnly;
    _focusNode.canRequestFocus = isEnabled;
    final hasFocus = _focusNode.hasFocus && isEnabled;
    final bool isMultiline =
        (widget.maxLines ?? 1) > 1 || (widget.minLines ?? 1) > 1;
    final int? effectiveMaxLines = widget.obscureText ? 1 : widget.maxLines;
    final int? effectiveMinLines = widget.obscureText
        ? 1
        : (widget.minLines ?? (isMultiline ? (widget.maxLines ?? 3) : 1));
    final textInputType = widget.keyboardType ??
        (isMultiline ? TextInputType.multiline : TextInputType.text);

    final backgroundColor = !widget.enabled
        ? colorScheme.fillMuted
        : hasFocus
            ? accentBlue.withOpacity(0.14)
            : colorScheme.fillFaint;

    final textLineHeight = widget.lineHeight ?? (isMultiline ? 1.5 : 1.25);
    final textColor =
        widget.enabled ? colorScheme.textBase : colorScheme.textFaint;

    return FormField<String>(
      key: _fieldKey,
      autovalidateMode: AutovalidateMode.disabled,
      validator: (value) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText.isNotEmpty) ...[
              Text(
                widget.labelText,
                style: textTheme.body,
              ),
              const SizedBox(height: 8),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: widget.contentPadding,
                child: Row(
                  crossAxisAlignment: (widget.maxLines ?? 1) > 1
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        readOnly: widget.readOnly,
                        enabled: widget.enabled,
                        autofocus: widget.autofocus,
                        obscureText: widget.obscureText,
                        obscuringCharacter: '•',
                        enableSuggestions: !widget.obscureText,
                        autocorrect: !widget.obscureText,
                        keyboardType: textInputType,
                        textCapitalization: widget.textCapitalization,
                        textInputAction: widget.textInputAction,
                        inputFormatters: widget.inputFormatters,
                        maxLines: effectiveMaxLines,
                        minLines: effectiveMinLines,
                        onChanged: (value) {
                          field.didChange(value);
                          widget.onChanged?.call(value);
                        },
                        onEditingComplete: widget.onEditingComplete,
                        onSubmitted: widget.onSubmitted,
                        cursorColor: colorScheme.textBase,
                        style: textTheme.body.copyWith(
                          height: textLineHeight,
                          color: textColor,
                        ),
                        textAlignVertical: isMultiline
                            ? TextAlignVertical.top
                            : TextAlignVertical.center,
                        decoration: InputDecoration.collapsed(
                          hintText: widget.hintText,
                          hintStyle: textTheme.body.copyWith(
                            color: colorScheme.textFaint,
                            height: textLineHeight,
                          ),
                        ),
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
            if (hasError && errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                errorText,
                style: textTheme.mini.copyWith(
                  color: colorScheme.warning500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class CapsuleDisplayField extends StatelessWidget {
  const CapsuleDisplayField({
    super.key,
    required this.labelText,
    required this.value,
    this.isSecret = false,
    this.maxLines,
    this.lineHeight,
    this.onCopy,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  final String labelText;
  final String value;
  final bool isSecret;
  final int? maxLines;
  final double? lineHeight;
  final VoidCallback? onCopy;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final displayValue = isSecret ? '••••••••' : value;
    final textLineHeight = lineHeight ?? ((maxLines ?? 1) > 1 ? 1.5 : 1.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty) ...[
          Text(
            labelText,
            style: textTheme.body,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: contentPadding,
            child: Row(
              crossAxisAlignment: (maxLines ?? 1) > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: isSecret
                      ? Text(
                          displayValue,
                          style:
                              textTheme.body.copyWith(height: textLineHeight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : SelectableText(
                          displayValue,
                          style:
                              textTheme.body.copyWith(height: textLineHeight),
                          maxLines: maxLines,
                        ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.fillBase.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: colorScheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
