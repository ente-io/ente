import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/image_cache.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/core/thumbnail_cache.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableImage extends StatefulWidget {
  final Photo photo;
  final Function(bool) shouldDisableScroll;

  ZoomableImage(
    this.photo, {
    Key key,
    this.shouldDisableScroll,
  }) : super(key: key);

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  ImageProvider _imageProvider;
  bool _loadedThumbnail = false;
  bool _loadedFinalImage = false;
  ValueChanged<PhotoViewScaleState> _scaleStateChangedCallback;

  @override
  void initState() {
    _scaleStateChangedCallback = (value) {
      if (widget.shouldDisableScroll != null) {
        widget.shouldDisableScroll(value != PhotoViewScaleState.initial);
      }
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedThumbnail && !_loadedFinalImage) {
      final cachedThumbnail = ThumbnailLruCache.get(widget.photo);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedThumbnail = true;
      }
    }

    if (!_loadedFinalImage) {
      if (ImageLruCache.get(widget.photo) != null) {
        final bytes = ImageLruCache.get(widget.photo);
        _onFinalImageLoaded(bytes, context);
      } else {
        widget.photo.getBytes().then((bytes) {
          if (mounted) {
            setState(() {
              ImageLruCache.put(widget.photo, bytes);
              _onFinalImageLoaded(bytes, context);
            });
          }
        });
      }
    }

    if (_imageProvider != null) {
      return PhotoView(
        imageProvider: _imageProvider,
        scaleStateChangedCallback: _scaleStateChangedCallback,
        minScale: PhotoViewComputedScale.contained,
        gaplessPlayback: true,
      );
    } else {
      return loadWidget;
    }
  }

  void _onFinalImageLoaded(Uint8List bytes, BuildContext context) {
    final imageProvider = Image.memory(bytes).image;
    precacheImage(imageProvider, context).then((value) {
      if (mounted) {
        setState(() {
          _imageProvider = imageProvider;
          _loadedFinalImage = true;
        });
      }
    });
  }
}
