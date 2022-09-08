// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState({Key key, this.text = "Nothing to see here! 👀"})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .defaultTextColor
                .withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
