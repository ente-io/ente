import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/search_result.dart";
import 'package:photos/models/selected_files.dart';
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
import "package:photos/ui/viewer/people/person_gallery_suggestion.dart";
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
  Future<List<EnteFile>> filesFuture = Future.value([]);
  late PersonEntity _person;

  bool userDismissedPersonGallerySuggestion = false;

  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;
  late SearchFilterDataProvider? _searchFilterDataProvider;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    ClusterFeedbackService.resetLastViewedClusterID();
    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.saveOrEditPerson) {
        if (event.person != null &&
            event.person!.remoteID == _person.remoteID) {
          setState(() {
            _person = event.person!;
          });
        }
      }
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
    _searchFilterDataProvider = widget.searchResult != null
        ? SearchFilterDataProvider(
            initialGalleryFilter:
                widget.searchResult!.getHierarchicalSearchFilter(),
          )
        : null;
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
    final Set<EnteFile> resultFiles = {};
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
        searchFilterDataProvider: _searchFilterDataProvider,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize:
                Size.fromHeight(widget.searchResult != null ? 90.0 : 50.0),
            child: PeopleAppBar(
              GalleryType.peopleTag,
              _person.data.isIgnored
                  ? AppLocalizations.of(context).ignored
                  : _person.data.name,
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
                return SelectionState(
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
                );
              } else if (snapshot.hasError) {
                _logger
                    .severe("Error: ${snapshot.error} ${snapshot.stackTrace}}");
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

class _Gallery extends StatefulWidget {
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
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  bool userDismissedPersonGallerySuggestion = false;

  @override
  Widget build(BuildContext context) {
    return Gallery(
      asyncLoader: (
        creationStartTime,
        creationEndTime, {
        limit,
        asc,
      }) async {
        final result = await widget.loadPersonFiles();
        return Future.value(
          FileLoadResult(
            result,
            false,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvents: [Bus.instance.on<PeopleChangedEvent>()],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix + widget.tagPrefix,
      selectedFiles: widget.selectedFiles,
      initialFiles:
          widget.personFiles.isNotEmpty ? [widget.personFiles.first] : [],
      header: Column(
        children: [
          (widget.personEntity.data.email != null &&
                      widget.personEntity.data.email!.isNotEmpty) ||
                  widget.personEntity.data.isIgnored
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: EndToEndBanner(
                    title: context.l10n.linkEmail,
                    caption: context.l10n.linkEmailToContactBannerCaption,
                    leadingIcon: Icons.email_outlined,
                    onTap: () async {
                      await routeToPage(
                        context,
                        LinkEmailScreen(widget.personEntity.remoteID),
                      );
                    },
                  ),
                ),
          !userDismissedPersonGallerySuggestion
              ? Dismissible(
                  key: const Key("personGallerySuggestion"),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    setState(() {
                      userDismissedPersonGallerySuggestion = true;
                    });
                  },
                  child: PersonGallerySuggestion(
                    person: widget.personEntity,
                    onClose: () {
                      setState(() {
                        userDismissedPersonGallerySuggestion = true;
                      });
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
