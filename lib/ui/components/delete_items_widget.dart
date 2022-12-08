import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/utils/add_separators_util.dart';

class DeleteItemsWidget extends StatelessWidget {
  final List<Widget> actionButtons;
  const DeleteItemsWidget({required this.actionButtons, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurMuted, sigmaY: blurMuted),
        child: Container(
          color: colorScheme.backdropBase,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TextContainer(),
                const SizedBox(height: 36),
                ActionButtons(
                  actionButtons,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextContainer extends StatelessWidget {
  const TextContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Delete items",
          style: textTheme.h3Bold,
        ),
        const SizedBox(height: 19),
        Text(
          "Some items exists both on ente and on your device.",
          style: textTheme.body.copyWith(color: colorScheme.textMuted),
        )
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  final List<Widget> actionButtons;
  const ActionButtons(this.actionButtons, {super.key});

  @override
  Widget build(BuildContext context) {
    final actionButtonsWithSeparators = actionButtons;
    return Column(
      children:
          //Separator is 8pts in figma. -2pts here as the action buttons are 2pts
          //extra in height in code compared to figma because of the border of buttons
          addSeparators(actionButtonsWithSeparators, const SizedBox(height: 6)),
    );
  }
}
