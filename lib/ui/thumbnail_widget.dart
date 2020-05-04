import 'package:flutter/material.dart';
import 'package:photos/core/thumbnail_cache.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/core/constants.dart';

class ThumbnailWidget extends StatefulWidget {
  final Photo photo;

  const ThumbnailWidget(
    this.photo, {
    Key key,
  }) : super(key: key);
  @override
  _ThumbnailWidgetState createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  static final Widget loadingWidget = Container(
    alignment: Alignment.center,
    color: Colors.grey[500],
  );

  bool _hasLoadedThumbnail = false;
  ImageProvider _imageProvider;

  @override
  Widget build(BuildContext context) {
    if (!_hasLoadedThumbnail) {
      final cachedSmallThumbnail =
          ThumbnailLruCache.get(widget.photo, THUMBNAIL_SMALL_SIZE);
      if (cachedSmallThumbnail != null) {
        final imageProvider = Image.memory(cachedSmallThumbnail).image;
        precacheImage(imageProvider, context).then((value) {
          if (mounted) {
            setState(() {
              _imageProvider = imageProvider;
              _hasLoadedThumbnail = true;
            });
          }
        });
      } else {
        widget.photo
            .getAsset()
            .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
            .then((data) {
          if (mounted) {
            setState(() {
              if (data != null) {
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
            });
          }
          ThumbnailLruCache.put(widget.photo, THUMBNAIL_SMALL_SIZE, data);
        });
      }
    }

    if (_imageProvider != null) {
      return Image(
        image: _imageProvider,
        fit: BoxFit.cover,
      );
    } else {
      return loadingWidget;
    }
  }

  @override
  void didUpdateWidget(ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photo.generatedId != oldWidget.photo.generatedId) {
      setState(() {
        _hasLoadedThumbnail = false;
        _imageProvider = null;
      });
    }
  }
}
