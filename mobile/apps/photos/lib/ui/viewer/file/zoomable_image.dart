import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import "package:flutter_image_compress/flutter_image_compress.dart";
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/events/file_caption_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/reset_zoom_of_photo_view_event.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/states/detail_page_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/image_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

class ZoomableImage extends StatefulWidget {
  final EnteFile photo;
  final Function(bool)? shouldDisableScroll;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;
  final bool shouldCover;
  final bool isGuestView;
  final Function({required int memoryDuration})? onFinalFileLoad;

  const ZoomableImage(
    this.photo, {
    super.key,
    this.shouldDisableScroll,
    required this.tagPrefix,
    this.backgroundDecoration,
    this.shouldCover = false,
    this.isGuestView = false,
    this.onFinalFileLoad,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  late Logger _logger;
  late EnteFile _photo;
  ImageProvider? _imageProvider;
  bool _loadedSmallThumbnail = false;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
  bool _loadedFinalImage = false;
  bool _convertToSupportedFormat = false;
  ValueChanged<PhotoViewScaleState>? _scaleStateChangedCallback;
  bool _isZooming = false;
  PhotoViewController _photoViewController = PhotoViewController();
  final _scaleStateController = PhotoViewScaleStateController();
  late final StreamSubscription<FileCaptionUpdatedEvent>
      _captionUpdatedSubscription;
  late final StreamSubscription<ResetZoomOfPhotoView> _resetZoomSubscription;

  // This is to prevent the app from crashing when loading 200MP images
  // https://github.com/flutter/flutter/issues/110331
  bool get isTooLargeImage => _photo.width * _photo.height > 100000000; //100MP

  @override
  void initState() {
    super.initState();
    _photo = widget.photo;
    _logger = Logger("ZoomableImage");
    _logger.info('initState for ${_photo.generatedID} with tag ${_photo.tag}');
    _scaleStateChangedCallback = (value) {
      if (widget.shouldDisableScroll != null) {
        widget.shouldDisableScroll!(value != PhotoViewScaleState.initial);
      }
      _isZooming = value != PhotoViewScaleState.initial;
      debugPrint("isZooming = $_isZooming, currentState $value");
      // _logger.info('is reakky zooming $_isZooming with state $value');
    };

    _captionUpdatedSubscription =
        Bus.instance.on<FileCaptionUpdatedEvent>().listen((event) {
      if (event.fileGeneratedID == _photo.generatedID) {
        if (mounted) {
          setState(() {});
        }
      }
    });

    _resetZoomSubscription =
        Bus.instance.on<ResetZoomOfPhotoView>().listen((event) {
      if (event.isSamePhoto(
        uploadedFileID: widget.photo.uploadedFileID,
        localID: widget.photo.localID,
      )) {
        _scaleStateController.scaleState = PhotoViewScaleState.initial;
      }
    });
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    _scaleStateController.dispose();
    _captionUpdatedSubscription.cancel();
    _resetZoomSubscription.cancel();
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
      content = PhotoViewGestureDetectorScope(
        axis: Axis.vertical,
        child: PhotoView(
          key: ValueKey(_loadedFinalImage),
          imageProvider: _imageProvider,
          controller: _photoViewController,
          filterQuality: FilterQuality.high,
          scaleStateController: _scaleStateController,
          scaleStateChangedCallback: _scaleStateChangedCallback,
          minScale: widget.shouldCover
              ? PhotoViewComputedScale.covered
              : PhotoViewComputedScale.contained,
          gaplessPlayback: true,
          heroAttributes: PhotoViewHeroAttributes(
            tag: widget.tagPrefix! + _photo.tag,
          ),
          backgroundDecoration: widget.backgroundDecoration as BoxDecoration?,
          loadingBuilder: (context, event) {
            // This is to make sure the hero anitmation animates and fits in the
            //dimensions of the image on screen.
            final screenDimensions = MediaQuery.sizeOf(context);
            late final double screenRelativeImageWidth;
            late final double screenRelativeImageHeight;
            final screenWidth = screenDimensions.width;
            final screenHeight = screenDimensions.height;

            final aspectRatioOfScreen = screenWidth / screenHeight;
            final aspectRatioOfImage = _photo.width / _photo.height;

            if (aspectRatioOfImage > aspectRatioOfScreen) {
              screenRelativeImageWidth = screenWidth;
              screenRelativeImageHeight = screenWidth / aspectRatioOfImage;
            } else if (aspectRatioOfImage < aspectRatioOfScreen) {
              screenRelativeImageHeight = screenHeight;
              screenRelativeImageWidth = screenHeight * aspectRatioOfImage;
            } else {
              screenRelativeImageWidth = screenWidth;
              screenRelativeImageHeight = screenHeight;
            }

            return Center(
              child: SizedBox(
                width: screenRelativeImageWidth,
                height: screenRelativeImageHeight,
                child: Hero(
                  tag: widget.tagPrefix! + _photo.tag,
                  child: const EnteLoadingWidget(
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      content = const EnteLoadingWidget(
        color: Colors.white,
      );
    }

    final GestureDragUpdateCallback? verticalDragCallback =
        _isZooming || widget.isGuestView
            ? null
            : (d) => {
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
      child: widget.photo.caption?.isNotEmpty ?? false
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                content,
                Positioned(
                  bottom: 72 + MediaQuery.paddingOf(context).bottom,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: InheritedDetailPageState.maybeOf(context)
                            ?.enableFullScreenNotifier ??
                        ValueNotifier(false),
                    builder: (context, doNotShowCaption, _) {
                      return AnimatedOpacity(
                        opacity: doNotShowCaption ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: doNotShowCaption,
                          child: GestureDetector(
                            onTap: () {
                              showDetailsSheet(context, widget.photo);
                            },
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.1),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8.0,
                                    ),
                                    child: SizedBox(
                                      width:
                                          MediaQuery.sizeOf(context).width - 16,
                                      child: Center(
                                        child: Text(
                                          widget.photo.caption!,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: getEnteTextTheme(context)
                                              .mini
                                              .copyWith(
                                                color: textBaseDark,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : content,
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
          _onFileLoaded(
            file,
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
          _onFileLoaded(
            file,
          );
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

  void _onFileLoaded(File file) {
    ImageProvider imageProvider;
    if (isTooLargeImage) {
      _logger.info(
        "Handling very large image (${_photo.width}x${_photo.height}) by decreasing resolution to 50MP to prevent crash",
      );
      final aspectRatio = _photo.width / _photo.height;
      const maxPixels = 50000000;
      final targetHeight = sqrt(maxPixels / aspectRatio);
      final targetWidth = aspectRatio * targetHeight;

      imageProvider = Image.file(
        file,
        gaplessPlayback: true,
        cacheWidth: targetWidth.round(),
        cacheHeight: targetHeight.round(),
      ).image;
    } else {
      imageProvider = Image.file(
        file,
        gaplessPlayback: true,
      ).image;
    }

    if (mounted) {
      precacheImage(
        imageProvider,
        context,
        onError: (exception, s) async {
          if (exception.toString().contains(
                    "Codec failed to produce an image, possibly due to invalid image data",
                  ) ||
              exception.toString().contains(
                    "Could not decompress image.",
                  )) {
            unawaited(_loadInSupportedFormat(file, e));
          } else {
            _logger.warning(
              "Failed to load image ${_photo.displayName} with error: $exception",
            );
          }
        },
      ).then((value) {
        if (mounted && !_loadedFinalImage && !_convertToSupportedFormat) {
          _updateViewWithFinalImage(imageProvider);
        }
      });
    }
  }

  Future<void> _updateViewWithFinalImage(ImageProvider imageProvider) async {
    await _updatePhotoViewController(
      previewImageProvider: _imageProvider,
      finalImageProvider: imageProvider,
    );
    setState(() {
      _imageProvider = imageProvider;
      _loadedFinalImage = true;
      _logger.info("Final image loaded");
    });
    widget.onFinalFileLoad?.call(memoryDuration: 5);
  }

  Future<void> _updatePhotoViewController({
    required ImageProvider? previewImageProvider,
    required ImageProvider finalImageProvider,
  }) async {
    final bool shouldFixPosition = previewImageProvider != null &&
        _isZooming &&
        _photoViewController.scale != null;
    ImageInfo? finalImageInfo;
    if (shouldFixPosition) {
      final prevImageInfo = await getImageInfo(previewImageProvider);
      finalImageInfo = await getImageInfo(finalImageProvider);
      final scale = _photoViewController.scale! /
          (finalImageInfo.image.width / prevImageInfo.image.width);
      final currentPosition = _photoViewController.value.position;
      _photoViewController = PhotoViewController(
        initialPosition: currentPosition,
        initialScale: scale,
      );
      // Fix for auto-zooming when final image is loaded after double tapping
      //twice.
      _scaleStateController.scaleState = PhotoViewScaleState.zoomedIn;
    }
    final bool canUpdateMetadata = _photo.canEditMetaInfo;
    // forcefully get finalImageInfo is dimensions are not available in metadata
    if (finalImageInfo == null && canUpdateMetadata && !_photo.hasDimensions) {
      finalImageInfo = await getImageInfo(finalImageProvider);
    }
  }

  bool _isGIF() => _photo.displayName.toLowerCase().endsWith(".gif");

  Future<void> _loadInSupportedFormat(
    File file,
    Object unsupportedErr,
  ) async {
    _logger.info(
      "Compressing ${_photo.displayName} to viewable format due to $unsupportedErr",
    );
    _convertToSupportedFormat = true;

    Uint8List? compressedFile;
    if (isTooLargeImage) {
      _logger.info(
        "Compressing very large image (${_photo.width}x${_photo.height}) more aggressively down to 50MP",
      );
      final aspectRatio = _photo.width / _photo.height;
      const maxPixels = 50000000;
      final targetHeight = sqrt(maxPixels / aspectRatio);
      final targetWidth = aspectRatio * targetHeight;

      compressedFile = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: targetWidth.round(),
        minHeight: targetHeight.round(),
        quality: 85,
      );
    } else {
      compressedFile = await FlutterImageCompress.compressWithFile(
        file.path,
        minHeight: 8000,
        minWidth: 8000,
      );
    }

    if (compressedFile != null) {
      final imageProvider = MemoryImage(compressedFile);

      unawaited(
        precacheImage(imageProvider, context).then((value) {
          if (mounted) {
            _updateViewWithFinalImage(imageProvider);
          }
        }),
      );
    } else {
      _logger.severe(
        "Failed to compress image ${_photo.displayName} to viewable format",
      );
    }
  }
}
