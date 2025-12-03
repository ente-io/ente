import "package:expandable/expandable.dart";
import "package:flutter/material.dart";

Widget sectionOptionSpacing = const SizedBox(height: 6);

ExpandableThemeData getExpandableTheme() {
  return const ExpandableThemeData(
    hasIcon: false,
    useInkWell: false,
    tapBodyToCollapse: true,
    tapBodyToExpand: true,
    animationDuration: Duration(milliseconds: 400),
  );
}
