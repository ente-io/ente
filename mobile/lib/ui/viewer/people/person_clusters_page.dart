import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/hooks/add_photos_sheet.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class PersonClustersPage extends StatefulWidget {
  final PersonEntity person;

  const PersonClustersPage(
    this.person, {
    super.key,
  });

  @override
  State<PersonClustersPage> createState() => _PersonClustersPageState();
}

class _PersonClustersPageState extends State<PersonClustersPage> {
  final Logger _logger = Logger("_PersonClustersState");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person.data.name),
      ),
      body: FutureBuilder<Map<String, List<EnteFile>>>(
        future: SearchService.instance
            .getClusterFilesForPersonID(widget.person.remoteID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final clusters = snapshot.data!;
            final List<String> keys = clusters.keys.toList();
            // Sort the clusters by the number of files in each cluster, largest first
            keys.sort(
              (b, a) => clusters[a]!.length.compareTo(clusters[b]!.length),
            );
            return ListView.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final String clusterID = keys[index];
                final List<EnteFile> files = clusters[clusterID]!;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClusterPage(
                          files,
                          personID: widget.person,
                          clusterID: clusterID,
                          showNamingBanner: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ClipPath(
                            clipper: ShapeBorderClipper(
                              shape: ContinuousRectangleBorder(
                                borderRadius: BorderRadius.circular(75),
                              ),
                            ),
                            child: files.isNotEmpty
                                ? PersonFaceWidget(
                                    files.first,
                                    clusterID: clusterID,
                                  )
                                : const NoThumbnailWidget(
                                    addBorder: false,
                                  ),
                          ),
                        ),
                        const SizedBox(
                          width: 8.0,
                        ), // Add some spacing between the thumbnail and the text
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "${files.length} photos",
                                  style: getEnteTextTheme(context).body,
                                ),
                                (index != 0)
                                    ? GestureDetector(
                                        onTap: () async {
                                          try {
                                            await PersonService.instance
                                                .removeClusterToPerson(
                                              personID: widget.person.remoteID,
                                              clusterID: clusterID,
                                            );
                                            _logger.info(
                                              "Removed cluster $clusterID from person ${widget.person.remoteID}",
                                            );
                                            Bus.instance
                                                .fire(PeopleChangedEvent());
                                            setState(() {});
                                          } catch (e) {
                                            _logger.severe(
                                              "removing cluster from person,",
                                              e,
                                            );
                                          }
                                        },
                                        child: const Icon(
                                          CupertinoIcons.minus_circled,
                                          color: Colors.red,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            _logger.warning("Failed to get cluster", snapshot.error);
            return const Center(child: Text("Error"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class PersonClustersWidget extends StatefulWidget {
  final PersonEntity person;
  final double? height;

  const PersonClustersWidget(
    this.person, {
    super.key,
    this.height,
  });

  @override
  State<PersonClustersWidget> createState() => _PersonClustersWidgetState();
}

class _PersonClustersWidgetState extends State<PersonClustersWidget> {
  final Logger _logger = Logger("_PersonClustersWidgetState");

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<EnteFile>>>(
      future: SearchService.instance
          .getClusterFilesForPersonID(widget.person.remoteID),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final clusters = snapshot.data!;
          final List<String> keys = clusters.keys.toList();
          // Sort the clusters by the number of files in each cluster, largest first
          keys.sort(
            (b, a) => clusters[a]!.length.compareTo(clusters[b]!.length),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              // Determine number of columns based on available width
              // Minimum column width of 150, maximum of 250
              final double columnWidth =
                  MediaQuery.of(context).size.width > 600 ? 250 : 150;
              final int crossAxisCount =
                  (constraints.maxWidth / columnWidth).floor().clamp(2, 5);

              // Calculate expected height based on number of rows
              final int rowCount = (keys.length / crossAxisCount).ceil();
              // Thumbnail height + text height + spacing
              final double expectedHeight =
                  widget.height ?? (rowCount * (110 + 30 + 8));

              return SizedBox(
                height: expectedHeight,
                child: GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio:
                        1, // Adjust this to control height vs width
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final String clusterID = keys[index];
                    final List<EnteFile> files = clusters[clusterID]!;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClusterPage(
                              files,
                              personID: widget.person,
                              clusterID: clusterID,
                              showNamingBanner: false,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: ClipPath(
                              clipper: ShapeBorderClipper(
                                shape: ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.circular(75),
                                ),
                              ),
                              child: files.isNotEmpty
                                  ? PersonFaceWidget(
                                      files.first,
                                      clusterID: clusterID,
                                    )
                                  : const NoThumbnailWidget(
                                      addBorder: false,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.memoryCount(
                              files.length,
                              NumberFormat().format(files.length),
                            ),
                            style: getEnteTextTheme(context).small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          _logger.warning("Failed to get cluster", snapshot.error);
          return const Center(child: Text("Error"));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
