import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:share_extend/share_extend.dart';

class DetailPage extends StatefulWidget {
  final Photo photo;
  final String url;

  const DetailPage({Key key, this.photo, this.url}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ShareExtend.share(widget.photo.localPath, "image");
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
      child: ImageLruCache.getData(widget.photo.localPath) == null
          ? Image.file(
              File(widget.photo.localPath),
              filterQuality: FilterQuality.low,
            )
          : ImageLruCache.getData(widget.photo.localPath),
    );
  }
}
