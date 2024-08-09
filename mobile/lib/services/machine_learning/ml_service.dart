import "dart:async";
import "dart:io" show Platform;
import "dart:math" show min;
import "dart:typed_data" show Uint8List;

import "package:flutter/foundation.dart" show debugPrint, kDebugMode;
import "package:logging/logging.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/machine_learning_control_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/box.dart";
import "package:photos/face/model/detection.dart" as face_detection;
import "package:photos/face/model/face.dart";
import "package:photos/face/model/landmark.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/filedata/model/file_data.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart';
import "package:photos/services/machine_learning/face_ml/face_clustering/face_db_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/ml_exceptions.dart';
import "package:photos/services/machine_learning/ml_indexing_isolate.dart";
import 'package:photos/services/machine_learning/ml_result.dart';
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/utils/ml_util.dart";
import "package:photos/utils/network_util.dart";
import "package:synchronized/synchronized.dart";

class MLService {
  final _logger = Logger("MLService");

  // Singleton pattern
  MLService._privateConstructor();
  static final instance = MLService._privateConstructor();
  factory MLService() => instance;

  final _initModelLock = Lock();
  final _downloadModelLock = Lock();

  bool _isInitialized = false;
  bool areModelsDownloaded = false;

  late String client;

  bool get isInitialized => _isInitialized;

  bool get showClusteringIsHappening => _showClusteringIsHappening;

  bool debugIndexingDisabled = false;
  bool _showClusteringIsHappening = false;
  bool _mlControllerStatus = false;
  bool _isIndexingOrClusteringRunning = false;
  bool _shouldPauseIndexingAndClustering = false;

  static const int _fileDownloadLimit = 10;
  static const _kForceClusteringFaceCount = 8000;

  /// Only call this function once at app startup, after that you can directly call [runAllML]
  Future<void> init({bool firstTime = false}) async {
    if (localSettings.isFaceIndexingEnabled == false || _isInitialized) {
      return;
    }
    _logger.info("init called");

    // Get client name
    final packageInfo = await PackageInfo.fromPlatform();
    client = "${packageInfo.packageName}/${packageInfo.version}";
    _logger.info("client: $client");

    // Activate FaceRecognitionService
    await FaceRecognitionService.instance.init();

    // Download models if not already downloaded
    unawaited(_ensureDownloadedModels(firstTime));

    // Listen on MachineLearningController
    Bus.instance.on<MachineLearningControlEvent>().listen((event) {
      if (localSettings.isFaceIndexingEnabled == false) {
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

  Future<void> sync() async {
    await FaceRecognitionService.instance.sync();
  }

  Future<void> runAllML({bool force = false}) async {
    try {
      if (force) {
        _mlControllerStatus = true;
      }
      if (_cannotRunMLFunction() && !force) return;

      await sync();

      final int unclusteredFacesCount =
          await FaceMLDataDB.instance.getUnclusteredFaceCount();
      if (unclusteredFacesCount > _kForceClusteringFaceCount) {
        _logger.info(
          "There are $unclusteredFacesCount unclustered faces, doing clustering first",
        );
        await clusterAllImages();
      }
      await indexAllImages();
      await clusterAllImages();
    } catch (e, s) {
      _logger.severe("runAllML failed", e, s);
      rethrow;
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

  /// Analyzes all the images in the database with the latest ml version and stores the results in the database.
  ///
  /// This function first checks if the image has already been analyzed with the lastest faceMlVersion and stored in the database. If so, it skips the image.
  Future<void> indexAllImages() async {
    if (_cannotRunMLFunction()) return;

    try {
      _isIndexingOrClusteringRunning = true;
      _logger.info('starting image indexing');
      final Stream<List<FileMLInstruction>> instructionStream =
          FaceRecognitionService.instance
              .syncEmbeddings(yieldSize: _fileDownloadLimit);

      int fileAnalyzedCount = 0;
      final Stopwatch stopwatch = Stopwatch()..start();

      await for (final chunk in instructionStream) {
        if (!await canUseHighBandwidth()) {
          _logger.info(
            'stopping indexing because user is not connected to wifi',
          );
          break;
        }
        final futures = <Future<bool>>[];
        for (final instruction in chunk) {
          if (_shouldPauseIndexingAndClustering) {
            _logger.info("indexAllImages() was paused, stopping");
            break;
          }
          await _ensureLoadedModels(instruction);
          futures.add(processImage(instruction));
        }
        final awaitedFutures = await Future.wait(futures);
        final sumFutures = awaitedFutures.fold<int>(
          0,
          (previousValue, element) => previousValue + (element ? 1 : 0),
        );
        fileAnalyzedCount += sumFutures;
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
    double minFaceScore = kMinimumQualityFaceScore,
    bool clusterInBuckets = true,
  }) async {
    if (_cannotRunMLFunction()) return;

    _logger.info("`clusterAllImages()` called");
    _isIndexingOrClusteringRunning = true;
    final clusterAllImagesTime = DateTime.now();

    _logger.info('Pulling remote feedback before actually clustering');
    await PersonService.instance.fetchRemoteClusterFeedback();

    try {
      _showClusteringIsHappening = true;

      // Get a sense of the total number of faces in the database
      final int totalFaces = await FaceMLDataDB.instance
          .getTotalFaceCount(minFaceScore: minFaceScore);
      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();
      final startEmbeddingFetch = DateTime.now();
      // read all embeddings
      final result = await FaceMLDataDB.instance.getFaceInfoForClustering(
        minScore: minFaceScore,
        maxFaces: totalFaces,
      );
      final Set<int> missingFileIDs = {};
      final allFaceInfoForClustering = <FaceDbInfoForClustering>[];
      for (final faceInfo in result) {
        if (!fileIDToCreationTime.containsKey(faceInfo.fileID)) {
          missingFileIDs.add(faceInfo.fileID);
        } else {
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
      final Map<int, (Uint8List, int)> oldClusterSummaries =
          await FaceMLDataDB.instance.getAllClusterSummary();

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

          await FaceMLDataDB.instance
              .updateFaceIdToClusterId(clusteringResult.newFaceIdToCluster);
          await FaceMLDataDB.instance
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
        await FaceMLDataDB.instance
            .updateFaceIdToClusterId(clusteringResult.newFaceIdToCluster);
        await FaceMLDataDB.instance
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
      _showClusteringIsHappening = false;
      _isIndexingOrClusteringRunning = false;
      _cancelPauseIndexingAndClustering();
    }
  }

  Future<bool> processImage(FileMLInstruction instruction) async {
    // TODO: clean this function up
    _logger.info(
      "`processImage` start processing image with uploadedFileID: ${instruction.file.uploadedFileID}",
    );
    bool actuallyRanML = false;

    try {
      final MLResult? result = await MLIndexingIsolate.instance.analyzeImage(
        instruction,
      );
      if (result == null) {
        if (!_shouldPauseIndexingAndClustering) {
          _logger.severe(
            "Failed to analyze image with uploadedFileID: ${instruction.file.uploadedFileID}",
          );
        }
        return actuallyRanML;
      }
      if (result.facesRan) {
        actuallyRanML = true;
        final List<Face> faces = [];
        if (result.foundNoFaces) {
          debugPrint(
            'No faces detected for file with name:${instruction.file.displayName}',
          );
          faces.add(
            Face.empty(result.fileId, error: result.errorOccured),
          );
        }
        if (result.foundFaces) {
          if (result.decodedImageSize.width == -1 ||
              result.decodedImageSize.height == -1) {
            _logger.severe(
                "decodedImageSize is not stored correctly for image with "
                "ID: ${instruction.file.uploadedFileID}");
            _logger.info(
              "Using aligned image size for image with ID: ${instruction.file.uploadedFileID}. This size is ${result.decodedImageSize.width}x${result.decodedImageSize.height} compared to size of ${instruction.file.width}x${instruction.file.height} in the metadata",
            );
          }
          for (int i = 0; i < result.faces!.length; ++i) {
            final FaceResult faceRes = result.faces![i];
            final detection = face_detection.Detection(
              box: FaceBox(
                x: faceRes.detection.xMinBox,
                y: faceRes.detection.yMinBox,
                width: faceRes.detection.width,
                height: faceRes.detection.height,
              ),
              landmarks: faceRes.detection.allKeypoints
                  .map(
                    (keypoint) => Landmark(
                      x: keypoint[0],
                      y: keypoint[1],
                    ),
                  )
                  .toList(),
            );
            faces.add(
              Face(
                faceRes.faceId,
                result.fileId,
                faceRes.embedding,
                faceRes.detection.score,
                detection,
                faceRes.blurValue,
                fileInfo: FileInfo(
                  imageHeight: result.decodedImageSize.height,
                  imageWidth: result.decodedImageSize.width,
                ),
              ),
            );
          }
        }
        _logger.info("inserting ${faces.length} faces for ${result.fileId}");
        if (!result.errorOccured) {
          final FileDataEntity dataEntity = instruction.existingRemoteFileML ??
              FileDataEntity.empty(
                instruction.file.uploadedFileID!,
                DataType.derivedMeta,
              );
          if (result.facesRan) {
            dataEntity.putFace(
              RemoteFaceEmbedding(
                faces,
                result.mlVersion,
                client: client,
                height: result.decodedImageSize.height,
                width: result.decodedImageSize.width,
              ),
            );
          }
          if (result.clipRan) {
            dataEntity.putClip(
              RemoteClipEmbedding(
                result.clip!.embedding,
                version: result.mlVersion,
                client: client,
              ),
            );
          }
          await FileDataService.instance.putFileData(
            instruction.file,
            dataEntity,
          );
        } else {
          _logger.warning(
            'Skipped putting embedding because of error ${result.toJsonString()}',
          );
        }
        await FaceMLDataDB.instance.bulkInsertFaces(faces);
      }

      if (result.clipRan) {
        actuallyRanML = true;
        await SemanticSearchService.storeClipImageResult(
          result.clip!,
          instruction.file,
        );
      }
    } on ThumbnailRetrievalException catch (e, s) {
      _logger.severe(
        'ThumbnailRetrievalException while processing image with ID ${instruction.file.uploadedFileID}, storing empty face so indexing does not get stuck',
        e,
        s,
      );
      await FaceMLDataDB.instance.bulkInsertFaces(
        [Face.empty(instruction.file.uploadedFileID!, error: true)],
      );
      await SemanticSearchService.storeEmptyClipImageResult(
        instruction.file,
      );
      return true;
    } catch (e, s) {
      _logger.severe(
        "Failed to analyze using FaceML for image with ID: ${instruction.file.uploadedFileID}. Not storing any faces, which means it will be automatically retried later.",
        e,
        s,
      );
      return false;
    }
    return actuallyRanML;
  }

  Future<void> _ensureDownloadedModels([bool forceRefresh = false]) async {
    if (_downloadModelLock.locked) {
      _logger.finest("Download models already in progress");
    }
    return _downloadModelLock.synchronized(() async {
      if (areModelsDownloaded) {
        _logger.finest("Models already downloaded");
        return;
      }
      _logger.info('Downloading models');
      await Future.wait([
        FaceDetectionService.instance.downloadModel(forceRefresh),
        FaceEmbeddingService.instance.downloadModel(forceRefresh),
        ClipImageEncoder.instance.downloadModel(forceRefresh),
      ]);
      areModelsDownloaded = true;
    });
  }

  Future<void> _ensureLoadedModels(FileMLInstruction instruction) async {
    return _initModelLock.synchronized(() async {
      final faceDetectionLoaded = FaceDetectionService.instance.isInitialized;
      final faceEmbeddingLoaded = FaceEmbeddingService.instance.isInitialized;
      final facesModelsLoaded = faceDetectionLoaded && faceEmbeddingLoaded;
      final clipModelsLoaded = ClipImageEncoder.instance.isInitialized;

      final shouldLoadFaces = instruction.shouldRunFaces && !facesModelsLoaded;
      final shouldLoadClip = instruction.shouldRunClip && !clipModelsLoaded;
      if (!shouldLoadFaces && !shouldLoadClip) {
        return;
      }

      _logger.info(
        'Loading models. faces: $shouldLoadFaces, clip: $shouldLoadClip',
      );
      await MLIndexingIsolate.instance
          .loadModels(loadFaces: shouldLoadFaces, loadClip: shouldLoadClip);
      _logger.info('Models loaded');
      _logStatus();
    });
  }

  bool _cannotRunMLFunction({String function = ""}) {
    if (kDebugMode && Platform.isIOS) {
      return false;
    }
    if (_isIndexingOrClusteringRunning) {
      _logger.info(
        "Cannot run $function because indexing or clustering is already running",
      );
      _logStatus();
      return true;
    }
    if (_mlControllerStatus == false) {
      _logger.info(
        "Cannot run $function because MLController does not allow it",
      );
      _logStatus();
      return true;
    }
    if (debugIndexingDisabled) {
      _logger.info(
        "Cannot run $function because debugIndexingDisabled is true",
      );
      _logStatus();
      return true;
    }
    if (_shouldPauseIndexingAndClustering) {
      // This should ideally not be triggered, because one of the above should be triggered instead.
      _logger.warning(
        "Cannot run $function because indexing and clustering is being paused",
      );
      _logStatus();
      return true;
    }
    return false;
  }

  void _logStatus() {
    final String status = '''
    isInternalUser: ${flagService.internalUser}
    isFaceIndexingEnabled: ${localSettings.isFaceIndexingEnabled}
    canRunMLController: $_mlControllerStatus
    isIndexingOrClusteringRunning: $_isIndexingOrClusteringRunning
    shouldPauseIndexingAndClustering: $_shouldPauseIndexingAndClustering
    debugIndexingDisabled: $debugIndexingDisabled
    ''';
    _logger.info(status);
  }
}
