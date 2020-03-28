import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:provider/provider.dart';

class ImageWidget extends StatefulWidget {
  final String path;

  const ImageWidget({
    Key key,
    this.path,
  }) : super(key: key);
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  var _logger = Logger();
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final size = 124;
    final cachedImage = ImageLruCache.getData(path, size);

    Widget image;

    if (cachedImage != null) {
      _logger.i("Cache hit for " + path);
      image = cachedImage;
    } else {
      image = FutureBuilder<Image>(
        future: _buildImageWidget(path, size),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            ImageLruCache.setData(path, size, snapshot.data);
            return snapshot.data;
          } else {
            return loadWidget;
          }
        },
      );
    }

    return image;
  }

  Future<Image> _buildImageWidget(String path, num size) async {
    return Image.file(File(path),
        width: size.toDouble(), height: size.toDouble(), fit: BoxFit.cover);
  }

  @override
  void didUpdateWidget(ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      setState(() {});
    }
  }
}
