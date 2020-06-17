import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/sync_indicator.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Gallery extends StatefulWidget {
  final Future<List<Photo>> Function() loader;
  // TODO: Verify why the event is necessary when calling loader post onRefresh
  // should have done the job.
  final Stream<Event> reloadEvent;
  final Future<void> Function() onRefresh;
  final Set<Photo> selectedPhotos;
  final Function(Set<Photo>) onPhotoSelectionChange;

  Gallery(
    this.loader, {
    this.reloadEvent,
    this.onRefresh,
    this.selectedPhotos,
    this.onPhotoSelectionChange,
  });

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  final Logger _logger = Logger("Gallery");
  final ScrollController _scrollController = ScrollController();
  final List<List<Photo>> _collatedPhotos = List<List<Photo>>();

  bool _requiresLoad = false;
  AsyncSnapshot<List<Photo>> _lastSnapshot;
  Set<Photo> _selectedPhotos = HashSet<Photo>();
  List<Photo> _photos;
  RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    _requiresLoad = true;
    if (widget.reloadEvent != null) {
      widget.reloadEvent.listen((event) {
        setState(() {
          _requiresLoad = true;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_requiresLoad) {
      return _onSnapshotAvailable(_lastSnapshot);
    }
    return FutureBuilder<List<Photo>>(
      future: widget.loader(),
      builder: (context, snapshot) {
        _lastSnapshot = snapshot;
        return _onSnapshotAvailable(snapshot);
      },
    );
  }

  Widget _onSnapshotAvailable(AsyncSnapshot<List<Photo>> snapshot) {
    if (snapshot.hasData) {
      _requiresLoad = false;
      return _onDataLoaded(snapshot.data);
    } else if (snapshot.hasError) {
      _requiresLoad = false;
      return Center(child: Text(snapshot.error.toString()));
    } else {
      return Center(child: loadWidget);
    }
  }

  Widget _onDataLoaded(List<Photo> photos) {
    _photos = photos;
    if (_photos.isEmpty) {
      return Center(child: Text("Nothing to see here! 👀"));
    }
    _selectedPhotos = widget.selectedPhotos ?? Set<Photo>();
    _collatePhotos();
    final list = ListView.builder(
      itemCount: _collatedPhotos.length,
      itemBuilder: _buildListItem,
      controller: _scrollController,
      cacheExtent: 1000,
    );
    if (widget.onRefresh != null) {
      return SmartRefresher(
        controller: _refreshController,
        child: list,
        header: SyncIndicator(_refreshController),
        onRefresh: () {
          widget.onRefresh().then((_) {
            _refreshController.refreshCompleted();
            widget.loader().then((_) => setState(() {
                  _requiresLoad = true;
                }));
          }).catchError((e) {
            _refreshController.refreshFailed();
            setState(() {});
          });
        },
      );
    } else {
      return list;
    }
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
          _routeToDetailPage(photo, context);
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
          tag: photo.generatedId.toString(),
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
      widget.onPhotoSelectionChange(_selectedPhotos);
    });
  }

  void _routeToDetailPage(Photo photo, BuildContext context) {
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
