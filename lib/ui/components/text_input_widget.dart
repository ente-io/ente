import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/utils/separators_util.dart';

class TextInputWidget extends StatelessWidget {
  final TextEditingController textController;
  final String? label;
  final String? message;
  final String? hintText;
  final IconData? prefixIcon;
  final String? initialValue;
  final Alignment? alignMessage;
  final bool? autoFocus;
  final int? maxLength;
  const TextInputWidget({
    required this.textController,
    this.label,
    this.message,
    this.hintText,
    this.prefixIcon,
    this.initialValue,
    this.alignMessage,
    this.autoFocus,
    this.maxLength,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      textController.text = initialValue!;
    }
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    var textInputChildren = <Widget>[];
    if (label != null) textInputChildren.add(Text(label!));
    textInputChildren.add(
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Material(
          child: TextFormField(
            autofocus: autoFocus ?? false,
            controller: textController,
            inputFormatters: maxLength != null
                ? [LengthLimitingTextInputFormatter(50)]
                : null,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: textTheme.body.copyWith(color: colorScheme.textMuted),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.strokeMuted),
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIconConstraints: const BoxConstraints(
                maxHeight: 44,
                maxWidth: 44,
                minHeight: 44,
                minWidth: 44,
              ),
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 44,
                maxWidth: 44,
                minHeight: 44,
                minWidth: 44,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: colorScheme.strokeMuted,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
    if (message != null) {
      textInputChildren.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: alignMessage ?? Alignment.centerLeft,
            child: Text(
              message!,
              style: textTheme.small.copyWith(color: colorScheme.textMuted),
            ),
          ),
        ),
      );
    }
    textInputChildren =
        addSeparators(textInputChildren, const SizedBox(height: 4));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textInputChildren,
    );
  }
}
