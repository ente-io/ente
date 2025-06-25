import "dart:async";
import "dart:io" show File;
import "dart:math" show pow;

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
import "package:photos/utils/standalone/task_queue.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("FaceCropUtils");

const int _retryLimit = 3;
final LRUMap<String, Uint8List?> _faceCropCache = LRUMap(1000);
final LRUMap<String, Uint8List?> _faceCropThumbnailCache = LRUMap(1000);

final LRUMap<String, String> _personOrClusterIdToCachedFaceID = LRUMap(1000);

TaskQueue _queueFullFileFaceGenerations = TaskQueue<String>(
  maxConcurrentTasks: 5,
  taskTimeout: const Duration(minutes: 1),
  maxQueueSize: 100,
);
TaskQueue _queueThumbnailFaceGenerations = TaskQueue<String>(
  maxConcurrentTasks: 5,
  taskTimeout: const Duration(minutes: 1),
  maxQueueSize: 100,
);

Uint8List? checkInMemoryCachedCropForPersonOrClusterID(
  String personOrClusterID,
) {
  final String? faceID =
      _personOrClusterIdToCachedFaceID.get(personOrClusterID);
  if (faceID == null) return null;
  final Uint8List? cachedCover = _faceCropCache.get(faceID);
  return cachedCover;
}

Uint8List? _checkInMemoryCachedCropForFaceID(String faceID) {
  final Uint8List? cachedCover = _faceCropCache.get(faceID);
  return cachedCover;
}

Future<String?> checkUsedFaceIDForPersonOrClusterId(
  String personOrClusterID,
) async {
  final String? cachedFaceID =
      _personOrClusterIdToCachedFaceID.get(personOrClusterID);
  if (cachedFaceID != null) return cachedFaceID;
  final String? faceIDFromDB = await MLDataDB.instance
      .getFaceIdUsedForPersonOrCluster(personOrClusterID);
  if (faceIDFromDB != null) {
    _personOrClusterIdToCachedFaceID.put(personOrClusterID, faceIDFromDB);
  }
  return faceIDFromDB;
}

Future<void> putFaceIdCachedForPersonOrCluster(
  String personOrClusterID,
  String faceID,
) async {
  await MLDataDB.instance.putFaceIdCachedForPersonOrCluster(
    personOrClusterID,
    faceID,
  );
  _personOrClusterIdToCachedFaceID.put(personOrClusterID, faceID);
}

Future<void> _putCachedCropForFaceID(
  String faceID,
  Uint8List data, [
  String? personOrClusterID,
]) async {
  _faceCropCache.put(faceID, data);
  if (personOrClusterID != null) {
    await putFaceIdCachedForPersonOrCluster(personOrClusterID, faceID);
  }
}

Future<void> checkRemoveCachedFaceIDForPersonOrClusterId(
  String personOrClusterID,
) async {
  final String? cachedFaceID = await MLDataDB.instance
      .getFaceIdUsedForPersonOrCluster(personOrClusterID);
  if (cachedFaceID != null) {
    _personOrClusterIdToCachedFaceID.remove(personOrClusterID);
    await MLDataDB.instance
        .removeFaceIdCachedForPersonOrCluster(personOrClusterID);
  }
}

/// Careful to only use [personOrClusterID] if all [faces] are from the same person or cluster.
Future<Map<String, Uint8List>?> getCachedFaceCrops(
  EnteFile enteFile,
  Iterable<Face> faces, {
  int fetchAttempt = 1,
  bool useFullFile = true,
  String? personOrClusterID,
  required bool useTempCache,
}) async {
  try {
    final faceIdToCrop = <String, Uint8List>{};
    final facesWithoutCrops = <String, FaceBox>{};
    for (final face in faces) {
      final Uint8List? cachedFace =
          _checkInMemoryCachedCropForFaceID(face.faceID);
      if (cachedFace != null) {
        faceIdToCrop[face.faceID] = cachedFace;
      } else {
        final faceCropCacheFile = cachedFaceCropPath(face.faceID, useTempCache);
        if ((await faceCropCacheFile.exists())) {
          try {
            final data = await faceCropCacheFile.readAsBytes();
            if (data.isNotEmpty) {
              await _putCachedCropForFaceID(
                face.faceID,
                data,
                personOrClusterID,
              );
              faceIdToCrop[face.faceID] = data;
            } else {
              _logger.warning(
                "Cached face crop for faceID ${face.faceID} is empty, deleting file ${faceCropCacheFile.path}",
              );
              await faceCropCacheFile.delete();
              facesWithoutCrops[face.faceID] = face.detection.box;
            }
          } catch (e, s) {
            _logger.severe(
              "Error reading cached face crop for faceID ${face.faceID} from file ${faceCropCacheFile.path}",
              e,
              s,
            );
            facesWithoutCrops[face.faceID] = face.detection.box;
          }
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

    final result = await _getFaceCropsUsingHeapPriorityQueue(
      enteFile,
      facesWithoutCrops,
      useFullFile: useFullFile,
    );
    if (result == null) {
      return (faceIdToCrop.isEmpty) ? null : faceIdToCrop;
    }
    for (final entry in result.entries) {
      final Uint8List? computedCrop = result[entry.key];
      if (computedCrop != null) {
        faceIdToCrop[entry.key] = computedCrop;
        if (useFullFile) {
          await _putCachedCropForFaceID(
            entry.key,
            computedCrop,
            personOrClusterID,
          );
          final faceCropCacheFile = cachedFaceCropPath(entry.key, useTempCache);
          try {
            // ignore: unawaited_futures
            faceCropCacheFile.writeAsBytes(computedCrop);
          } catch (e, s) {
            _logger.severe(
              "Error writing cached face crop for faceID ${entry.key} to file ${faceCropCacheFile.path}",
              e,
              s,
            );
          }
        } else {
          _faceCropThumbnailCache.put(entry.key, computedCrop);
        }
      }
    }
    return faceIdToCrop.isEmpty ? null : faceIdToCrop;
  } catch (e, s) {
    if (e is! TaskQueueTimeoutException &&
        e is! TaskQueueOverflowException &&
        e is! TaskQueueCancelledException) {
      if (fetchAttempt <= _retryLimit) {
        final backoff = Duration(
          milliseconds: 100 * pow(2, fetchAttempt + 1).toInt(),
        );
        await Future.delayed(backoff);
        _logger.warning(
          "Error getting face crops for faceIDs: ${faces.map((face) => face.faceID).toList()}, retrying (attempt ${fetchAttempt + 1}) in ${backoff.inMilliseconds} ms",
          e,
          s,
        );
        return getCachedFaceCrops(
          enteFile,
          faces,
          fetchAttempt: fetchAttempt + 1,
          useFullFile: useFullFile,
          useTempCache: useTempCache,
        );
      }
      _logger.severe(
        "Error getting face crops for faceIDs: ${faces.map((face) => face.faceID).toList()}",
        e,
        s,
      );
    } else {
      _logger.info(
        "Stopped getting face crops for faceIDs: ${faces.map((face) => face.faceID).toList()} due to $e",
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
    final w = (kDebugMode ? EnteWatch('precomputeClusterFaceCrop') : null)
      ?..start();
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
      useTempCache: true,
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

void checkStopTryingToGenerateFaceThumbnails(
  int fileID, {
  bool useFullFile = true,
}) {
  final taskId = [fileID, useFullFile ? "-full" : "-thumbnail"].join();
  if (useFullFile) {
    _queueFullFileFaceGenerations.removeTask(taskId);
  } else {
    _queueThumbnailFaceGenerations.removeTask(taskId);
  }
}

Future<Map<String, Uint8List>?> _getFaceCropsUsingHeapPriorityQueue(
  EnteFile file,
  Map<String, FaceBox> faceBoxeMap, {
  bool useFullFile = true,
}) async {
  final completer = Completer<Map<String, Uint8List>?>();

  late final TaskQueue relevantTaskQueue;
  late final String taskId;
  if (useFullFile) {
    relevantTaskQueue = _queueFullFileFaceGenerations;
    taskId = [file.uploadedFileID!, "-full"].join();
  } else {
    relevantTaskQueue = _queueThumbnailFaceGenerations;
    taskId = [file.uploadedFileID!, "-thumbnail"].join();
  }

  await relevantTaskQueue.addTask(taskId, () async {
    final faceCrops = await _getFaceCrops(
      file,
      faceBoxeMap,
      useFullFile: useFullFile,
    );
    completer.complete(faceCrops);
  });

  return completer.future;
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
