import "dart:math";

import 'package:flutter/material.dart';
import "package:photos/theme/ente_theme.dart";

class PlaceHolderGridViewWidget extends StatelessWidget {
  const PlaceHolderGridViewWidget(
    this.count,
    this.columns, {
    Key? key,
  }) : super(key: key);

  final int count, columns;

  static final _gridViewCache = <String, GridView>{};
  static const crossAxisSpacing = 2.0; // as per your code
  static const mainAxisSpacing = 2.0; // as per your code

  @override
  Widget build(BuildContext context) {
    final Color faintColor = getEnteColorScheme(context).fillFaint;
    final int limitCount = min(count, columns * 5);
    final key = '$limitCount:$columns';
    if (!_gridViewCache.containsKey(key)) {
      _gridViewCache[key] = GridView.builder(
        padding: const EdgeInsets.only(top: 2),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(color: faintColor);
        },
        itemCount: limitCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
      );
    }
    return _gridViewCache[key]!;
  }
}
