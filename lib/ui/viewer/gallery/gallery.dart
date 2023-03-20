import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/huge_listview/huge_listview.dart';
import 'package:photos/ui/huge_listview/lazy_loading_gallery.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef GalleryLoader = Future<FileLoadResult> Function(
  int creationStartTime,
  int creationEndTime, {
  int? limit,
  bool? asc,
});

class Gallery extends StatefulWidget {
  final GalleryLoader asyncLoader;
  final List<File>? initialFiles;
  final Stream<FilesUpdatedEvent>? reloadEvent;
  final List<Stream<Event>>? forceReloadEvents;
  final Set<EventType> removalEventTypes;
  final SelectedFiles? selectedFiles;
  final String tagPrefix;
  final Widget? header;
  final Widget? footer;
  final Widget emptyState;
  final String? albumName;
  final double scrollBottomSafeArea;

  const Gallery({
    required this.asyncLoader,
    required this.tagPrefix,
    this.selectedFiles,
    this.initialFiles,
    this.reloadEvent,
    this.forceReloadEvents,
    this.removalEventTypes = const {},
    this.header,
    this.footer = const SizedBox(height: 120),
    this.emptyState = const EmptyState(),
    this.scrollBottomSafeArea = 120.0,
    this.albumName = '',
    Key? key,
  }) : super(key: key);

  @override
  State<Gallery> createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  static const int kInitialLoadLimit = 100;

  final _hugeListViewKey = GlobalKey<HugeListViewState>();

  late Logger _logger;
  List<List<File>> _collatedFiles = [];
  bool _hasLoadedFiles = false;
  ItemScrollController? _itemScroller;
  StreamSubscription<FilesUpdatedEvent>? _reloadEventSubscription;
  StreamSubscription<TabDoubleTapEvent>? _tabDoubleTapEvent;
  final _forceReloadEventSubscriptions = <StreamSubscription<Event>>[];
  String? _logTag;
  late int _photoGridSize;

  @override
  void initState() {
    _logTag =
        "Gallery_${widget.tagPrefix}${kDebugMode ? "_" + widget.albumName! : ""}";
    _logger = Logger(_logTag!);
    _logger.finest("init Gallery");
    _itemScroller = ItemScrollController();
    if (widget.reloadEvent != null) {
      _reloadEventSubscription = widget.reloadEvent!.listen((event) async {
        // In soft refresh, setState is called for entire gallery only when
        // number of child change
        _logger.finest("Soft refresh all files on ${event.reason} ");
        final result = await _loadFiles();
        final bool hasReloaded = _onFilesLoaded(result.files);
        if (hasReloaded && kDebugMode) {
          _logger.finest(
            "Reloaded gallery on soft refresh all files on ${event.reason}",
          );
        }
      });
    }
    _tabDoubleTapEvent =
        Bus.instance.on<TabDoubleTapEvent>().listen((event) async {
      // todo: Assign ID to Gallery and fire generic event with ID &
      //  target index/date
      if (mounted && event.selectedIndex == 0) {
        _itemScroller!.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
    if (widget.forceReloadEvents != null) {
      for (final event in widget.forceReloadEvents!) {
        _forceReloadEventSubscriptions.add(
          event.listen((event) async {
            _logger.finest("Force refresh all files on ${event.reason}");
            final result = await _loadFiles();
            _setFilesAndReload(result.files);
          }),
        );
      }
    }
    if (widget.initialFiles != null) {
      _onFilesLoaded(widget.initialFiles!);
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

  Future<FileLoadResult> _loadFiles({int? limit}) async {
    _logger.info("Loading ${limit ?? "all"} files");
    try {
      final startTime = DateTime.now().microsecondsSinceEpoch;
      final result = await widget.asyncLoader(
        galleryLoadStartTime,
        galleryLoadEndTime,
        limit: limit,
      );
      final endTime = DateTime.now().microsecondsSinceEpoch;
      final duration = Duration(microseconds: endTime - startTime);
      _logger.info(
        "Time taken to load " +
            result.files.length.toString() +
            " files :" +
            duration.inMilliseconds.toString() +
            "ms",
      );
      return result;
    } catch (e, s) {
      _logger.severe("failed to load files", e, s);
      rethrow;
    }
  }

  // Collates files and returns `true` if it resulted in a gallery reload
  bool _onFilesLoaded(List<File> files) {
    final updatedCollatedFiles = _collateFiles(files);
    if (_collatedFiles.length != updatedCollatedFiles.length ||
        _collatedFiles.isEmpty) {
      if (mounted) {
        setState(() {
          _hasLoadedFiles = true;
          _collatedFiles = updatedCollatedFiles;
        });
      }
      return true;
    } else {
      _collatedFiles = updatedCollatedFiles;
      return false;
    }
  }

  @override
  void dispose() {
    _reloadEventSubscription?.cancel();
    _tabDoubleTapEvent?.cancel();
    for (final subscription in _forceReloadEventSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("Building Gallery  ${widget.tagPrefix}");
    if (!_hasLoadedFiles) {
      return const EnteLoadingWidget();
    }
    _photoGridSize = LocalSettings.instance.getPhotoGridSize();
    return _getListView();
  }

  Widget _getListView() {
    return HugeListView<List<File>>(
      key: _hugeListViewKey,
      controller: _itemScroller,
      startIndex: 0,
      totalCount: _collatedFiles.length,
      isDraggableScrollbarEnabled: _collatedFiles.length > 10,
      waitBuilder: (_) {
        return const EnteLoadingWidget();
      },
      emptyResultBuilder: (_) {
        final List<Widget> children = [];
        if (widget.header != null) {
          children.add(widget.header!);
        }
        children.add(
          Expanded(
            child: widget.emptyState,
          ),
        );
        if (widget.footer != null) {
          children.add(widget.footer!);
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );
      },
      itemBuilder: (context, index) {
        Widget gallery;
        gallery = LazyLoadingGallery(
          _collatedFiles[index],
          index,
          widget.reloadEvent,
          widget.removalEventTypes,
          widget.asyncLoader,
          widget.selectedFiles,
          widget.tagPrefix,
          Bus.instance
              .on<GalleryIndexUpdatedEvent>()
              .where((event) => event.tag == widget.tagPrefix)
              .map((event) => event.index),
          logTag: _logTag,
          photoGirdSize: _photoGridSize,
        );
        if (widget.header != null && index == 0) {
          gallery = Column(children: [widget.header!, gallery]);
        }
        if (widget.footer != null && index == _collatedFiles.length - 1) {
          gallery = Column(children: [gallery, widget.footer!]);
        }
        return gallery;
      },
      labelTextBuilder: (int index) {
        try {
          return getMonthAndYear(
            DateTime.fromMicrosecondsSinceEpoch(
              _collatedFiles[index][0].creationTime!,
            ),
          );
        } catch (e) {
          _logger.severe("label text builder failed", e);
          return "";
        }
      },
      thumbBackgroundColor:
          Theme.of(context).colorScheme.galleryThumbBackgroundColor,
      thumbDrawColor: Theme.of(context).colorScheme.galleryThumbDrawColor,
      thumbPadding: widget.header != null
          ? const EdgeInsets.only(top: 60)
          : const EdgeInsets.all(0),
      bottomSafeArea: widget.scrollBottomSafeArea,
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
          !areFromSameDay(
            files[index - 1].creationTime!,
            files[index].creationTime!,
          )) {
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
        .sort((a, b) => b[0].creationTime!.compareTo(a[0].creationTime!));
    return collatedFiles;
  }
}

class GalleryIndexUpdatedEvent {
  final String tag;
  final int index;

  GalleryIndexUpdatedEvent(this.tag, this.index);
}
