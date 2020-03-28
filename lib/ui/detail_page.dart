import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/core/lru_map.dart';

class DetailPage extends StatefulWidget {
  final File file;

  const DetailPage({Key key, this.file}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      child: Hero(
        tag: 'photo_' + widget.file.path,
        child: ImageLruCache.getData(widget.file.path) == null
            ? Image.file(
                widget.file,
                filterQuality: FilterQuality.low,
              )
            : ImageLruCache.getData(widget.file.path),
      ),
    );
  }
}
