import 'dart:io' as io;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/utils/crypto_util.dart';

class ZoomableImage extends StatefulWidget {
  final File photo;
  final Function(bool) shouldDisableScroll;
  final String tagPrefix;
  final Decoration backgroundDecoration;

  ZoomableImage(
    this.photo, {
    Key key,
    this.shouldDisableScroll,
    @required this.tagPrefix,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableImage");
  File _photo;
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
    _photo = widget.photo;
    if (_photo.localID == null) {
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
          tag: widget.tagPrefix + _photo.tag(),
        ),
        backgroundDecoration: widget.backgroundDecoration,
      );
    } else {
      return loadWidget;
    }
  }

  void _loadNetworkImage() {
    if (!_photo.isEncrypted) {
      _loadUnencryptedImage();
    } else {
      _loadEncryptedImage();
    }
  }

  void _loadUnencryptedImage() {
    if (!_loadedSmallThumbnail && !_loadedFinalImage) {
      _imageProvider = CachedNetworkImageProvider(_photo.getThumbnailUrl());
      _loadedSmallThumbnail = true;
    }
    if (!_loadedFinalImage) {
      DefaultCacheManager().getSingleFile(_photo.getDownloadUrl()).then((file) {
        _onFinalImageLoaded(
            Image.file(
              file,
              gaplessPlayback: true,
            ).image,
            context);
      });
    }
  }

  void _loadEncryptedImage() {
    if (!_loadedSmallThumbnail && !_loadedFinalImage) {
      if (ThumbnailFileLruCache.get(_photo) != null) {
        _imageProvider = Image.file(
          ThumbnailFileLruCache.get(_photo),
        ).image;
        _loadedSmallThumbnail = true;
      }
    }
    if (!_loadedFinalImage) {
      final url = _photo.getDownloadUrl();
      DefaultCacheManager().getFileFromCache(url).then((info) {
        if (info == null) {
          final temporaryPath = Configuration.instance.getTempDirectory() +
              _photo.generatedID.toString() +
              ".aes";
          Dio().download(url, temporaryPath).then((_) async {
            final data = await CryptoUtil.decryptFileToData(
                temporaryPath, Configuration.instance.getKey());
            io.File(temporaryPath).deleteSync();
            DefaultCacheManager().putFile(url, data);
            _onFinalImageLoaded(
                Image.memory(
                  data,
                  gaplessPlayback: true,
                ).image,
                context);
          });
        } else {
          _onFinalImageLoaded(
              Image.memory(
                info.file.readAsBytesSync(),
                gaplessPlayback: true,
              ).image,
              context);
        }
      });
    }
  }

  void _loadLocalImage(BuildContext context) {
    if (!_loadedSmallThumbnail &&
        !_loadedLargeThumbnail &&
        !_loadedFinalImage) {
      final cachedThumbnail =
          ThumbnailLruCache.get(_photo, THUMBNAIL_SMALL_SIZE);
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
          ThumbnailLruCache.get(_photo, THUMBNAIL_LARGE_SIZE);
      if (cachedThumbnail != null) {
        _onLargeThumbnailLoaded(Image.memory(cachedThumbnail).image, context);
      } else {
        _photo.getAsset().then((asset) {
          asset
              .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
              .then((data) {
            _onLargeThumbnailLoaded(Image.memory(data).image, context);
            ThumbnailLruCache.put(_photo, THUMBNAIL_LARGE_SIZE, data);
          });
        });
      }
    }

    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      final cachedFile = FileLruCache.get(_photo);
      if (cachedFile != null) {
        _onFinalImageLoaded(Image.file(cachedFile).image, context);
      } else {
        _photo.getAsset().then((asset) {
          asset.file.then((file) {
            if (mounted) {
              _onFinalImageLoaded(Image.file(file).image, context);
              FileLruCache.put(_photo, file);
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
