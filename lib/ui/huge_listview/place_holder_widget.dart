import 'package:flutter/material.dart';

class PlaceHolderWidget extends StatelessWidget {
  const PlaceHolderWidget({
    Key key,
    @required this.day,
    @required this.count,
  }) : super(key: key);

  final Widget day;
  final int count;

  static final _gridViewCache = Map<int, GridView>();

  @override
  Widget build(BuildContext context) {
    if (!_gridViewCache.containsKey(count)) {
      _gridViewCache[count] = GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 12),
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
    return Column(
      children: <Widget>[
        day,
        _gridViewCache[count],
      ],
    );
  }
}