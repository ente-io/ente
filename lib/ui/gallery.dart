import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/sync_indicator.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Gallery extends StatefulWidget {
  final Future<List<File>> Function() loader;
  // TODO: Verify why the event is necessary when calling loader post onRefresh
  // should have done the job.
  final Stream<Event> reloadEvent;
  final Future<void> Function() onRefresh;
  final Set<File> selectedFiles;
  final Function(Set<File>) onFileSelectionChange;

  Gallery(
    this.loader, {
    this.reloadEvent,
    this.onRefresh,
    this.selectedFiles,
    this.onFileSelectionChange,
  });

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  final Logger _logger = Logger("Gallery");
  final ScrollController _scrollController = ScrollController();
  final List<List<File>> _collatedFiles = List<List<File>>();

  bool _requiresLoad = false;
  AsyncSnapshot<List<File>> _lastSnapshot;
  Set<File> _selectedFiles = HashSet<File>();
  List<File> _files;
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
    return FutureBuilder<List<File>>(
      future: widget.loader(),
      builder: (context, snapshot) {
        _lastSnapshot = snapshot;
        return _onSnapshotAvailable(snapshot);
      },
    );
  }

  Widget _onSnapshotAvailable(AsyncSnapshot<List<File>> snapshot) {
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

  Widget _onDataLoaded(List<File> files) {
    _files = files;
    if (_files.isEmpty) {
      return Center(child: Text("Nothing to see here! 👀"));
    }
    _selectedFiles = widget.selectedFiles ?? Set<File>();
    _collateFiles();
    final list = ListView.builder(
      itemCount: _collatedFiles.length,
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
    var files = _collatedFiles[index];
    return Column(
      children: <Widget>[_getDay(files[0].createTimestamp), _getGallery(files)],
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

  Widget _getGallery(List<File> files) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 12),
      physics: ScrollPhysics(), // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return _buildFile(context, files[index]);
      },
      itemCount: files.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
    );
  }

  Widget _buildFile(BuildContext context, File file) {
    return GestureDetector(
      onTap: () {
        if (_selectedFiles.isNotEmpty) {
          _selectFile(file);
        } else {
          _routeToDetailPage(file, context);
        }
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        _selectFile(file);
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: _selectedFiles.contains(file)
              ? Border.all(width: 4.0, color: Colors.blue)
              : null,
        ),
        child: Hero(
          tag: file.heroTag(),
          child: ThumbnailWidget(file),
        ),
      ),
    );
  }

  void _selectFile(File file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
      widget.onFileSelectionChange(_selectedFiles);
    });
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      _files,
      _files.indexOf(file),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _collateFiles() {
    final dailyFiles = List<File>();
    final collatedFiles = List<List<File>>();
    for (int index = 0; index < _files.length; index++) {
      if (index > 0 &&
          !_areFilesFromSameDay(_files[index], _files[index - 1])) {
        var collatedDailyFiles = List<File>();
        collatedDailyFiles.addAll(dailyFiles);
        collatedFiles.add(collatedDailyFiles);
        dailyFiles.clear();
      }
      dailyFiles.add(_files[index]);
    }
    if (dailyFiles.isNotEmpty) {
      collatedFiles.add(dailyFiles);
    }
    _collatedFiles.clear();
    _collatedFiles.addAll(collatedFiles);
  }

  bool _areFilesFromSameDay(File first, File second) {
    var firstDate = DateTime.fromMicrosecondsSinceEpoch(first.createTimestamp);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.createTimestamp);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}
