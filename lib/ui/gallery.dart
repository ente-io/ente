import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/core/thumbnail_cache.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/detail_page.dart';
import 'package:myapp/ui/thumbnail_widget.dart';
import 'package:myapp/utils/date_time_util.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:myapp/core/constants.dart';

class Gallery extends StatefulWidget {
  final List<Photo> photos;
  final Function(Set<Photo>) photoSelectionChangeCallback;

  Gallery(this.photos, {this.photoSelectionChangeCallback});

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  final ScrollController _scrollController = ScrollController();
  final List<List<Photo>> _collatedPhotos = List<List<Photo>>();
  final Set<Photo> _selectedPhotos = HashSet<Photo>();
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  bool _shouldSelectOnTap = false;

  @override
  Widget build(BuildContext context) {
    _collatePhotos();

    return ListView.builder(
      itemCount: _collatedPhotos.length,
      itemBuilder: _buildListItem,
      controller: _scrollController,
      cacheExtent: 2000,
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
        if (_shouldSelectOnTap) {
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
        child: GalleryItemWidget(photo),
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
      if (_selectedPhotos.isNotEmpty) {
        _shouldSelectOnTap = true;
      } else {
        _shouldSelectOnTap = false;
      }
      widget.photoSelectionChangeCallback(_selectedPhotos);
    });
  }

  void routeToDetailPage(Photo photo, BuildContext context) {
    final page = DetailPage(widget.photos, widget.photos.indexOf(photo));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _collatePhotos() {
    final dailyPhotos = List<Photo>();
    final collatedPhotos = List<List<Photo>>();
    for (int index = 0; index < widget.photos.length; index++) {
      if (index > 0 &&
          !_arePhotosFromSameDay(
              widget.photos[index], widget.photos[index - 1])) {
        var collatedDailyPhotos = List<Photo>();
        collatedDailyPhotos.addAll(dailyPhotos);
        collatedPhotos.add(collatedDailyPhotos);
        dailyPhotos.clear();
      }
      dailyPhotos.add(widget.photos[index]);
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

class GalleryItemWidget extends StatefulWidget {
  final Photo photo;

  const GalleryItemWidget(
    this.photo, {
    Key key,
  }) : super(key: key);

  @override
  _GalleryItemWidgetState createState() => _GalleryItemWidgetState();
}

class _GalleryItemWidgetState extends State<GalleryItemWidget> {
  bool _isVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.photo.generatedId.toString()),
      child: ThumbnailWidget(widget.photo),
      onVisibilityChanged: (info) {
        _isVisible = info.visibleFraction == 1;
        if (_isVisible && !_isLoading) {
          _isLoading = true;
          _scheduleCaching();
        }
      },
    );
  }

  void _scheduleCaching() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (!_isVisible) {
        _isLoading = false;
        return;
      }
      if (ThumbnailLruCache.get(widget.photo, THUMBNAIL_LARGE_SIZE) == null) {
        widget.photo
            .getAsset()
            .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE)
            .then((data) {
          ThumbnailLruCache.put(widget.photo, THUMBNAIL_LARGE_SIZE, data);
        });
      }
    });
  }
}
