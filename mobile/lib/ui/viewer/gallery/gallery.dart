import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/component/multiple_groups_gallery_view.dart";
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/debouncer.dart";
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef GalleryLoader = Future<FileLoadResult> Function(
  int creationStartTime,
  int creationEndTime, {
  int? limit,
  bool? asc,
});

typedef SortAscFn = bool Function();

class Gallery extends StatefulWidget {
  final GalleryLoader asyncLoader;
  final List<EnteFile>? initialFiles;
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
  final bool enableFileGrouping;
  final Widget loadingWidget;
  final bool disableScroll;
  final Duration reloadDebounceTime;
  final Duration reloadDebounceExecutionInterval;

  /// When true, selection will be limited to one item. Tapping on any item
  /// will select even when no other item is selected.
  final bool limitSelectionToOne;

  /// When true, the gallery will be in selection mode. Tapping on any item
  /// will select even when no other item is selected.
  final bool inSelectionMode;
  final bool showSelectAllByDefault;
  final bool isScrollablePositionedList;

  // add a Function variable to get sort value in bool
  final SortAscFn? sortAsyncFn;
  final GroupType groupType;

  const Gallery({
    required this.asyncLoader,
    required this.tagPrefix,
    this.selectedFiles,
    this.initialFiles,
    this.reloadEvent,
    this.forceReloadEvents,
    this.removalEventTypes = const {},
    this.header,
    this.footer = const SizedBox(height: 212),
    this.emptyState = const EmptyState(),
    this.scrollBottomSafeArea = 120.0,
    this.albumName = '',
    this.groupType = GroupType.day,
    this.enableFileGrouping = true,
    this.loadingWidget = const EnteLoadingWidget(),
    this.disableScroll = false,
    this.limitSelectionToOne = false,
    this.inSelectionMode = false,
    this.sortAsyncFn,
    this.showSelectAllByDefault = true,
    this.isScrollablePositionedList = true,
    this.reloadDebounceTime = const Duration(milliseconds: 500),
    this.reloadDebounceExecutionInterval = const Duration(seconds: 2),
    Key? key,
  }) : super(key: key);

  @override
  State<Gallery> createState() {
    return GalleryState();
  }
}

class GalleryState extends State<Gallery> {
  static const int kInitialLoadLimit = 100;
  late final Debouncer _debouncer;

  late Logger _logger;
  List<List<EnteFile>> currentGroupedFiles = [];
  bool _hasLoadedFiles = false;
  late ItemScrollController _itemScroller;
  StreamSubscription<FilesUpdatedEvent>? _reloadEventSubscription;
  StreamSubscription<TabDoubleTapEvent>? _tabDoubleTapEvent;
  final _forceReloadEventSubscriptions = <StreamSubscription<Event>>[];
  late String _logTag;
  bool _sortOrderAsc = false;
  List<EnteFile> _allFiles = [];

  @override
  void initState() {
    super.initState();
    _logTag =
        "Gallery_${widget.tagPrefix}${kDebugMode ? "_" + widget.albumName! : ""}";
    _logger = Logger(_logTag);
    _logger.finest("init Gallery");
    _debouncer = Debouncer(
      widget.reloadDebounceTime,
      executionInterval: widget.reloadDebounceExecutionInterval,
    );
    _sortOrderAsc = widget.sortAsyncFn != null ? widget.sortAsyncFn!() : false;
    _itemScroller = ItemScrollController();
    if (widget.reloadEvent != null) {
      _reloadEventSubscription = widget.reloadEvent!.listen((event) async {
        _debouncer.run(() async {
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

          setState(() {});
        });
      });
    }
    _tabDoubleTapEvent =
        Bus.instance.on<TabDoubleTapEvent>().listen((event) async {
      // todo: Assign ID to Gallery and fire generic event with ID &
      //  target index/date
      if (mounted && event.selectedIndex == 0) {
        await _itemScroller.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
    if (widget.forceReloadEvents != null) {
      for (final event in widget.forceReloadEvents!) {
        _forceReloadEventSubscriptions.add(
          event.listen((event) async {
            _debouncer.run(() async {
              _logger.finest("Force refresh all files on ${event.reason}");
              _sortOrderAsc =
                  widget.sortAsyncFn != null ? widget.sortAsyncFn!() : false;
              final result = await _loadFiles();
              _setFilesAndReload(result.files);
            });
          }),
        );
      }
    }
    if (widget.initialFiles != null && !_sortOrderAsc) {
      _onFilesLoaded(widget.initialFiles!);
    }
    _loadFiles(limit: kInitialLoadLimit).then((result) async {
      _setFilesAndReload(result.files);
      if (result.hasMore) {
        final result = await _loadFiles();
        _setFilesAndReload(result.files);
      }
    });
  }

  void _setFilesAndReload(List<EnteFile> files) {
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
        asc: _sortOrderAsc,
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

  // group files into multiple groups and returns `true` if it resulted in a
  // gallery reload
  bool _onFilesLoaded(List<EnteFile> files) {
    _allFiles = files;

    final updatedGroupedFiles =
        widget.enableFileGrouping && widget.groupType.timeGrouping()
            ? _groupBasedOnTime(files)
            : _genericGroupForPerf(files);
    if (currentGroupedFiles.length != updatedGroupedFiles.length ||
        currentGroupedFiles.isEmpty) {
      if (mounted) {
        setState(() {
          _hasLoadedFiles = true;
          currentGroupedFiles = updatedGroupedFiles;
        });
      }
      return true;
    } else {
      currentGroupedFiles = updatedGroupedFiles;
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
    _debouncer.cancelDebounce();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest("Building Gallery  ${widget.tagPrefix}");
    SelectionState.of(context)?.allGalleryFiles = _allFiles;
    if (!_hasLoadedFiles) {
      return widget.loadingWidget;
    }
    return GalleryContextState(
      sortOrderAsc: _sortOrderAsc,
      inSelectionMode: widget.inSelectionMode,
      type: widget.groupType,
      child: MultipleGroupsGalleryView(
        itemScroller: _itemScroller,
        groupedFiles: currentGroupedFiles,
        disableScroll: widget.disableScroll,
        emptyState: widget.emptyState,
        asyncLoader: widget.asyncLoader,
        removalEventTypes: widget.removalEventTypes,
        tagPrefix: widget.tagPrefix,
        scrollBottomSafeArea: widget.scrollBottomSafeArea,
        limitSelectionToOne: widget.limitSelectionToOne,
        enableFileGrouping:
            widget.enableFileGrouping && widget.groupType.showGroupHeader(),
        logTag: _logTag,
        logger: _logger,
        reloadEvent: widget.reloadEvent,
        header: widget.header,
        footer: widget.footer,
        selectedFiles: widget.selectedFiles,
        showSelectAllByDefault:
            widget.showSelectAllByDefault && widget.groupType.showGroupHeader(),
        isScrollablePositionedList: widget.isScrollablePositionedList,
      ),
    );
  }

  // create groups of 200 files for performance
  List<List<EnteFile>> _genericGroupForPerf(List<EnteFile> files) {
    if (widget.groupType == GroupType.size) {
      // sort files by fileSize on the bases of _sortOrderAsc
      files.sort((a, b) {
        if (_sortOrderAsc) {
          return a.fileSize!.compareTo(b.fileSize!);
        } else {
          return b.fileSize!.compareTo(a.fileSize!);
        }
      });
    }
    // todo:(neeraj) Stick to default group behaviour for magicSearch and editLocationGallery
    // In case of Magic search, we need to hide the scrollbar title (can be done
    // by specifying none as groupType)
    if (widget.groupType != GroupType.size) {
      return [files];
    }

    final List<List<EnteFile>> resultGroupedFiles = [];
    List<EnteFile> singleGroupFile = [];
    const int groupSize = 40;
    for (int i = 0; i < files.length; i += 1) {
      singleGroupFile.add(files[i]);
      if (singleGroupFile.length == groupSize) {
        resultGroupedFiles.add(singleGroupFile);
        singleGroupFile = [];
      }
    }
    if (singleGroupFile.isNotEmpty) {
      resultGroupedFiles.add(singleGroupFile);
    }
    _logger.info('Grouped files into ${resultGroupedFiles.length} groups');
    return resultGroupedFiles;
  }

  List<List<EnteFile>> _groupBasedOnTime(List<EnteFile> files) {
    List<EnteFile> dailyFiles = [];

    final List<List<EnteFile>> resultGroupedFiles = [];
    for (int index = 0; index < files.length; index++) {
      if (index > 0 &&
          !widget.groupType.areFromSameGroup(files[index - 1], files[index])) {
        resultGroupedFiles.add(dailyFiles);
        dailyFiles = [];
      }
      dailyFiles.add(files[index]);
    }
    if (dailyFiles.isNotEmpty) {
      resultGroupedFiles.add(dailyFiles);
    }
    if (_sortOrderAsc) {
      resultGroupedFiles
          .sort((a, b) => a[0].creationTime!.compareTo(b[0].creationTime!));
    } else {
      resultGroupedFiles
          .sort((a, b) => b[0].creationTime!.compareTo(a[0].creationTime!));
    }
    return resultGroupedFiles;
  }
}

class GalleryIndexUpdatedEvent {
  final String tag;
  final int index;

  GalleryIndexUpdatedEvent(this.tag, this.index);
}
