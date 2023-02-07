import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/separators_util.dart';

typedef FutureVoidCallbackParamStr = Future<void> Function(String);

///Will return null if dismissed by tapping outside
Future<ButtonAction?> showDialogWidget({
  required BuildContext context,
  required String title,
  String? body,
  required List<ButtonWidget> buttons,
  IconData? icon,
  bool isDismissible = true,
}) {
  return showDialog(
    barrierDismissible: isDismissible,
    barrierColor: backdropFaintDark,
    context: context,
    builder: (context) {
      final widthOfScreen = MediaQuery.of(context).size.width;
      final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobileSmall ? 8 : 0),
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          child: DialogWidget(
            title: title,
            body: body,
            buttons: buttons,
            icon: icon,
          ),
        ),
      );
    },
  );
}

class DialogWidget extends StatelessWidget {
  final String title;
  final String? body;
  final List<ButtonWidget> buttons;
  final IconData? icon;
  const DialogWidget({
    required this.title,
    this.body,
    required this.buttons,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.of(context).size.width;
    final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: min(widthOfScreen, 320),
      padding: isMobileSmall
          ? const EdgeInsets.all(0)
          : const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        boxShadow: shadowFloatLight,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentContainer(
              title: title,
              body: body,
              icon: icon,
            ),
            const SizedBox(height: 36),
            Actions(buttons),
          ],
        ),
      ),
    );
  }
}

class ContentContainer extends StatelessWidget {
  final String title;
  final String? body;
  final IconData? icon;
  const ContentContainer({
    required this.title,
    this.body,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        icon == null
            ? const SizedBox.shrink()
            : Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                  ),
                ],
              ),
        icon == null ? const SizedBox.shrink() : const SizedBox(height: 19),
        Text(title, style: textTheme.largeBold),
        body != null ? const SizedBox(height: 19) : const SizedBox.shrink(),
        body != null
            ? Text(
                body!,
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class Actions extends StatelessWidget {
  final List<ButtonWidget> buttons;
  const Actions(this.buttons, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: addSeparators(
        buttons,
        const SizedBox(
          // In figma this white space is of height 8pts. But the Button
          // component has 1pts of invisible border by default in code. So two
          // 1pts borders will visually make the whitespace 8pts.
          // Height of button component in figma = 48, in code = 50 (2pts for
          // top + bottom border)
          height: 6,
        ),
      ),
    );
  }
}

class TextInputDialog extends StatefulWidget {
  final String title;
  final String? body;
  final String confirmationButtonLabel;
  final IconData? icon;
  final String? label;
  final String? message;
  final FutureVoidCallbackParamStr onConfirm;
  final String? hintText;
  const TextInputDialog({
    required this.title,
    this.body,
    required this.confirmationButtonLabel,
    required this.onConfirm,
    this.icon,
    this.label,
    this.message,
    this.hintText,
    super.key,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final TextEditingController _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.of(context).size.width;
    final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    var textInputChildren = <Widget>[];
    if (widget.label != null) textInputChildren.add(Text(widget.label!));
    textInputChildren.add(
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Material(
          child: TextFormField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: textTheme.body.copyWith(color: colorScheme.textMuted),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 11,
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
              prefixIcon: Icon(
                Icons.search_outlined,
                color: colorScheme.strokeMuted,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.message != null) {
      textInputChildren.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            widget.message!,
            style: textTheme.small.copyWith(color: colorScheme.textMuted),
          ),
        ),
      );
    }
    textInputChildren =
        addSeparators(textInputChildren, const SizedBox(height: 4));
    return Container(
      width: min(widthOfScreen, 320),
      padding: isMobileSmall
          ? const EdgeInsets.all(0)
          : const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        boxShadow: shadowFloatLight,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentContainer(
              title: widget.title,
              body: widget.body,
              icon: widget.icon,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 19),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: textInputChildren,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Expanded(
                  child: ButtonWidget(
                    buttonType: ButtonType.secondary,
                    buttonSize: ButtonSize.small,
                    labelText: "Cancel",
                    isInAlert: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ButtonWidget(
                    buttonSize: ButtonSize.small,
                    buttonType: ButtonType.neutral,
                    labelText: widget.confirmationButtonLabel,
                    onTap: _onTap,
                    isInAlert: true,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    await widget.onConfirm.call(_textController.text);
  }
}
