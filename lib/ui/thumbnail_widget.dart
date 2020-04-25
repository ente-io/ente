import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/thumbnail_cache.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/core/constants.dart';

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

  bool _loadedSmallThumbnail = false;
  bool _loadedLargeThumbnail = false;
  ImageProvider _imageProvider;

  @override
  Widget build(BuildContext context) {
    if (!_loadedSmallThumbnail && !_loadedLargeThumbnail) {
      final cachedSmallThumbnail =
          ThumbnailLruCache.get(widget.photo, THUMBNAIL_SMALL_SIZE);
      if (cachedSmallThumbnail != null) {
        _imageProvider = Image.memory(cachedSmallThumbnail).image;
        _loadedSmallThumbnail = true;
      } else {
        if (mounted) {
          widget.photo
              .getAsset()
              .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
              .then((data) {
            if (mounted) {
              setState(() {
                if (data != null) {
                  _imageProvider = Image.memory(data).image;
                }
                _loadedSmallThumbnail = true;
              });
            }
            ThumbnailLruCache.put(widget.photo, THUMBNAIL_SMALL_SIZE, data);
          });
        }
      }
    }

    if (!_loadedLargeThumbnail) {
      if (ThumbnailLruCache.get(widget.photo, THUMBNAIL_LARGE_SIZE) == null) {
        widget.photo
            .getAsset()
            .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
            .then((data) {
          ThumbnailLruCache.put(widget.photo, THUMBNAIL_LARGE_SIZE, data);
        });
      }
    }

    if (_imageProvider != null) {
      return Image(
        image: _imageProvider,
        gaplessPlayback: true,
        fit: BoxFit.cover,
      );
    } else {
      return loadingWidget;
    }
  }
}
