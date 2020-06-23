import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/constants.dart';

class ZoomableImage extends StatefulWidget {
  final File photo;
  final Function(bool) shouldDisableScroll;

  ZoomableImage(
    this.photo, {
    Key key,
    this.shouldDisableScroll,
  }) : super(key: key);

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableImage");
  ImageProvider _imageProvider;
  bool _loadedSmallThumbnail = false;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
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
        heroAttributes: PhotoViewHeroAttributes(
          tag: widget.photo.generatedId.toString(),
        ),
      );
    } else {
      return loadWidget;
    }
  }

  void _loadNetworkImage() {
    if (!_loadedSmallThumbnail && widget.photo.previewURL.isNotEmpty) {
      _imageProvider =
          CachedNetworkImageProvider(widget.photo.getThumbnailUrl());
      _loadedSmallThumbnail = true;
    }
    if (!_loadedFinalImage) {
      if (BytesLruCache.get(widget.photo) != null) {
        _onFinalImageLoaded(
            Image.memory(
              BytesLruCache.get(widget.photo),
              gaplessPlayback: true,
            ).image,
            context);
      } else {
        widget.photo.getBytes().then((data) {
          _onFinalImageLoaded(
              Image.memory(
                data,
                gaplessPlayback: true,
              ).image,
              context);
          BytesLruCache.put(widget.photo, data);
        });
      }
    }
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

    if (!_loadingLargeThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      _loadingLargeThumbnail = true;
      final cachedThumbnail =
          ThumbnailLruCache.get(widget.photo, THUMBNAIL_LARGE_SIZE);
      if (cachedThumbnail != null) {
        _onLargeThumbnailLoaded(Image.memory(cachedThumbnail).image, context);
      } else {
        widget.photo.getAsset().then((asset) {
          asset
              .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
              .then((data) {
            _onLargeThumbnailLoaded(Image.memory(data).image, context);
            ThumbnailLruCache.put(widget.photo, THUMBNAIL_LARGE_SIZE, data);
          });
        });
      }
    }

    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      final cachedFile = FileLruCache.get(widget.photo);
      if (cachedFile != null) {
        _onFinalImageLoaded(Image.file(cachedFile).image, context);
      } else {
        widget.photo.getAsset().then((asset) {
          asset.file.then((file) {
            if (mounted) {
              _onFinalImageLoaded(Image.file(file).image, context);
              FileLruCache.put(widget.photo, file);
            }
          });
        });
      }
    }
  }

  void _onLargeThumbnailLoaded(
      ImageProvider imageProvider, BuildContext context) {
    if (mounted && !_loadedFinalImage) {
      precacheImage(imageProvider, context).then((value) {
        if (mounted && !_loadedFinalImage) {
          setState(() {
            _imageProvider = imageProvider;
            _loadedLargeThumbnail = true;
          });
        }
      });
    }
  }

  void _onFinalImageLoaded(ImageProvider imageProvider, BuildContext context) {
    if (mounted) {
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
}
