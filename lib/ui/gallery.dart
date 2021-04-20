import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/huge_listview/huge_listview.dart';
import 'package:photos/ui/huge_listview/lazy_loading_gallery.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Gallery extends StatefulWidget {
  final Future<List<File>> Function(int creationStartTime, int creationEndTime,
      {int limit}) asyncLoader;
  final Future<List<int>> creationTimesFuture;
  final Stream<Event> reloadEvent;
  final SelectedFiles selectedFiles;
  final String tagPrefix;
  final Widget headerWidget;
  final bool isHomePageGallery;

  Gallery({
    @required this.asyncLoader,
    @required this.creationTimesFuture,
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
  static final int kPageSize = 10;

  final Logger _logger = Logger("Gallery");
  final _cache = Map<int, Future<List<List<File>>>>();

  int _pageIndex = 0;
  final _hugeListViewKey = GlobalKey<HugeListViewState>();

  @override
  void initState() {
    if (widget.reloadEvent != null) {
      widget.reloadEvent.listen((event) {
        _logger.info("Building gallery because reload event fired");
        if (mounted) {
          setState(() {
            _cache.clear();
          });
        }
      });
    }
    widget.selectedFiles.addListener(() {
      _logger.info("Building gallery because selected files updated");
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building " + widget.tagPrefix);
    return FutureBuilder(
      future: widget.creationTimesFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final creationTimes = snapshot.data;
          final collatedTimes = _collateCreationTimes(creationTimes);
          _logger.info("Days fetched " + collatedTimes.length.toString());
          var gallery;
          gallery = HugeListView<List<File>>(
            key: _hugeListViewKey,
            controller: ItemScrollController(),
            pageSize: kPageSize,
            startIndex: _pageIndex,
            totalCount: collatedTimes.length,
            isDraggableScrollbarEnabled: collatedTimes.length > 30,
            pageFuture: (pageIndex) {
              _pageIndex = pageIndex;
              if (!_cache.containsKey(pageIndex)) {
                final endTimeIndex =
                    min(pageIndex * kPageSize, collatedTimes.length - 1);
                final endTime = collatedTimes[endTimeIndex][0];
                final startTimeIndex =
                    min((pageIndex + 1) * kPageSize, collatedTimes.length - 1);
                final startTime = collatedTimes[startTimeIndex]
                    [collatedTimes[startTimeIndex].length - 1];
                _cache[pageIndex] = widget
                    .asyncLoader(startTime, endTime)
                    .then((files) => _clubFiles(files));
              }
              return _cache[pageIndex];
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
                  files, widget.selectedFiles, widget.tagPrefix);
              if (widget.headerWidget != null && index == 0) {
                gallery = Column(children: [widget.headerWidget, gallery]);
              }
              return gallery;
            },
            labelTextBuilder: (int index) {
              return getMonthAndYear(
                  DateTime.fromMicrosecondsSinceEpoch(collatedTimes[index][0]));
            },
            thumbBackgroundColor: Colors.grey[900],
            thumbDrawColor: Colors.white.withOpacity(0.5),
            velocityThreshold: 128,
          );
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
        } else {
          return loadWidget;
        }
      },
    );
  }

  List<List<File>> _clubFiles(List<File> files) {
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
