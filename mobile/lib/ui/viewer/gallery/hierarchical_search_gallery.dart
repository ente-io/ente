import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_banner.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";
import "package:photos/utils/hierarchical_search_util.dart";
import "package:photos/utils/navigation_util.dart";

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
  final _logger = Logger("HierarchicalSearchGallery");
  StreamSubscription<LocalPhotosUpdatedEvent>? _filesUpdatedEvent;
  late SearchFilterDataProvider? _searchFilterDataProvider;
  List<EnteFile> _filterdFiles = <EnteFile>[];
  int _filteredFilesVersion = 0;
  final _isLoading = ValueNotifier<bool>(true);
  FaceFilter? _firstUnnamedAppliedFaceFilter;

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

        _searchFilterDataProvider =
            InheritedSearchFilterData.of(context).searchFilterDataProvider;
        assert(_searchFilterDataProvider != null);

        _searchFilterDataProvider!
            .removeListener(fromApplied: true, listener: _onFiltersUpdated);
        _searchFilterDataProvider!
            .addListener(toApplied: true, listener: _onFiltersUpdated);

        _onFiltersUpdated();
      } catch (e) {
        _logger.severe('Something went wrong: $e');
      }
    });
  }

  void _onFiltersUpdated() async {
    final filters = _searchFilterDataProvider!.appliedFilters;
    if (filters.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    _isLoading.value = true;
    final filterdFiles = await getFilteredFiles(filters);

    _setFilteredFiles(filterdFiles);
    await curateFilters(_searchFilterDataProvider!, filterdFiles, context);
    _setUnnamedFaceFilter(filters);

    _isLoading.value = false;
  }

  void _setUnnamedFaceFilter(List<HierarchicalSearchFilter> filters) {
    for (HierarchicalSearchFilter filter in filters) {
      if (filter is FaceFilter && filter.clusterId != null) {
        if (filters.last == filter) {
          _firstUnnamedAppliedFaceFilter = filter;
        }
        break;
      }
      _firstUnnamedAppliedFaceFilter = null;
    }
  }

  void _setFilteredFiles(List<EnteFile> files) {
    _filterdFiles = files;
    GalleryFilesState.of(context).setGalleryFiles = files;
    _filteredFilesVersion++;
  }

  @override
  void dispose() {
    _filesUpdatedEvent?.cancel();
    _isLoading.dispose();
    if (_searchFilterDataProvider != null) {
      _searchFilterDataProvider!
          .removeListener(fromApplied: true, listener: _onFiltersUpdated);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _isLoading,
      builder: (context, isLoading, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOutExpo,
          switchOutCurve: Curves.easeInOutExpo,
          child: isLoading
              ? const EnteLoadingWidget()
              : Gallery(
                  key: ValueKey(_filteredFilesVersion),
                  asyncLoader: (
                    creationStartTime,
                    creationEndTime, {
                    limit,
                    asc,
                  }) async {
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
                  header: _firstUnnamedAppliedFaceFilter != null
                      ? PeopleBanner(
                          type: PeopleBannerType.addName,
                          faceWidget: PersonFaceWidget(
                            _firstUnnamedAppliedFaceFilter!.faceFile,
                            clusterID:
                                _firstUnnamedAppliedFaceFilter!.clusterId,
                            thumbnailFallback: false,
                            cannotTrustFile: true,
                          ),
                          actionIcon: Icons.add_outlined,
                          text: S.of(context).savePerson,
                          subText: S.of(context).findThemQuickly,
                          onTap: () async {
                            final result = await showAssignPersonAction(
                              context,
                              clusterID:
                                  _firstUnnamedAppliedFaceFilter!.clusterId!,
                            );
                            Navigator.of(context).pop();
                            if (result != null) {
                              final person = result is (PersonEntity, EnteFile)
                                  ? result.$1
                                  : result;
                              // ignore: unawaited_futures
                              routeToPage(
                                context,
                                PeoplePage(
                                  person: person,
                                  searchResult: null,
                                ),
                              );
                            }
                          },
                        )
                      : null,
                ),
        );
      },
    );
  }
}
