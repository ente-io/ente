// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class EnteSectionTitle extends StatelessWidget {
  final double opacity;

  const EnteSectionTitle({
    this.opacity = 0.8,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "On ",
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(fontSize: 22),
                  ),
                  TextSpan(
                    text: "ente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.defaultTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
