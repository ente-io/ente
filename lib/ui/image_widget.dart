import 'dart:io';
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
    final path = widget.photo.localPath;
    final size = widget.size == null ? 124 : widget.size;
    final cachedImage = ImageLruCache.getData(path, size);

    Widget image;

    if (cachedImage != null) {
      image = cachedImage;
    } else {
      if (widget.photo.localId != null) {
        image = FutureBuilder<Uint8List>(
          future: AssetEntity(id: widget.photo.localId)
              .thumbDataWithSize(size, size),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Image image = Image.memory(snapshot.data,
                  width: size.toDouble(),
                  height: size.toDouble(),
                  fit: BoxFit.cover);
              ImageLruCache.setData(path, size, image);
              return image;
            } else {
              return loadingWidget;
            }
          },
        );
      } else {
        image = Image.file(File(widget.photo.localPath),
            width: size.toDouble(), height: size.toDouble(), fit: BoxFit.cover);
      }
    }

    return image;
  }

  @override
  void didUpdateWidget(ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photo.localPath != oldWidget.photo.localPath) {
      setState(() {});
    }
  }
}
