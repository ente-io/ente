import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class DetailPage extends StatefulWidget {
  final File file;
  final AssetEntity entity;

  const DetailPage({Key key, this.file, this.entity}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.black,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return buildImage();
  }

  Widget buildImage() {
    return Image.file(
      widget.file,
      filterQuality: FilterQuality.low,
    );
  }

  Widget buildInfoItem(String title, String info) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              title.padLeft(10, " "),
              textAlign: TextAlign.start,
            ),
            width: 88,
          ),
          Expanded(
            child: Text(info.padLeft(40, " ")),
          ),
        ],
      ),
    );
  }
}
