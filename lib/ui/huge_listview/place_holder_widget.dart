// @dart=2.9

import 'package:flutter/material.dart';

class PlaceHolderWidget extends StatelessWidget {
  const PlaceHolderWidget(
    this.count,
    this.columns, {
    Key key,
  }) : super(key: key);

  final int count, columns;

  static final _gridViewCache = <String, GridView>{};

  @override
  Widget build(BuildContext context) {
    final key = _getCacheKey(count, columns);
    if (!_gridViewCache.containsKey(key)) {
      _gridViewCache[key] = GridView.builder(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(2.0),
            color: Colors.grey[900],
          );
        },
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
        ),
      );
    }
    return _gridViewCache[key];
  }

  String _getCacheKey(int totalCount, int columns) {
    return totalCount.toString() + ":" + columns.toString();
  }
}
