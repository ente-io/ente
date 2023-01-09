import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

class ZoomableImage extends StatefulWidget {
  final File? photo;
  final Function(bool)? shouldDisableScroll;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;

  const ZoomableImage(
    this.photo, {
    Key? key,
    this.shouldDisableScroll,
    required this.tagPrefix,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableImage");
  File? _photo;
  ImageProvider? _imageProvider;
  bool _loadedSmallThumbnail = false;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
  bool _loadedFinalImage = false;
  ValueChanged<PhotoViewScaleState>? _scaleStateChangedCallback;
  bool _isZooming = false;

  @override
  void initState() {
    _photo = widget.photo;
    debugPrint('initState for ${_photo.toString()}');
    _scaleStateChangedCallback = (value) {
      if (widget.shouldDisableScroll != null) {
        widget.shouldDisableScroll!(value != PhotoViewScaleState.initial);
      }
      _isZooming = value != PhotoViewScaleState.initial;
      debugPrint("isZooming = $_isZooming, currentState $value");
      // _logger.info('is reakky zooming $_isZooming with state $value');
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_photo!.isRemoteFile) {
      _loadNetworkImage();
    } else {
      _loadLocalImage(context);
    }
    Widget content;

    if (_imageProvider != null) {
      content = PhotoViewGestureDetectorScope(
        axis: Axis.vertical,
        child: PhotoView(
          imageProvider: _imageProvider,
          scaleStateChangedCallback: _scaleStateChangedCallback,
          minScale: PhotoViewComputedScale.contained,
          gaplessPlayback: true,
          heroAttributes: PhotoViewHeroAttributes(
            tag: widget.tagPrefix! + _photo!.tag,
          ),
          backgroundDecoration: widget.backgroundDecoration as BoxDecoration?,
        ),
      );
    } else {
      content = const EnteLoadingWidget();
    }

    final GestureDragUpdateCallback? verticalDragCallback = _isZooming
        ? null
        : (d) => {
              if (!_isZooming && d.delta.dy > dragSensitivity)
                {Navigator.of(context).pop()}
            };
    return GestureDetector(
      onVerticalDragUpdate: verticalDragCallback,
      child: content,
    );
  }

  void _loadNetworkImage() {
    if (!_loadedSmallThumbnail && !_loadedFinalImage) {
      final cachedThumbnail = ThumbnailLruCache.get(_photo!);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedSmallThumbnail = true;
      } else {
        getThumbnailFromServer(_photo!).then((file) {
          final imageProvider = Image.memory(file).image;
          if (mounted) {
            precacheImage(imageProvider, context).then((value) {
              if (mounted) {
                setState(() {
                  _imageProvider = imageProvider;
                  _loadedSmallThumbnail = true;
                });
              }
            }).catchError((e) {
              _logger.severe("Could not load image " + _photo.toString());
              _loadedSmallThumbnail = true;
            });
          }
        });
      }
    }
    if (!_loadedFinalImage) {
      getFileFromServer(_photo!).then((file) {
        _onFinalImageLoaded(
          Image.file(
            file!,
            gaplessPlayback: true,
          ).image,
        );
      });
    }
  }

  void _loadLocalImage(BuildContext context) {
    if (!_loadedSmallThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      final cachedThumbnail =
          ThumbnailLruCache.get(_photo!, thumbnailSmallSize);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedSmallThumbnail = true;
      }
    }

    if (!_loadingLargeThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      _loadingLargeThumbnail = true;
      getThumbnailFromLocal(_photo!, size: thumbnailLargeSize, quality: 100)
          .then((cachedThumbnail) {
        if (cachedThumbnail != null) {
          _onLargeThumbnailLoaded(Image.memory(cachedThumbnail).image, context);
        }
      });
    }

    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      getFile(
        _photo!,
        isOrigin: Platform.isIOS &&
            _isGIF(), // since on iOS GIFs playback only when origin-files are loaded
      ).then((file) {
        if (file != null && file.existsSync()) {
          _onFinalImageLoaded(Image.file(file).image);
        } else {
          _logger.info("File was deleted " + _photo.toString());
          if (_photo!.uploadedFileID != null) {
            _photo!.localID = null;
            FilesDB.instance.update(_photo!);
            _loadNetworkImage();
          } else {
            FilesDB.instance.deleteLocalFile(_photo!);
            Bus.instance.fire(
              LocalPhotosUpdatedEvent(
                [_photo],
                type: EventType.deletedFromDevice,
                source: "zoomPreview",
              ),
            );
          }
        }
      });
    }
  }

  void _onLargeThumbnailLoaded(
    ImageProvider imageProvider,
    BuildContext context,
  ) {
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

  void _onFinalImageLoaded(ImageProvider imageProvider) {
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

  bool _isGIF() => _photo!.displayName.toLowerCase().endsWith(".gif");
}
