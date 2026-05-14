import 'package:ente_components/theme/colors.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TextInputComponentMessageType {
  helper,
  error,
  alert,
  success,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2275-11526&m=dev
/// Section: Textfield / Text Input
/// Specs: 388px design width, 52px field height, 81px with label, 100px with helper.
/// States: default, disabled, focused, error, success.
///
/// Multiline variant:
/// https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2275-11746&m=dev
class TextInputComponent extends StatefulWidget {
  const TextInputComponent({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.helperText,
    this.alertText,
    this.errorText,
    this.successText,
    this.isFocused = false,
    this.prefix,
    this.suffix,
    this.messageIcon,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.isClearable = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.scrollController,
    this.expands = false,
    this.counterText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? alertText;
  final String? errorText;
  final String? successText;
  final bool isFocused;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? messageIcon;
  final bool isRequired;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final bool showPasswordToggle;
  final bool isClearable;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool? enableInteractiveSelection;
  final bool? showCursor;
  final String obscuringCharacter;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final ScrollController? scrollController;
  final bool expands;
  final String? counterText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  @override
  State<TextInputComponent> createState() => _TextInputComponentState();
}

class _TextInputComponentState extends State<TextInputComponent> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  late bool _obscureText;
  bool _hasText = false;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _internalController =
        widget.controller == null ? TextEditingController() : null;
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _obscureText = widget.obscureText;
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant TextInputComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      _internalController?.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _internalController?.dispose();
      }
      _internalController =
          widget.controller == null ? TextEditingController() : null;
      _controller.addListener(_handleControllerChanged);
      _hasText = _controller.text.isNotEmpty;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      _internalFocusNode?.removeListener(_handleFocusChanged);
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
      }
      _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
      _focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final message = _message;
    final messageType = _messageType;
    final messageColor = switch (messageType) {
      TextInputComponentMessageType.error ||
      TextInputComponentMessageType.alert =>
        colors.warning,
      TextInputComponentMessageType.success => colors.primary,
      TextInputComponentMessageType.helper => colors.textLight,
    };
    final suffix = _effectiveSuffix();
    final effectiveObscureText = _obscureText;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text.rich(
              TextSpan(
                text: widget.label,
                children: [
                  if (widget.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyles.body.copyWith(
                        color: colors.warning,
                      ),
                    ),
                ],
              ),
              style: TextStyles.body.copyWith(color: colors.textBase),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: effectiveObscureText,
            obscuringCharacter: widget.obscuringCharacter,
            maxLines: widget.expands
                ? null
                : effectiveObscureText
                    ? 1
                    : widget.maxLines,
            minLines:
                widget.expands || effectiveObscureText ? null : widget.minLines,
            expands: widget.expands,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            autocorrect: widget.autocorrect && !effectiveObscureText,
            enableSuggestions:
                widget.enableSuggestions && !effectiveObscureText,
            enableInteractiveSelection: widget.enableInteractiveSelection,
            showCursor: widget.showCursor,
            textAlign: widget.textAlign,
            textAlignVertical: widget.textAlignVertical ??
                (_isMultiline
                    ? TextAlignVertical.top
                    : TextAlignVertical.center),
            scrollController: widget.scrollController,
            onChanged: _handleChanged,
            onSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            style: TextStyles.body.copyWith(color: colors.textBase),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyles.body.copyWith(color: colors.textLighter),
              filled: true,
              fillColor: colors.fillLight,
              prefixIcon:
                  widget.prefix == null ? null : _slot(widget.prefix!, colors),
              suffixIcon: suffix == null ? null : _slot(suffix, colors),
              prefixIconConstraints: const BoxConstraints.tightFor(
                width: Spacing.xxl + Spacing.lg,
                height: Spacing.xxl + Spacing.lg,
              ),
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: Spacing.xxl + Spacing.lg,
                height: Spacing.xxl + Spacing.lg,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.lg,
              ),
              counterText: widget.counterText,
              border: _border(colors),
              enabledBorder: _border(colors),
              focusedBorder: _border(colors, focused: true),
              disabledBorder: _border(colors),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Spacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_messageIcon(messageType) != null) ...[
                  Icon(
                    _messageIcon(messageType),
                    size: 14,
                    color: messageColor,
                  ),
                  const SizedBox(width: Spacing.xs),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: TextStyles.tiny.copyWith(color: messageColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool get _isMultiline {
    return !_obscureText &&
        (widget.maxLines > 1 ||
            (widget.minLines != null && widget.minLines! > 1));
  }

  String? get _message =>
      widget.errorText ??
      widget.alertText ??
      widget.successText ??
      widget.helperText;

  TextInputComponentMessageType get _messageType {
    if (widget.errorText != null) {
      return TextInputComponentMessageType.error;
    }
    if (widget.alertText != null) {
      return TextInputComponentMessageType.alert;
    }
    if (widget.successText != null) {
      return TextInputComponentMessageType.success;
    }
    return TextInputComponentMessageType.helper;
  }

  IconData? _messageIcon(TextInputComponentMessageType messageType) {
    if (widget.messageIcon != null) {
      return widget.messageIcon;
    }
    return switch (messageType) {
      TextInputComponentMessageType.alert => Icons.warning_amber_rounded,
      TextInputComponentMessageType.success =>
        Icons.check_circle_outline_rounded,
      TextInputComponentMessageType.error ||
      TextInputComponentMessageType.helper =>
        null,
    };
  }

  Widget? _effectiveSuffix() {
    if (widget.showPasswordToggle) {
      return GestureDetector(
        key: const ValueKey('text-field-password-toggle'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled
            ? () => setState(() => _obscureText = !_obscureText)
            : null,
        child: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
      );
    }
    if (widget.isClearable && _hasText) {
      return GestureDetector(
        key: const ValueKey('text-field-clear'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled && !widget.readOnly
            ? () {
                _controller.clear();
                widget.onChanged?.call('');
              }
            : null,
        child: const Icon(Icons.close_rounded, size: 20),
      );
    }
    return widget.suffix;
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
  }

  void _handleControllerChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _slot(Widget child, ColorTokens colors) {
    return IconTheme.merge(
      data: IconThemeData(color: colors.textLighter, size: 24),
      child: Center(
        widthFactor: 1,
        child: SizedBox.square(
          dimension: 24,
          child: Center(child: child),
        ),
      ),
    );
  }

  bool get _hasError => widget.errorText != null || widget.alertText != null;

  bool get _hasSuccess => widget.successText != null;

  bool get _hasFocus => widget.isFocused || _focusNode.hasFocus;

  OutlineInputBorder _border(ColorTokens colors, {bool focused = false}) {
    final Color color;
    final double width;
    if (_hasError) {
      color = colors.warning;
      width = 1.5;
    } else if (_hasSuccess) {
      color = colors.primary;
      width = 1.5;
    } else if (focused || _hasFocus) {
      color = colors.primary;
      width = 2;
    } else {
      color = colors.strokeFaint.withAlpha(0);
      width = 0;
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
