import 'package:flutter/material.dart';

class PlaceHolderWidget extends StatelessWidget {
  const PlaceHolderWidget(
    this.count, {
    Key key,
  }) : super(key: key);

  final int count;

  static final _gridViewCache = Map<int, GridView>();

  @override
  Widget build(BuildContext context) {
    if (!_gridViewCache.containsKey(count)) {
      _gridViewCache[count] = GridView.builder(
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(2.0),
            color: Colors.grey[900],
          );
        },
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
      );
    }
    return _gridViewCache[count];
  }
}
