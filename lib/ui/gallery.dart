import 'dart:io';
import 'dart:math';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/image_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';

import 'change_notifier_builder.dart';
import 'detail_page.dart';

class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  Map<int, String> _months = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December",
  };

  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: photoLoader,
      builder: (_, __) {
        return DraggableScrollbar.semicircle(
          labelTextBuilder: (double offset) {
            int itemIndex = _scrollController.hasClients
                ? (_scrollController.offset /
                        _scrollController.position.maxScrollExtent *
                        photoLoader.getPhotos().length)
                    .floor()
                : 0;
            itemIndex = min(itemIndex, photoLoader.getPhotos().length);
            Photo photo = photoLoader.getPhotos()[itemIndex];
            var date =
                DateTime.fromMicrosecondsSinceEpoch(photo.createTimestamp);
            return Text(
              _months[date.month],
              style: TextStyle(color: Colors.black),
            );
          },
          labelConstraints: BoxConstraints.tightFor(width: 80.0, height: 30.0),
          controller: _scrollController,
          child: GridView.builder(
              itemBuilder: _buildItem,
              itemCount: photoLoader.getPhotos().length,
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              )),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var photo = photoLoader.getPhotos()[index];
    return GestureDetector(
      onTap: () {
        routeToDetailPage(photo, context);
      },
      onLongPress: () {
        _showPopup(photo, context);
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ImageWidget(photo),
      ),
    );
  }

  void _showPopup(Photo photo, BuildContext context) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Share"),
          isDefaultAction: true,
          onPressed: () {
            ShareExtend.share(photo.localPath, "image");
            Navigator.pop(context);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete"),
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            _showDeletePopup(photo, context);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  void _showDeletePopup(Photo photo, BuildContext context) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () {
            DatabaseHelper.instance.deletePhoto(photo).then((_) {
              File file = File(photo.localPath);
              file.delete().then((_) {
                photoLoader.reloadPhotos();
                Navigator.pop(context);
              });
            });
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () {
            DatabaseHelper.instance.markPhotoAsDeleted(photo).then((_) {
              File file = File(photo.localPath);
              file.delete().then((_) {
                photoLoader.reloadPhotos();
                Navigator.pop(context);
              });
            });
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  void routeToDetailPage(Photo photo, BuildContext context) {
    final page = DetailPage(photo);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
