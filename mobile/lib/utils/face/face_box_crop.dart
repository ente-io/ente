import "dart:io" show File;

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/services/machine_learning/face_thumbnail_generator.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:pool/pool.dart";

void resetPool({required bool fullFile}) {
  if (fullFile) {
    _poolFullFileFaceGenerations =
        Pool(20, timeout: const Duration(seconds: 15));
  } else {
    _poolThumbnailFaceGenerations =
        Pool(100, timeout: const Duration(seconds: 15));
  }
}

final _logger = Logger("FaceCropUtils");

const int _retryLimit = 3;
final LRUMap<String, Uint8List?> _faceCropCache = LRUMap(1000);
final LRUMap<String, Uint8List?> _faceCropThumbnailCache = LRUMap(1000);
Pool _poolFullFileFaceGenerations =
    Pool(20, timeout: const Duration(seconds: 15));
Pool _poolThumbnailFaceGenerations =
    Pool(100, timeout: const Duration(seconds: 15));

Future<Uint8List?> checkGetCachedCropForFaceID(String faceID) async {
  final Uint8List? cachedCover = _faceCropCache.get(faceID);
  return cachedCover;
}

Future<void> putCachedCropForFaceID(
  String faceID,
  Uint8List data,
) async {
  _faceCropCache.put(faceID, data);
}

Future<Map<String, Uint8List>?> getCachedFaceCrops(
  EnteFile enteFile,
  Iterable<Face> faces, {
  int fetchAttempt = 1,
  bool useFullFile = true,
}) async {
  try {
    final faceIdToCrop = <String, Uint8List>{};
    final facesWithoutCrops = <String, FaceBox>{};
    for (final face in faces) {
      final Uint8List? cachedFace = _faceCropCache.get(face.faceID);
      if (cachedFace != null) {
        faceIdToCrop[face.faceID] = cachedFace;
      } else {
        final faceCropCacheFile = cachedFaceCropPath(face.faceID);
        if ((await faceCropCacheFile.exists())) {
          final data = await faceCropCacheFile.readAsBytes();
          _faceCropCache.put(face.faceID, data);
          faceIdToCrop[face.faceID] = data;
        } else {
          facesWithoutCrops[face.faceID] = face.detection.box;
        }
      }
    }
    if (facesWithoutCrops.isEmpty) {
      return faceIdToCrop;
    }

    if (!useFullFile) {
      for (final face in faces) {
        if (facesWithoutCrops.containsKey(face.faceID)) {
          final Uint8List? cachedFaceThumbnail =
              _faceCropThumbnailCache.get(face.faceID);
          if (cachedFaceThumbnail != null) {
            faceIdToCrop[face.faceID] = cachedFaceThumbnail;
            facesWithoutCrops.remove(face.faceID);
          }
        }
      }
      if (facesWithoutCrops.isEmpty) {
        return faceIdToCrop;
      }
    }

    late final Pool relevantResourcePool;
    if (useFullFile) {
      relevantResourcePool = _poolFullFileFaceGenerations;
    } else {
      relevantResourcePool = _poolThumbnailFaceGenerations;
    }

    final result = await relevantResourcePool.withResource(
      () async => await _getFaceCrops(
        enteFile,
        facesWithoutCrops,
        useFullFile: useFullFile,
      ),
    );
    if (result == null) {
      return (faceIdToCrop.isEmpty) ? null : faceIdToCrop;
    }
    for (final entry in result.entries) {
      final Uint8List? computedCrop = result[entry.key];
      if (computedCrop != null) {
        faceIdToCrop[entry.key] = computedCrop;
        if (useFullFile) {
          _faceCropCache.put(entry.key, computedCrop);
          final faceCropCacheFile = cachedFaceCropPath(entry.key);
          faceCropCacheFile.writeAsBytes(computedCrop).ignore();
        } else {
          _faceCropThumbnailCache.put(entry.key, computedCrop);
        }
      }
    }
    return faceIdToCrop.isEmpty ? null : faceIdToCrop;
  } catch (e, s) {
    _logger.severe(
      "Error getting face crops for faceIDs: ${faces.map((face) => face.faceID).toList()}",
      e,
      s,
    );
    resetPool(fullFile: useFullFile);
    if (fetchAttempt <= _retryLimit) {
      return getCachedFaceCrops(
        enteFile,
        faces,
        fetchAttempt: fetchAttempt + 1,
        useFullFile: useFullFile,
      );
    }
    return null;
  }
}

Future<Uint8List?> precomputeClusterFaceCrop(
  file,
  clusterID, {
  required bool useFullFile,
}) async {
  try {
    final w = (kDebugMode ? EnteWatch('precomputeClusterFaceCrop') : null)?..start();
    final Face? face = await MLDataDB.instance.getCoverFaceForPerson(
      recentFileID: file.uploadedFileID!,
      clusterID: clusterID,
    );
    w?.log('getCoverFaceForPerson');
    if (face == null) {
      debugPrint(
        "No cover face for cluster $clusterID and recentFile ${file.uploadedFileID}",
      );
      return null;
    }
    EnteFile? fileForFaceCrop = file;
    if (face.fileID != file.uploadedFileID!) {
      fileForFaceCrop = await FilesDB.instance.getAnyUploadedFile(face.fileID);
      w?.log('getAnyUploadedFile');
    }
    if (fileForFaceCrop == null) {
      return null;
    }
    final cropMap = await getCachedFaceCrops(
      fileForFaceCrop,
      [face],
      useFullFile: useFullFile,
    );
    w?.logAndReset('getCachedFaceCrops');
    return cropMap?[face.faceID];
  } catch (e, s) {
    _logger.severe(
      "Error getting cover face for cluster $clusterID",
      e,
      s,
    );
    return null;
  }
}

Future<Map<String, Uint8List>?> _getFaceCrops(
  EnteFile file,
  Map<String, FaceBox> faceBoxeMap, {
  bool useFullFile = true,
}) async {
  late String? imagePath;
  if (useFullFile && file.fileType != FileType.video) {
    final File? ioFile = await getFile(file);
    if (ioFile == null) {
      return null;
    }
    imagePath = ioFile.path;
  } else {
    final thumbnail = await getThumbnailForUploadedFile(file);
    if (thumbnail == null) {
      return null;
    }
    imagePath = thumbnail.path;
  }
  final List<String> faceIds = [];
  final List<FaceBox> faceBoxes = [];
  for (final e in faceBoxeMap.entries) {
    faceIds.add(e.key);
    faceBoxes.add(e.value);
  }
  final List<Uint8List> faceCrop =
      await FaceThumbnailGenerator.instance.generateFaceThumbnails(
    // await generateJpgFaceThumbnails(
    imagePath,
    faceBoxes,
  );
  final Map<String, Uint8List> result = {};
  for (int i = 0; i < faceCrop.length; i++) {
    result[faceIds[i]] = faceCrop[i];
  }
  return result;
}
