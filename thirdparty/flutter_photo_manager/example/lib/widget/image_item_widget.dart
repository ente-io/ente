import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/core/lru_map.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:image_scanner_example/widget/loading_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class ImageItemWidget extends StatefulWidget {
  const ImageItemWidget({
    Key? key,
    required this.entity,
    required this.option,
  }) : super(key: key);

  final AssetEntity entity;
  final ThumbOption option;

  @override
  _ImageItemWidgetState createState() => _ImageItemWidgetState();
}

class _ImageItemWidgetState extends State<ImageItemWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    return ChangeNotifierBuilder(
      builder: (c, p) {
        final format = provider.thumbFormat;
        return buildContent(format);
      },
      value: provider,
    );
  }

  Widget buildContent(ThumbFormat format) {
    if (widget.entity.type == AssetType.audio) {
      return Center(
        child: Icon(
          Icons.audiotrack,
          size: 30,
        ),
      );
    }
    final item = widget.entity;
    final size = widget.option.width;
    final u8List = ImageLruCache.getData(item, size, format);

    Widget image;

    if (u8List != null) {
      return _buildImageWidget(item, u8List, size);
    } else {
      image = FutureBuilder<Uint8List?>(
        future: item.thumbDataWithOption(widget.option),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Center(
              child: Text("load error, error: ${snapshot.error}"),
            );
          }
          if (snapshot.hasData) {
            ImageLruCache.setData(item, size, format, snapshot.data!);
            w = _buildImageWidget(item, snapshot.data!, size);
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
