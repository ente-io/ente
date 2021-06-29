import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/huge_listview/huge_listview.dart';
import 'package:photos/ui/huge_listview/lazy_loading_gallery.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef GalleryLoader = Future<FileLoadResult>
    Function(int creationStartTime, int creationEndTime, {int limit, bool asc});

class Gallery extends StatefulWidget {
  final GalleryLoader asyncLoader;
  final List<File> initialFiles;
  final Stream<FilesUpdatedEvent> reloadEvent;
  final Stream<Event> forceReloadEvent;
  final SelectedFiles selectedFiles;
  final String tagPrefix;
  final Widget header;
  final Widget footer;

  Gallery({
    @required this.asyncLoader,
    @required this.selectedFiles,
    @required this.tagPrefix,
    this.initialFiles,
    this.reloadEvent,
    this.forceReloadEvent,
    this.header,
    this.footer,
  });

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  static const int kInitialLoadLimit = 100;

  final _hugeListViewKey = GlobalKey<HugeListViewState>();

  Logger _logger;
  int _index = 0;
  List<List<File>> _collatedFiles = [];
  bool _hasLoadedFiles = false;
  StreamSubscription<FilesUpdatedEvent> _reloadEventSubscription;
  StreamSubscription<Event> _forceReloadEventSubscription;

  @override
  void initState() {
    _logger = Logger("Gallery_" + widget.tagPrefix);
    _logger.info("initState");
    if (widget.reloadEvent != null) {
      _reloadEventSubscription = widget.reloadEvent.listen((event) async {
        _logger.info("Building gallery because reload event fired");
        final result = await _loadFiles();
        _onFilesLoaded(result.files);
      });
    }
    if (widget.forceReloadEvent != null) {
      _forceReloadEventSubscription =
          widget.forceReloadEvent.listen((event) async {
        _logger.info("Force reload triggered");
        final result = await _loadFiles();
        _setFilesAndReload(result.files);
      });
    }
    if (widget.initialFiles != null) {
      _onFilesLoaded(widget.initialFiles);
    }
    _loadFiles(limit: kInitialLoadLimit).then((result) async {
      _setFilesAndReload(result.files);
      if (result.hasMore) {
        final result = await _loadFiles();
        _setFilesAndReload(result.files);
      }
    });
    super.initState();
  }

  void _setFilesAndReload(List<File> files) {
    final hasReloaded = _onFilesLoaded(files);
    if (!hasReloaded && mounted) {
      setState(() {});
    }
  }

  Future<FileLoadResult> _loadFiles({int limit}) async {
    _logger.info("Loading files");
    final startTime = DateTime.now().microsecondsSinceEpoch;
    final result = await widget
        .asyncLoader(0, DateTime.now().microsecondsSinceEpoch, limit: limit);
    final endTime = DateTime.now().microsecondsSinceEpoch;
    final duration = Duration(microseconds: endTime - startTime);
    _logger.info("Time taken to load " +
        result.files.length.toString() +
        " files :" +
        duration.inMilliseconds.toString() +
        "ms");
    return result;
  }

  // Collates files and returns `true` if it resulted in a gallery reload
  bool _onFilesLoaded(List<File> files) {
    final collatedFiles = _collateFiles(files);
    if (_collatedFiles.length != collatedFiles.length) {
      if (mounted) {
        setState(() {
          _hasLoadedFiles = true;
          _collatedFiles = collatedFiles;
        });
      }
      return true;
    } else {
      _collatedFiles = collatedFiles;
      return false;
    }
  }

  @override
  void dispose() {
    _reloadEventSubscription?.cancel();
    _forceReloadEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building " + widget.tagPrefix);
    if (!_hasLoadedFiles) {
      return loadWidget;
    }
    return _getListView();
  }

  Widget _getListView() {
    return HugeListView<List<File>>(
      key: _hugeListViewKey,
      controller: ItemScrollController(),
      startIndex: _index,
      totalCount: _collatedFiles.length,
      isDraggableScrollbarEnabled: _collatedFiles.length > 30,
      waitBuilder: (_) {
        return loadWidget;
      },
      emptyResultBuilder: (_) {
        return nothingToSeeHere;
      },
      itemBuilder: (context, index) {
        var gallery;
        gallery = LazyLoadingGallery(
          _collatedFiles[index],
          index,
          widget.reloadEvent,
          widget.asyncLoader,
          widget.selectedFiles,
          widget.tagPrefix,
          Bus.instance
              .on<GalleryIndexUpdatedEvent>()
              .where((event) => event.tag == widget.tagPrefix)
              .map((event) => event.index),
        );
        if (widget.header != null && index == 0) {
          gallery = Column(children: [widget.header, gallery]);
        }
        if (widget.footer != null && index == _collatedFiles.length - 1) {
          gallery = Column(children: [gallery, widget.footer]);
        }
        return gallery;
      },
      labelTextBuilder: (int index) {
        return getMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(
            _collatedFiles[index][0].creationTime));
      },
      thumbBackgroundColor: Color(0xFF151515),
      thumbDrawColor: Colors.white.withOpacity(0.5),
      firstShown: (int firstIndex) {
        Bus.instance
            .fire(GalleryIndexUpdatedEvent(widget.tagPrefix, firstIndex));
      },
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

class GalleryIndexUpdatedEvent {
  final String tag;
  final int index;

  GalleryIndexUpdatedEvent(this.tag, this.index);
}
