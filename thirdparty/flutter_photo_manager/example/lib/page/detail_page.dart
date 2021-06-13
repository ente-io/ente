import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/util/common_util.dart';
import 'package:image_scanner_example/widget/video_widget.dart';
import 'package:photo_manager/photo_manager.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    Key? key,
    required this.entity,
    this.mediaUrl,
  }) : super(key: key);

  final AssetEntity entity;
  final String? mediaUrl;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool? useOrigin = true;

  @override
  Widget build(BuildContext context) {
    final originCheckbox = CheckboxListTile(
      title: Text("Use origin file."),
      onChanged: (value) {
        this.useOrigin = value;
        setState(() {});
      },
      value: useOrigin,
    );
    final children = <Widget>[
      Container(
        color: Colors.black,
        child: _buildContent(),
      ),
    ];

    if (widget.entity.type == AssetType.image) {
      children.insert(0, originCheckbox);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Asset detail"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  Widget _buildContent() {
    if (widget.entity.type == AssetType.video) {
      return buildVideo();
    } else if (widget.entity.type == AssetType.audio) {
      return buildVideo();
    } else {
      return buildImage();
    }
  }

  Widget buildImage() {
    return FutureBuilder<File?>(
      future: useOrigin == true ? widget.entity.originFile : widget.entity.file,
      builder: (_, snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Image.file(snapshot.data!);
      },
    );
  }

  Widget buildVideo() {
    if (widget.mediaUrl == null) {
      return const SizedBox.shrink();
    }
    return VideoWidget(
      isAudio: widget.entity.type == AssetType.audio,
      mediaUrl: widget.mediaUrl!,
    );
  }

  void _showInfo() async {
    await CommonUtil.showInfoDialog(context, widget.entity);
  }

  Widget buildAudio() {
    return Container(
      child: Center(
        child: Icon(Icons.audiotrack),
      ),
    );
  }
}
