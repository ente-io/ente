import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/image_widget.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:photo_view/photo_view.dart';

class WidgetLruCache {
  static LRUMap<int, Widget> _map = LRUMap(500);

  static Widget get(Photo photo) {
    return _map.get(photo.generatedId);
  }

  static void put(Photo photo, Widget data) {
    _map.put(photo.generatedId, data);
  }
}

class ZoomableImage extends StatelessWidget {
  final Function(bool) shouldDisableScroll;

  const ZoomableImage(
    this.photo, {
    Key key,
    this.shouldDisableScroll,
  }) : super(key: key);

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    Logger().i("Building " + photo.toString());
    if (WidgetLruCache.get(photo) != null) {
      return WidgetLruCache.get(photo);
    }
    Logger().i("Cache miss " + photo.toString());
    return FutureBuilder<Uint8List>(
      future: photo.getBytes(),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final photoView = _buildPhotoView(snapshot.data);
          WidgetLruCache.put(photo, photoView);
          return photoView;
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          Logger().i("Loading");
          return ImageWidget(photo);
        }
      },
    );
  }

  Widget _buildPhotoView(Uint8List imageData) {
    ValueChanged<PhotoViewScaleState> scaleStateChangedCallback = (value) {
      if (shouldDisableScroll != null) {
        shouldDisableScroll(value != PhotoViewScaleState.initial);
      }
    };
    return PhotoView(
      imageProvider: Image.memory(imageData).image,
      scaleStateChangedCallback: scaleStateChangedCallback,
      minScale: PhotoViewComputedScale.contained,
    );
  }
}
