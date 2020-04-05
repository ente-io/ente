import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/image_widget.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import 'change_notifier_builder.dart';
import 'detail_page.dart';

class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  Logger _logger = Logger();

  int _crossAxisCount = 4;

  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);

  @override
  Widget build(BuildContext context) {
    _logger.i("Build with _crossAxisCount: " + _crossAxisCount.toString());
    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        _logger.i("Scale update: " + details.horizontalScale.toString());
        setState(() {
          if (details.horizontalScale < 1) {
            _crossAxisCount = 8;
          } else if (details.horizontalScale < 2) {
            _crossAxisCount = 5;
          } else if (details.horizontalScale < 4) {
            _crossAxisCount = 4;
          } else if (details.horizontalScale < 8) {
            _crossAxisCount = 2;
          } else {
            _crossAxisCount = 1;
          }
        });
      },
      child: ChangeNotifierBuilder(
        value: photoLoader,
        builder: (_, __) {
          return GridView.builder(
              itemBuilder: _buildItem,
              itemCount: photoLoader.getPhotos().length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
              ));
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var photo = photoLoader.getPhotos()[index];
    return GestureDetector(
      onTap: () {
        routeToDetailPage(photo, context);
      },
      onLongPress: () {
        Toast.show(photo.localPath, context);
      },
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: ImageWidget(path: photo.thumbnailPath),
      ),
    );
  }

  void routeToDetailPage(Photo photo, BuildContext context) {
    final page = DetailPage(
      photo: photo,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
