import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';

class ActionBarWidget extends StatelessWidget {
  final String? text;
  final List<Widget> iconButtons;
  const ActionBarWidget({
    this.text,
    required this.iconButtons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actionBarWidgets(context),
      ),
    );
  }

  List<Widget> _actionBarWidgets(BuildContext context) {
    final actionBarWidgets = <Widget>[];
    final initialLength = iconButtons.length;
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final hasSelectedFiles = SelectedFiles().files.isNotEmpty;

    actionBarWidgets.addAll(iconButtons);
    if (text != null) {
      //adds 12 px spacing at the start and between iconButton elements
      for (var i = 0; i < initialLength; i++) {
        actionBarWidgets.insert(
          2 * i,
          const SizedBox(
            width: 12,
          ),
        );
      }
      actionBarWidgets.insertAll(0, [
        const SizedBox(width: 20),
        Flexible(
          child: Row(
            children: [
              Text(
                text!,
                style: hasSelectedFiles
                    ? textTheme.body
                    : textTheme.small.copyWith(
                        color: colorScheme.textMuted,
                      ),
              )
            ],
          ),
        ),
      ]);
      //to add whitespace of 8pts or 12 pts at the end
      if (iconButtons.length > 1) {
        actionBarWidgets.add(
          const SizedBox(width: 8),
        );
      } else {
        actionBarWidgets.add(
          const SizedBox(width: 12),
        );
      }
    }
    return actionBarWidgets;
  }
}
