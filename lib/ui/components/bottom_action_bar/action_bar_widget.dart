import 'package:flutter/material.dart';

class ActionBarWidget extends StatelessWidget {
  final Widget? textWidget;
  final List<Widget> iconButtons;
  const ActionBarWidget({
    this.textWidget,
    required this.iconButtons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actionBarWidgets(),
      ),
    );
  }

  List<Widget> _actionBarWidgets() {
    final actionBarWidgets = <Widget>[];
    final initialLength = iconButtons.length;
    actionBarWidgets.addAll(iconButtons);
    if (textWidget != null) {
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
        Flexible(child: Row(children: [textWidget!])),
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
