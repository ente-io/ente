import 'dart:io';

import 'package:flutter/material.dart';

class SettingsTextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  const SettingsTextItem({
    Key key,
    @required this.text,
    @required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(text)),
            Icon(icon),
          ],
        ),
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
      ],
    );
  }
}