

import 'dart:io';

import 'package:flutter/material.dart';

class SettingsTextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  const SettingsTextItem({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium),
            ),
            Icon(icon),
          ],
        ),
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
      ],
    );
  }
}
