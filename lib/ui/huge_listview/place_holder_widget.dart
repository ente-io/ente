import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class PlaceHolderWidget extends StatelessWidget {
  const PlaceHolderWidget(
    this.count,
    this.columns, {
    Key? key,
  }) : super(key: key);

  final int count, columns;

  static final _gridViewCache = <String, GridView>{};

  @override
  Widget build(BuildContext context) {
    final key = _getCacheKey(count, columns);
    if (!_gridViewCache.containsKey(key)) {
      _gridViewCache[key] = GridView.builder(
        padding: const EdgeInsets.only(top: 2),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            color: getEnteColorScheme(context).fillFaint,
          );
        },
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
      );
    }
    return _gridViewCache[key]!;
  }

  String _getCacheKey(int totalCount, int columns) {
    return totalCount.toString() + ":" + columns.toString();
  }
}
