import "dart:math";

import 'package:flutter/material.dart';

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
    final int limitCount = min(count, columns * 5);
    final key = '$limitCount:$columns';
    if (!_gridViewCache.containsKey(key)) {
      _gridViewCache[key] = GridView.builder(
        padding: const EdgeInsets.only(top: 2),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(color: Colors.transparent);
        },
        itemCount: limitCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
      );
    }
    return _gridViewCache[key]!;
  }
}
