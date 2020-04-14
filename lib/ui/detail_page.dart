import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:share_extend/share_extend.dart';

class DetailPage extends StatelessWidget {
  final Photo photo;

  const DetailPage(this.photo, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Logger().i(photo.localPath);
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ShareExtend.share(photo.localPath, "image");
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        Navigator.pop(context);
      },
      child: ImageLruCache.getData(photo.localPath) == null
          ? Image.file(
              File(photo.localPath),
              filterQuality: FilterQuality.low,
            )
          : ImageLruCache.getData(photo.localPath),
    );
  }
}
