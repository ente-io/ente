import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photos/ui/loading_widget.dart';

class CircularNetworkImageWidget extends StatelessWidget {
  final String _url;
  final double _size;

  const CircularNetworkImageWidget(String url, double size, {Key key})
      : this._url = url,
        this._size = size,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _url,
      imageBuilder: (context, imageProvider) => Container(
        width: _size,
        height: _size,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
      placeholder: (context, url) => loadWidget,
    );
  }
}
