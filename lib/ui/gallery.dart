import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_sync_manager.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Gallery extends StatefulWidget {
  final List<Photo> photos;
  final Set<Photo> selectedPhotos;
  final Function(Set<Photo>) photoSelectionChangeCallback;

  Gallery(this.photos, this.selectedPhotos,
      {this.photoSelectionChangeCallback});

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  final ScrollController _scrollController = ScrollController();
  final List<List<Photo>> _collatedPhotos = List<List<Photo>>();
  Set<Photo> _selectedPhotos = HashSet<Photo>();
  List<Photo> _photos;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    // TODO: Investigate reason for multiple rebuilds on selection change
    _photos = widget.photos;
    _selectedPhotos = widget.selectedPhotos;
    _deduplicatePhotos();
    _collatePhotos();

    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      child: ListView.builder(
        itemCount: _collatedPhotos.length,
        itemBuilder: _buildListItem,
        controller: _scrollController,
        cacheExtent: 1000,
      ),
      header: ClassicHeader(
        idleText: "Pull down to sync.",
        refreshingText: "Syncing...",
        releaseText: "Release to sync.",
        completeText: "Sync completed.",
        failedText: "Sync unsuccessful.",
      ),
      onRefresh: () async {
        PhotoSyncManager.instance.sync().then((value) {
          _refreshController.refreshCompleted();
        }).catchError((e) {
          _refreshController.refreshFailed();
        });
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    var photos = _collatedPhotos[index];
    return Column(
      children: <Widget>[
        _getDay(photos[0].createTimestamp),
        _getGallery(photos)
      ],
    );
  }

  Widget _getDay(int timestamp) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.centerLeft,
      child: Text(
        getDayAndMonth(DateTime.fromMicrosecondsSinceEpoch(timestamp)),
        style: TextStyle(fontSize: 16),
      ),
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
        if (_selectedPhotos.isNotEmpty) {
          _selectPhoto(photo);
        } else {
          routeToDetailPage(photo, context);
        }
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        _selectPhoto(photo);
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: _selectedPhotos.contains(photo)
              ? Border.all(width: 4.0, color: Colors.blue)
              : null,
        ),
        child: Hero(
          tag: photo.hashCode,
          child: ThumbnailWidget(photo),
        ),
      ),
    );
  }

  void _selectPhoto(Photo photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        _selectedPhotos.add(photo);
      }
      widget.photoSelectionChangeCallback(_selectedPhotos);
    });
  }

  void routeToDetailPage(Photo photo, BuildContext context) {
    final page = DetailPage(
      _photos,
      _photos.indexOf(photo),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _deduplicatePhotos() {
    for (int index = 1; index < _photos.length; index++) {
      final current = _photos[index], previous = _photos[index - 1];
      if (current.localId != null && current.localId == previous.localId) {
        _photos.removeAt(index);
        index--;
      }
    }
  }

  void _collatePhotos() {
    final dailyPhotos = List<Photo>();
    final collatedPhotos = List<List<Photo>>();
    for (int index = 0; index < _photos.length; index++) {
      if (index > 0 &&
          !_arePhotosFromSameDay(_photos[index], _photos[index - 1])) {
        var collatedDailyPhotos = List<Photo>();
        collatedDailyPhotos.addAll(dailyPhotos);
        collatedPhotos.add(collatedDailyPhotos);
        dailyPhotos.clear();
      }
      dailyPhotos.add(_photos[index]);
    }
    if (dailyPhotos.isNotEmpty) {
      collatedPhotos.add(dailyPhotos);
    }
    _collatedPhotos.clear();
    _collatedPhotos.addAll(collatedPhotos);
  }

  bool _arePhotosFromSameDay(Photo firstPhoto, Photo secondPhoto) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(firstPhoto.createTimestamp);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(secondPhoto.createTimestamp);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}
