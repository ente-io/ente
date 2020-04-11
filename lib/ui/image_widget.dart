import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class ImageWidget extends StatefulWidget {
  final Photo photo;

  const ImageWidget(
    this.photo, {
    Key key,
  }) : super(key: key);
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);

  @override
  Widget build(BuildContext context) {
    final path = widget.photo.localPath;
    final size = 124;
    final cachedImage = ImageLruCache.getData(path, size);

    Widget image;

    if (cachedImage != null) {
      image = cachedImage;
    } else {
      image = FutureBuilder<Uint8List>(
        future:
            AssetEntity(id: widget.photo.localId).thumbDataWithSize(size, size),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Image image = Image.memory(snapshot.data,
                width: 124, height: 124, fit: BoxFit.cover);
            ImageLruCache.setData(path, size, image);
            return image;
          } else {
            return loadWidget;
          }
        },
      );
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
