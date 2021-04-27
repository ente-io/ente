import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/huge_listview/huge_listview.dart';
import 'package:photos/ui/huge_listview/lazy_loading_gallery.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/loading_photos_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Gallery extends StatefulWidget {
  final Future<List<File>> Function(int creationStartTime, int creationEndTime,
      {int limit}) asyncLoader;
  final Stream<FilesUpdatedEvent> reloadEvent;
  final SelectedFiles selectedFiles;
  final String tagPrefix;
  final Widget headerWidget;
  final bool isHomePageGallery;

  Gallery({
    @required this.asyncLoader,
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
  static const int kInitialLoadLimit = 100;

  final _hugeListViewKey = GlobalKey<HugeListViewState>();

  Logger _logger;
  int _pageIndex = 0;
  List<List<File>> _collatedFiles = [];
  bool _hasLoadedFiles = false;
  StreamSubscription<FilesUpdatedEvent> _reloadEventSubscription;

  @override
  void initState() {
    _logger = Logger("Gallery_" + widget.tagPrefix);
    if (widget.reloadEvent != null) {
      _reloadEventSubscription = widget.reloadEvent.listen((event) {
        _logger.info("Building gallery because reload event fired");
        _loadFiles();
      });
    }
    widget.selectedFiles.addListener(() {
      _logger.info("Building gallery because selected files updated");
      setState(() {});
    });
    _loadFiles(limit: kInitialLoadLimit).then((value) => _loadFiles());
    super.initState();
  }

  Future<bool> _loadFiles({int limit}) async {
    _logger.info("Loading files");
    final startTime = DateTime.now();
    final files = await widget
        .asyncLoader(0, DateTime.now().microsecondsSinceEpoch, limit: limit);
    final endTime = DateTime.now();
    final duration = Duration(
        microseconds:
            endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch);
    _logger.info("Time taken: " + duration.inMilliseconds.toString() + "ms");
    final collatedFiles = _collateFiles(files);
    if (_collatedFiles.length != collatedFiles.length) {
      if (mounted) {
        _logger.info("New day discovered");
        setState(() {
          _hasLoadedFiles = true;
          _collatedFiles = collatedFiles;
        });
      }
    }
    return true;
  }

  @override
  void dispose() {
    _reloadEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building " + widget.tagPrefix);
    if (!_hasLoadedFiles) {
      return const LoadingPhotosWidget();
    }
    var gallery = _getListView();
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

  Widget _getListView() {
    return HugeListView<List<File>>(
      key: _hugeListViewKey,
      controller: ItemScrollController(),
      pageSize: kPageSize,
      startIndex: _pageIndex,
      totalCount: _collatedFiles.length,
      isDraggableScrollbarEnabled: _collatedFiles.length > 30,
      page: (pageIndex) {
        _pageIndex = pageIndex;
        final endTimeIndex =
            min(pageIndex * kPageSize, _collatedFiles.length - 1);
        final startTimeIndex =
            min((pageIndex + 1) * kPageSize, _collatedFiles.length - 1);
        return _collatedFiles.sublist(endTimeIndex, startTimeIndex);
      },
      placeholderBuilder: (context, pageIndex) {
        var day = getDayWidget(_collatedFiles[pageIndex][0].creationTime);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              day,
              PlaceHolderWidget(_collatedFiles[pageIndex].length),
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
        return getMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(
            _collatedFiles[index][0].creationTime));
      },
      thumbBackgroundColor: Color(0xFF151515),
      thumbDrawColor: Colors.white.withOpacity(0.5),
      velocityThreshold: 128,
    );
  }

  List<List<File>> _collateFiles(List<File> files) {
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
    collatedFiles
        .sort((a, b) => b[0].creationTime.compareTo(a[0].creationTime));
    return collatedFiles;
  }

  bool _areFromSameDay(int firstCreationTime, int secondCreationTime) {
    var firstDate = DateTime.fromMicrosecondsSinceEpoch(firstCreationTime);
    var secondDate = DateTime.fromMicrosecondsSinceEpoch(secondCreationTime);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}
