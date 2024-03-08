import "dart:math";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/face_ml/feedback/cluster_feedback.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class PersonReviewClusterSuggestion extends StatefulWidget {
  final Person person;

  const PersonReviewClusterSuggestion(
    this.person, {
    super.key,
  });

  @override
  State<PersonReviewClusterSuggestion> createState() => _PersonClustersState();
}

class _PersonClustersState extends State<PersonReviewClusterSuggestion> {
  int currentSuggestionIndex = 0;
  Key futureBuilderKey = UniqueKey();

  // Declare a variable for the future
  late Future<List<(int, List<EnteFile>)>> futureClusterSuggestions;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState
    _fetchClusterSuggestions();
    // futureClusterSuggestions = ClusterFeedbackService.instance
    //     .getClusterFilesForPersonID(widget.person);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review suggestions'),
      ),
      body: FutureBuilder<List<(int, List<EnteFile>)>>(
        key: futureBuilderKey,
        future: futureClusterSuggestions,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // final List<int> keys = snapshot.data!.map((e) => e.$1).toList();
            if (snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No suggestions for ${widget.person.attr.name}",
                  style: getEnteTextTheme(context).largeMuted,
                ),
              );
            }
            final numberOfDifferentSuggestions = snapshot.data!.length;
            final currentSuggestion = snapshot.data![currentSuggestionIndex];
            final int clusterID = currentSuggestion.$1;
            final List<EnteFile> files = currentSuggestion.$2;
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClusterPage(
                      files,
                      personID: widget.person,
                      cluserID: clusterID,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 20,
                ),
                child: _buildSuggestionView(
                  clusterID,
                  files,
                  numberOfDifferentSuggestions,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            // log the error
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
    if (yesOrNo) {
      await FaceMLDataDB.instance.assignClusterToPerson(
        personID: widget.person.remoteID,
        clusterID: clusterID,
      );
      Bus.instance.fire(PeopleChangedEvent());
    } else {
      await FaceMLDataDB.instance.captureNotPersonFeedback(
        personID: widget.person.remoteID,
        clusterID: clusterID,
      );
    }

    // Increment the suggestion index
    if (mounted) {
      setState(() => currentSuggestionIndex++);
    }

    // Check if we need to fetch new data
    if (currentSuggestionIndex >= (numberOfSuggestions)) {
      setState(() {
        currentSuggestionIndex = 0;
        futureBuilderKey = UniqueKey(); // Reset to trigger FutureBuilder
        _fetchClusterSuggestions();
      });
    }
  }

  // Method to fetch cluster suggestions
  void _fetchClusterSuggestions() {
    futureClusterSuggestions = ClusterFeedbackService.instance
        .getClusterFilesForPersonID(widget.person);
  }

  Widget _buildSuggestionView(
    int clusterID,
    List<EnteFile> files,
    int numberOfSuggestions,
  ) {
    return Column(
      key: ValueKey("cluster_id-$clusterID"),
      children: <Widget>[
        Text(
          files.length > 1
              ? "These photos belong to ${widget.person.attr.name}?"
              : "This photo belongs to ${widget.person.attr.name}?",
          style: getEnteTextTheme(context).largeMuted,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildThumbnailWidgets(
            files,
            clusterID,
          ),
        ),
        if (files.length > 4) const SizedBox(height: 24),
        if (files.length > 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildThumbnailWidgets(
              files,
              clusterID,
              start: 4,
            ),
          ),
        const SizedBox(
          height: 24.0,
        ),
        Text(
          "${files.length} photos",
          style: getEnteTextTheme(context).body,
        ),
        const SizedBox(
          height: 24.0,
        ), // Add some spacing between the thumbnail and the text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ButtonWidget(
                buttonType: ButtonType.primary,
                labelText: 'Yes, confirm',
                buttonSize: ButtonSize.large,
                onTap: () async => {
                  await _handleUserClusterChoice(
                    clusterID,
                    true,
                    numberOfSuggestions,
                  ),
                },
              ),
              const SizedBox(height: 12.0), // Add some spacing
              ButtonWidget(
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
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildThumbnailWidgets(
    List<EnteFile> files,
    int cluserId, {
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
            ),
          ),
        ),
      ),
    );
  }
}
