import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/people_changed_event.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/search_result.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/components/end_to_end_banner.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/link_email_screen.dart";

import "package:photos/ui/viewer/people/people_app_bar.dart";
import "package:photos/ui/viewer/people/people_banner.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";
import "package:photos/utils/navigation_util.dart";

class PeoplePage extends StatefulWidget {
  final String tagPrefix;
  final PersonEntity person;
  final SearchResult? searchResult;

  static const GalleryType appBarType = GalleryType.peopleTag;
  static const GalleryType overlayType = GalleryType.peopleTag;

  const PeoplePage({
    this.tagPrefix = "",
    required this.person,
    required this.searchResult,
    super.key,
  });

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final Logger _logger = Logger("_PeoplePageState");
  final _selectedFiles = SelectedFiles();
  List<EnteFile>? files;
  int? smallestClusterSize;
  Future<List<EnteFile>> filesFuture = Future.value([]);
  late PersonEntity _person;

  bool get showSuggestionBanner => (!userDismissedSuggestionBanner &&
      smallestClusterSize != null &&
      smallestClusterSize! >= kMinimumClusterSizeSearchResult &&
      files != null &&
      files!.isNotEmpty);

  bool userDismissedSuggestionBanner = false;

  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    ClusterFeedbackService.resetLastViewedClusterID();
    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      setState(() {
        if (event.type == PeopleEventType.saveOrEditPerson) {
          if (event.person != null &&
              event.person!.remoteID == _person.remoteID) {
            _person = event.person!;
          }
        }
      });
    });

    filesFuture = loadPersonFiles();

    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files?.remove(updatedFile);
        }
        setState(() {});
      }
    });
  }

  Future<List<EnteFile>> loadPersonFiles() async {
    final result = await SearchService.instance
        .getClusterFilesForPersonID(_person.remoteID);
    if (result.isEmpty) {
      _logger.severe(
        "No files found for person with id ${_person.remoteID}, can't load files",
      );
      return [];
    }
    smallestClusterSize = result.values.fold<int>(result.values.first.length,
        (previousValue, element) {
      return element.length < previousValue ? element.length : previousValue;
    });
    final List<EnteFile> resultFiles = [];
    for (final e in result.entries) {
      resultFiles.addAll(e.value);
    }
    final List<EnteFile> sortedFiles = List<EnteFile>.from(resultFiles);
    sortedFiles.sort((a, b) => b.creationTime!.compareTo(a.creationTime!));
    files = sortedFiles;
    return sortedFiles;
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _peopleChangedEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building for ${_person.data.name}");
    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: widget.searchResult != null
            ? SearchFilterDataProvider(
                initialGalleryFilter:
                    widget.searchResult!.getHierarchicalSearchFilter(),
              )
            : null,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize:
                Size.fromHeight(widget.searchResult != null ? 90.0 : 50.0),
            child: PeopleAppBar(
              GalleryType.peopleTag,
              _person.data.name,
              _selectedFiles,
              _person,
            ),
          ),
          body: FutureBuilder<List<EnteFile>>(
            future: filesFuture,
            builder: (context, snapshot) {
              final inheritedSearchFilterData = InheritedSearchFilterData.of(
                context,
              );
              if (snapshot.hasData) {
                final personFiles = snapshot.data as List<EnteFile>;
                return Column(
                  children: [
                    Expanded(
                      child: SelectionState(
                        selectedFiles: _selectedFiles,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            inheritedSearchFilterData.isHierarchicalSearchable
                                ? ValueListenableBuilder(
                                    valueListenable: inheritedSearchFilterData
                                        .searchFilterDataProvider!
                                        .isSearchingNotifier,
                                    builder: (
                                      context,
                                      value,
                                      _,
                                    ) {
                                      return value
                                          ? HierarchicalSearchGallery(
                                              tagPrefix: widget.tagPrefix,
                                              selectedFiles: _selectedFiles,
                                            )
                                          : _Gallery(
                                              tagPrefix: widget.tagPrefix,
                                              selectedFiles: _selectedFiles,
                                              personFiles: personFiles,
                                              loadPersonFiles: loadPersonFiles,
                                              personEntity: _person,
                                            );
                                    },
                                  )
                                : _Gallery(
                                    tagPrefix: widget.tagPrefix,
                                    selectedFiles: _selectedFiles,
                                    personFiles: personFiles,
                                    loadPersonFiles: loadPersonFiles,
                                    personEntity: _person,
                                  ),
                            FileSelectionOverlayBar(
                              PeoplePage.overlayType,
                              _selectedFiles,
                              person: _person,
                            ),
                          ],
                        ),
                      ),
                    ),
                    showSuggestionBanner
                        ? Dismissible(
                            key: const Key("suggestionBanner"),
                            direction: DismissDirection.horizontal,
                            onDismissed: (direction) {
                              setState(() {
                                userDismissedSuggestionBanner = true;
                              });
                            },
                            child: PeopleBanner(
                              type: PeopleBannerType.suggestion,
                              startIcon: Icons.face_retouching_natural,
                              actionIcon: Icons.search_outlined,
                              text: "Review suggestions",
                              subText: "Improve the results",
                              onTap: () async {
                                unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PersonReviewClusterSuggestion(
                                        _person,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                );
              } else if (snapshot.hasError) {
                _logger.severe("Error: ${snapshot.error} ${snapshot.stackTrace}}");
                //Need to show an error on the UI here
                return const SizedBox.shrink();
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  final String tagPrefix;
  final SelectedFiles selectedFiles;
  final List<EnteFile> personFiles;
  final Future<List<EnteFile>> Function() loadPersonFiles;
  final PersonEntity personEntity;

  const _Gallery({
    required this.tagPrefix,
    required this.selectedFiles,
    required this.personFiles,
    required this.loadPersonFiles,
    required this.personEntity,
  });

  @override
  Widget build(BuildContext context) {
    return Gallery(
      asyncLoader: (
        creationStartTime,
        creationEndTime, {
        limit,
        asc,
      }) async {
        final result = await loadPersonFiles();
        return Future.value(
          FileLoadResult(
            result,
            false,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvents: [
        Bus.instance.on<PeopleChangedEvent>(),
      ],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: tagPrefix + tagPrefix,
      selectedFiles: selectedFiles,
      initialFiles: personFiles.isNotEmpty ? [personFiles.first] : [],
      header:
          personEntity.data.email != null && personEntity.data.email!.isNotEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: EndToEndBanner(
                    title: "Link email",
                    caption: "for faster sharing",
                    leadingIcon: Icons.email_outlined,
                    onTap: () async {
                      await routeToPage(
                        context,
                        LinkEmailScreen(personEntity.remoteID),
                      );
                    },
                  ),
                ),
    );
  }
}
