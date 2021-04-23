import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/huge_listview/huge_listview.dart';
import 'package:photos/ui/huge_listview/lazy_loading_gallery.dart';
import 'package:photos/ui/huge_listview/page_result.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:quiver/cache.dart';
import 'package:quiver/collection.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Gallery extends StatefulWidget {
  final Future<List<File>> Function(int creationStartTime, int creationEndTime,
      {int limit}) asyncLoader;
  final Future<List<int>> Function() creationTimesLoader;
  final Stream<Event> reloadEvent;
  final SelectedFiles selectedFiles;
  final String tagPrefix;
  final Widget headerWidget;
  final bool isHomePageGallery;

  Gallery({
    @required this.asyncLoader,
    @required this.creationTimesLoader,
    @required this.selectedFiles,
    @required this.tagPrefix,
    this.reloadEvent,
    this.headerWidget,
    this.isHomePageGallery = false,
  });

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  static const int kPageSize = 10;
  static const int kCacheSize = 256;

  final _hugeListViewKey = GlobalKey<HugeListViewState>();

  Logger _logger;
  Map<int, HugeListViewPageResult<List<File>>> _map;
  MapCache<int, HugeListViewPageResult<List<File>>> _cache;
  int _pageIndex = 0;
  List<int> _creationTimes;
  bool _hasLoadedCreationTimes = false;

  @override
  void initState() {
    _logger = Logger("Gallery_" + widget.tagPrefix);
    _map = LruMap<int, HugeListViewPageResult<List<File>>>(
        maximumSize: kCacheSize ~/ kPageSize);
    _cache = MapCache<int, HugeListViewPageResult<List<File>>>(map: _map);
    if (widget.reloadEvent != null) {
      widget.reloadEvent.listen((event) {
        if (mounted) {
          _logger.info("Building gallery because reload event fired");
          setState(() {
            if (event is LocalPhotosUpdatedEvent) {
              // TODO: Attach new days
            } else {
              _logger.info("Clearing all cache");
              _map.clear();
              _hasLoadedCreationTimes = false;
              _loadCreationTimes();
            }
          });
        }
      });
    }
    widget.selectedFiles.addListener(() {
      _logger.info("Building gallery because selected files updated");
      setState(() {});
    });
    _loadCreationTimes();
    super.initState();
  }

  void _loadCreationTimes() {
    widget.creationTimesLoader().then((times) async {
      if (mounted) {
        setState(() {
          _creationTimes = times;
          _hasLoadedCreationTimes = true;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building " + widget.tagPrefix);
    if (!_hasLoadedCreationTimes) {
      return loadWidget;
    }
    _logger.info("Creation times fetched " + _creationTimes.length.toString());
    final collatedTimes = _collateCreationTimes(_creationTimes);
    var gallery = _getListView(collatedTimes);
    if (widget.isHomePageGallery) {
      gallery = Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: gallery,
      );
      if (widget.selectedFiles.files.isNotEmpty) {
        gallery = Stack(children: [
          gallery,
          Container(
            height: 60,
            child: GalleryAppBarWidget(
              GalleryAppBarType.homepage,
              null,
              widget.selectedFiles,
            ),
          ),
        ]);
      }
    }
    return gallery;
  }

  Widget _getListView(List<List<int>> collatedTimes) {
    return HugeListView<List<File>>(
      key: _hugeListViewKey,
      controller: ItemScrollController(),
      pageSize: kPageSize,
      startIndex: _pageIndex,
      totalCount: collatedTimes.length,
      isDraggableScrollbarEnabled: collatedTimes.length > 30,
      cache: _cache,
      map: _map,
      pageFuture: (pageIndex) {
        _pageIndex = pageIndex;
        final endTimeIndex =
            min(pageIndex * kPageSize, collatedTimes.length - 1);
        final endTime = collatedTimes[endTimeIndex][0];
        final startTimeIndex =
            min((pageIndex + 1) * kPageSize, collatedTimes.length - 1);
        final startTime = collatedTimes[startTimeIndex]
            [collatedTimes[startTimeIndex].length - 1];
        return widget
            .asyncLoader(startTime, endTime)
            .then((files) => _clubFiles(files));
      },
      placeholderBuilder: (context, pageIndex) {
        var day = getDayWidget(collatedTimes[pageIndex][0]);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              day,
              PlaceHolderWidget(collatedTimes[pageIndex].length),
            ],
          ),
        );
      },
      waitBuilder: (_) {
        return loadWidget;
      },
      emptyResultBuilder: (_) {
        return nothingToSeeHere;
      },
      itemBuilder: (context, index, files) {
        var gallery;
        gallery = LazyLoadingGallery(
          files,
          widget.reloadEvent,
          widget.asyncLoader,
          widget.selectedFiles,
          widget.tagPrefix,
        );
        if (widget.headerWidget != null && index == 0) {
          gallery = Column(children: [widget.headerWidget, gallery]);
        }
        return gallery;
      },
      labelTextBuilder: (int index) {
        return getMonthAndYear(
            DateTime.fromMicrosecondsSinceEpoch(collatedTimes[index][0]));
      },
      thumbBackgroundColor: Color(0xFF151515),
      thumbDrawColor: Colors.white.withOpacity(0.5),
      velocityThreshold: 128,
    );
  }

  List<List<File>> _clubFiles(List<File> files) {
    _logger.info("Clubbing file count " + files.length.toString());
    final List<File> dailyFiles = [];
    final List<List<File>> collatedFiles = [];
    for (int index = 0; index < files.length; index++) {
      if (index > 0 &&
          !_areFromSameDay(
              files[index - 1].creationTime, files[index].creationTime)) {
        final List<File> collatedDailyFiles = [];
        collatedDailyFiles.addAll(dailyFiles);
        collatedFiles.add(collatedDailyFiles);
        dailyFiles.clear();
      }
      dailyFiles.add(files[index]);
    }
    if (dailyFiles.isNotEmpty) {
      collatedFiles.add(dailyFiles);
    }
    return collatedFiles;
  }

  List<List<int>> _collateCreationTimes(List<int> creationTimes) {
    final List<int> dailyTimes = [];
    final List<List<int>> collatedTimes = [];
    for (int index = 0; index < creationTimes.length; index++) {
      if (index > 0 &&
          !_areFromSameDay(creationTimes[index - 1], creationTimes[index])) {
        final List<int> collatedDailyTimes = [];
        collatedDailyTimes.addAll(dailyTimes);
        collatedTimes.add(collatedDailyTimes);
        dailyTimes.clear();
      }
      dailyTimes.add(creationTimes[index]);
    }
    if (dailyTimes.isNotEmpty) {
      collatedTimes.add(dailyTimes);
    }
    return collatedTimes;
  }

  bool _areFromSameDay(int firstCreationTime, int secondCreationTime) {
    var firstDate = DateTime.fromMicrosecondsSinceEpoch(firstCreationTime);
    var secondDate = DateTime.fromMicrosecondsSinceEpoch(secondCreationTime);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}
