import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import "package:photos/models/gallery/gallery_sections.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/viewer/gallery/component/group/group_header_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/component/sectioned_sliver_list.dart";
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import "package:photos/ui/viewer/gallery/scrollbar/custom_scroll_bar_2.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/utils/hierarchical_search_util.dart";
import "package:photos/utils/misc_util.dart";
import "package:photos/utils/standalone/date_time.dart";
import "package:photos/utils/standalone/debouncer.dart";
import "package:photos/utils/widget_util.dart";
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
  /// will select it even when no other item is selected. This is only used to
  /// make selection possible without long pressing. If a gallery has selected
  /// files, it's not necessary that this will be true.
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
    super.key,
  });

  @override
  State<Gallery> createState() {
    return GalleryState();
  }
}

class GalleryState extends State<Gallery> {
  static const int kInitialLoadLimit = 100;
  late final Debouncer _debouncer;
  double? groupHeaderExtent;

  late Logger _logger;
  List<List<EnteFile>> currentGroupedFiles = [];
  bool _hasLoadedFiles = false;
  late ItemScrollController _itemScroller;
  StreamSubscription<FilesUpdatedEvent>? _reloadEventSubscription;
  StreamSubscription<TabDoubleTapEvent>? _tabDoubleTapEvent;
  final _forceReloadEventSubscriptions = <StreamSubscription<Event>>[];
  late String _logTag;
  bool _sortOrderAsc = false;
  List<EnteFile> _allGalleryFiles = [];
  final _scrollController = ScrollController();
  final _sectionedListSliverKey = GlobalKey();
  final _stackKey = GlobalKey();
  double? _stackRenderBoxYOffset;
  double? _sectionedListSliverRenderBoxYOffset;
  double? get _sectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox {
    if (_sectionedListSliverRenderBoxYOffset != null &&
        _stackRenderBoxYOffset != null) {
      return _sectionedListSliverRenderBoxYOffset! - _stackRenderBoxYOffset!;
    }
    return null;
  }

  final miscUtil = MiscUtil();
  final scrollBarInUseNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // end the tag with x to avoid `.` in the end if logger name
    _logTag =
        "Gallery_${widget.tagPrefix}${kDebugMode ? "_" + widget.albumName! : ""}_x";
    _logger = Logger(_logTag);
    _logger.info("init Gallery");
    _debouncer = Debouncer(
      widget.reloadDebounceTime,
      executionInterval: widget.reloadDebounceExecutionInterval,
      leading: true,
    );
    _sortOrderAsc = widget.sortAsyncFn != null ? widget.sortAsyncFn!() : false;
    _itemScroller = ItemScrollController();
    if (widget.reloadEvent != null) {
      _reloadEventSubscription = widget.reloadEvent!.listen((event) async {
        bool shouldReloadFromDB = true;
        if (event.source == 'uploadCompleted') {
          shouldReloadFromDB = _shouldReloadOnUploadCompleted(event);
        } else if (event.source == 'fileMissingLocal') {
          shouldReloadFromDB = _shouldReloadOnFileMissingLocal(event);
        }
        if (!shouldReloadFromDB) {
          final bool hasCalledSetState = _onFilesLoaded(_allGalleryFiles);
          _logger.info(
            'Skip softRefresh from DB on ${event.reason}, processed updated in memory with setStateReload $hasCalledSetState',
          );
          return;
        }

        _debouncer.run(() async {
          // In soft refresh, setState is called for entire gallery only when
          // number of child change
          _logger.info("Soft refresh all files on ${event.reason} ");
          final result = await _loadFiles();
          final bool hasTriggeredSetState = _onFilesLoaded(result.files);
          if (hasTriggeredSetState && kDebugMode) {
            _logger.info(
              "Reloaded gallery on soft refresh all files on ${event.reason}",
            );
          }
          if (!hasTriggeredSetState && mounted) {
            setState(() {});
          }
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
              _logger.info("Force refresh all files on ${event.reason}");
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

    getIntrinsicSizeOfWidget(
      GroupHeaderWidget(
        title: "Dummy title",
        gridSize: localSettings.getPhotoGridSize(),
        filesInGroup: const [],
        selectedFiles: null,
        showSelectAllByDefault: false,
      ),
      context,
    ).then((size) {
      setState(() {
        groupHeaderExtent = size.height;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final sectionedListSliverRenderBox = await miscUtil
            .getNonNullValueWithRetry(
              () => _sectionedListSliverKey.currentContext?.findRenderObject(),
              retryInterval: const Duration(milliseconds: 750),
              id: "sectionedListSliverRenderBox",
            )
            .then((value) => value as RenderBox);
        final stackRenderBox = await miscUtil
            .getNonNullValueWithRetry(
              () => _stackKey.currentContext?.findRenderObject(),
              retryInterval: const Duration(milliseconds: 750),
              id: "stackRenderBox",
            )
            .then((value) => value as RenderBox);

        _sectionedListSliverRenderBoxYOffset =
            sectionedListSliverRenderBox.localToGlobal(Offset.zero).dy;
        _stackRenderBoxYOffset = stackRenderBox.localToGlobal(Offset.zero).dy;
      } catch (e, s) {
        _logger.warning("Error getting renderBox offset", e, s);
      }
      setState(() {});
    });
  }

  void _setFilesAndReload(List<EnteFile> files) {
    final hasReloaded = _onFilesLoaded(files);
    if (!hasReloaded && mounted) {
      setState(() {});
    }
  }

  bool _shouldReloadOnUploadCompleted(FilesUpdatedEvent event) {
    bool shouldReloadFromDB = true;
    if (event.source == 'uploadCompleted') {
      final Map<int, EnteFile> genIDToUploadedFiles = {};
      for (int i = 0; i < event.updatedFiles.length; i++) {
        // matching happens on generatedID and localID
        if (event.updatedFiles[i].generatedID == null) {
          return true;
        }
        genIDToUploadedFiles[event.updatedFiles[i].generatedID!] =
            event.updatedFiles[i];
      }
      for (int i = 0; i < _allGalleryFiles.length; i++) {
        final file = _allGalleryFiles[i];
        if (file.generatedID == null) {
          continue;
        }
        final updateFile = genIDToUploadedFiles[file.generatedID!];
        if (updateFile != null &&
            updateFile.localID == file.localID &&
            areFromSameDay(
              updateFile.creationTime ?? 0,
              file.creationTime ?? 0,
            )) {
          _allGalleryFiles[i] = updateFile;
          genIDToUploadedFiles.remove(file.generatedID!);
        }
      }
      shouldReloadFromDB = genIDToUploadedFiles.isNotEmpty;
    }
    return shouldReloadFromDB;
  }

  // Handle event when an local file was already uploaded and we have now
  // added localID link link to the remote file
  bool _shouldReloadOnFileMissingLocal(FilesUpdatedEvent event) {
    bool shouldReloadFromDB = true;
    if (event.source != 'fileMissingLocal' ||
        event.type != EventType.deletedFromEverywhere) {
      _logger.warning(
        "Invalid event source or type for fileMissingLocal: ${event.source} ${event.type}",
      );
      return true;
    }
    final Map<int, EnteFile> genIDToUploadedFiles = {};
    for (int i = 0; i < event.updatedFiles.length; i++) {
      // the file should have generatedID, localID and should not be uploaded for
      // following logic to work
      if (event.updatedFiles[i].generatedID == null ||
          event.updatedFiles[i].localID == null ||
          event.updatedFiles[i].isUploaded) {
        _logger.warning(
          "Invalid file in updatedFiles: ${event.updatedFiles[i].localID} ${event.updatedFiles[i].generatedID} ${event.updatedFiles[i].isUploaded}",
        );
        return shouldReloadFromDB;
      }
      genIDToUploadedFiles[event.updatedFiles[i].generatedID!] =
          event.updatedFiles[i];
    }
    final List<EnteFile> newAllGalleryFiles = [];
    for (int i = 0; i < _allGalleryFiles.length; i++) {
      final file = _allGalleryFiles[i];
      if (file.generatedID == null) {
        newAllGalleryFiles.add(file);
        continue;
      }
      final updateFile = genIDToUploadedFiles[file.generatedID!];
      if (updateFile != null &&
          areFromSameDay(
            updateFile.creationTime ?? 0,
            file.creationTime ?? 0,
          )) {
        genIDToUploadedFiles.remove(file.generatedID!);
      } else {
        newAllGalleryFiles.add(file);
      }
    }
    shouldReloadFromDB = genIDToUploadedFiles.isNotEmpty;
    if (!shouldReloadFromDB) {
      _allGalleryFiles = newAllGalleryFiles;
    }
    return shouldReloadFromDB;
  }

  // group files into multiple groups and returns `true` if it resulted in a
  // gallery reload
  bool _onFilesLoaded(List<EnteFile> files) {
    _allGalleryFiles = files;

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
        return true;
      }
      return false;
    } else {
      currentGroupedFiles = updatedGroupedFiles;
      return false;
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

      /// To curate filters when a gallery is first opened.
      if (!result.hasMore) {
        final searchFilterDataProvider =
            InheritedSearchFilterData.maybeOf(context)
                ?.searchFilterDataProvider;
        if (searchFilterDataProvider != null &&
            !searchFilterDataProvider.isSearchingNotifier.value) {
          unawaited(
            curateFilters(searchFilterDataProvider, result.files, context),
          );
        }
      }

      return result;
    } catch (e, s) {
      _logger.severe("failed to load files", e, s);
      rethrow;
    }
  }

  @override
  void dispose() {
    _reloadEventSubscription?.cancel();
    _tabDoubleTapEvent?.cancel();
    for (final subscription in _forceReloadEventSubscriptions) {
      subscription.cancel();
    }
    _debouncer.cancelDebounceTimer();
    _scrollController.dispose();
    scrollBarInUseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (groupHeaderExtent == null) return const SliverFillRemaining();

    _logger.info("Building Gallery  ${widget.tagPrefix}");

    final galleryGroups = GalleryGroups(
      allFiles: _allGalleryFiles,
      groupType: widget.groupType,
      widthAvailable: MediaQuery.sizeOf(context).width,
      selectedFiles: widget.selectedFiles,
      tagPrefix: widget.tagPrefix,
      headerExtent: groupHeaderExtent!,
      showSelectAllByDefault: widget.showSelectAllByDefault,
    );
    GalleryFilesState.of(context).setGalleryFiles = _allGalleryFiles;
    if (!_hasLoadedFiles) {
      return widget.loadingWidget;
    }
    return GalleryContextState(
      sortOrderAsc: _sortOrderAsc,
      inSelectionMode: widget.inSelectionMode,
      type: widget.groupType,
      // Replace this with the new gallery and use `_allGalleryFiles`
      // child: MultipleGroupsGalleryView(
      //   itemScroller: _itemScroller,
      //   groupedFiles: currentGroupedFiles,
      //   disableScroll: widget.disableScroll,
      //   emptyState: widget.emptyState,
      //   asyncLoader: widget.asyncLoader,
      //   removalEventTypes: widget.removalEventTypes,
      //   tagPrefix: widget.tagPrefix,
      //   scrollBottomSafeArea: widget.scrollBottomSafeArea,
      //   limitSelectionToOne: widget.limitSelectionToOne,
      //   enableFileGrouping:
      //       widget.enableFileGrouping && widget.groupType.showGroupHeader(),
      //   logTag: _logTag,
      //   logger: _logger,
      //   reloadEvent: widget.reloadEvent,
      //   header: widget.header,
      //   footer: widget.footer,
      //   selectedFiles: widget.selectedFiles,
      //   showSelectAllByDefault:
      //       widget.showSelectAllByDefault && widget.groupType.showGroupHeader(),
      //   isScrollablePositionedList: widget.isScrollablePositionedList,
      // ),
      child: CustomScrollBar2(
        scrollController: _scrollController,
        galleryGroups: galleryGroups,
        inUseNotifier: scrollBarInUseNotifier,
        heighOfViewport: MediaQuery.sizeOf(context).height,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: widget.header ?? const SizedBox.shrink(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox.shrink(
                    key: _sectionedListSliverKey,
                  ),
                ),
                SectionedListSliver(
                  sectionLayouts: galleryGroups.groupLayouts,
                ),
                SliverToBoxAdapter(
                  child: widget.footer,
                ),
              ],
            ),
            PinnedGroupHeader(
              scrollController: _scrollController,
              galleryGroups: galleryGroups,
              getSectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox: () =>
                  _sectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox,
              selectedFiles: widget.selectedFiles,
              showSelectAllByDefault: widget.showSelectAllByDefault,
              scrollbarInUseNotifier: scrollBarInUseNotifier,
            ),
          ],
        ),
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

class PinnedGroupHeader extends StatefulWidget {
  final ScrollController scrollController;
  final GalleryGroups galleryGroups;
  final double? Function()
      getSectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox;
  final SelectedFiles? selectedFiles;
  final bool showSelectAllByDefault;
  final ValueNotifier<bool> scrollbarInUseNotifier;

  const PinnedGroupHeader({
    required this.scrollController,
    required this.galleryGroups,
    required this.getSectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox,
    required this.selectedFiles,
    required this.showSelectAllByDefault,
    required this.scrollbarInUseNotifier,
    super.key,
  });

  @override
  State<PinnedGroupHeader> createState() => _PinnedGroupHeaderState();
}

class _PinnedGroupHeaderState extends State<PinnedGroupHeader> {
  String? currentGroupId;
  final _enlargeHeader = ValueNotifier<bool>(false);
  Timer? _enlargeHeaderTimer;
  @override
  void initState() {
    super.initState();
    widget.scrollbarInUseNotifier.addListener(scrollbarInUseListener);
    widget.scrollController.addListener(_setCurrentGroupID);
  }

  @override
  void didUpdateWidget(covariant PinnedGroupHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setCurrentGroupID();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_setCurrentGroupID);
    widget.scrollbarInUseNotifier.removeListener(scrollbarInUseListener);
    _enlargeHeaderTimer?.cancel();
    _enlargeHeader.dispose();
    super.dispose();
  }

  void _setCurrentGroupID() {
    final normalizedScrollOffset = widget.scrollController.offset -
        widget
            .getSectionedListSliverRenderBoxYOffsetRelativeToStackRenderBox()!;
    if (normalizedScrollOffset < 0) {
      // No change in group ID, no need to call setState
      if (currentGroupId == null) return;
      currentGroupId = null;
    } else {
      final groupScrollOffsets = widget.galleryGroups.groupScrollOffsets;

      // Binary search to find the index of the largest scrollOffset in
      // groupScrollOffsets which is <= scrollPosition
      int low = 0;
      int high = groupScrollOffsets.length - 1;
      int floorIndex = 0;

      // Handle the case where scrollPosition is smaller than the first key.
      // In this scenario, we associate it with the first heading.
      if (normalizedScrollOffset < groupScrollOffsets.first) {
        return;
      }

      while (low <= high) {
        final mid = low + (high - low) ~/ 2;
        final midValue = groupScrollOffsets[mid];

        if (midValue <= normalizedScrollOffset) {
          // This key is less than or equal to the target scrollPosition.
          // It's a potential floor. Store its index and try searching higher
          // for a potentially closer floor value.
          floorIndex = mid;
          low = mid + 1;
        } else {
          // This key is greater than the target scrollPosition.
          // The floor must be in the lower half.
          high = mid - 1;
        }
      }
      if (currentGroupId ==
          widget.galleryGroups
              .scrollOffsetToGroupIdMap[groupScrollOffsets[floorIndex]]) {
        // No change in group ID, no need to call setState
        return;
      }
      currentGroupId = widget.galleryGroups
          .scrollOffsetToGroupIdMap[groupScrollOffsets[floorIndex]];
    }

    setState(() {});
    if (widget.scrollbarInUseNotifier.value) {
      HapticFeedback.vibrate();
    }
  }

  void scrollbarInUseListener() {
    _enlargeHeaderTimer?.cancel();
    if (widget.scrollbarInUseNotifier.value) {
      _enlargeHeader.value = true;
    } else {
      _enlargeHeaderTimer = Timer(const Duration(milliseconds: 250), () {
        _enlargeHeader.value = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return currentGroupId != null
        ? ValueListenableBuilder(
            valueListenable: _enlargeHeader,
            builder: (context, inUse, _) {
              return AnimatedScale(
                scale: inUse ? 1.3 : 1.0,
                alignment: Alignment.topLeft,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutSine,
                child: ColoredBox(
                  color: getEnteColorScheme(context).backgroundBase,
                  child: GroupHeaderWidget(
                    title: widget.galleryGroups
                        .groupIdToheaderDataMap[currentGroupId!]!.groupType
                        .getTitle(
                      context,
                      widget.galleryGroups.groupIDToFilesMap[currentGroupId]!
                          .first,
                    ),
                    gridSize: localSettings.getPhotoGridSize(),
                    height: widget.galleryGroups.headerExtent,
                    filesInGroup: widget
                        .galleryGroups.groupIDToFilesMap[currentGroupId!]!,
                    selectedFiles: widget.selectedFiles,
                    showSelectAllByDefault: widget.showSelectAllByDefault,
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
}

class GalleryIndexUpdatedEvent {
  final String tag;
  final int index;

  GalleryIndexUpdatedEvent(this.tag, this.index);
}
