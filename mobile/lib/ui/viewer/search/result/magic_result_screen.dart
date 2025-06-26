import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/magic_sort_change_event.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/search/hierarchical/magic_filter.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class MagicResultScreen extends StatefulWidget {
  ///This widget expects [files] to be sorted by most relelvant first to the
  ///magic search query.
  final List<EnteFile> files;
  final String name;
  final String heroTag;
  final bool enableGrouping;
  final Map<int, int> fileIdToPosMap;
  final MagicFilter magicFilter;

  static const GalleryType appBarType = GalleryType.magic;
  static const GalleryType overlayType = GalleryType.magic;

  const MagicResultScreen(
    this.files, {
    required this.name,
    required this.magicFilter,
    this.enableGrouping = false,
    this.fileIdToPosMap = const {},
    this.heroTag = "",
    super.key,
  });

  @override
  State<MagicResultScreen> createState() => _MagicResultScreenState();
}

class _MagicResultScreenState extends State<MagicResultScreen> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<MagicSortChangeEvent> _magicSortChangeEvent;
  late final Logger _logger = Logger("_MagicResultScreenState");
  late final Map<int, int> fileIDToRelevantPos;
  bool _enableGrouping = false;
  late final SearchFilterDataProvider _searchFilterDataProvider;

  @override
  void initState() {
    super.initState();
    files = widget.files;
    _enableGrouping = widget.enableGrouping;
    fileIDToRelevantPos = getFileIDToRelevantPos();
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });

    _magicSortChangeEvent =
        Bus.instance.on<MagicSortChangeEvent>().listen((event) {
      if (event.sortType == MagicSortType.mostRelevant) {
        if (_enableGrouping) {
          if (fileIDToRelevantPos.isNotEmpty) {
            files.sort(
              (a, b) =>
                  fileIDToRelevantPos[a.uploadedFileID]! -
                  fileIDToRelevantPos[b.uploadedFileID]!,
            );
          } else {
            _logger.warning(
              "fileIdToPosMap is empty, cannot sort by most relevant.",
            );
          }
        }
        setState(() {
          _enableGrouping = false;
        });
      } else if (event.sortType == MagicSortType.mostRecent) {
        if (!_enableGrouping) {
          files.sort((a, b) => b.creationTime!.compareTo(a.creationTime!));
        }
        setState(() {
          _enableGrouping = true;
        });
      }
    });

    _searchFilterDataProvider = SearchFilterDataProvider(
      initialGalleryFilter: widget.magicFilter,
    );
  }

  Map<int, int> getFileIDToRelevantPos() {
    if (widget.fileIdToPosMap.isNotEmpty) {
      return widget.fileIdToPosMap;
    } else if (widget.enableGrouping == false) {
      _logger.warning(
        "fileIdToPosMap is empty, assuming existing list of files is sorted by most relevant.",
      );
      final map = <int, int>{};
      for (int i = 0; i < files.length; i++) {
        map[files[i].uploadedFileID!] = i;
      }
      return map;
    } else {
      _logger.warning(
        "fileIdToPosMap is empty, cannot sort by most relevant.",
      );
      return <int, int>{};
    }
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _magicSortChangeEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = Gallery(
      key: ValueKey(_enableGrouping),
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(
            result,
            result.length < files.length,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.heroTag,
      selectedFiles: _selectedFiles,
      enableFileGrouping: _enableGrouping,
      initialFiles: [files.first],
    );
    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: _searchFilterDataProvider,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              MagicResultScreen.appBarType,
              widget.name,
              _selectedFiles,
            ),
          ),
          body: SelectionState(
            selectedFiles: _selectedFiles,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Builder(
                  builder: (context) {
                    return ValueListenableBuilder(
                      valueListenable: InheritedSearchFilterData.of(context)
                          .searchFilterDataProvider!
                          .isSearchingNotifier,
                      builder: (context, value, _) {
                        return value
                            ? HierarchicalSearchGallery(
                                tagPrefix: widget.heroTag,
                                selectedFiles: _selectedFiles,
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeInOutQuad,
                                switchOutCurve: Curves.easeInOutQuad,
                                child: gallery,
                              );
                      },
                    );
                  },
                ),
                FileSelectionOverlayBar(
                  MagicResultScreen.overlayType,
                  _selectedFiles,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
