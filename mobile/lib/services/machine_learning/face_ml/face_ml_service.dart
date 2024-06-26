import "dart:async";
import "dart:developer" as dev show log;
import "dart:io" show File;
import "dart:isolate";
import "dart:math" show min;
import "dart:typed_data" show Uint8List, Float32List, ByteData;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:dart_ui_isolate/dart_ui_isolate.dart";
import "package:flutter/foundation.dart" show debugPrint, kDebugMode;
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/machine_learning_control_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/list.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/box.dart";
import "package:photos/face/model/detection.dart" as face_detection;
import "package:photos/face/model/face.dart";
import "package:photos/face/model/landmark.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart';
import "package:photos/services/machine_learning/face_ml/face_clustering/face_db_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import 'package:photos/services/machine_learning/face_ml/face_ml_result.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/file_ml/file_ml.dart';
import 'package:photos/services/machine_learning/file_ml/remote_fileml_service.dart';
import 'package:photos/services/machine_learning/ml_exceptions.dart';
import "package:photos/services/search_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/network_util.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:synchronized/synchronized.dart";

enum FileDataForML { thumbnailData, fileData }

enum FaceMlOperation { analyzeImage }

/// This class is responsible for running the full face ml pipeline on images.
///
/// WARNING: For getting the ML results needed for the UI, you should use `FaceSearchService` instead of this class!
///
/// The pipeline consists of face detection, face alignment and face embedding.
class FaceMlService {
  final _logger = Logger("FaceMlService");

  // Flutter isolate things for running the image ml pipeline
  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 120);
  int _activeTasks = 0;
  late DartUiIsolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  // Singleton pattern
  FaceMlService._privateConstructor();
  static final instance = FaceMlService._privateConstructor();
  factory FaceMlService() => instance;

  final _initModelLock = Lock();
  final _functionLock = Lock();
  final _initIsolateLock = Lock();

  final _computer = Computer.shared();

  bool _isInitialized = false;
  bool _isModelsInitialized = false;
  bool _isIsolateSpawned = false;

  late String client;

  bool get isInitialized => _isInitialized;

  bool get showClusteringIsHappening => _showClusteringIsHappening;

  bool debugIndexingDisabled = false;
  bool _showClusteringIsHappening = false;
  bool _mlControllerStatus = false;
  bool _isIndexingOrClusteringRunning = false;
  bool _shouldPauseIndexingAndClustering = false;
  bool _shouldSyncPeople = false;
  bool _isSyncing = false;

  static const int _fileDownloadLimit = 10;
  static const _embeddingFetchLimit = 200;
  static const _kForceClusteringFaceCount = 8000;

  /// Only call this function once at app startup, after that you can directly call [runAllFaceML]
  Future<void> init() async {
    if (LocalSettings.instance.isFaceIndexingEnabled == false ||
        _isInitialized) {
      return;
    }
    _logger.info("init called");

    // Listen on MachineLearningController
    Bus.instance.on<MachineLearningControlEvent>().listen((event) {
      if (LocalSettings.instance.isFaceIndexingEnabled == false) {
        return;
      }
      _mlControllerStatus = event.shouldRun;
      if (_mlControllerStatus) {
        if (_shouldPauseIndexingAndClustering) {
          _shouldPauseIndexingAndClustering = false;
          _logger.info(
            "MLController allowed running ML, faces indexing undoing previous pause",
          );
        } else {
          _logger.info(
            "MLController allowed running ML, faces indexing starting",
          );
        }
        unawaited(runAllFaceML());
      } else {
        _logger.info(
          "MLController stopped running ML, faces indexing will be paused (unless it's fetching embeddings)",
        );
        pauseIndexingAndClustering();
      }
    });

    // Listen on DiffSync
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      unawaited(sync());
    });

    // Listne on PeopleChanged
    Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.syncDone) return;
      _shouldSyncPeople = true;
    });

    _isInitialized = true;
    _logger.info('init done');
  }

  Future<void> sync({bool forceSync = true}) async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    if (forceSync) {
      await PersonService.instance.reconcileClusters();
      Bus.instance.fire(PeopleChangedEvent(type: PeopleEventType.syncDone));
      _shouldSyncPeople = false;
    }
    _isSyncing = false;
  }

  Future<void> runAllFaceML({bool force = false}) async {
    if (force) {
      _mlControllerStatus = true;
    }
    if (_cannotRunMLFunction() && !force) return;

    await sync(forceSync: _shouldSyncPeople);

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
  }

  void pauseIndexingAndClustering() {
    if (_isIndexingOrClusteringRunning) {
      _shouldPauseIndexingAndClustering = true;
    }
  }

  /// Analyzes all the images in the database with the latest ml version and stores the results in the database.
  ///
  /// This function first checks if the image has already been analyzed with the lastest faceMlVersion and stored in the database. If so, it skips the image.
  Future<void> indexAllImages({int retryFetchCount = 10}) async {
    if (_cannotRunMLFunction()) return;

    try {
      _isIndexingOrClusteringRunning = true;
      _logger.info('starting image indexing');

      final w = (kDebugMode ? EnteWatch('prepare indexing files') : null)
        ?..start();
      final Map<int, int> alreadyIndexedFiles =
          await FaceMLDataDB.instance.getIndexedFileIds();
      w?.log('getIndexedFileIds');
      final List<EnteFile> enteFiles =
          await SearchService.instance.getAllFiles();
      w?.log('getAllFiles');

      int fileAnalyzedCount = 0;
      int fileSkippedCount = 0;
      final stopwatch = Stopwatch()..start();
      final List<EnteFile> filesWithLocalID = <EnteFile>[];
      final List<EnteFile> filesWithoutLocalID = <EnteFile>[];
      final List<EnteFile> hiddenFilesToIndex = <EnteFile>[];
      w?.log('getIndexableFileIDs');

      for (final EnteFile enteFile in enteFiles) {
        if (_skipAnalysisEnteFile(enteFile, alreadyIndexedFiles)) {
          fileSkippedCount++;
          continue;
        }
        if ((enteFile.localID ?? '').isEmpty) {
          filesWithoutLocalID.add(enteFile);
        } else {
          filesWithLocalID.add(enteFile);
        }
      }
      w?.log('sifting through all normal files');
      final List<EnteFile> hiddenFiles =
          await SearchService.instance.getHiddenFiles();
      w?.log('getHiddenFiles: ${hiddenFiles.length} hidden files');
      for (final EnteFile enteFile in hiddenFiles) {
        if (_skipAnalysisEnteFile(enteFile, alreadyIndexedFiles)) {
          fileSkippedCount++;
          continue;
        }
        hiddenFilesToIndex.add(enteFile);
      }

      // list of files where files with localID are first
      final sortedBylocalID = <EnteFile>[];
      sortedBylocalID.addAll(filesWithLocalID);
      sortedBylocalID.addAll(filesWithoutLocalID);
      sortedBylocalID.addAll(hiddenFilesToIndex);
      w?.log('preparing all files to index');
      final List<List<EnteFile>> chunks =
          sortedBylocalID.chunks(_embeddingFetchLimit);
      int fetchedCount = 0;
      outerLoop:
      for (final chunk in chunks) {
        if (LocalSettings.instance.remoteFetchEnabled) {
          try {
            final Set<int> fileIds =
                {}; // if there are duplicates here server returns 400
            // Try to find embeddings on the remote server
            for (final f in chunk) {
              fileIds.add(f.uploadedFileID!);
            }
            _logger.info('starting remote fetch for ${fileIds.length} files');
            final res =
                await RemoteFileMLService.instance.getFilessEmbedding(fileIds);
            _logger.info('fetched ${res.mlData.length} embeddings');
            fetchedCount += res.mlData.length;
            final List<Face> faces = [];
            final remoteFileIdToVersion = <int, int>{};
            for (FileMl fileMl in res.mlData.values) {
              if (_shouldDiscardRemoteEmbedding(fileMl)) continue;
              if (fileMl.faceEmbedding.faces.isEmpty) {
                faces.add(
                  Face.empty(
                    fileMl.fileID,
                  ),
                );
              } else {
                for (final f in fileMl.faceEmbedding.faces) {
                  f.fileInfo = FileInfo(
                    imageHeight: fileMl.height,
                    imageWidth: fileMl.width,
                  );
                  faces.add(f);
                }
              }
              remoteFileIdToVersion[fileMl.fileID] =
                  fileMl.faceEmbedding.version;
            }
            if (res.noEmbeddingFileIDs.isNotEmpty) {
              _logger.info(
                'No embeddings found for ${res.noEmbeddingFileIDs.length} files',
              );
              for (final fileID in res.noEmbeddingFileIDs) {
                faces.add(Face.empty(fileID, error: false));
                remoteFileIdToVersion[fileID] = faceMlVersion;
              }
            }

            await FaceMLDataDB.instance.bulkInsertFaces(faces);
            _logger.info('stored embeddings');
            for (final entry in remoteFileIdToVersion.entries) {
              alreadyIndexedFiles[entry.key] = entry.value;
            }
            _logger
                .info('already indexed files ${remoteFileIdToVersion.length}');
          } catch (e, s) {
            _logger.severe("err while getting files embeddings", e, s);
            if (retryFetchCount < 1000) {
              Future.delayed(Duration(seconds: retryFetchCount), () {
                unawaited(indexAllImages(retryFetchCount: retryFetchCount * 2));
              });
              return;
            } else {
              _logger.severe(
                "Failed to fetch embeddings for files after multiple retries",
                e,
                s,
              );
              rethrow;
            }
          }
        } else {
          _logger.warning(
            'Not fetching embeddings because user manually disabled it in debug options',
          );
        }
        final smallerChunks = chunk.chunks(_fileDownloadLimit);
        for (final smallestChunk in smallerChunks) {
          final futures = <Future<bool>>[];
          if (!await canUseHighBandwidth()) {
            _logger.info(
              'stopping indexing because user is not connected to wifi',
            );
            break outerLoop;
          }
          for (final enteFile in smallestChunk) {
            if (_shouldPauseIndexingAndClustering) {
              _logger.info("indexAllImages() was paused, stopping");
              break outerLoop;
            }
            if (_skipAnalysisEnteFile(
              enteFile,
              alreadyIndexedFiles,
            )) {
              fileSkippedCount++;
              continue;
            }
            await _ensureReadyForInference();
            futures.add(processImage(enteFile));
          }
          final awaitedFutures = await Future.wait(futures);
          final sumFutures = awaitedFutures.fold<int>(
            0,
            (previousValue, element) => previousValue + (element ? 1 : 0),
          );
          fileAnalyzedCount += sumFutures;
        }
      }

      stopwatch.stop();
      _logger.info(
        "`indexAllImages()` finished. Fetched $fetchedCount and analyzed $fileAnalyzedCount images, in ${stopwatch.elapsed.inSeconds} seconds (avg of ${stopwatch.elapsed.inSeconds / fileAnalyzedCount} seconds per image, skipped $fileSkippedCount images)",
      );
      _logStatus();
    } catch (e, s) {
      _logger.severe("indexAllImages failed", e, s);
    } finally {
      _isIndexingOrClusteringRunning = false;
      _shouldPauseIndexingAndClustering = false;
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
      _shouldPauseIndexingAndClustering = false;
    }
  }

  Future<bool> processImage(EnteFile enteFile) async {
    _logger.info(
      "`processImage` start processing image with uploadedFileID: ${enteFile.uploadedFileID}",
    );

    try {
      final FaceMlResult? result = await _analyzeImageInSingleIsolate(
        enteFile,
        // preferUsingThumbnailForEverything: false,
        // disposeImageIsolateAfterUse: false,
      );
      if (result == null) {
        if (!_shouldPauseIndexingAndClustering) {
          _logger.severe(
            "Failed to analyze image with uploadedFileID: ${enteFile.uploadedFileID}",
          );
        }
        return false;
      }
      final List<Face> faces = [];
      if (!result.hasFaces) {
        debugPrint(
          'No faces detected for file with name:${enteFile.displayName}',
        );
        faces.add(
          Face.empty(result.fileId, error: result.errorOccured),
        );
      } else {
        if (result.decodedImageSize.width == -1 ||
            result.decodedImageSize.height == -1) {
          _logger
              .severe("decodedImageSize is not stored correctly for image with "
                  "ID: ${enteFile.uploadedFileID}");
          _logger.info(
            "Using aligned image size for image with ID: ${enteFile.uploadedFileID}. This size is ${result.decodedImageSize.width}x${result.decodedImageSize.height} compared to size of ${enteFile.width}x${enteFile.height} in the metadata",
          );
        }
        for (int i = 0; i < result.faces.length; ++i) {
          final FaceResult faceRes = result.faces[i];
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
        await RemoteFileMLService.instance.putFileEmbedding(
          enteFile,
          FileMl(
            enteFile.uploadedFileID!,
            FaceEmbeddings(
              faces,
              result.mlVersion,
              client: client,
            ),
            height: result.decodedImageSize.height,
            width: result.decodedImageSize.width,
          ),
        );
      } else {
        _logger.warning(
          'Skipped putting embedding because of error ${result.toJsonString()}',
        );
      }
      await FaceMLDataDB.instance.bulkInsertFaces(faces);
      return true;
    } on ThumbnailRetrievalException catch (e, s) {
      _logger.severe(
        'ThumbnailRetrievalException while processing image with ID ${enteFile.uploadedFileID}, storing empty face so indexing does not get stuck',
        e,
        s,
      );
      await FaceMLDataDB.instance
          .bulkInsertFaces([Face.empty(enteFile.uploadedFileID!, error: true)]);
      return true;
    } catch (e, s) {
      _logger.severe(
        "Failed to analyze using FaceML for image with ID: ${enteFile.uploadedFileID}. Not storing any faces, which means it will be automatically retried later.",
        e,
        s,
      );
      return false;
    }
  }

  Future<void> _initModels() async {
    return _initModelLock.synchronized(() async {
      if (_isModelsInitialized) return;
      _logger.info('initModels called');

      // Get client name
      final packageInfo = await PackageInfo.fromPlatform();
      client = "${packageInfo.packageName}/${packageInfo.version}";
      _logger.info("client: $client");

      // Initialize models
      await _computer.compute(() => OrtEnv.instance.init());
      try {
        await FaceDetectionService.instance.init();
      } catch (e, s) {
        _logger.severe("Could not initialize yolo onnx", e, s);
      }
      try {
        await FaceEmbeddingService.instance.init();
      } catch (e, s) {
        _logger.severe("Could not initialize mobilefacenet", e, s);
      }
      _isModelsInitialized = true;
      _logger.info('initModels done');
      _logStatus();
    });
  }

  Future<void> _releaseModels() async {
    return _initModelLock.synchronized(() async {
      _logger.info("dispose called");
      if (!_isModelsInitialized) {
        return;
      }
      try {
        await FaceDetectionService.instance.release();
      } catch (e, s) {
        _logger.severe("Could not dispose yolo onnx", e, s);
      }
      try {
        await FaceEmbeddingService.instance.release();
      } catch (e, s) {
        _logger.severe("Could not dispose mobilefacenet", e, s);
      }
      OrtEnv.instance.release();
      _isModelsInitialized = false;
    });
  }

  Future<void> _initIsolate() async {
    return _initIsolateLock.synchronized(() async {
      if (_isIsolateSpawned) return;
      _logger.info("initIsolate called");

      _receivePort = ReceivePort();

      try {
        _isolate = await DartUiIsolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        _isIsolateSpawned = true;

        _resetInactivityTimer();
        _logger.info('initIsolate done');
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        _isIsolateSpawned = false;
      }
    });
  }

  Future<void> _ensureReadyForInference() async {
    await _initModels();
    await _initIsolate();
  }

  /// The main execution function of the isolate.
  @pragma('vm:entry-point')
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = FaceMlOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case FaceMlOperation.analyzeImage:
            final time = DateTime.now();
            final FaceMlResult result =
                await FaceMlService._analyzeImageSync(args);
            dev.log(
              "`analyzeImageSync` function executed in ${DateTime.now().difference(time).inMilliseconds} ms",
            );
            sendPort.send(result.toJsonString());
            break;
        }
      } catch (e, stackTrace) {
        dev.log(
          "[SEVERE] Error in FaceML isolate: $e",
          error: e,
          stackTrace: stackTrace,
        );
        sendPort
            .send({'error': e.toString(), 'stackTrace': stackTrace.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (FaceMlOperation, Map<String, dynamic>) message,
  ) async {
    await _initIsolate();
    return _functionLock.synchronized(() async {
      _resetInactivityTimer();

      if (_shouldPauseIndexingAndClustering) {
        return null;
      }

      final completer = Completer<dynamic>();
      final answerPort = ReceivePort();

      _activeTasks++;
      _mainSendPort.send([message.$1.index, message.$2, answerPort.sendPort]);

      answerPort.listen((receivedMessage) {
        if (receivedMessage is Map && receivedMessage.containsKey('error')) {
          // Handle the error
          final errorMessage = receivedMessage['error'];
          final errorStackTrace = receivedMessage['stackTrace'];
          final exception = Exception(errorMessage);
          final stackTrace = StackTrace.fromString(errorStackTrace);
          completer.completeError(exception, stackTrace);
        } else {
          completer.complete(receivedMessage);
        }
      });
      _activeTasks--;

      return completer.future;
    });
  }

  /// Resets a timer that kills the isolate after a certain amount of inactivity.
  ///
  /// Should be called after initialization (e.g. inside `init()`) and after every call to isolate (e.g. inside `_runInIsolate()`)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (_activeTasks > 0) {
        _logger.info('Tasks are still running. Delaying isolate disposal.');
        // Optionally, reschedule the timer to check again later.
        _resetInactivityTimer();
      } else {
        _logger.info(
          'Clustering Isolate has been inactive for ${_inactivityDuration.inSeconds} seconds with no tasks running. Killing isolate.',
        );
        _dispose();
      }
    });
  }

  void _dispose() async {
    if (!_isIsolateSpawned) return;
    _logger.info('Disposing isolate and models');
    await _releaseModels();
    _isIsolateSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  /// Analyzes the given image data by running the full pipeline for faces, using [_analyzeImageSync] in the isolate.
  Future<FaceMlResult?> _analyzeImageInSingleIsolate(EnteFile enteFile) async {
    _checkEnteFileForID(enteFile);

    final String? filePath =
        await _getImagePathForML(enteFile, typeOfData: FileDataForML.fileData);

    if (filePath == null) {
      _logger.warning(
        "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID} since its file path is null",
      );
      throw CouldNotRetrieveAnyFileData();
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    late FaceMlResult result;

    try {
      final resultJsonString = await _runInIsolate(
        (
          FaceMlOperation.analyzeImage,
          {
            "enteFileID": enteFile.uploadedFileID ?? -1,
            "filePath": filePath,
            "faceDetectionAddress":
                FaceDetectionService.instance.sessionAddress,
            "faceEmbeddingAddress":
                FaceEmbeddingService.instance.sessionAddress,
          }
        ),
      ) as String?;
      if (resultJsonString == null) {
        if (!_shouldPauseIndexingAndClustering) {
          _logger.severe('Analyzing image in isolate is giving back null');
        }
        return null;
      }
      result = FaceMlResult.fromJsonString(resultJsonString);
    } catch (e, s) {
      _logger.severe(
        "Could not analyze image with ID ${enteFile.uploadedFileID} \n",
        e,
        s,
      );
      debugPrint(
        "This image with ID ${enteFile.uploadedFileID} has name ${enteFile.displayName}.",
      );
      final resultBuilder =
          FaceMlResult.fromEnteFileID(enteFile.uploadedFileID!)
            ..errorOccurred();
      return resultBuilder;
    }
    stopwatch.stop();
    _logger.info(
      "Finished Analyze image (${result.faces.length} faces) with uploadedFileID ${enteFile.uploadedFileID}, in "
      "${stopwatch.elapsedMilliseconds} ms (including time waiting for inference engine availability)",
    );

    return result;
  }

  static Future<FaceMlResult> _analyzeImageSync(Map args) async {
    try {
      final int enteFileID = args["enteFileID"] as int;
      final String imagePath = args["filePath"] as String;
      final int faceDetectionAddress = args["faceDetectionAddress"] as int;
      final int faceEmbeddingAddress = args["faceEmbeddingAddress"] as int;

      final resultBuilder = FaceMlResult.fromEnteFileID(enteFileID);

      dev.log(
        "Start analyzing image with uploadedFileID: $enteFileID inside the isolate",
      );
      final stopwatchTotal = Stopwatch()..start();
      final stopwatch = Stopwatch()..start();

      // Decode the image once to use for both face detection and alignment
      final imageData = await File(imagePath).readAsBytes();
      final image = await decodeImageFromData(imageData);
      final ByteData imgByteData = await getByteDataFromImage(image);
      dev.log('Reading and decoding image took '
          '${stopwatch.elapsedMilliseconds} ms');
      stopwatch.reset();

      // Get the faces
      final List<FaceDetectionRelative> faceDetectionResult =
          await FaceMlService._detectFacesSync(
        image,
        imgByteData,
        faceDetectionAddress,
        resultBuilder: resultBuilder,
      );

      dev.log(
          "${faceDetectionResult.length} faces detected with scores ${faceDetectionResult.map((e) => e.score).toList()}: completed `detectFacesSync` function, in "
          "${stopwatch.elapsedMilliseconds} ms");

      // If no faces were detected, return a result with no faces. Otherwise, continue.
      if (faceDetectionResult.isEmpty) {
        dev.log(
            "No faceDetectionResult, Completed analyzing image with uploadedFileID $enteFileID, in "
            "${stopwatch.elapsedMilliseconds} ms");
        resultBuilder.noFaceDetected();
        return resultBuilder;
      }

      stopwatch.reset();
      // Align the faces
      final Float32List faceAlignmentResult =
          await FaceMlService._alignFacesSync(
        image,
        imgByteData,
        faceDetectionResult,
        resultBuilder: resultBuilder,
      );

      dev.log("Completed `alignFacesSync` function, in "
          "${stopwatch.elapsedMilliseconds} ms");

      stopwatch.reset();
      // Get the embeddings of the faces
      final embeddings = await FaceMlService._embedFacesSync(
        faceAlignmentResult,
        faceEmbeddingAddress,
        resultBuilder: resultBuilder,
      );

      dev.log("Completed `embedFacesSync` function, in "
          "${stopwatch.elapsedMilliseconds} ms");

      stopwatch.stop();
      stopwatchTotal.stop();
      dev.log("Finished Analyze image (${embeddings.length} faces) with "
          "uploadedFileID $enteFileID, in "
          "${stopwatchTotal.elapsedMilliseconds} ms");

      return resultBuilder;
    } catch (e, s) {
      dev.log("Could not analyze image: \n e: $e \n s: $s");
      rethrow;
    }
  }

  Future<String?> _getImagePathForML(
    EnteFile enteFile, {
    FileDataForML typeOfData = FileDataForML.fileData,
  }) async {
    String? imagePath;

    switch (typeOfData) {
      case FileDataForML.fileData:
        final stopwatch = Stopwatch()..start();
        File? file;
        if (enteFile.fileType == FileType.video) {
          try {
            file = await getThumbnailForUploadedFile(enteFile);
          } on PlatformException catch (e, s) {
            _logger.severe(
              "Could not get thumbnail for $enteFile due to PlatformException",
              e,
              s,
            );
            throw ThumbnailRetrievalException(e.toString(), s);
          }
        } else {
          try {
            file = await getFile(enteFile, isOrigin: true);
          } catch (e, s) {
            _logger.severe(
              "Could not get file for $enteFile",
              e,
              s,
            );
          }
        }
        if (file == null) {
          _logger.warning(
            "Could not get file for $enteFile of type ${enteFile.fileType.toString()}",
          );
          imagePath = null;
          break;
        }
        imagePath = file.path;
        stopwatch.stop();
        _logger.info(
          "Getting file data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
        );
        break;

      case FileDataForML.thumbnailData:
        final stopwatch = Stopwatch()..start();
        final File? thumbnail = await getThumbnailForUploadedFile(enteFile);
        if (thumbnail == null) {
          _logger.warning("Could not get thumbnail for $enteFile");
          imagePath = null;
          break;
        }
        imagePath = thumbnail.path;
        stopwatch.stop();
        _logger.info(
          "Getting thumbnail data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
        );
        break;
    }

    return imagePath;
  }

  /// Detects faces in the given image data.
  ///
  /// `imageData`: The image data to analyze.
  ///
  /// Returns a list of face detection results.
  static Future<List<FaceDetectionRelative>> _detectFacesSync(
    Image image,
    ByteData imageByteData,
    int interpreterAddress, {
    FaceMlResult? resultBuilder,
  }) async {
    try {
      // Get the bounding boxes of the faces
      final (List<FaceDetectionRelative> faces, dataSize) =
          await FaceDetectionService.predict(
        image,
        imageByteData,
        interpreterAddress,
      );

      // Add detected faces to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addNewlyDetectedFaces(faces, dataSize);
      }

      return faces;
    } on YOLOFaceInterpreterRunException {
      throw CouldNotRunFaceDetector();
    } catch (e) {
      dev.log('[SEVERE] Face detection failed: $e');
      throw GeneralFaceMlException('Face detection failed: $e');
    }
  }

  /// Aligns multiple faces from the given image data.
  ///
  /// `imageData`: The image data in [Uint8List] that contains the faces.
  /// `faces`: The face detection results in a list of [FaceDetectionAbsolute] for the faces to align.
  ///
  /// Returns a list of the aligned faces as image data.
  static Future<Float32List> _alignFacesSync(
    Image image,
    ByteData imageByteData,
    List<FaceDetectionRelative> faces, {
    FaceMlResult? resultBuilder,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final (alignedFaces, alignmentResults, _, blurValues, _) =
          await preprocessToMobileFaceNetFloat32List(
        image,
        imageByteData,
        faces,
      );
      stopwatch.stop();
      dev.log(
        "Face alignment image decoding and processing took ${stopwatch.elapsedMilliseconds} ms",
      );

      if (resultBuilder != null) {
        resultBuilder.addAlignmentResults(
          alignmentResults,
          blurValues,
        );
      }

      return alignedFaces;
    } catch (e, s) {
      dev.log('[SEVERE] Face alignment failed: $e $s');
      throw CouldNotWarpAffine();
    }
  }

  static Future<List<List<double>>> _embedFacesSync(
    Float32List facesList,
    int interpreterAddress, {
    FaceMlResult? resultBuilder,
  }) async {
    try {
      // Get the embedding of the faces
      final List<List<double>> embeddings =
          await FaceEmbeddingService.predict(facesList, interpreterAddress);

      // Add the embeddings to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addEmbeddingsToExistingFaces(embeddings);
      }

      return embeddings;
    } on MobileFaceNetInterpreterRunException {
      throw CouldNotRunFaceEmbeddor();
    } catch (e) {
      dev.log('[SEVERE] Face embedding (batch) failed: $e');
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }

  bool _shouldDiscardRemoteEmbedding(FileMl fileMl) {
    if (fileMl.faceEmbedding.version < faceMlVersion) {
      debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
          "because version is ${fileMl.faceEmbedding.version} and we need $faceMlVersion");
      return true;
    }
    // are all landmarks equal?
    bool allLandmarksEqual = true;
    if (fileMl.faceEmbedding.faces.isEmpty) {
      debugPrint("No face for ${fileMl.fileID}");
      allLandmarksEqual = false;
    }
    for (final face in fileMl.faceEmbedding.faces) {
      if (face.detection.landmarks.isEmpty) {
        allLandmarksEqual = false;
        break;
      }
      if (face.detection.landmarks
          .any((landmark) => landmark.x != landmark.y)) {
        allLandmarksEqual = false;
        break;
      }
    }
    if (allLandmarksEqual) {
      debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
          "because landmarks are equal");
      debugPrint(
        fileMl.faceEmbedding.faces
            .map((e) => e.detection.landmarks.toString())
            .toList()
            .toString(),
      );
      return true;
    }
    if (fileMl.width == null || fileMl.height == null) {
      debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
          "because width is null");
      return true;
    }
    return false;
  }

  /// Checks if the ente file to be analyzed actually can be analyzed: it must be uploaded and in the correct format.
  void _checkEnteFileForID(EnteFile enteFile) {
    if (_skipAnalysisEnteFile(enteFile, <int, int>{})) {
      final String logString =
          '''Skipped analysis of image with enteFile, it might be the wrong format or has no uploadedFileID, or MLController doesn't allow it to run.
        enteFile: ${enteFile.toString()}
        ''';
      _logger.warning(logString);
      _logStatus();
      throw GeneralFaceMlException(logString);
    }
  }

  bool _skipAnalysisEnteFile(EnteFile enteFile, Map<int, int> indexedFileIds) {
    if (_isIndexingOrClusteringRunning == false ||
        _mlControllerStatus == false) {
      return true;
    }
    // Skip if the file is not uploaded or not owned by the user
    if (!enteFile.isUploaded || enteFile.isOwner == false) {
      return true;
    }
    // I don't know how motionPhotos and livePhotos work, so I'm also just skipping them for now
    if (enteFile.fileType == FileType.other) {
      return true;
    }
    // Skip if the file is already analyzed with the latest ml version
    final id = enteFile.uploadedFileID!;

    return indexedFileIds.containsKey(id) &&
        indexedFileIds[id]! >= faceMlVersion;
  }

  bool _cannotRunMLFunction({String function = ""}) {
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
    isFaceIndexingEnabled: ${LocalSettings.instance.isFaceIndexingEnabled}
    canRunMLController: $_mlControllerStatus
    isIndexingOrClusteringRunning: $_isIndexingOrClusteringRunning
    shouldPauseIndexingAndClustering: $_shouldPauseIndexingAndClustering
    debugIndexingDisabled: $debugIndexingDisabled
    shouldSyncPeople: $_shouldSyncPeople
    ''';
    _logger.info(status);
  }
}
