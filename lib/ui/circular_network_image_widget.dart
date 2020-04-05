import 'package:flutter/material.dart';

class CircularNetworkImageWidget extends StatelessWidget {
  final String _url;
  final double _size;

  const CircularNetworkImageWidget(String url, double size, {Key key})
      : this._url = url,
        this._size = size,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
        width: _size,
        height: _size,
        margin: const EdgeInsets.only(right: 8),
        decoration: new BoxDecoration(
            shape: BoxShape.circle,
            image: new DecorationImage(
                fit: BoxFit.contain, image: new NetworkImage(_url))));
  }
}
