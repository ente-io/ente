import 'dart:math';

import "package:ente_components/ente_components.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/button_result.dart';
import 'package:photos/models/typedefs.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/buttons/button_component_adapter.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/text_input_widget.dart';

///Will return null if dismissed by tapping outside
Future<ButtonResult?> showDialogWidget({
  required BuildContext context,
  required String title,
  String? body,
  required List<ButtonWidget> buttons,
  IconData? icon,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  return showBottomSheetComponent<ButtonResult>(
    barrierColor: backdropFaintDark,
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useRootNavigator: useRootNavigator,
    builder: (_) {
      return DialogWidget(
        title: title,
        body: body,
        buttons: buttons,
        icon: icon,
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
    final colors = context.componentColors;
    final hasTitle = title.isNotEmpty;
    final hasBody = body?.isNotEmpty == true;
    final hasContent = hasTitle || hasBody || icon != null;

    return BottomSheetComponent(
      title: hasTitle ? title : null,
      illustration: icon == null
          ? null
          : Icon(icon, size: 48, color: colors.iconColor),
      content: hasBody ? _DialogBody(body!) : null,
      actions: [
        for (final button in buttons) ButtonComponentAdapter(button: button),
      ],
      showCloseButton: false,
      actionsTopSpacing: hasContent ? Spacing.xl : 0,
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody(this.body);

  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Text(
          body,
          style: TextStyles.body.copyWith(color: colors.textLight),
        ),
      ),
    );
  }
}

class _ContentContainer extends StatelessWidget {
  final String title;
  final String? body;
  final IconData? icon;
  const _ContentContainer({required this.title, this.body, this.icon});

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
            : Row(children: [Icon(icon, size: 32)]),
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

class TextInputDialog extends StatefulWidget {
  final String title;
  final String? body;
  final String submitButtonLabel;
  final IconData? icon;
  final String? label;
  final String? message;
  final FutureVoidCallbackParamStr onSubmit;
  final String? hintText;
  final IconData? prefixIcon;
  final String? initialValue;
  final Alignment? alignMessage;
  final int? maxLength;
  final bool showOnlyLoadingState;
  final TextCapitalization? textCapitalization;
  final bool alwaysShowSuccessState;
  final bool isPasswordInput;
  final TextEditingController? textEditingController;
  final List<TextInputFormatter>? textInputFormatter;
  final TextInputType? textInputType;
  final bool popnavAfterSubmission;
  const TextInputDialog({
    required this.title,
    this.body,
    required this.submitButtonLabel,
    required this.onSubmit,
    this.icon,
    this.label,
    this.message,
    this.hintText,
    this.prefixIcon,
    this.initialValue,
    this.alignMessage,
    this.maxLength,
    this.textCapitalization,
    this.showOnlyLoadingState = false,
    this.alwaysShowSuccessState = false,
    this.isPasswordInput = false,
    this.textEditingController,
    this.textInputFormatter,
    this.textInputType,
    this.popnavAfterSubmission = true,
    super.key,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  //the value of this ValueNotifier has no significance
  final _submitNotifier = ValueNotifier(false);
  late final ValueNotifier<bool> _inputIsEmptyNotifier;
  late final TextEditingController _textEditingController;
  late final bool _ownsTextEditingController;
  late final VoidCallback _textEditingControllerListener;

  @override
  void initState() {
    super.initState();
    _ownsTextEditingController = widget.textEditingController == null;
    _textEditingController =
        widget.textEditingController ?? TextEditingController();
    _inputIsEmptyNotifier = widget.initialValue?.isEmpty ?? true
        ? ValueNotifier(true)
        : ValueNotifier(false);
    _textEditingControllerListener = () {
      if (_textEditingController.text.isEmpty != _inputIsEmptyNotifier.value) {
        _inputIsEmptyNotifier.value = _textEditingController.text.isEmpty;
      }
    };
    _textEditingController.addListener(_textEditingControllerListener);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_textEditingControllerListener);
    if (_ownsTextEditingController) {
      _textEditingController.dispose();
    }
    _submitNotifier.dispose();
    _inputIsEmptyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.sizeOf(context).width;
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
            _ContentContainer(
              title: widget.title,
              body: widget.body,
              icon: widget.icon,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 19),
              child: TextInputWidget(
                label: widget.label,
                message: widget.message,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
                initialValue: widget.initialValue,
                alignMessage: widget.alignMessage,
                autoFocus: true,
                maxLength: widget.maxLength,
                submitNotifier: _submitNotifier,
                onSubmit: widget.onSubmit,
                popNavAfterSubmission: widget.popnavAfterSubmission,
                showOnlyLoadingState: widget.showOnlyLoadingState,
                textCapitalization: widget.textCapitalization,
                alwaysShowSuccessState: widget.alwaysShowSuccessState,
                isPasswordInput: widget.isPasswordInput,
                textEditingController: _textEditingController,
                textInputFormatter: widget.textInputFormatter,
                keyboardType: widget.textInputType,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ButtonWidget(
                    buttonType: ButtonType.secondary,
                    buttonSize: ButtonSize.small,
                    labelText: AppLocalizations.of(context).cancel,
                    isInAlert: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _inputIsEmptyNotifier,
                    builder: (context, bool value, _) {
                      return ButtonWidget(
                        buttonSize: ButtonSize.small,
                        buttonType: ButtonType.neutral,
                        labelText: widget.submitButtonLabel,
                        isDisabled: value,
                        onTap: () async {
                          _submitNotifier.value = !_submitNotifier.value;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
