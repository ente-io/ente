import 'dart:io';

import 'package:flutter/material.dart';

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
        child: Image.file(
          widget.file,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}
