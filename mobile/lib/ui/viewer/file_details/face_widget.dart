import "dart:developer" show log;
import "dart:typed_data";

import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/face.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/utils/face/face_box_crop.dart";
import "package:photos/utils/thumbnail_util.dart";

class FaceWidget extends StatefulWidget {
  final EnteFile file;
  final Face face;
  final Future<Map<String, Uint8List>?>? faceCrops;
  final PersonEntity? person;
  final int? clusterID;
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
    Key? key,
  }) : super(key: key);

  @override
  State<FaceWidget> createState() => _FaceWidgetState();
}

class _FaceWidgetState extends State<FaceWidget> {
  bool isJustRemoved = false;

  @override
  Widget build(BuildContext context) {
    final bool givenFaces = widget.faceCrops != null;
    return _buildFaceImageGenerated(givenFaces);
  }

  Widget _buildFaceImageGenerated(bool givenFaces) {
    return FutureBuilder<Map<String, Uint8List>?>(
      future: givenFaces ? widget.faceCrops : getFaceCrop(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final ImageProvider imageProvider =
              MemoryImage(snapshot.data![widget.face.faceID]!);

          return GestureDetector(
            onTap: () async {
              if (widget.editMode) return;

              log(
                "FaceWidget is tapped, with person ${widget.person} and clusterID ${widget.clusterID}",
                name: "FaceWidget",
              );
              if (widget.person == null && widget.clusterID == null) {
                // Get faceID and double check that it doesn't belong to an existing clusterID. If it does, push that cluster page
                final w = (kDebugMode ? EnteWatch('FaceWidget') : null)
                  ?..start();
                final existingClusterID = await FaceMLDataDB.instance
                    .getClusterIDForFaceID(widget.face.faceID);
                w?.log('getting existing clusterID for faceID');
                if (existingClusterID != null) {
                  final fileIdsToClusterIds =
                      await FaceMLDataDB.instance.getFileIdToClusterIds();
                  final files = await SearchService.instance.getAllFiles();
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
                }

                // Create new clusterID for the faceID and update DB to assign the faceID to the new clusterID
                final int newClusterID = DateTime.now().microsecondsSinceEpoch;
                await FaceMLDataDB.instance.updateFaceIdToClusterId(
                  {widget.face.faceID: newClusterID},
                );

                // Push page for the new cluster
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClusterPage(
                      [widget.file],
                      clusterID: newClusterID,
                    ),
                  ),
                );
              }
              if (widget.person != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PeoplePage(
                      person: widget.person!,
                    ),
                  ),
                );
              } else if (widget.clusterID != null) {
                final fileIdsToClusterIds =
                    await FaceMLDataDB.instance.getFileIdToClusterIds();
                final files = await SearchService.instance.getAllFiles();
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
                        ? '(ignored)'
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
            log('Error getting face: ${snapshot.error}');
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
      log("removing face/file from cluster from file info widget failed: $e, \n $s");
    }
  }

  Future<Map<String, Uint8List>?> getFaceCrop({int fetchAttempt = 1}) async {
    try {
      final Uint8List? cachedFace = faceCropCache.get(widget.face.faceID);
      if (cachedFace != null) {
        return {widget.face.faceID: cachedFace};
      }
      final faceCropCacheFile = cachedFaceCropPath(widget.face.faceID);
      if ((await faceCropCacheFile.exists())) {
        final data = await faceCropCacheFile.readAsBytes();
        faceCropCache.put(widget.face.faceID, data);
        return {widget.face.faceID: data};
      }

      final result = await poolFullFileFaceGenerations.withResource(
        () async => await getFaceCrops(
          widget.file,
          {
            widget.face.faceID: widget.face.detection.box,
          },
        ),
      );
      final Uint8List? computedCrop = result?[widget.face.faceID];
      if (computedCrop != null) {
        faceCropCache.put(widget.face.faceID, computedCrop);
        faceCropCacheFile.writeAsBytes(computedCrop).ignore();
      }
      return {widget.face.faceID: computedCrop!};
    } catch (e, s) {
      log(
        "Error getting face for faceID: ${widget.face.faceID}",
        error: e,
        stackTrace: s,
      );
      resetPool(fullFile: true);
      if (fetchAttempt <= retryLimit) {
        return getFaceCrop(fetchAttempt: fetchAttempt + 1);
      }
      return null;
    }
  }
}
