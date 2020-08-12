import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'dart:io' as io;
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/models/file.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

class ThumbnailWidget extends StatefulWidget {
  final File file;
  final BoxFit fit;
  const ThumbnailWidget(
    this.file, {
    Key key,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  @override
  _ThumbnailWidgetState createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  static final _logger = Logger("ThumbnailWidget");
  static final Widget loadingWidget = Container(
    alignment: Alignment.center,
    color: Colors.grey[800],
  );

  bool _hasLoadedThumbnail = false;
  bool _encounteredErrorLoadingThumbnail = false;
  ImageProvider _imageProvider;

  @override
  Widget build(BuildContext context) {
    var image;
    if (widget.file.localID == null) {
      image = _getNetworkImage();
    } else {
      _loadLocalImage(context);
      if (_imageProvider != null) {
        image = Image(
          image: _imageProvider,
          fit: widget.fit,
        );
      }
    }
    var content;
    if (image != null) {
      if (widget.file.fileType == FileType.video) {
        content = Stack(
          children: [
            image,
            Icon(Icons.play_circle_outline),
          ],
          fit: StackFit.expand,
        );
      } else {
        content = image;
      }
    }
    return Stack(
      children: [
        loadingWidget,
        AnimatedOpacity(
          opacity: content == null ? 0 : 1.0,
          duration: Duration(milliseconds: 400),
          child: content,
        ),
      ],
      fit: StackFit.expand,
    );
  }

  void _loadLocalImage(BuildContext context) {
    if (!_hasLoadedThumbnail && !_encounteredErrorLoadingThumbnail) {
      final cachedSmallThumbnail =
          ThumbnailLruCache.get(widget.file, THUMBNAIL_SMALL_SIZE);
      if (cachedSmallThumbnail != null) {
        _imageProvider = Image.memory(cachedSmallThumbnail).image;
        _hasLoadedThumbnail = true;
      } else {
        widget.file.getAsset().then((asset) async {
          if (asset == null) {
            await deleteFiles([widget.file]);
            await FileRepository.instance.reloadFiles();
            return;
          }
          asset
              .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
              .then((data) {
            if (data != null && mounted) {
              final imageProvider = Image.memory(data).image;
              precacheImage(imageProvider, context).then((value) {
                if (mounted) {
                  setState(() {
                    _imageProvider = imageProvider;
                    _hasLoadedThumbnail = true;
                  });
                }
              });
            }
            ThumbnailLruCache.put(widget.file, THUMBNAIL_SMALL_SIZE, data);
          });
        }).catchError((e) {
          _logger.warning("Could not load image: ", e);
          _encounteredErrorLoadingThumbnail = true;
        });
      }
    }
  }

  Widget _getNetworkImage() {
    if (!widget.file.isEncrypted) {
      return CachedNetworkImage(
        imageUrl: widget.file.getThumbnailUrl(),
        placeholder: (context, url) => loadWidget,
        errorWidget: (context, url, error) => Icon(Icons.error),
        fit: BoxFit.cover,
      );
    } else {
      if (FileLruCache.get(widget.file) != null) {
        return Image.file(
          FileLruCache.get(widget.file),
          fit: widget.fit,
        );
      }
      final thumbnailPath = Configuration.instance.getThumbnailsDirectory() +
          widget.file.generatedID.toString() +
          ".jpg";
      final thumbnailFile = io.File(thumbnailPath);
      if (thumbnailFile.existsSync()) {
        FileLruCache.put(widget.file, thumbnailFile);
        return Image.file(
          thumbnailFile,
          fit: widget.fit,
        );
      } else {
        final temporaryPath = Configuration.instance.getTempDirectory() +
            widget.file.generatedID.toString() +
            "_thumbnail.aes";
        final decryptedFileFuture = Dio()
            .download(widget.file.getThumbnailUrl(), temporaryPath)
            .then((_) async {
          await CryptoUtil.decryptFileToFile(
              temporaryPath, thumbnailPath, Configuration.instance.getKey());
          io.File(temporaryPath).deleteSync();
          return io.File(thumbnailPath);
        });
        return FutureBuilder<io.File>(
          future: decryptedFileFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              FileLruCache.put(widget.file, snapshot.data);
              return Image.file(
                snapshot.data,
                fit: widget.fit,
              );
            } else if (snapshot.hasError) {
              _logger.warning(snapshot.error);
              return Text(snapshot.error.toString());
            } else {
              return loadingWidget;
            }
          },
        );
      }
    }
  }

  @override
  void didUpdateWidget(ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file.generatedID != oldWidget.file.generatedID) {
      setState(() {
        _hasLoadedThumbnail = false;
        _imageProvider = null;
      });
    }
  }
}
