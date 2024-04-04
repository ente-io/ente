import "dart:developer" show log;
import "dart:io" show Platform;
import "dart:typed_data";

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/face.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/cropped_face_image_view.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/utils/face/face_box_crop.dart";
import "package:photos/utils/thumbnail_util.dart";

class FaceWidget extends StatelessWidget {
  final EnteFile file;
  final Face face;
  final Person? person;
  final int? clusterID;
  final bool highlight;

  const FaceWidget(
    this.file,
    this.face, {
    this.person,
    this.clusterID,
    this.highlight = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isAndroid) {
      return FutureBuilder<Uint8List?>(
        future: getFaceCrop(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final ImageProvider imageProvider = MemoryImage(snapshot.data!);
            return GestureDetector(
              onTap: () async {
                log(
                  "FaceWidget is tapped, with person $person and clusterID $clusterID",
                  name: "FaceWidget",
                );
                if (person == null && clusterID == null) {
                  return;
                }
                if (person != null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PeoplePage(
                        person: person!,
                      ),
                    ),
                  );
                } else if (clusterID != null) {
                  final fileIdsToClusterIds =
                      await FaceMLDataDB.instance.getFileIdToClusterIds();
                  final files = await SearchService.instance.getAllFiles();
                  final clusterFiles = files
                      .where(
                        (file) =>
                            fileIdsToClusterIds[file.uploadedFileID]
                                ?.contains(clusterID) ??
                            false,
                      )
                      .toList();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClusterPage(
                        clusterFiles,
                        clusterID: clusterID!,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  // TODO: the edges of the green line are still not properly rounded around ClipRRect
                  Container(
                    height: 60,
                    width: 60,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(16, 12)),
                        side: highlight
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
                  const SizedBox(height: 8),
                  if (person != null)
                    Text(
                      person!.attr.name.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (kDebugMode)
                    Text(
                      'S: ${face.score.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                    ),
                  // if (kDebugMode)
                  //   if (highlight)
                  //     const Text(
                  //       "Highlighted",
                  //       style: TextStyle(
                  //         color: Colors.red,
                  //         fontSize: 12,
                  //       ),
                  //     ),
                ],
              ),
            );
          } else {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ClipRRect(
                borderRadius: BorderRadius.all(Radius.elliptical(16, 12)),
                child: SizedBox(
                  width: 60, // Ensure consistent sizing
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
                width: 60, // Ensure consistent sizing
                height: 60,
                child: NoThumbnailWidget(),
              ),
            );
          }
        },
      );
    } else {
      return Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () async {
              log(
                "FaceWidget is tapped, with person $person and clusterID $clusterID",
                name: "FaceWidget",
              );
              if (person == null && clusterID == null) {
                return;
              }
              if (person != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PeoplePage(
                      person: person!,
                    ),
                  ),
                );
              } else if (clusterID != null) {
                final fileIdsToClusterIds =
                    await FaceMLDataDB.instance.getFileIdToClusterIds();
                final files = await SearchService.instance.getAllFiles();
                final clusterFiles = files
                    .where(
                      (file) =>
                          fileIdsToClusterIds[file.uploadedFileID]
                              ?.contains(clusterID) ??
                          false,
                    )
                    .toList();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClusterPage(
                      clusterFiles,
                      clusterID: clusterID!,
                    ),
                  ),
                );
              }
            },
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          const BorderRadius.all(Radius.elliptical(16, 12)),
                      side: highlight
                          ? BorderSide(
                              color: getEnteColorScheme(context).primary700,
                              width: 2.0,
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
                      child: CroppedFaceImageView(
                        enteFile: file,
                        face: face,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (person != null)
                  Text(
                    person!.attr.name.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (kDebugMode)
                  Text(
                    'S: ${face.score.toStringAsFixed(3)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<Uint8List?> getFaceCrop() async {
    try {
      final Uint8List? cachedFace = faceCropCache.get(face.faceID);
      if (cachedFace != null) {
        return cachedFace;
      }
      final faceCropCacheFile = cachedFaceCropPath(face.faceID);
      if ((await faceCropCacheFile.exists())) {
        final data = await faceCropCacheFile.readAsBytes();
        faceCropCache.put(face.faceID, data);
        return data;
      }

      final result = await pool.withResource(
        () async => await getFaceCrops(
          file,
          {
            face.faceID: face.detection.box,
          },
        ),
      );
      final Uint8List? computedCrop = result?[face.faceID];
      if (computedCrop != null) {
        faceCropCache.put(face.faceID, computedCrop);
        faceCropCacheFile.writeAsBytes(computedCrop).ignore();
      }
      return computedCrop;
    } catch (e, s) {
      log(
        "Error getting face for faceID: ${face.faceID}",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
