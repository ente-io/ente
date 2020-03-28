import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/image_widget.dart';
import 'package:provider/provider.dart';

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
  
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  
  @override
  Widget build(BuildContext context) {
    _logger.i("Build");
    return ChangeNotifierBuilder(
      value: photoLoader,
      builder: (_, __) {
        return GridView.builder(
          itemBuilder: _buildItem,
          itemCount: photoLoader.getPhotos().length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var file = File(photoLoader.getPhotos()[index].localPath);
    return GestureDetector(
      onTap: () async {
        routeToDetailPage(file, context);
      },
      child: Hero(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: ImageWidget(path: file.path),
        ),
        tag: 'photo_' + file.path,
      ),
    );
  }

  void routeToDetailPage(File file, BuildContext context) async {
    final page = DetailPage(
      file: file,
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
