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
    return Column(children: [
      Padding(padding: EdgeInsets.all(4)),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Theme.of(context).buttonColor,
          ),
        ),
      ),
      Padding(padding: EdgeInsets.all(4)),
    ]);
  }
}
