import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/utils/hierarchical_search_util.dart";

class HierarchicalSearchGallery extends StatefulWidget {
  final String tagPrefix;
  final SelectedFiles? selectedFiles;
  const HierarchicalSearchGallery({
    required this.tagPrefix,
    this.selectedFiles,
    super.key,
  });

  @override
  State<HierarchicalSearchGallery> createState() =>
      _HierarchicalSearchGalleryState();
}

class _HierarchicalSearchGalleryState extends State<HierarchicalSearchGallery> {
  StreamSubscription<LocalPhotosUpdatedEvent>? _filesUpdatedEvent;
  late SearchFilterDataProvider? _searchFilterDataProvider;
  List<EnteFile> _filterdFiles = <EnteFile>[];
  int _filteredFilesVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_filesUpdatedEvent != null) {
          _filesUpdatedEvent!.cancel();
        }
        _filesUpdatedEvent =
            Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
          if (event.type == EventType.deletedFromDevice ||
              event.type == EventType.deletedFromEverywhere ||
              event.type == EventType.deletedFromRemote ||
              event.type == EventType.hide) {
            for (var updatedFile in event.updatedFiles) {
              _filterdFiles.remove(updatedFile);
              GalleryFilesState.of(context).galleryFiles.remove(updatedFile);
            }
            setState(() {});
          }
        });

        _searchFilterDataProvider = InheritedSearchFilterData.maybeOf(context)
            ?.searchFilterDataProvider;

        if (_searchFilterDataProvider != null) {
          _searchFilterDataProvider!
              .removeListener(fromApplied: true, listener: _onFiltersUpdated);
          _searchFilterDataProvider!
              .addListener(toApplied: true, listener: _onFiltersUpdated);
        }
        _onFiltersUpdated();
      } catch (e) {
        log('An error occurred: $e');
      }
    });
  }

  void _onFiltersUpdated() async {
    final filters = _searchFilterDataProvider!.appliedFilters;
    if (filters.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final filterdFiles = await getFilteredFiles(filters);
    _setFilteredFilesAndReload(filterdFiles);
    curateFilters(_searchFilterDataProvider!, filterdFiles);
  }

  void _setFilteredFilesAndReload(List<EnteFile> files) {
    if (mounted) {
      setState(() {
        _filterdFiles = files;
        GalleryFilesState.of(context).setGalleryFiles = files;
        _filteredFilesVersion++;
      });
    }
  }

  @override
  void dispose() {
    _filesUpdatedEvent?.cancel();
    if (_searchFilterDataProvider != null) {
      _searchFilterDataProvider!
          .removeListener(fromApplied: true, listener: _onFiltersUpdated);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Gallery(
      key: ValueKey(_filteredFilesVersion),
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final files = _filterdFiles
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return FileLoadResult(files, false);
      },
      tagPrefix: widget.tagPrefix,
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      selectedFiles: widget.selectedFiles,
    );
  }
}
