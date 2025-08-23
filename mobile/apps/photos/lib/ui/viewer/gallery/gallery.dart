import 'dart:async';
import "dart:io";
import 'dart:math' as math;

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
import "package:photos/models/gallery/gallery_groups.dart";
import "package:photos/models/gallery_type.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/group_header_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/component/sectioned_sliver_list.dart";
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import "package:photos/ui/viewer/gallery/scrollbar/custom_scroll_bar.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/utils/hierarchical_search_util.dart";
import "package:photos/utils/misc_util.dart";
import "package:photos/utils/standalone/date_time.dart";
import "package:photos/utils/standalone/debouncer.dart";
import "package:photos/utils/widget_util.dart";

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
  final bool enableFileGrouping;
  final Widget loadingWidget;
  final bool disableScroll;
  final Duration reloadDebounceTime;
  final Duration reloadDebounceExecutionInterval;
  final GalleryType? galleryType;
  final bool showGallerySettingsCTA;

  /// When true, selection will be limited to one item. Tapping on any item
  /// will select even when no other item is selected.
  final bool limitSelectionToOne;

  final bool addHeaderOrFooterEmptyState;

  /// When true, the gallery will be in selection mode. Tapping on any item
  /// will select it even when no other item is selected. This is only used to
  /// make selection possible without long pressing. If a gallery has selected
  /// files, it's not necessary that this will be true.
  final bool inSelectionMode;
  final bool showSelectAll;
  final bool isScrollablePositionedList;

  // add a Function variable to get sort value in bool
  final SortAscFn? sortAsyncFn;

  /// Pass value to override default group type.
  final GroupType? groupType;
  final bool disablePinnedGroupHeader;
  final bool disableVerticalPaddingForScrollbar;

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
    this.addHeaderOrFooterEmptyState = true,
    this.emptyState = const EmptyState(),
    this.albumName = '',
    this.groupType,
    this.enableFileGrouping = true,
    this.loadingWidget = const EnteLoadingWidget(),
    this.disableScroll = false,
    this.limitSelectionToOne = false,
    this.inSelectionMode = false,
    this.sortAsyncFn,
    this.showSelectAll = true,
    this.isScrollablePositionedList = true,
    this.reloadDebounceTime = const Duration(milliseconds: 500),
    this.reloadDebounceExecutionInterval = const Duration(seconds: 2),
    this.disablePinnedGroupHeader = false,
    this.galleryType,
    this.disableVerticalPaddingForScrollbar = false,
    this.showGallerySettingsCTA = false,
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
  bool _hasLoadedFiles = false;
  StreamSubscription<FilesUpdatedEvent>? _reloadEventSubscription;
  StreamSubscription<TabDoubleTapEvent>? _tabDoubleTapEvent;
  final _forceReloadEventSubscriptions = <StreamSubscription<Event>>[];
  late String _logTag;
  bool _sortOrderAsc = false;
  List<EnteFile> _allGalleryFiles = [];
  final _scrollController = ScrollController();
  final _headerKey = GlobalKey();
  final _headerHeightNotifier = ValueNotifier<double?>(null);
  final miscUtil = MiscUtil();
  final scrollBarInUseNotifier = ValueNotifier<bool>(false);
  late GroupType _groupType;
  final scrollbarBottomPaddingNotifier = ValueNotifier<double>(0);
  late GalleryGroups galleryGroups;

  @override
  void initState() {
    super.initState();
    // end the tag with x to avoid `.` in the end if logger name
    _logTag =
        "Gallery_${widget.tagPrefix}${kDebugMode ? "_" + widget.albumName! : ""}_x";
    _logger = Logger(_logTag);
    _logger.info("init Gallery");

    if (widget.limitSelectionToOne) {
      assert(widget.showSelectAll == false);
    }

    _setGroupType();
    _debouncer = Debouncer(
      widget.reloadDebounceTime,
      executionInterval: widget.reloadDebounceExecutionInterval,
      leading: true,
    );
    _sortOrderAsc = widget.sortAsyncFn != null ? widget.sortAsyncFn!() : false;
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
            _updateGalleryGroups();
          }
        });
      });
    }
    _tabDoubleTapEvent =
        Bus.instance.on<TabDoubleTapEvent>().listen((event) async {
      // todo: Assign ID to Gallery and fire generic event with ID &
      //  target index/date
      if (mounted && event.selectedIndex == 0) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutExpo,
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
              _setGroupType();
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

    // First load
    _loadFiles(limit: kInitialLoadLimit).then((result) async {
      _setFilesAndReload(result.files);
      if (result.hasMore) {
        // _setScrollController(allFilesLoaded: false);
        final result = await _loadFiles();
        _setFilesAndReload(result.files);
        // _setScrollController(allFilesLoaded: true);
      } else {
        // _setScrollController(allFilesLoaded: true);
      }
    });

    if (_groupType.showGroupHeader()) {
      getIntrinsicSizeOfWidget(
        GroupHeaderWidget(
          title: "Dummy title",
          gridSize: localSettings.getPhotoGridSize(),
          filesInGroup: const [],
          selectedFiles: null,
          showSelectAll: false,
        ),
        context,
      ).then((size) {
        setState(() {
          groupHeaderExtent = size.height;
          _updateGalleryGroups(callSetState: false);
        });
      });
    } else {
      groupHeaderExtent = GalleryGroups.spacing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateGalleryGroups();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // To set the initial value of scrollbar bottom padding
      _selectedFilesListener();
      try {
        final headerRenderBox = await miscUtil
            .getNonNullValueWithRetry(
              () => _headerKey.currentContext?.findRenderObject(),
              retryInterval: const Duration(milliseconds: 750),
              id: "headerRenderBox",
            )
            .then((value) => value as RenderBox);

        _headerHeightNotifier.value = headerRenderBox.size.height;
      } catch (e, s) {
        _logger.warning("Error getting renderBox offset", e, s);
      }
      setState(() {});
    });

    widget.selectedFiles?.addListener(_selectedFilesListener);
  }

  @override
  void didUpdateWidget(covariant Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupType != widget.groupType) {
      _setGroupType();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _updateGalleryGroups({bool callSetState = true}) {
    if (groupHeaderExtent == null) return;
    galleryGroups = GalleryGroups(
      allFiles: _allGalleryFiles,
      groupType: _groupType,
      sortOrderAsc: _sortOrderAsc,
      widthAvailable: MediaQuery.sizeOf(context).width,
      selectedFiles: widget.selectedFiles,
      tagPrefix: widget.tagPrefix,
      groupHeaderExtent: groupHeaderExtent!,
      showSelectAll: widget.showSelectAll,
      limitSelectionToOne: widget.limitSelectionToOne,
      showGallerySettingsCTA: widget.showGallerySettingsCTA,
    );

    if (callSetState) {
      setState(() {});
    }
  }

  // void _setScrollController({required bool allFilesLoaded}) {
  //   if (widget.fileToJumpScrollTo != null && allFilesLoaded) {
  //     final fileOffset =
  //         galleryGroups.getOffsetOfFile(widget.fileToJumpScrollTo!);
  //     if (fileOffset == null) {
  //       _logger.warning(
  //         "File offset is null, cannot set initial scroll controller",
  //       );
  //     }

  //     _scrollController?.jumpTo(fileOffset ?? 0);
  //   } else {
  //     _scrollController = ScrollController();
  //   }
  //   setState(() {});
  // }

  void _selectedFilesListener() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final extra = widget.galleryType == GalleryType.homepage ? 76.0 : 0.0;
    widget.selectedFiles?.files.isEmpty ?? true
        ? scrollbarBottomPaddingNotifier.value = bottomInset + extra
        : scrollbarBottomPaddingNotifier.value =
            FileSelectionOverlayBar.roughHeight + bottomInset;
  }

  void _setGroupType() {
    if (!widget.enableFileGrouping) {
      _groupType = GroupType.none;
    } else if (widget.groupType != null) {
      _groupType = widget.groupType!;
    } else {
      _groupType = localSettings.getGalleryGroupType();
    }
  }

  void _setFilesAndReload(List<EnteFile> files) {
    final hasReloaded = _onFilesLoaded(files);
    if (!hasReloaded && mounted) {
      _updateGalleryGroups();
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

  bool _onFilesLoaded(List<EnteFile> files) {
    _allGalleryFiles = files;
    _hasLoadedFiles = true;
    return false;
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
    _headerHeightNotifier.dispose();
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    scrollbarBottomPaddingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building Gallery  ${widget.tagPrefix}");
    final widthAvailable = MediaQuery.sizeOf(context).width;

    if (groupHeaderExtent == null) {
      final photoGridSize = localSettings.getPhotoGridSize();
      final tileHeight =
          (widthAvailable - (photoGridSize - 1) * GalleryGroups.spacing) /
              photoGridSize;
      return widget.initialFiles != null && widget.initialFiles!.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                widget.header ?? const SizedBox.shrink(),
                GroupHeaderWidget(
                  title: "",
                  gridSize: photoGridSize,
                  filesInGroup: const [],
                  selectedFiles: null,
                  showSelectAll: false,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: tileHeight,
                    width: tileHeight,
                    child: GalleryFileWidget(
                      file: widget.initialFiles!.first,
                      selectedFiles: null,
                      limitSelectionToOne: false,
                      tag: widget.tagPrefix,
                      photoGridSize: photoGridSize,
                      currentUserID: null,
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink();
    }

    GalleryFilesState.of(context).setGalleryFiles = _allGalleryFiles;
    if (!_hasLoadedFiles) {
      return widget.loadingWidget;
    }
    return GalleryContextState(
      sortOrderAsc: _sortOrderAsc,
      inSelectionMode: widget.inSelectionMode,
      type: _groupType,
      child: _allGalleryFiles.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.addHeaderOrFooterEmptyState)
                  widget.header ?? const SizedBox.shrink(),
                Expanded(child: widget.emptyState),
                if (widget.addHeaderOrFooterEmptyState)
                  widget.footer ?? const SizedBox.shrink(),
              ],
            )
          : CustomScrollBar(
              scrollController: _scrollController,
              galleryGroups: galleryGroups,
              inUseNotifier: scrollBarInUseNotifier,
              heighOfViewport: MediaQuery.sizeOf(context).height,
              topPadding: widget.disableVerticalPaddingForScrollbar
                  ? 0.0
                  : groupHeaderExtent!,
              bottomPadding: widget.disableVerticalPaddingForScrollbar
                  ? ValueNotifier(0.0)
                  : scrollbarBottomPaddingNotifier,
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (notification) {
                  final renderBox = _headerKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    _headerHeightNotifier.value = renderBox.size.height;
                  } else {
                    _logger.info(
                      "Header render box is null, cannot get height",
                    );
                  }

                  return true;
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomScrollView(
                      physics: widget.disableScroll
                          ? const NeverScrollableScrollPhysics()
                          : const ExponentialBouncingScrollPhysics(),
                      controller: _scrollController,
                      cacheExtent: galleryCacheExtent,
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizeChangedLayoutNotifier(
                            child: SizedBox(
                              key: _headerKey,
                              child: widget.header ?? const SizedBox.shrink(),
                            ),
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
                    galleryGroups.groupType.showGroupHeader() &&
                            !widget.disablePinnedGroupHeader
                        ? PinnedGroupHeader(
                            scrollController: _scrollController,
                            galleryGroups: galleryGroups,
                            headerHeightNotifier: _headerHeightNotifier,
                            selectedFiles: widget.selectedFiles,
                            showSelectAll: widget.showSelectAll &&
                                !widget.limitSelectionToOne,
                            scrollbarInUseNotifier: scrollBarInUseNotifier,
                            showGallerySettingsCTA:
                                widget.showGallerySettingsCTA,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
    );
  }

  double get galleryCacheExtent {
    final int photoGridSize = localSettings.getPhotoGridSize();
    switch (photoGridSize) {
      case 2:
      case 3:
        return 1000;
      case 4:
        return 850;
      case 5:
        return 600;
      case 6:
        return 300;
      default:
        throw StateError(
          'Invalid photo grid size configuration: $photoGridSize',
        );
    }
  }
}

class PinnedGroupHeader extends StatefulWidget {
  final ScrollController scrollController;
  final GalleryGroups galleryGroups;
  final ValueNotifier<double?> headerHeightNotifier;
  final SelectedFiles? selectedFiles;
  final bool showSelectAll;
  final ValueNotifier<bool> scrollbarInUseNotifier;
  final bool showGallerySettingsCTA;
  static const kScaleDurationInMilliseconds = 200;
  static const kTrailingIconsFadeInDelayMs = 0;
  static const kTrailingIconsFadeInDurationMs = 200;

  const PinnedGroupHeader({
    required this.scrollController,
    required this.galleryGroups,
    required this.headerHeightNotifier,
    required this.selectedFiles,
    required this.showSelectAll,
    required this.scrollbarInUseNotifier,
    required this.showGallerySettingsCTA,
    super.key,
  });

  @override
  State<PinnedGroupHeader> createState() => _PinnedGroupHeaderState();
}

class _PinnedGroupHeaderState extends State<PinnedGroupHeader> {
  String? currentGroupId;
  final _enlargeHeader = ValueNotifier<bool>(false);
  Timer? _enlargeHeaderTimer;
  late final ValueNotifier<bool> _atZeroScrollNotifier;
  Timer? _timer;
  bool lastInUseState = false;
  bool fadeInTrailingIcons = false;
  @override
  void initState() {
    super.initState();
    widget.scrollbarInUseNotifier.addListener(scrollbarInUseListener);
    widget.scrollController.addListener(_setCurrentGroupID);
    _atZeroScrollNotifier = ValueNotifier<bool>(
      widget.scrollController.offset == 0,
    );
    widget.scrollController.addListener(
      _scrollControllerListenerForZeroScrollNotifier,
    );
    widget.headerHeightNotifier.addListener(_headerHeightNotifierListener);
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
    _atZeroScrollNotifier.removeListener(
      _scrollControllerListenerForZeroScrollNotifier,
    );
    widget.headerHeightNotifier.removeListener(_headerHeightNotifierListener);
    _enlargeHeader.dispose();
    _atZeroScrollNotifier.dispose();
    _enlargeHeaderTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _setCurrentGroupID() {
    if (widget.headerHeightNotifier.value == null) return;
    final normalizedScrollOffset =
        widget.scrollController.offset - widget.headerHeightNotifier.value!;
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
      if (Platform.isIOS) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.vibrate();
      }
    }
  }

  void _scrollControllerListenerForZeroScrollNotifier() {
    _atZeroScrollNotifier.value = widget.scrollController.offset == 0;
  }

  void scrollbarInUseListener() {
    _enlargeHeaderTimer?.cancel();
    if (widget.scrollbarInUseNotifier.value) {
      _enlargeHeader.value = true;
      lastInUseState = true;
      fadeInTrailingIcons = false;
    } else {
      _enlargeHeaderTimer = Timer(const Duration(milliseconds: 250), () {
        _enlargeHeader.value = false;
        if (lastInUseState) {
          fadeInTrailingIcons = true;
          Future.delayed(
              const Duration(
                milliseconds: PinnedGroupHeader.kTrailingIconsFadeInDelayMs +
                    PinnedGroupHeader.kTrailingIconsFadeInDurationMs +
                    100,
              ), () {
            setState(() {
              if (!mounted) return;
              fadeInTrailingIcons = false;
            });
          });
        }
        lastInUseState = false;
      });
    }
  }

  void _headerHeightNotifierListener() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      _setCurrentGroupID();
    });
  }

  @override
  Widget build(BuildContext context) {
    return currentGroupId != null
        ? ValueListenableBuilder(
            valueListenable: _enlargeHeader,
            builder: (context, inUse, _) {
              return AnimatedScale(
                scale: inUse ? 1.2 : 1.0,
                alignment: Alignment.topLeft,
                duration: const Duration(
                  milliseconds: PinnedGroupHeader.kScaleDurationInMilliseconds,
                ),
                curve: Curves.easeInOutSine,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _atZeroScrollNotifier,
                  builder: (context, atZeroScroll, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        boxShadow: atZeroScroll
                            ? []
                            : [
                                const BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: child,
                    );
                  },
                  child: ColoredBox(
                    color: getEnteColorScheme(context).backgroundBase,
                    child: GroupHeaderWidget(
                      title: widget.galleryGroups
                          .groupIdToGroupDataMap[currentGroupId!]!.groupType
                          .getTitle(
                        context,
                        widget.galleryGroups.groupIDToFilesMap[currentGroupId]!
                            .first,
                      ),
                      gridSize: localSettings.getPhotoGridSize(),
                      height: widget.galleryGroups.groupHeaderExtent,
                      filesInGroup: widget
                          .galleryGroups.groupIDToFilesMap[currentGroupId!]!,
                      selectedFiles: widget.selectedFiles,
                      showSelectAll: widget.showSelectAll,
                      showGalleryLayoutSettingCTA:
                          widget.showGallerySettingsCTA,
                      showTrailingIcons: !inUse,
                      isPinnedHeader: true,
                      fadeInTrailingIcons: fadeInTrailingIcons,
                    ),
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

/// Scroll physics similar to [BouncingScrollPhysics] but with exponentially
/// increasing friction when scrolling out of bounds.
///
/// This creates a stronger resistance to overscrolling the further you go
/// past the scroll boundary.
class ExponentialBouncingScrollPhysics extends BouncingScrollPhysics {
  const ExponentialBouncingScrollPhysics({
    this.frictionExponent = 7.0,
    super.decelerationRate,
    super.parent,
  });

  /// The exponent used in the friction calculation.
  ///
  /// A higher value will result in a more rapid increase in friction as the
  /// user overscrolls. Defaults to 7.0.
  final double frictionExponent;

  @override
  ExponentialBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ExponentialBouncingScrollPhysics(
      parent: buildParent(ancestor),
      decelerationRate: decelerationRate,
      frictionExponent: frictionExponent,
    );
  }

  @override
  double frictionFactor(double overscrollFraction) {
    final double baseFactor = switch (decelerationRate) {
      ScrollDecelerationRate.fast => 0.26,
      ScrollDecelerationRate.normal => 0.52,
    };
    return baseFactor * math.exp(-overscrollFraction * frictionExponent);
  }
}
