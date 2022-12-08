import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/utils/add_separators_util.dart';

class ActionSheetWidget extends StatelessWidget {
  final String? title;
  final String? body;
  final List<Widget> actionButtons;

  const ActionSheetWidget(
      {required this.actionButtons, this.title, this.body, super.key});

  @override
  Widget build(BuildContext context) {
    final isTitleAndBodyNull = title == null && body == null;
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurMuted, sigmaY: blurMuted),
          child: Container(
            color: colorScheme.backdropBase,
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(24, 24, 24, isTitleAndBodyNull ? 24 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isTitleAndBodyNull
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 36),
                          child:
                              ContentContainerWidget(title: title, body: body),
                        ),
                  ActionButtons(
                    actionButtons,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContentContainerWidget extends StatelessWidget {
  final String? title;
  final String? body;
  const ContentContainerWidget({this.title, this.body, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      //set cross axis to center when icon should be shown in place of body
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title == null
            ? const SizedBox.shrink()
            : Text(
                title!,
                style: textTheme.h3Bold,
              ),
        title == null || body == null
            ? const SizedBox.shrink()
            : const SizedBox(height: 19),
        body == null
            ? const SizedBox.shrink()
            : Text(
                body!,
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
