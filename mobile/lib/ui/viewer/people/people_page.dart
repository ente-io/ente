import "dart:async";
import "dart:developer";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/search_service.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/people_app_bar.dart";
import "package:photos/ui/viewer/people/people_banner.dart";
import "package:photos/ui/viewer/people/person_cluster_suggestion.dart";

class PeoplePage extends StatefulWidget {
  final String tagPrefix;
  final PersonEntity person;

  static const GalleryType appBarType = GalleryType.peopleTag;
  static const GalleryType overlayType = GalleryType.peopleTag;

  const PeoplePage({
    this.tagPrefix = "",
    required this.person,
    Key? key,
  }) : super(key: key);

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final Logger _logger = Logger("_PeoplePageState");
  final _selectedFiles = SelectedFiles();
  List<EnteFile>? files;
  int? smallestClusterSize;
  Future<List<EnteFile>> filesFuture = Future.value([]);

  bool get showSuggestionBanner => (!userDismissedSuggestionBanner &&
      smallestClusterSize != null &&
      smallestClusterSize! >= kMinimumClusterSizeSearchResult &&
      files != null &&
      files!.isNotEmpty &&
      files!.length > 200);

  bool userDismissedSuggestionBanner = false;

  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  @override
  void initState() {
    super.initState();
    ClusterFeedbackService.resetLastViewedClusterID();
    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      setState(() {});
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
    log("loadPersonFiles");
    final result = await SearchService.instance
        .getClusterFilesForPersonID(widget.person.remoteID);
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
    _logger.info("Building for ${widget.person.data.name}");
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: PeopleAppBar(
          GalleryType.peopleTag,
          widget.person.data.name,
          _selectedFiles,
          widget.person,
        ),
      ),
      body: FutureBuilder<List<EnteFile>>(
        future: filesFuture,
        builder: (context, snapshot) {
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
                        Gallery(
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
                          reloadEvent:
                              Bus.instance.on<LocalPhotosUpdatedEvent>(),
                          forceReloadEvents: [
                            Bus.instance.on<PeopleChangedEvent>(),
                          ],
                          removalEventTypes: const {
                            EventType.deletedFromRemote,
                            EventType.deletedFromEverywhere,
                            EventType.hide,
                          },
                          tagPrefix: widget.tagPrefix + widget.tagPrefix,
                          selectedFiles: _selectedFiles,
                          initialFiles:
                              personFiles.isNotEmpty ? [personFiles.first] : [],
                        ),
                        FileSelectionOverlayBar(
                          PeoplePage.overlayType,
                          _selectedFiles,
                          person: widget.person,
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
                                    widget.person,
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
            log("Error: ${snapshot.error} ${snapshot.stackTrace}}");
            //Need to show an error on the UI here
            return const SizedBox.shrink();
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
