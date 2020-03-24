import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatefulWidget {
  final AssetEntity entity;

  const ImageItemWidget({
    Key key,
    this.entity,
  }) : super(key: key);
  @override
  _ImageItemWidgetState createState() => _ImageItemWidgetState();
}

class _ImageItemWidgetState extends State<ImageItemWidget> {
  @override
  Widget build(BuildContext context) {
    final item = widget.entity;
    final size = 130;
    final u8List = ImageLruCache.getData(item, size);

    Widget image;

    if (u8List != null) {
      return _buildImageWidget(item, u8List, size);
    } else {
      image = FutureBuilder<Uint8List>(
        future: item.thumbDataWithSize(size, size),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Center(
              child: Text("load error, error: ${snapshot.error}"),
            );
          }
          if (snapshot.hasData) {
            ImageLruCache.setData(item, size, snapshot.data);
            w = _buildImageWidget(item, snapshot.data, size);
          } else {
            w = Center(
              child: loadWidget,
            );
          }

          return w;
        },
      );
    }

    return image;
  }

  Widget _buildImageWidget(AssetEntity entity, Uint8List uint8list, num size) {
    return Image.memory(
      uint8list,
      width: size.toDouble(),
      height: size.toDouble(),
      fit: BoxFit.cover,
    );
  }

  @override
  void didUpdateWidget(ImageItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      setState(() {});
    }
  }
}
