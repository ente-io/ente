import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/ui/file_info_dialog.dart';
import 'package:photos/utils/share_util.dart';

class FadingBottomBar extends StatefulWidget {
  final File file;
  final Function(File) onEditRequested;

  FadingBottomBar(
    this.file, this.onEditRequested, {
    Key key,
  }) : super(key: key);

  @override
  FadingBottomBarState createState() => FadingBottomBarState();
}

class FadingBottomBarState extends State<FadingBottomBar> {
  bool _shouldHide = false;

  @override
  Widget build(BuildContext context) {
    return _getBottomBar();
  }

  void hide() {
    setState(() {
      _shouldHide = true;
    });
  }

  void show() {
    setState(() {
      _shouldHide = false;
    });
  }

  Widget _getBottomBar() {
    List<Widget> children = [];
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: IconButton(
          icon: Icon(
              Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info),
          onPressed: () {
            _displayInfo(widget.file);
          },
        ),
      ),
    );
    if (widget.file.fileType == FileType.image) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.tune_outlined),
            onPressed: () {
              widget.onEditRequested(widget.file);
            },
          ),
        ),
      );
    }
    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: IconButton(
          icon: Icon(
              Platform.isAndroid ? Icons.share_outlined : CupertinoIcons.share),
          onPressed: () {
            share(context, [widget.file]);
          },
        ),
      ),
    );
    return AnimatedOpacity(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.64),
              ],
              stops: [0, 0.8, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            ),
          ),
        ),
      ),
      opacity: _shouldHide ? 0 : 1,
      duration: Duration(milliseconds: 150),
    );
  }

  Future<void> _displayInfo(File file) async {
    AssetEntity asset;
    int fileSize;
    final isLocalFile = file.localID != null;
    if (isLocalFile) {
      asset = await file.getAsset();
      fileSize = await (await asset.originFile).length();
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return FileInfoWidget(file, asset, fileSize);
      },
    );
  }
}
