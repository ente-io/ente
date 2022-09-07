// @dart=2.9

import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Alignment alignment;
  final double opacity;

  const SectionTitle(
    this.title, {
    this.opacity = 0.8,
    Key key,
    this.alignment = Alignment.centerLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: Column(
        children: [
          Align(
            alignment: alignment,
            child: Text(
              title,
              style:
                  Theme.of(context).textTheme.headline6.copyWith(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}
