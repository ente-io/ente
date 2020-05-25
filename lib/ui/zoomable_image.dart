import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/constants.dart';

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
  bool _loadedSmallThumbnail = false;
  bool _loadedLargeThumbnail = false;
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
    if (widget.photo.localId == null) {
      _loadNetworkImage();
    } else {
      _loadLocalImage(context);
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

  void _loadNetworkImage() {
    _imageProvider = Image.network(Configuration.instance.getHttpEndpoint() +
            "/" +
            widget.photo.remotePath)
        .image;
  }

  void _loadLocalImage(BuildContext context) {
    if (!_loadedSmallThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      final cachedThumbnail =
          ThumbnailLruCache.get(widget.photo, THUMBNAIL_SMALL_SIZE);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedSmallThumbnail = true;
      }
    }

    if (!_loadedLargeThumbnail && !_loadedFinalImage) {
      final cachedThumbnail =
          ThumbnailLruCache.get(widget.photo, THUMBNAIL_LARGE_SIZE);
      if (cachedThumbnail != null) {
        _onLargeThumbnailLoaded(Image.memory(cachedThumbnail).image, context);
      } else {
        widget.photo
            .getAsset()
            .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
            .then((data) {
          _onLargeThumbnailLoaded(Image.memory(data).image, context);
          ThumbnailLruCache.put(widget.photo, THUMBNAIL_LARGE_SIZE, data);
        });
      }
    }

    if (!_loadedFinalImage) {
      final cachedFile = ImageLruCache.get(widget.photo);
      if (cachedFile != null) {
        _onFinalImageLoaded(cachedFile, context);
      } else {
        widget.photo.getAsset().file.then((file) {
          if (mounted) {
            setState(() {
              _onFinalImageLoaded(file, context);
              ImageLruCache.put(widget.photo, file);
            });
          }
        });
      }
    }
  }

  void _onLargeThumbnailLoaded(
      ImageProvider imageProvider, BuildContext context) {
    precacheImage(imageProvider, context).then((value) {
      if (mounted) {
        setState(() {
          _imageProvider = imageProvider;
          _loadedLargeThumbnail = true;
        });
      }
    });
  }

  void _onFinalImageLoaded(File file, BuildContext context) {
    final imageProvider = Image.file(file).image;
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
