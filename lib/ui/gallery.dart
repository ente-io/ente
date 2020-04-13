import 'dart:io';
import 'dart:math';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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

  Map<int, String> _days = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday",
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
                        photoLoader.collatedPhotos.length)
                    .floor()
                : 0;
            itemIndex = min(itemIndex, photoLoader.collatedPhotos.length);
            var photos = photoLoader.collatedPhotos[itemIndex];
            var date =
                DateTime.fromMicrosecondsSinceEpoch(photos[0].createTimestamp);
            return Text(
              _months[date.month],
              style: TextStyle(color: Colors.black),
            );
          },
          labelConstraints: BoxConstraints.tightFor(width: 80.0, height: 30.0),
          controller: _scrollController,
          child: ListView.builder(
            itemCount: photoLoader.collatedPhotos.length,
            itemBuilder: _buildListItem,
            controller: _scrollController,
          ),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    var photos = photoLoader.collatedPhotos[index];
    return Column(
      children: <Widget>[_getDay(photos), _getGallery(photos)],
    );
  }

  Widget _getDay(List<Photo> photos) {
    var date = DateTime.fromMicrosecondsSinceEpoch(photos[0].createTimestamp);
    return Container(
      padding: const EdgeInsets.all(4.0),
      alignment: Alignment.centerLeft,
      child: Text(_days[date.weekday] +
          ", " +
          _months[date.month] +
          " " +
          date.day.toString()),
    );
  }

  Widget _getGallery(List<Photo> photos) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 12),
      physics: ScrollPhysics(), // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return _buildPhoto(context, photos[index]);
      },
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
    );
  }

  Widget _buildPhoto(BuildContext context, Photo photo) {
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
