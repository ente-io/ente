import 'dart:async';
import 'dart:io';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import "package:photo_view/photo_view_gallery.dart";
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/image_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

class ZoomableImage extends StatefulWidget {
  final EnteFile photo;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;
  final bool shouldCover;

  const ZoomableImage(
    this.photo, {
    Key? key,
    required this.tagPrefix,
    this.backgroundDecoration,
    this.shouldCover = false,
  }) : super(key: key);

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  late Logger _logger;
  late EnteFile _photo;
  ImageProvider? _imageProvider;
  bool _loadedSmallThumbnail = false;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
  bool _loadedFinalImage = false;
  PhotoViewController _photoViewController = PhotoViewController();
  bool _isZooming = false;
  ValueChanged<PhotoViewScaleState>? _scaleStateChangedCallback;

  @override
  void initState() {
    _photo = widget.photo;
    _logger = Logger("ZoomableImage");
    _logger.info('initState for ${_photo.generatedID} with tag ${_photo.tag}');
    _scaleStateChangedCallback = (value) {
      _isZooming = value != PhotoViewScaleState.initial;
      debugPrint("isZooming = $_isZooming, currentState $value");
    };
    super.initState();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photo.isRemoteFile) {
      _loadNetworkImage();
    } else {
      _loadLocalImage(context);
    }
    Widget content;

    if (_imageProvider != null) {
      content = PhotoViewGallery.builder(
        gaplessPlayback: true,
        scaleStateChangedCallback: _scaleStateChangedCallback,
        backgroundDecoration: widget.backgroundDecoration as BoxDecoration?,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: _imageProvider!,
            minScale: widget.shouldCover
                ? PhotoViewComputedScale.covered
                : PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.tagPrefix! + _photo.tag,
            ),
            controller: _photoViewController,
          );
        },
        itemCount: 1,
      );
    } else {
      content = const EnteLoadingWidget();
    }
    verticalDragCallback(d) => {
          if (!_isZooming)
            {
              if (d.delta.dy > dragSensitivity)
                {
                  {Navigator.of(context).pop()},
                }
              else if (d.delta.dy < (dragSensitivity * -1))
                {
                  showDetailsSheet(context, widget.photo),
                },
            },
        };

    return GestureDetector(
      onVerticalDragUpdate: verticalDragCallback,
      child: content,
    );
  }

  void _loadNetworkImage() {
    if (!_loadedSmallThumbnail && !_loadedFinalImage) {
      final cachedThumbnail = ThumbnailInMemoryLruCache.get(_photo);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedSmallThumbnail = true;
      } else {
        getThumbnailFromServer(_photo).then((file) {
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
    if (!_loadedFinalImage && !_loadingFinalImage) {
      _loadingFinalImage = true;
      getFileFromServer(_photo).then((file) {
        if (file != null) {
          _onFinalImageLoaded(
            Image.file(
              file,
              gaplessPlayback: true,
            ).image,
          );
        } else {
          _loadingFinalImage = false;
        }
      });
    }
  }

  void _loadLocalImage(BuildContext context) {
    if (!_loadedSmallThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      final cachedThumbnail =
          ThumbnailInMemoryLruCache.get(_photo, thumbnailSmallSize);
      if (cachedThumbnail != null) {
        _imageProvider = Image.memory(cachedThumbnail).image;
        _loadedSmallThumbnail = true;
      }
    }

    if (!_loadingLargeThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      _loadingLargeThumbnail = true;
      getThumbnailFromLocal(_photo, size: thumbnailLargeSize, quality: 100)
          .then((cachedThumbnail) {
        if (cachedThumbnail != null) {
          _onLargeThumbnailLoaded(Image.memory(cachedThumbnail).image, context);
        }
      });
    }

    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      getFile(
        _photo,
        isOrigin: Platform.isIOS &&
            _isGIF(), // since on iOS GIFs playback only when origin-files are loaded
      ).then((file) {
        if (file != null && file.existsSync()) {
          _onFinalImageLoaded(Image.file(file).image);
        } else {
          _logger.info("File was deleted " + _photo.toString());
          if (_photo.uploadedFileID != null) {
            _photo.localID = null;
            FilesDB.instance.update(_photo);
            _loadNetworkImage();
          } else {
            FilesDB.instance.deleteLocalFile(_photo);
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
      precacheImage(imageProvider, context).then((value) async {
        if (mounted) {
          await _updatePhotoViewController(
            previewImageProvider: _imageProvider,
            finalImageProvider: imageProvider,
          );
          setState(() {
            _imageProvider = imageProvider;
            _loadedFinalImage = true;
            _logger.info("Final image loaded");
          });
        }
      });
    }
  }

  Future<void> _updatePhotoViewController({
    required ImageProvider? previewImageProvider,
    required ImageProvider finalImageProvider,
  }) async {
    final bool shouldFixPosition = previewImageProvider != null && _isZooming;
    ImageInfo? finalImageInfo;
    if (shouldFixPosition) {
      final prevImageInfo = await getImageInfo(previewImageProvider);
      finalImageInfo = await getImageInfo(finalImageProvider);
      final scale = _photoViewController.scale! /
          (finalImageInfo.image.width / prevImageInfo.image.width);
      final currentPosition = _photoViewController.value.position;
      final positionScaleFactor = 1 / scale;
      final newPosition = currentPosition.scale(
        positionScaleFactor,
        positionScaleFactor,
      );
      _photoViewController = PhotoViewController(
        initialPosition: newPosition,
        initialScale: scale,
      );
    }
    final bool canUpdateMetadata = _photo.canEditMetaInfo;
    // forcefully get finalImageInfo is dimensions are not available in metadata
    if (finalImageInfo == null && canUpdateMetadata && !_photo.hasDimensions) {
      finalImageInfo = await getImageInfo(finalImageProvider);
    }
    if (finalImageInfo != null && canUpdateMetadata) {
      _updateAspectRatioIfNeeded(_photo, finalImageInfo).ignore();
    }
  }

  // Fallback logic to finish back fill and update aspect
  // ratio if needed.
  Future<void> _updateAspectRatioIfNeeded(
    EnteFile enteFile,
    ImageInfo imageInfo,
  ) async {
    final int h = imageInfo.image.height, w = imageInfo.image.width;
    if (h != enteFile.height || w != enteFile.width) {
      final logMessage =
          'Updating aspect ratio for from ${enteFile.height}x${enteFile.width} to ${h}x$w';
      _logger.info(logMessage);
      await FileMagicService.instance.updatePublicMagicMetadata([
        enteFile,
      ], {
        heightKey: h,
        widthKey: w,
      });
    }
  }

  bool _isGIF() => _photo.displayName.toLowerCase().endsWith(".gif");
}
