import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
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

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  ImageProvider _imageProvider;
  bool _loadedSmallThumbnail = false;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
  bool _loadedFinalImage = false;
  ValueChanged<PhotoViewScaleState> _scaleStateChangedCallback;
  // AnimationController _animationController;
  // Animation _animation;
  // VoidCallback _animationListener;
  final doubleTapScales = [1.0, 2.0];

  @override
  void initState() {
    _scaleStateChangedCallback = (value) {
      if (widget.shouldDisableScroll != null) {
        widget.shouldDisableScroll(value != PhotoViewScaleState.initial);
      }
    };
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 100),
    // );
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
      // return ExtendedImage(
      //   image: _imageProvider,
      //   gaplessPlayback: true,
      //   mode: ExtendedImageMode.gesture,
      //   enableSlideOutPage: true,
      //   initGestureConfigHandler: (state) {
      //     return GestureConfig(
      //       inPageView: true,
      //       initialScale: 1.0,
      //       minScale: 1.0,
      //     );
      //   },
      //   onDoubleTap: (ExtendedImageGestureState state) {
      //     var pointerDownPosition = state.pointerDownPosition;
      //     double begin = state.gestureDetails.totalScale;
      //     double end;
      //     _animation?.removeListener(_animationListener);
      //     _animationController.stop();
      //     _animationController.reset();
      //     if (begin == doubleTapScales[0]) {
      //       end = doubleTapScales[1];
      //     } else {
      //       end = doubleTapScales[0];
      //     }
      //     _animationListener = () {
      //       state.handleDoubleTap(
      //           scale: _animation.value,
      //           doubleTapPosition: pointerDownPosition);
      //     };
      //     _animation =
      //         _animationController.drive(Tween<double>(begin: begin, end: end));
      //     _animation.addListener(_animationListener);
      //     _animationController.forward();
      //   },
      // );
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
    if (!_loadedSmallThumbnail && widget.photo.thumbnailPath.isNotEmpty) {
      _imageProvider = Image.network(widget.photo.getThumbnailUrl()).image;
      _loadedSmallThumbnail = true;
    }
    if (!_loadedFinalImage) {
      widget.photo.getBytes().then((data) {
        _onFinalImageLoaded(Image.memory(data).image, context);
      });
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
        widget.photo
            .getAsset()
            .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
            .then((data) {
          _onLargeThumbnailLoaded(Image.memory(data).image, context);
          ThumbnailLruCache.put(widget.photo, THUMBNAIL_LARGE_SIZE, data);
        });
      }
    }

    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      final cachedFile = ImageLruCache.get(widget.photo);
      if (cachedFile != null) {
        final imageProvider = Image.file(cachedFile).image;
        _onFinalImageLoaded(imageProvider, context);
      } else {
        widget.photo.getAsset().file.then((file) {
          if (mounted) {
            final imageProvider = Image.file(file).image;
            _onFinalImageLoaded(imageProvider, context);
            ImageLruCache.put(widget.photo, file);
          }
        });
      }
    }
  }

  void _onLargeThumbnailLoaded(
      ImageProvider imageProvider, BuildContext context) {
    if (mounted && !_loadedFinalImage) {
      precacheImage(imageProvider, context).then((value) {
        if (mounted) {
          setState(() {
            _imageProvider = imageProvider;
            _loadedLargeThumbnail = true;
          });
        }
      });
    }
  }

  void _onFinalImageLoaded(ImageProvider imageProvider, BuildContext context) {
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
