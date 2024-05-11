import "dart:async";
import "dart:developer";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
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
import "package:photos/ui/components/notification_widget.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/people/people_app_bar.dart";
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

  bool get showSuggestionBanner => (!userDismissed &&
      smallestClusterSize != null &&
      smallestClusterSize! >= kMinimumClusterSizeSearchResult &&
      files != null &&
      files!.isNotEmpty &&
      files!.length > 200);

  bool userDismissed = false;

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
                showSuggestionBanner
                    ? Dismissible(
                        key: const Key("suggestionBanner"),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          setState(() {
                            userDismissed = true;
                          });
                        },
                        child: RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0,
                            ),
                            child: NotificationWidget(
                              startIcon: Icons.star_border_rounded,
                              actionIcon: Icons.search_outlined,
                              text: "Review suggestions",
                              subText:
                                  "Improve the results by adding more suggested photos",
                              type: NotificationType.greenBanner,
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
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 1000.ms,
                                delay: 3200.ms,
                                size: 0.6,
                              ),
                        ),
                      )
                    : const SizedBox.shrink(),
                Expanded(
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
                        reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
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
