import "dart:async";
import "dart:io" show Platform;
import "dart:math" show min;
import "dart:typed_data" show Uint8List;

import "package:flutter/foundation.dart" show kDebugMode;
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/compute_control_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/model/file_data.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart';
import "package:photos/services/machine_learning/face_ml/face_clustering/face_db_info_for_clustering.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_indexing_isolate.dart";
import 'package:photos/services/machine_learning/ml_result.dart';
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/utils/ml_util.dart";
import "package:photos/utils/network_util.dart";
import "package:photos/utils/ram_check_util.dart";

class MLService {
  final _logger = Logger("MLService");

  // Singleton pattern
  MLService._privateConstructor();
  static final instance = MLService._privateConstructor();
  factory MLService() => instance;

  bool _isInitialized = false;

  int? lastRemoteFetch;
  static const int _kRemoteFetchCooldownOnLite = 1000 * 60 * 5;

  late String client;

  bool get showClusteringIsHappening => _clusteringIsHappening;

  bool debugIndexingDisabled = false;
  bool _clusteringIsHappening = false;
  bool _mlControllerStatus = false;
  bool _isIndexingOrClusteringRunning = false;
  bool _isRunningML = false;
  bool _shouldPauseIndexingAndClustering = false;

  bool get isRunningML =>
      _isRunningML || memoriesCacheService.isUpdatingMemories;

  static const _kForceClusteringFaceCount = 8000;
  late final mlDataDB = MLDataDB.instance;

  /// Only call this function once at app startup, after that you can directly call [runAllML]
  Future<void> init() async {
    if (_isInitialized) return;
    _logger.info("init called");

    // Check if the device has enough RAM to run local indexing
    await checkDeviceTotalRAM();

    // Get client name
    final packageInfo = ServiceLocator.instance.packageInfo;
    client = "${packageInfo.packageName}/${packageInfo.version}";
    _logger.info("client: $client");

    // Listen on ComputeController
    Bus.instance.on<ComputeControlEvent>().listen((event) {
      if (!flagService.hasGrantedMLConsent) {
        if (event.shouldRun) {
          VideoPreviewService.instance.queueFiles(duration: Duration.zero);
        }
        return;
      }

      _mlControllerStatus = event.shouldRun;
      if (_mlControllerStatus) {
        if (_shouldPauseIndexingAndClustering) {
          _cancelPauseIndexingAndClustering();
          _logger.info(
            "MLController allowed running ML, faces indexing undoing previous pause",
          );
        } else {
          _logger.info(
            "MLController allowed running ML, faces indexing starting",
          );
        }
        unawaited(runAllML());
      } else {
        _logger.info(
          "MLController stopped running ML, faces indexing will be paused (unless it's fetching embeddings)",
        );
        pauseIndexingAndClustering();
      }
    });

    _isInitialized = true;
    _logger.info('init done');
  }

  bool canFetch() {
    if (localSettings.isMLLocalIndexingEnabled) return true;
    if (lastRemoteFetch == null) {
      lastRemoteFetch = DateTime.now().millisecondsSinceEpoch;
      return true;
    }
    final intDiff = DateTime.now().millisecondsSinceEpoch - lastRemoteFetch!;
    final bool canFetch = intDiff > _kRemoteFetchCooldownOnLite;
    if (canFetch) {
      lastRemoteFetch = DateTime.now().millisecondsSinceEpoch;
    }
    return canFetch;
  }

  Future<void> sync() async {
    await fileDataService.syncFDStatus();
    await faceRecognitionService.syncPersonFeedback();
  }

  Future<void> runAllML({bool force = false}) async {
    try {
      if (force) {
        _mlControllerStatus = true;
      }
      if (!_canRunMLFunction(function: "AllML") && !force) return;
      if (!force && !computeController.requestCompute(ml: true)) return;
      _isRunningML = true;
      await sync();

      final int unclusteredFacesCount =
          await mlDataDB.getUnclusteredFaceCount();
      if (unclusteredFacesCount > _kForceClusteringFaceCount) {
        _logger.info(
          "There are $unclusteredFacesCount unclustered faces, doing clustering first",
        );
        await clusterAllImages();
      }
      if (_mlControllerStatus == true) {
        // refresh discover section
        magicCacheService.updateCache(forced: force).ignore();
        // refresh memories section
        memoriesCacheService.updateCache(forced: force).ignore();
      }
      if (canFetch()) {
        await fetchAndIndexAllImages();
      }
      if ((await mlDataDB.getUnclusteredFaceCount()) > 0) {
        await clusterAllImages();
      }
      if (_mlControllerStatus == true) {
        // refresh discover section
        magicCacheService.updateCache().ignore();
        // refresh memories section (only runs if forced is true)
        memoriesCacheService.updateCache(forced: force).ignore();
      }
    } catch (e, s) {
      _logger.severe("runAllML failed", e, s);
      rethrow;
    } finally {
      _logger.severe("ML finished running");
      _isRunningML = false;
      computeController.releaseCompute(ml: true);
      VideoPreviewService.instance.queueFiles();
    }
  }

  void triggerML() {
    if (_mlControllerStatus &&
        !_isIndexingOrClusteringRunning &&
        !_isRunningML) {
      unawaited(runAllML());
    }
  }

  void pauseIndexingAndClustering() {
    if (_isIndexingOrClusteringRunning) {
      _shouldPauseIndexingAndClustering = true;
      MLIndexingIsolate.instance.shouldPauseIndexingAndClustering = true;
    }
  }

  void _cancelPauseIndexingAndClustering() {
    _shouldPauseIndexingAndClustering = false;
    MLIndexingIsolate.instance.shouldPauseIndexingAndClustering = false;
  }

  /// Analyzes all the images in the user library with the latest ml version and stores the results in the database.
  ///
  /// This function first fetches from remote and checks if the image has already been analyzed
  /// with the lastest faceMlVersion and stored on remote or local database. If so, it skips the image.
  Future<void> fetchAndIndexAllImages() async {
    if (!_canRunMLFunction(function: "Indexing")) return;

    try {
      _isIndexingOrClusteringRunning = true;
      _logger.info('starting image indexing');
      final Stream<List<FileMLInstruction>> instructionStream =
          fetchEmbeddingsAndInstructions(fileDownloadMlLimit);

      int fileAnalyzedCount = 0;
      final Stopwatch stopwatch = Stopwatch()..start();

      stream:
      await for (final chunk in instructionStream) {
        if (!localSettings.isMLLocalIndexingEnabled) {
          await MLIndexingIsolate.instance.cleanupLocalIndexingModels();
          continue;
        } else if (!await canUseHighBandwidth()) {
          _logger.info(
            'stopping indexing because user is not connected to wifi',
          );
          break stream;
        } else {
          await MLIndexingIsolate.instance.ensureDownloadedModels();
        }
        final futures = <Future<bool>>[];
        for (final instruction in chunk) {
          if (_shouldPauseIndexingAndClustering) {
            _logger.info("indexAllImages() was paused, stopping");
            break stream;
          }
          await MLIndexingIsolate.instance.ensureLoadedModels(instruction);
          futures.add(processImage(instruction));
        }
        final awaitedFutures = await Future.wait(futures);
        final sumFutures = awaitedFutures.fold<int>(
          0,
          (previousValue, element) => previousValue + (element ? 1 : 0),
        );
        fileAnalyzedCount += sumFutures;
      }
      if (fileAnalyzedCount > 0) {
        magicCacheService.queueUpdate('fileIndexed');
      }
      _logger.info(
        "`indexAllImages()` finished. Analyzed $fileAnalyzedCount images, in ${stopwatch.elapsed.inSeconds} seconds (avg of ${stopwatch.elapsed.inSeconds / fileAnalyzedCount} seconds per image)",
      );
      _logStatus();
    } catch (e, s) {
      _logger.severe("indexAllImages failed", e, s);
    } finally {
      _isIndexingOrClusteringRunning = false;
      _cancelPauseIndexingAndClustering();
    }
  }

  Future<void> clusterAllImages({
    bool clusterInBuckets = true,
    bool force = false,
  }) async {
    if (!_canRunMLFunction(function: "Clustering") && !force) return;
    if (_clusteringIsHappening) {
      _logger.info("clusterAllImages() is already running, returning");
      return;
    }

    _logger.info("`clusterAllImages()` called");
    _isIndexingOrClusteringRunning = true;
    _clusteringIsHappening = true;
    final clusterAllImagesTime = DateTime.now();

    _logger.info('Pulling remote feedback before actually clustering');
    await PersonService.instance.fetchRemoteClusterFeedback();
    final persons = await PersonService.instance.getPersons();
    final faceIdNotToCluster = <String, List<String>>{};
    for (final person in persons) {
      if (person.data.rejectedFaceIDs.isNotEmpty) {
        final personClusters = person.data.assigned.map((e) => e.id).toList();
        for (final faceID in person.data.rejectedFaceIDs) {
          faceIdNotToCluster[faceID] = personClusters;
        }
      }
    }

    try {
      // Get a sense of the total number of faces in the database
      final int totalFaces = await mlDataDB.getTotalFaceCount();
      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();
      final startEmbeddingFetch = DateTime.now();
      // read all embeddings
      final result = await mlDataDB.getFaceInfoForClustering(
        maxFaces: totalFaces,
      );
      final Set<int> missingFileIDs = {};
      final allFaceInfoForClustering = <FaceDbInfoForClustering>[];
      for (final faceInfo in result) {
        if (!fileIDToCreationTime.containsKey(faceInfo.fileID)) {
          missingFileIDs.add(faceInfo.fileID);
        } else {
          if (faceIdNotToCluster.containsKey(faceInfo.faceID)) {
            faceInfo.rejectedClusterIds = faceIdNotToCluster[faceInfo.faceID];
          }
          allFaceInfoForClustering.add(faceInfo);
        }
      }
      // sort the embeddings based on file creation time, newest first
      allFaceInfoForClustering.sort((b, a) {
        return fileIDToCreationTime[a.fileID]!
            .compareTo(fileIDToCreationTime[b.fileID]!);
      });
      _logger.info(
        'Getting and sorting embeddings took ${DateTime.now().difference(startEmbeddingFetch).inMilliseconds} ms for ${allFaceInfoForClustering.length} embeddings'
        'and ${missingFileIDs.length} missing fileIDs',
      );

      // Get the current cluster statistics
      final Map<String, (Uint8List, int)> oldClusterSummaries =
          await mlDataDB.getAllClusterSummary();

      if (clusterInBuckets) {
        const int bucketSize = 10000;
        const int offsetIncrement = 7500;
        int offset = 0;
        int bucket = 1;

        while (true) {
          if (_shouldPauseIndexingAndClustering) {
            _logger.info(
              "MLController does not allow running ML, stopping before clustering bucket $bucket",
            );
            break;
          }
          if (offset > allFaceInfoForClustering.length - 1) {
            _logger.warning(
              'faceIdToEmbeddingBucket is empty, this should ideally not happen as it should have stopped earlier. offset: $offset, totalFaces: $totalFaces',
            );
            break;
          }
          if (offset > totalFaces) {
            _logger.warning(
              'offset > totalFaces, this should ideally not happen. offset: $offset, totalFaces: $totalFaces',
            );
            break;
          }

          final bucketStartTime = DateTime.now();
          final faceInfoForClustering = allFaceInfoForClustering.sublist(
            offset,
            min(offset + bucketSize, allFaceInfoForClustering.length),
          );

          if (faceInfoForClustering.every((face) => face.clusterId != null)) {
            _logger.info('Everything in bucket $bucket is already clustered');
            if (offset + bucketSize >= totalFaces) {
              _logger.info('All faces clustered');
              break;
            } else {
              _logger.info('Skipping to next bucket');
              offset += offsetIncrement;
              bucket++;
              continue;
            }
          }

          final clusteringResult =
              await FaceClusteringService.instance.predictLinearIsolate(
            faceInfoForClustering.toSet(),
            fileIDToCreationTime: fileIDToCreationTime,
            offset: offset,
            oldClusterSummaries: oldClusterSummaries,
          );
          if (clusteringResult == null) {
            _logger.warning("faceIdToCluster is null");
            return;
          }

          await mlDataDB
              .updateFaceIdToClusterId(clusteringResult.newFaceIdToCluster);
          await mlDataDB
              .clusterSummaryUpdate(clusteringResult.newClusterSummaries);
          Bus.instance.fire(PeopleChangedEvent());
          for (final faceInfo in faceInfoForClustering) {
            faceInfo.clusterId ??=
                clusteringResult.newFaceIdToCluster[faceInfo.faceID];
          }
          for (final clusterUpdate
              in clusteringResult.newClusterSummaries.entries) {
            oldClusterSummaries[clusterUpdate.key] = clusterUpdate.value;
          }
          _logger.info(
            'Done with clustering ${offset + faceInfoForClustering.length} embeddings (${(100 * (offset + faceInfoForClustering.length) / totalFaces).toStringAsFixed(0)}%) in bucket $bucket, offset: $offset, in ${DateTime.now().difference(bucketStartTime).inSeconds} seconds',
          );
          if (offset + bucketSize >= totalFaces) {
            _logger.info('All faces clustered');
            break;
          }
          offset += offsetIncrement;
          bucket++;
        }
      } else {
        final clusterStartTime = DateTime.now();
        // Cluster the embeddings using the linear clustering algorithm, returning a map from faceID to clusterID
        final clusteringResult =
            await FaceClusteringService.instance.predictLinearIsolate(
          allFaceInfoForClustering.toSet(),
          fileIDToCreationTime: fileIDToCreationTime,
          oldClusterSummaries: oldClusterSummaries,
        );
        if (clusteringResult == null) {
          _logger.warning("faceIdToCluster is null");
          return;
        }
        final clusterDoneTime = DateTime.now();
        _logger.info(
          'done with clustering ${allFaceInfoForClustering.length} in ${clusterDoneTime.difference(clusterStartTime).inSeconds} seconds ',
        );

        // Store the updated clusterIDs in the database
        _logger.info(
          'Updating ${clusteringResult.newFaceIdToCluster.length} FaceIDs with clusterIDs in the DB',
        );
        await mlDataDB
            .updateFaceIdToClusterId(clusteringResult.newFaceIdToCluster);
        await mlDataDB
            .clusterSummaryUpdate(clusteringResult.newClusterSummaries);
        Bus.instance.fire(PeopleChangedEvent());
        _logger.info('Done updating FaceIDs with clusterIDs in the DB, in '
            '${DateTime.now().difference(clusterDoneTime).inSeconds} seconds');
      }
      _logger.info('clusterAllImages() finished, in '
          '${DateTime.now().difference(clusterAllImagesTime).inSeconds} seconds');
    } catch (e, s) {
      _logger.severe("`clusterAllImages` failed", e, s);
    } finally {
      _clusteringIsHappening = false;
      _isIndexingOrClusteringRunning = false;
      _cancelPauseIndexingAndClustering();
    }
  }

  Future<bool> processImage(FileMLInstruction instruction) async {
    bool actuallyRanML = false;

    try {
      final String filePath = await getImagePathForML(instruction.file);

      final MLResult? result = await MLIndexingIsolate.instance.analyzeImage(
        instruction,
        filePath,
      );
      // Check if there's no result simply because MLController paused indexing
      if (result == null) {
        if (!_shouldPauseIndexingAndClustering) {
          _logger.severe(
            "Failed to analyze image with uploadedFileID: ${instruction.file.uploadedFileID}",
          );
        }
        return actuallyRanML;
      }
      // Check anything actually ran
      actuallyRanML = result.ranML;
      if (!actuallyRanML) return actuallyRanML;
      // Prepare storing data on remote
      final FileDataEntity dataEntity = instruction.existingRemoteFileML ??
          FileDataEntity.empty(
            instruction.file.uploadedFileID!,
            DataType.mlData,
          );
      // Faces results
      final List<Face> faces = [];
      if (result.facesRan) {
        if (result.faces!.isEmpty) {
          faces.add(Face.empty(result.fileId));
        }
        if (result.faces!.isNotEmpty) {
          for (int i = 0; i < result.faces!.length; ++i) {
            faces.add(
              Face.fromFaceResult(
                result.faces![i],
                result.fileId,
                result.decodedImageSize,
              ),
            );
          }
        }
        dataEntity.putFace(
          RemoteFaceEmbedding(
            faces,
            faceMlVersion,
            client: client,
            height: result.decodedImageSize.height,
            width: result.decodedImageSize.width,
          ),
        );
      }
      // Clip results
      if (result.clipRan) {
        dataEntity.putClip(
          RemoteClipEmbedding(
            result.clip!.embedding,
            version: clipMlVersion,
            client: client,
          ),
        );
      }
      // Storing results on remote
      await fileDataService.putFileData(
        instruction.file,
        dataEntity,
      );
      // Storing results locally
      if (result.facesRan) await mlDataDB.bulkInsertFaces(faces);
      if (result.clipRan) {
        await SemanticSearchService.instance.storeClipImageResult(
          result.clip!,
        );
      }
      _logger.info("ML result for fileID ${result.fileId} stored remote+local");
      return actuallyRanML;
    } catch (e, s) {
      final String errorString = e.toString();
      final String format = instruction.file.displayName.split('.').last;
      final int? size = instruction.file.fileSize;
      final fileType = instruction.file.fileType;
      final bool acceptedIssue =
          errorString.contains('ThumbnailRetrievalException') ||
              errorString.contains('InvalidImageFormatException') ||
              errorString.contains('UnhandledExifOrientation') ||
              errorString.contains('FileSizeTooLargeForMobileIndexing');
      if (acceptedIssue) {
        _logger.severe(
          '$errorString for fileID ${instruction.file.uploadedFileID} (format $format, type $fileType, size $size), storing empty results so indexing does not get stuck',
          e,
          s,
        );
        await mlDataDB.bulkInsertFaces(
          [Face.empty(instruction.file.uploadedFileID!, error: true)],
        );
        await SemanticSearchService.instance.storeEmptyClipImageResult(
          instruction.file,
        );
        return true;
      }
      _logger.severe(
        "Failed to index file for fileID ${instruction.file.uploadedFileID} (format $format, type $fileType, size $size). Not storing any results locally, which means it will be automatically retried later.",
        e,
        s,
      );
      return false;
    }
  }

  bool _canRunMLFunction({required String function}) {
    if (kDebugMode && Platform.isIOS && !_isIndexingOrClusteringRunning) {
      return true;
    }
    if (_isIndexingOrClusteringRunning) {
      _logger.info(
        "Cannot run $function because indexing or clustering is already running",
      );
      _logStatus();
      return false;
    }
    if (_mlControllerStatus == false) {
      _logger.info(
        "Cannot run $function because MLController does not allow it",
      );
      _logStatus();
      return false;
    }
    if (debugIndexingDisabled) {
      _logger.info(
        "Cannot run $function because debugIndexingDisabled is true",
      );
      _logStatus();
      return false;
    }
    if (_shouldPauseIndexingAndClustering) {
      // This should ideally not be triggered, because one of the above should be triggered instead.
      _logger.warning(
        "Cannot run $function because indexing and clustering is being paused",
      );
      _logStatus();
      return false;
    }
    return true;
  }

  void _logStatus() {
    final String status = '''
    isInternalUser: ${flagService.internalUser}
    Local indexing: ${localSettings.isMLLocalIndexingEnabled}
    canRunMLController: $_mlControllerStatus
    isIndexingOrClusteringRunning: $_isIndexingOrClusteringRunning
    shouldPauseIndexingAndClustering: $_shouldPauseIndexingAndClustering
    debugIndexingDisabled: $debugIndexingDisabled
    ''';
    _logger.info(status);
  }
}
