import "dart:async" show StreamSubscription, unawaited;
import "dart:math";
import "dart:typed_data";

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/person_clusters_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class SuggestionUserFeedback {
  final bool accepted;
  final ClusterSuggestion suggestion;

  SuggestionUserFeedback(this.accepted, this.suggestion);
}

class PersonReviewClusterSuggestion extends StatefulWidget {
  final PersonEntity person;

  const PersonReviewClusterSuggestion(
    this.person, {
    super.key,
  });

  @override
  State<PersonReviewClusterSuggestion> createState() => _PersonClustersState();
}

class _PersonClustersState extends State<PersonReviewClusterSuggestion> {
  int currentSuggestionIndex = 0;
  bool fetch = true;
  Key futureBuilderKeySuggestions = UniqueKey();
  Key futureBuilderKeyFaceThumbnails = UniqueKey();
  bool canGiveFeedback = true;
  List<SuggestionUserFeedback> pastUserFeedback = [];
  List<ClusterSuggestion> allSuggestions = [];
  late final Logger _logger = Logger('_PersonClustersState');

  // Declare a variable for the future
  late Future<List<ClusterSuggestion>> futureClusterSuggestions;
  late StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState
    if (fetch) _fetchClusterSuggestions();
    fetch = true;
  }

  @override
  void dispose() {
    _peopleChangedEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reviewSuggestions),
        actions: [
          if (pastUserFeedback.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_outlined),
              onPressed: () async {
                await _undoLastFeedback();
              },
            ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PersonClustersPage(widget.person),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ClusterSuggestion>>(
        key: futureBuilderKeySuggestions,
        future: futureClusterSuggestions,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No suggestions for ${widget.person.data.name}",
                  style: getEnteTextTheme(context).largeMuted,
                ),
              );
            }

            allSuggestions = snapshot.data!;
            final numberOfDifferentSuggestions = allSuggestions.length;
            final currentSuggestion = allSuggestions[currentSuggestionIndex];
            final int clusterID = currentSuggestion.clusterIDToMerge;
            final double distance = currentSuggestion.distancePersonToCluster;
            final bool usingMean = currentSuggestion.usedOnlyMeanForSuggestion;
            final List<EnteFile> files = currentSuggestion.filesInCluster;

            final Future<Map<int, Uint8List?>> generateFacedThumbnails =
                _generateFaceThumbnails(
              files.sublist(0, min(files.length, 8)),
              clusterID,
            );

            _peopleChangedEvent =
                Bus.instance.on<PeopleChangedEvent>().listen((event) {
              if (event.type == PeopleEventType.removedFilesFromCluster &&
                  (event.source == clusterID.toString())) {
                for (var updatedFile in event.relevantFiles!) {
                  files.remove(updatedFile);
                }
                fetch = false;
                setState(() {});
              }
            });
            return GestureDetector(
              onTap: () {
                final List<EnteFile> sortedFiles =
                    List<EnteFile>.from(currentSuggestion.filesInCluster);
                sortedFiles.sort(
                  (a, b) => b.creationTime!.compareTo(a.creationTime!),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClusterPage(
                      sortedFiles,
                      personID: widget.person,
                      clusterID: clusterID,
                      showNamingBanner: false,
                    ),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 20,
                ),
                child: _buildSuggestionView(
                  clusterID,
                  distance,
                  usingMean,
                  files,
                  numberOfDifferentSuggestions,
                  allSuggestions,
                  generateFacedThumbnails,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            _logger.severe(
              "Error fetching suggestions",
              snapshot.error!,
              snapshot.stackTrace,
            );
            return const Center(child: Text("Error"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> _handleUserClusterChoice(
    int clusterID,
    bool yesOrNo,
    int numberOfSuggestions,
  ) async {
    // Perform the action based on clusterID, e.g., assignClusterToPerson or captureNotPersonFeedback
    if (!canGiveFeedback) {
      return;
    }
    // Store the feedback in case the user wants to revert
    pastUserFeedback.add(
      SuggestionUserFeedback(
        yesOrNo,
        allSuggestions[currentSuggestionIndex],
      ),
    );
    if (yesOrNo) {
      canGiveFeedback = false;
      await FaceMLDataDB.instance.assignClusterToPerson(
        personID: widget.person.remoteID,
        clusterID: clusterID,
      );
      Bus.instance.fire(PeopleChangedEvent());
      // Increment the suggestion index
      if (mounted) {
        setState(() => currentSuggestionIndex++);
      }

      // Check if we need to fetch new data
      if (currentSuggestionIndex >= (numberOfSuggestions)) {
        setState(() {
          currentSuggestionIndex = 0;
          futureBuilderKeySuggestions =
              UniqueKey(); // Reset to trigger FutureBuilder
          futureBuilderKeyFaceThumbnails = UniqueKey();
          _fetchClusterSuggestions();
        });
      } else {
        futureBuilderKeyFaceThumbnails = UniqueKey();
        fetch = false;
        setState(() {});
      }
    } else {
      await _rejectSuggestion(clusterID, numberOfSuggestions);
    }
  }

  Future<void> _rejectSuggestion(
    int clusterID,
    int numberOfSuggestions,
  ) async {
    canGiveFeedback = false;
    await FaceMLDataDB.instance.captureNotPersonFeedback(
      personID: widget.person.remoteID,
      clusterID: clusterID,
    );
    // Recalculate the suggestions when a suggestion is rejected
    setState(() {
      currentSuggestionIndex = 0;
      futureBuilderKeySuggestions =
          UniqueKey(); // Reset to trigger FutureBuilder
      futureBuilderKeyFaceThumbnails = UniqueKey();
      _fetchClusterSuggestions();
    });
  }

  // Method to fetch cluster suggestions
  void _fetchClusterSuggestions() {
    futureClusterSuggestions =
        ClusterFeedbackService.instance.getSuggestionForPerson(widget.person);
  }

  Widget _buildSuggestionView(
    int clusterID,
    double distance,
    bool usingMean,
    List<EnteFile> files,
    int numberOfSuggestions,
    List<ClusterSuggestion> allSuggestions,
    Future<Map<int, Uint8List?>> generateFaceThumbnails,
  ) {
    final widgetToReturn = Column(
      key: ValueKey("cluster_id-$clusterID-files-${files.length}"),
      children: <Widget>[
        if (kDebugMode)
          Text(
            "ClusterID: $clusterID, Distance: ${distance.toStringAsFixed(3)}, usingMean: $usingMean",
            style: getEnteTextTheme(context).smallMuted,
          ),
        Text(
          "${widget.person.data.name}?",
          style: getEnteTextTheme(context).largeMuted,
        ),
        const SizedBox(height: 24),
        _buildThumbnailWidget(
          files,
          clusterID,
          generateFaceThumbnails,
        ),
        const SizedBox(
          height: 24.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ButtonWidget(
                  buttonType: ButtonType.critical,
                  labelText: 'No',
                  buttonSize: ButtonSize.large,
                  onTap: () async => {
                    await _handleUserClusterChoice(
                      clusterID,
                      false,
                      numberOfSuggestions,
                    ),
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ButtonWidget(
                  buttonType: ButtonType.primary,
                  labelText: context.l10n.yes,
                  buttonSize: ButtonSize.large,
                  onTap: () async => {
                    await _handleUserClusterChoice(
                      clusterID,
                      true,
                      numberOfSuggestions,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(
        //   height: 24.0,
        // ),
        // ButtonWidget(
        //   shouldSurfaceExecutionStates: false,
        //   buttonType: ButtonType.neutral,
        //   labelText: 'Assign different person',
        //   buttonSize: ButtonSize.small,
        //   onTap: () async {
        //     final result = await showAssignPersonAction(
        //       context,
        //       clusterID: clusterID,
        //     );
        //     if (result != null &&
        //         (result is (PersonEntity, EnteFile) ||
        //             result is PersonEntity)) {
        //       await _rejectSuggestion(clusterID, numberOfSuggestions);
        //     }
        //   },
        // ),
      ],
    );
    // Precompute face thumbnails for next suggestions, in case there are
    const precomputeSuggestions = 8;
    const maxPrecomputations = 8;
    int compCount = 0;
    if (allSuggestions.length > currentSuggestionIndex + 1) {
      outerLoop:
      for (final suggestion in allSuggestions.sublist(
        currentSuggestionIndex + 1,
        min(
          allSuggestions.length,
          currentSuggestionIndex + precomputeSuggestions,
        ),
      )) {
        final files = suggestion.filesInCluster;
        final clusterID = suggestion.clusterIDToMerge;
        for (final file in files.sublist(0, min(files.length, 8))) {
          unawaited(
            PersonFaceWidget.precomputeNextFaceCrops(
              file,
              clusterID,
              useFullFile: false,
            ),
          );
          compCount++;
          if (compCount >= maxPrecomputations) {
            debugPrint(
              'Prefetching $compCount face thumbnails for suggestions',
            );
            break outerLoop;
          }
        }
      }
    }
    return widgetToReturn;
  }

  Widget _buildThumbnailWidget(
    List<EnteFile> files,
    int clusterID,
    Future<Map<int, Uint8List?>> generateFaceThumbnails,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: FutureBuilder<Map<int, Uint8List?>>(
        key: futureBuilderKeyFaceThumbnails,
        future: generateFaceThumbnails,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final faceThumbnails = snapshot.data!;
            canGiveFeedback = true;
            return Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildThumbnailWidgetsRow(
                    files,
                    clusterID,
                    faceThumbnails,
                  ),
                ),
                if (files.length > 4) const SizedBox(height: 24),
                if (files.length > 4)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildThumbnailWidgetsRow(
                      files,
                      clusterID,
                      faceThumbnails,
                      start: 4,
                    ),
                  ),
                const SizedBox(height: 24.0),
                Text(
                  "${files.length} photos",
                  style: getEnteTextTheme(context).body,
                ),
              ],
            );
          } else if (snapshot.hasError) {
            // log the error
            return const Center(child: Text("Error"));
          } else {
            canGiveFeedback = false;
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  List<Widget> _buildThumbnailWidgetsRow(
    List<EnteFile> files,
    int cluserId,
    Map<int, Uint8List?> faceThumbnails, {
    int start = 0,
  }) {
    return List<Widget>.generate(
      min(4, max(0, files.length - start)),
      (index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 72,
          height: 72,
          child: ClipOval(
            child: PersonFaceWidget(
              files[start + index],
              clusterID: cluserId,
              useFullFile: false,
              thumbnailFallback: false,
              faceCrop: faceThumbnails[files[start + index].uploadedFileID!],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<int, Uint8List?>> _generateFaceThumbnails(
    List<EnteFile> files,
    int clusterID,
  ) async {
    final futures = <Future<Uint8List?>>[];
    for (final file in files) {
      futures.add(
        PersonFaceWidget.precomputeNextFaceCrops(
          file,
          clusterID,
          useFullFile: false,
        ),
      );
    }
    final faceCropsList = await Future.wait(futures);
    final faceCrops = <int, Uint8List?>{};
    for (var i = 0; i < faceCropsList.length; i++) {
      faceCrops[files[i].uploadedFileID!] = faceCropsList[i];
    }
    return faceCrops;
  }

  Future<void> _undoLastFeedback() async {
    if (pastUserFeedback.isNotEmpty) {
      final SuggestionUserFeedback lastFeedback = pastUserFeedback.removeLast();
      if (lastFeedback.accepted) {
        await PersonService.instance.removeClusterToPerson(
          personID: widget.person.remoteID,
          clusterID: lastFeedback.suggestion.clusterIDToMerge,
        );
      } else {
        await FaceMLDataDB.instance.removeNotPersonFeedback(
          personID: widget.person.remoteID,
          clusterID: lastFeedback.suggestion.clusterIDToMerge,
        );
      }

      // futureClusterSuggestions =
      //     pastUserFeedback.map((element) => element.suggestion)
      //         as Future<List<ClusterSuggestion>>;

      fetch = false;
      futureClusterSuggestions = futureClusterSuggestions.then((list) {
        return list.sublist(currentSuggestionIndex)
          ..insert(0, lastFeedback.suggestion);
      });
      currentSuggestionIndex = 0;
      futureBuilderKeySuggestions = UniqueKey();
      futureBuilderKeyFaceThumbnails = UniqueKey();
      setState(() {});
    }
  }
}
