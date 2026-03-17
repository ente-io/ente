import "dart:async";
import "dart:io" show File;
import "dart:math" show pow;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/offline_files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/service_locator.dart" show flagService, isOfflineMode;
import "package:photos/services/machine_learning/face_thumbnail_generator.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("FaceCropUtils");

const int _retryLimit = 3;
final LRUMap<String, Uint8List?> _faceCropCache = LRUMap(100);
final LRUMap<String, Uint8List?> _faceCropThumbnailCache = LRUMap(100);
final LRUMap<int, ({int width, int height})>
    _thumbnailSourceDimensionsByFileId = LRUMap(2000);

final LRUMap<String, String> _personOrClusterIdToCachedFaceID = LRUMap(2000);

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

Uint8List? checkInMemoryCachedThumbnailCropForPersonOrClusterID(
  String personOrClusterID,
) {
  final String? faceID =
      _personOrClusterIdToCachedFaceID.get(personOrClusterID);
  if (faceID == null) return null;
  return _faceCropThumbnailCache.get(faceID);
}

({int width, int height})? getCachedThumbnailSourceDimensionsForFileId(
  int fileId,
) {
  return _thumbnailSourceDimensionsByFileId.get(fileId);
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
  final mlDataDB = isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
  final String? faceIDFromDB =
      await mlDataDB.getFaceIdUsedForPersonOrCluster(personOrClusterID);
  if (faceIDFromDB != null) {
    _personOrClusterIdToCachedFaceID.put(personOrClusterID, faceIDFromDB);
  }
  return faceIDFromDB;
}

Future<void> putFaceIdCachedForPersonOrCluster(
  String personOrClusterID,
  String faceID,
) async {
  final mlDataDB = isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
  await mlDataDB.putFaceIdCachedForPersonOrCluster(
    personOrClusterID,
    faceID,
  );
  _personOrClusterIdToCachedFaceID.put(personOrClusterID, faceID);
}

Future<void> cacheFaceIdForPersonOrClusterIfNeeded(
  String personOrClusterID,
  String faceID,
) async {
  if (_personOrClusterIdToCachedFaceID.get(personOrClusterID) == faceID) {
    return;
  }
  await putFaceIdCachedForPersonOrCluster(personOrClusterID, faceID);
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
  final mlDataDB = isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
  final String? cachedFaceID =
      await mlDataDB.getFaceIdUsedForPersonOrCluster(personOrClusterID);
  if (cachedFaceID != null) {
    _personOrClusterIdToCachedFaceID.remove(personOrClusterID);
    await mlDataDB.removeFaceIdCachedForPersonOrCluster(personOrClusterID);
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
            _logger.warning(
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
        _logger.fine(
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
      _logger.warning(
        "Error getting face crops for faceIDs: ${faces.map((face) => face.faceID).toList()}",
        e,
        s,
      );
    } else {
      _logger.severe(
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

bool areThumbnailFaceGenerationQueuesIdle() {
  return _queueThumbnailFaceGenerations.pendingTasksCount == 0 &&
      _queueThumbnailFaceGenerations.runningTasksCount == 0;
}

Future<bool> waitForThumbnailFaceGenerationIdle({
  Duration pollInterval = const Duration(milliseconds: 120),
  Duration? maxWait,
  bool Function()? shouldStopWaiting,
}) async {
  final startedAt = DateTime.now();
  while (true) {
    if (shouldStopWaiting?.call() ?? false) {
      return false;
    }
    if (areThumbnailFaceGenerationQueuesIdle()) {
      return true;
    }
    if (maxWait != null && DateTime.now().difference(startedAt) >= maxWait) {
      return false;
    }
    await Future.delayed(pollInterval);
  }
}

Future<bool> hasPersistedFullFaceCrop(String faceID) async {
  final faceCropCacheFile = cachedFaceCropPath(faceID, false);
  return faceCropCacheFile.exists();
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
    taskId = await _faceCropTaskId(file, useFullFile: true);
  } else {
    relevantTaskQueue = _queueThumbnailFaceGenerations;
    taskId = await _faceCropTaskId(file, useFullFile: false);
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

Future<String> _faceCropTaskId(
  EnteFile file, {
  required bool useFullFile,
}) async {
  final suffix = useFullFile ? "-full" : "-thumbnail";
  if (isOfflineMode) {
    final localId = file.localID;
    if (localId != null && localId.isNotEmpty) {
      final localIntId =
          await OfflineFilesDB.instance.getOrCreateLocalIntId(localId);
      return "$localIntId$suffix";
    }
    return "${file.hashCode}$suffix";
  }
  final baseId = file.uploadedFileID?.toString() ??
      file.generatedID?.toString() ??
      file.localID ??
      file.hashCode.toString();
  return "$baseId${useFullFile ? "-full" : "-thumbnail"}";
}

Future<int?> _faceCropFileIdForDimensions(EnteFile file) async {
  if (isOfflineMode) {
    final localId = file.localID;
    if (localId == null || localId.isEmpty) {
      return null;
    }
    return OfflineFilesDB.instance.getOrCreateLocalIntId(localId);
  }
  return file.uploadedFileID;
}

Future<void> _cacheThumbnailSourceDimensionsForFile(
  EnteFile file, {
  required int width,
  required int height,
}) async {
  if (width <= 0 || height <= 0) {
    return;
  }
  final fileId = await _faceCropFileIdForDimensions(file);
  if (fileId == null) {
    return;
  }
  _thumbnailSourceDimensionsByFileId.put(
    fileId,
    (width: width, height: height),
  );
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
      _logger.severe("Failed to get file for face crop generation");
      return null;
    }
    imagePath = ioFile.path;
  } else {
    final thumbnail = await getThumbnailForUploadedFile(file);
    if (thumbnail == null) {
      _logger.severe("Failed to get thumbnail for face crop generation");
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
  late final List<Uint8List> faceCrop;
  if (flagService.progressivePersonFaceThumbnailsEnabled) {
    final generationResult = await FaceThumbnailGenerator.instance
        .generateFaceThumbnailsWithSourceDimensions(
      imagePath,
      faceBoxes,
    );
    if (!useFullFile) {
      await _cacheThumbnailSourceDimensionsForFile(
        file,
        width: generationResult.sourceWidth,
        height: generationResult.sourceHeight,
      );
    }
    faceCrop = generationResult.thumbnails;
  } else {
    faceCrop = await FaceThumbnailGenerator.instance.generateFaceThumbnails(
      imagePath,
      faceBoxes,
    );
  }
  final Map<String, Uint8List> result = {};
  for (int i = 0; i < faceCrop.length; i++) {
    result[faceIds[i]] = faceCrop[i];
  }
  return result;
}
