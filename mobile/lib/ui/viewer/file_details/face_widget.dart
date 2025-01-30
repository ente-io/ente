import "dart:async";
import "dart:developer" show log;
import "dart:typed_data";

import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/base/id.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/utils/face/face_box_crop.dart";
import "package:photos/utils/toast_util.dart";

class FaceWidget extends StatefulWidget {
  final EnteFile file;
  final Face face;
  final Future<Map<String, Uint8List>?>? faceCrops;
  final PersonEntity? person;
  final String? clusterID;
  final bool highlight;
  final bool editMode;

  const FaceWidget(
    this.file,
    this.face, {
    this.faceCrops,
    this.person,
    this.clusterID,
    this.highlight = false,
    this.editMode = false,
    super.key,
  });

  @override
  State<FaceWidget> createState() => _FaceWidgetState();
}

class _FaceWidgetState extends State<FaceWidget> {
  bool isJustRemoved = false;

  final _logger = Logger("FaceWidget");

  @override
  Widget build(BuildContext context) {
    final bool givenFaces = widget.faceCrops != null;
    return _buildFaceImageGenerated(givenFaces);
  }

  Widget _buildFaceImageGenerated(bool givenFaces) {
    late final mlDataDB = MLDataDB.instance;
    return FutureBuilder<Map<String, Uint8List>?>(
      future: givenFaces
          ? widget.faceCrops
          : getCachedFaceCrops(widget.file, [widget.face]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final ImageProvider imageProvider =
              MemoryImage(snapshot.data![widget.face.faceID]!);

          return GestureDetector(
            onTap: () async {
              if (widget.editMode) return;

              log(
                "FaceWidget is tapped, with person ${widget.person?.data.name} and clusterID ${widget.clusterID}",
                name: "FaceWidget",
              );
              if (widget.person == null && widget.clusterID == null) {
                // Double check that it doesn't belong to an existing clusterID.
                final existingClusterID =
                    await mlDataDB.getClusterIDForFaceID(widget.face.faceID);
                if (existingClusterID != null) {
                  final fileIdsToClusterIds =
                      await mlDataDB.getFileIdToClusterIds();
                  final files =
                      await SearchService.instance.getAllFilesForSearch();
                  final clusterFiles = files
                      .where(
                        (file) =>
                            fileIdsToClusterIds[file.uploadedFileID]
                                ?.contains(existingClusterID) ??
                            false,
                      )
                      .toList();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClusterPage(
                        clusterFiles,
                        clusterID: existingClusterID,
                      ),
                    ),
                  );
                  return;
                }
                if (widget.face.score <= kMinimumQualityFaceScore) {
                  // The face score is too low for automatic clustering,
                  // assigning a manual new clusterID so that the user can cluster it manually
                  final String clusterID = newClusterID();
                  await mlDataDB.updateFaceIdToClusterId(
                    {widget.face.faceID: clusterID},
                  );
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClusterPage(
                        [widget.file],
                        clusterID: clusterID,
                      ),
                    ),
                  );
                  return;
                }

                showShortToast(
                  context,
                  S.of(context).faceNotClusteredYet,
                );
                unawaited(MLService.instance.clusterAllImages(force: true));
                return;
              }
              if (widget.person != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PeoplePage(
                      person: widget.person!,
                      searchResult: null,
                    ),
                  ),
                );
              } else if (widget.clusterID != null) {
                final fileIdsToClusterIds =
                    await mlDataDB.getFileIdToClusterIds();
                final files =
                    await SearchService.instance.getAllFilesForSearch();
                final clusterFiles = files
                    .where(
                      (file) =>
                          fileIdsToClusterIds[file.uploadedFileID]
                              ?.contains(widget.clusterID) ??
                          false,
                    )
                    .toList();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClusterPage(
                      clusterFiles,
                      clusterID: widget.clusterID!,
                    ),
                  ),
                );
              }
            },
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.elliptical(16, 12),
                          ),
                          side: widget.highlight
                              ? BorderSide(
                                  color: getEnteColorScheme(context).primary700,
                                  width: 1.0,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(16, 12)),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // TODO: the edges of the green line are still not properly rounded around ClipRRect
                    if (widget.editMode)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: _cornerIconPressed,
                          child: isJustRemoved
                              ? const Icon(
                                  CupertinoIcons.add_circled_solid,
                                  color: Colors.green,
                                )
                              : const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.person != null)
                  Text(
                    widget.person!.data.isIgnored
                        ? '(' + S.of(context).ignored + ')'
                        : widget.person!.data.name.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (kDebugMode)
                  Text(
                    'S: ${widget.face.score.toStringAsFixed(3)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                if (kDebugMode)
                  Text(
                    'B: ${widget.face.blur.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                if (kDebugMode)
                  Text(
                    'D: ${widget.face.detection.getFaceDirection().toDirectionString()}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                if (kDebugMode)
                  Text(
                    'Sideways: ${widget.face.detection.faceIsSideways().toString()}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                if (kDebugMode && widget.face.score < 0.75)
                  Text(
                    '[Debug only]',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
              ],
            ),
          );
        } else {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ClipRRect(
              borderRadius: BorderRadius.all(Radius.elliptical(16, 12)),
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            _logger.severe(
              'Error getting face: ${snapshot.error} ${snapshot.stackTrace}',
            );
          }
          return const ClipRRect(
            borderRadius: BorderRadius.all(Radius.elliptical(16, 12)),
            child: SizedBox(
              width: 60,
              height: 60,
              child: NoThumbnailWidget(),
            ),
          );
        }
      },
    );
  }

  void _cornerIconPressed() async {
    log('face widget (file info) corner icon is pressed');
    try {
      if (isJustRemoved) {
        await ClusterFeedbackService.instance
            .addFacesToCluster([widget.face.faceID], widget.clusterID!);
      } else {
        await ClusterFeedbackService.instance
            .removeFilesFromCluster([widget.file], widget.clusterID!);
      }

      setState(() {
        isJustRemoved = !isJustRemoved;
      });
    } catch (e, s) {
      _logger.severe(
        "removing face/file from cluster from file info widget failed: $e, \n $s",
      );
    }
  }
}
