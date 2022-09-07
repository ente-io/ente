// @dart=2.9

import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget sectionOptionDivider = Padding(
  padding: EdgeInsets.all(Platform.isIOS ? 4 : 2),
);

ExpandableThemeData getExpandableTheme(BuildContext context) {
  return ExpandableThemeData(
    expandIcon: CupertinoIcons.chevron_down,
    collapseIcon: CupertinoIcons.chevron_up,
    iconPadding: const EdgeInsets.all(4),
    iconColor: Theme.of(context).colorScheme.onSurface,
    iconSize: 20.0,
    iconRotationAngle: -3.14 / 2,
    hasIcon: true,
  );
}
