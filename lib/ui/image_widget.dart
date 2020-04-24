import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageWidget extends StatefulWidget {
  final Photo photo;
  final int size;

  const ImageWidget(
    this.photo, {
    Key key,
    this.size,
  }) : super(key: key);
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  static final Widget loadingWidget = Container(
    alignment: Alignment.center,
    color: Colors.grey[500],
  );
  @override
  Widget build(BuildContext context) {
    final size = widget.size == null ? 124 : widget.size;
    final cachedImageData =
        ImageLruCache.getData(widget.photo.generatedId, size);

    Widget image;

    if (cachedImageData != null) {
      image = _buildImage(cachedImageData, size);
    } else {
      if (widget.photo.localId != null) {
        image = FutureBuilder<Uint8List>(
          future: AssetEntity(id: widget.photo.localId)
              .thumbDataWithSize(size, size),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              ImageLruCache.setData(
                  widget.photo.generatedId, size, snapshot.data);
              Image image = _buildImage(snapshot.data, size);
              return image;
            } else {
              return loadingWidget;
            }
          },
        );
      } else {
        // TODO
        return Text("Not Implemented");
      }
    }

    return image;
  }

  Image _buildImage(Uint8List data, int size) {
    return Image.memory(data,
        width: size.toDouble(), height: size.toDouble(), fit: BoxFit.cover);
  }
}
