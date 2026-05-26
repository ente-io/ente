import "dart:io";

import "package:ente_components/ente_components.dart";
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/button_result.dart';
import 'package:photos/ui/components/buttons/button_component_adapter.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';

enum ActionSheetType { defaultActionSheet, iconOnly }

///Returns null if dismissed
Future<ButtonResult?> showActionSheet({
  required BuildContext context,
  required List<ButtonWidget> buttons,
  ActionSheetType actionSheetType = ActionSheetType.defaultActionSheet,
  bool enableDrag = true,
  bool isDismissible = true,
  bool isCheckIconGreen = false,
  String? title,
  Widget? bodyWidget,
  String? body,
  String? bodyHighlight,
}) {
  final colors = context.componentColors;
  return showMaterialModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: colors.specialScrim.withValues(alpha: 0.55),
    // On iOS setting it to false causes previous page to shift
    // So we're explicitly setting it to true
    useRootNavigator: Platform.isIOS,
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (_) {
      return ActionSheetWidget(
        title: title,
        bodyWidget: bodyWidget,
        body: body,
        bodyHighlight: bodyHighlight,
        actionButtons: buttons,
        actionSheetType: actionSheetType,
        isCheckIconGreen: isCheckIconGreen,
      );
    },
  );
}

class ActionSheetWidget extends StatelessWidget {
  final String? title;
  final Widget? bodyWidget;
  final String? body;
  final String? bodyHighlight;
  final List<ButtonWidget> actionButtons;
  final ActionSheetType actionSheetType;
  final bool isCheckIconGreen;

  const ActionSheetWidget({
    required this.actionButtons,
    required this.actionSheetType,
    required this.isCheckIconGreen,
    this.title,
    this.bodyWidget,
    this.body,
    this.bodyHighlight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasDefaultContent =
        actionSheetType == ActionSheetType.defaultActionSheet &&
        (bodyWidget != null || body != null || bodyHighlight != null);
    final hasContent =
        title != null ||
        hasDefaultContent ||
        actionSheetType == ActionSheetType.iconOnly;
    final colors = context.componentColors;
    final cancelButtonIndex = sheetCancelButtonIndex(context, actionButtons);
    final cancelButton = cancelButtonIndex == -1
        ? null
        : actionButtons[cancelButtonIndex];
    final visibleButtons = [
      for (var index = 0; index < actionButtons.length; index++)
        if (index != cancelButtonIndex) actionButtons[index],
    ];

    return BottomSheetComponent(
      title: title,
      illustration: actionSheetType == ActionSheetType.iconOnly
          ? Icon(
              Icons.check_outlined,
              size: 48,
              color: isCheckIconGreen ? colors.primary : colors.iconColor,
            )
          : null,
      content: hasDefaultContent
          ? _ActionSheetContent(
              bodyWidget: bodyWidget,
              body: body,
              bodyHighlight: bodyHighlight,
            )
          : null,
      actions: [
        for (final button in visibleButtons)
          ButtonComponentAdapter(button: button),
      ],
      showCloseButton: cancelButton != null,
      closeTooltip: AppLocalizations.of(context).close,
      closeResult: cancelButton == null ? null : sheetCloseResult(cancelButton),
      onClose: cancelButton == null
          ? null
          : () => sheetCloseAction(context, cancelButton),
      actionsTopSpacing: hasContent ? Spacing.lg : 0,
    );
  }
}

class _ActionSheetContent extends StatelessWidget {
  final Widget? bodyWidget;
  final String? body;
  final String? bodyHighlight;

  const _ActionSheetContent({this.bodyWidget, this.body, this.bodyHighlight});

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final hasBody = body != null || bodyWidget != null;

    if (!hasBody && bodyHighlight == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasBody)
          bodyWidget ??
              Text(
                body!,
                style: TextStyles.body.copyWith(color: colors.textLight),
              ),
        if (bodyHighlight != null) ...[
          if (hasBody) const SizedBox(height: Spacing.lg),
          Text(
            bodyHighlight!,
            style: TextStyles.body.copyWith(color: colors.textBase),
          ),
        ],
      ],
    );
  }
}
