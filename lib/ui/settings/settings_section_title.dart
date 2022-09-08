// @dart=2.9

import 'package:flutter/material.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const SettingsSectionTitle(
    this.title, {
    Key key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(4)),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: color != null
                ? Theme.of(context)
                    .textTheme
                    .headline6
                    .merge(TextStyle(color: color))
                : Theme.of(context).textTheme.headline6,
          ),
        ),
        const Padding(padding: EdgeInsets.all(4)),
      ],
    );
  }
}
