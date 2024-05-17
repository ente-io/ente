import "dart:async";
import "dart:developer" as dev show log;
import "dart:io" show File, Platform;
import "dart:isolate";
import "dart:math" show min;
import "dart:typed_data" show Uint8List, Float32List, ByteData;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:dart_ui_isolate/dart_ui_isolate.dart";
import "package:flutter/foundation.dart" show debugPrint, kDebugMode;
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/core/configuration.dart";
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
import "package:photos/services/machine_learning/face_ml/face_clustering/face_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import 'package:photos/services/machine_learning/face_ml/face_ml_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_ml_result.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/file_ml/file_ml.dart';
import 'package:photos/services/machine_learning/file_ml/remote_fileml_service.dart';
import "package:photos/services/search_service.dart";
import "package:photos/utils/file_util.dart";
import 'package:photos/utils/image_ml_isolate.dart';
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/network_util.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:synchronized/synchronized.dart";

enum FileDataForML { thumbnailData, fileData, compressedFileData }

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
  final _initLockIsolate = Lock();
  late DartUiIsolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isIsolateSpawned = false;

  // singleton pattern
  FaceMlService._privateConstructor();

  static final instance = FaceMlService._privateConstructor();

  factory FaceMlService() => instance;

  final _initLock = Lock();
  final _functionLock = Lock();

  final _computer = Computer.shared();

  bool isInitialized = false;

  bool canRunMLController = false;
  bool isImageIndexRunning = false;
  bool isClusteringRunning = false;
  bool shouldSyncPeople = false;

  final int _fileDownloadLimit = 15;
  final int _embeddingFetchLimit = 200;

  Future<void> init({bool initializeImageMlIsolate = false}) async {
    if (LocalSettings.instance.isFaceIndexingEnabled == false) {
      return;
    }
    return _initLock.synchronized(() async {
      if (isInitialized) {
        return;
      }
      _logger.info("init called");
      await _computer.compute(initOrtEnv);
      try {
        await FaceDetectionService.instance.init();
      } catch (e, s) {
        _logger.severe("Could not initialize yolo onnx", e, s);
      }
      if (initializeImageMlIsolate) {
        try {
          await ImageMlIsolate.instance.init();
        } catch (e, s) {
          _logger.severe("Could not initialize image ml isolate", e, s);
        }
      }
      try {
        await FaceEmbeddingService.instance.init();
      } catch (e, s) {
        _logger.severe("Could not initialize mobilefacenet", e, s);
      }

      isInitialized = true;
      canRunMLController = !Platform.isAndroid || kDebugMode;

      /// hooking FaceML into [MachineLearningController]
      if (Platform.isAndroid && !kDebugMode) {
        Bus.instance.on<MachineLearningControlEvent>().listen((event) {
          if (LocalSettings.instance.isFaceIndexingEnabled == false) {
            return;
          }
          canRunMLController = event.shouldRun;
          if (canRunMLController) {
            unawaited(indexAllImages());
          } else {
            pauseIndexing();
          }
        });
      } else {
        unawaited(indexAllImages());
      }
    });
  }

  static void initOrtEnv() async {
    OrtEnv.instance.init();
  }

  void listenIndexOnDiffSync() {
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      if (LocalSettings.instance.isFaceIndexingEnabled == false || kDebugMode) {
        return;
      }
      // [neeraj] intentional delay in starting indexing on diff sync, this gives time for the user
      // to disable face-indexing in case it's causing crash. In the future, we
      // should have a better way to handle this.
      shouldSyncPeople = true;
      Future.delayed(const Duration(seconds: 10), () {
        unawaited(indexAllImages());
      });
    });
  }

  void listenOnPeopleChangedSync() {
    Bus.instance.on<PeopleChangedEvent>().listen((event) {
      shouldSyncPeople = true;
    });
  }

  Future<void> ensureInitialized() async {
    if (!isInitialized) {
      await init();
    }
  }

  Future<void> release() async {
    return _initLock.synchronized(() async {
      _logger.info("dispose called");
      if (!isInitialized) {
        return;
      }
      try {
        await FaceDetectionService.instance.release();
      } catch (e, s) {
        _logger.severe("Could not dispose yolo onnx", e, s);
      }
      try {
        ImageMlIsolate.instance.dispose();
      } catch (e, s) {
        _logger.severe("Could not dispose image ml isolate", e, s);
      }
      try {
        await FaceEmbeddingService.instance.release();
      } catch (e, s) {
        _logger.severe("Could not dispose mobilefacenet", e, s);
      }
      OrtEnv.instance.release();
      isInitialized = false;
    });
  }

  Future<void> initIsolate() async {
    return _initLockIsolate.synchronized(() async {
      if (isIsolateSpawned) return;
      _logger.info("initIsolate called");

      _receivePort = ReceivePort();

      try {
        _isolate = await DartUiIsolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        isIsolateSpawned = true;

        _resetInactivityTimer();
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        isIsolateSpawned = false;
      }
    });
  }

  Future<void> ensureSpawnedIsolate() async {
    if (!isIsolateSpawned) {
      await initIsolate();
    }
  }

  /// The main execution function of the isolate.
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
                await FaceMlService.analyzeImageSync(args);
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
    await ensureSpawnedIsolate();
    return _functionLock.synchronized(() async {
      _resetInactivityTimer();

      if (isImageIndexRunning == false || canRunMLController == false) {
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
        disposeIsolate();
      }
    });
  }

  void disposeIsolate() async {
    if (!isIsolateSpawned) return;
    await release();

    isIsolateSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  Future<void> clusterAllImages({
    double minFaceScore = kMinimumQualityFaceScore,
    bool clusterInBuckets = true,
  }) async {
    if (!canRunMLController) {
      _logger
          .info("MLController does not allow running ML, skipping clustering");
      return;
    }
    if (isClusteringRunning) {
      _logger.info("clusterAllImages is already running, skipping");
      return;
    }
    // verify faces is enabled
    if (LocalSettings.instance.isFaceIndexingEnabled == false) {
      _logger.warning("clustering is disabled by user");
      return;
    }

    final indexingCompleteRatio = await _getIndexedDoneRatio();
    if (indexingCompleteRatio < 0.95) {
      _logger.info(
        "Indexing is not far enough, skipping clustering. Indexing is at $indexingCompleteRatio",
      );
      return;
    }

    _logger.info("`clusterAllImages()` called");
    isClusteringRunning = true;
    final clusterAllImagesTime = DateTime.now();

    try {
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
      final allFaceInfoForClustering = <FaceInfoForClustering>[];
      for (final faceInfo in result) {
        if (!fileIDToCreationTime.containsKey(faceInfo.fileID)) {
          missingFileIDs.add(faceInfo.fileID);
        } else {
          allFaceInfoForClustering.add(faceInfo);
        }
      }
      // sort the embeddings based on file creation time, oldest first
      allFaceInfoForClustering.sort((a, b) {
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
        const int bucketSize = 20000;
        const int offsetIncrement = 7500;
        int offset = 0;
        int bucket = 1;

        while (true) {
          if (!canRunMLController) {
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

          final clusteringResult =
              await FaceClusteringService.instance.predictLinear(
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
              .clusterSummaryUpdate(clusteringResult.newClusterSummaries!);
          for (final faceInfo in faceInfoForClustering) {
            faceInfo.clusterId ??=
                clusteringResult.newFaceIdToCluster[faceInfo.faceID];
          }
          for (final clusterUpdate
              in clusteringResult.newClusterSummaries!.entries) {
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
            await FaceClusteringService.instance.predictLinear(
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
            .clusterSummaryUpdate(clusteringResult.newClusterSummaries!);
        _logger.info('Done updating FaceIDs with clusterIDs in the DB, in '
            '${DateTime.now().difference(clusterDoneTime).inSeconds} seconds');
      }
      Bus.instance.fire(PeopleChangedEvent());
      _logger.info('clusterAllImages() finished, in '
          '${DateTime.now().difference(clusterAllImagesTime).inSeconds} seconds');
      isClusteringRunning = false;
    } catch (e, s) {
      _logger.severe("`clusterAllImages` failed", e, s);
    }
  }

  bool shouldDiscardRemoteEmbedding(FileMl fileMl) {
    if (fileMl.faceEmbedding.version < faceMlVersion) {
      debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
          "because version is ${fileMl.faceEmbedding.version} and we need $faceMlVersion");
      return true;
    }
    if (fileMl.faceEmbedding.error ?? false) {
      debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
          "because error is true");
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

  /// Analyzes all the images in the database with the latest ml version and stores the results in the database.
  ///
  /// This function first checks if the image has already been analyzed with the lastest faceMlVersion and stored in the database. If so, it skips the image.
  Future<void> indexAllImages({int retryFetchCount = 10}) async {
    if (isImageIndexRunning) {
      _logger.warning("indexAllImages is already running, skipping");
      return;
    }
    if (shouldSyncPeople) {
      await PersonService.instance.reconcileClusters();
      shouldSyncPeople = false;
    }

    // verify faces is enabled
    if (LocalSettings.instance.isFaceIndexingEnabled == false) {
      _logger.warning("indexing is disabled by user");
      return;
    }
    try {
      isImageIndexRunning = true;
      _logger.info('starting image indexing');
      // final w = (kDebugMode ? EnteWatch('FacesGetAllFiles') : null)?..start();
      // final uploadedFileIDs = await FilesDB.instance
      //     .getOwnedFileIDs(Configuration.instance.getUserID()!);
      // w?.log('getOwnedFileIDs');
      // final enteFiles =
      //     await FilesDB.instance.getUploadedFiles(uploadedFileIDs);
      // w?.log('getUploadedFiles');
      final Map<int, int> alreadyIndexedFiles =
          await FaceMLDataDB.instance.getIndexedFileIds();
      // w?.log('getIndexedFileIds');
      final List<EnteFile> enteFiles =
          await SearchService.instance.getAllFiles();

      // Make sure the image conversion isolate is spawned
      // await ImageMlIsolate.instance.ensureSpawned();
      await ensureInitialized();

      int fileAnalyzedCount = 0;
      int fileSkippedCount = 0;
      final stopwatch = Stopwatch()..start();
      final List<EnteFile> filesWithLocalID = <EnteFile>[];
      final List<EnteFile> filesWithoutLocalID = <EnteFile>[];
      final List<EnteFile> hiddenFiles = <EnteFile>[];
      // final ignoredCollections =
      //     CollectionsService.instance.getHiddenCollectionIds();
      for (final EnteFile enteFile in enteFiles) {
        if (_skipAnalysisEnteFile(enteFile, alreadyIndexedFiles)) {
          fileSkippedCount++;
          continue;
        }
        // if (ignoredCollections.contains(enteFile.collectionID)) {
        //   hiddenFiles.add(enteFile);
        // } else
        if ((enteFile.localID ?? '').isEmpty) {
          filesWithoutLocalID.add(enteFile);
        } else {
          filesWithLocalID.add(enteFile);
        }
      }

      // list of files where files with localID are first
      final sortedBylocalID = <EnteFile>[];
      sortedBylocalID.addAll(filesWithLocalID);
      sortedBylocalID.addAll(filesWithoutLocalID);
      sortedBylocalID.addAll(hiddenFiles);
      final List<List<EnteFile>> chunks =
          sortedBylocalID.chunks(_embeddingFetchLimit);
      outerLoop:
      for (final chunk in chunks) {
        final futures = <Future<bool>>[];

        if (LocalSettings.instance.remoteFetchEnabled) {
          try {
            final List<int> fileIds = [];
            // Try to find embeddings on the remote server
            for (final f in chunk) {
              fileIds.add(f.uploadedFileID!);
            }
            final EnteWatch? w =
                flagService.internalUser ? EnteWatch("face_em_fetch") : null;
            w?.start();
            w?.log('starting remote fetch for ${fileIds.length} files');
            final res =
                await RemoteFileMLService.instance.getFilessEmbedding(fileIds);
            w?.logAndReset('fetched ${res.mlData.length} embeddings');
            final List<Face> faces = [];
            final remoteFileIdToVersion = <int, int>{};
            for (FileMl fileMl in res.mlData.values) {
              if (shouldDiscardRemoteEmbedding(fileMl)) continue;
              if (fileMl.faceEmbedding.faces.isEmpty) {
                faces.add(
                  Face.empty(
                    fileMl.fileID,
                    error: (fileMl.faceEmbedding.error ?? false),
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
            w?.logAndReset('stored embeddings');
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
        }
        if (!await canUseHighBandwidth()) {
          continue;
        }
        final smallerChunks = chunk.chunks(_fileDownloadLimit);
        for (final smallestChunk in smallerChunks) {
          for (final enteFile in smallestChunk) {
            if (isImageIndexRunning == false) {
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
        "`indexAllImages()` finished. Analyzed $fileAnalyzedCount images, in ${stopwatch.elapsed.inSeconds} seconds (avg of ${stopwatch.elapsed.inSeconds / fileAnalyzedCount} seconds per image, skipped $fileSkippedCount images. MLController status: $canRunMLController)",
      );

      // Cluster all the images after finishing indexing
      unawaited(clusterAllImages());

      // Dispose of all the isolates
      // ImageMlIsolate.instance.dispose();
      // await release();
    } catch (e, s) {
      _logger.severe("indexAllImages failed", e, s);
    } finally {
      isImageIndexRunning = false;
    }
  }

  Future<bool> processImage(EnteFile enteFile) async {
    _logger.info(
      "`indexAllImages()` on file number  start processing image with uploadedFileID: ${enteFile.uploadedFileID}",
    );

    try {
      final FaceMlResult? result = await analyzeImageInSingleIsolate(
        enteFile,
        // preferUsingThumbnailForEverything: false,
        // disposeImageIsolateAfterUse: false,
      );
      if (result == null) {
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
              xMin: faceRes.detection.xMinBox,
              yMin: faceRes.detection.yMinBox,
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
      await RemoteFileMLService.instance.putFileEmbedding(
        enteFile,
        FileMl(
          enteFile.uploadedFileID!,
          FaceEmbeddings(
            faces,
            result.mlVersion,
            error: result.errorOccured ? true : null,
          ),
          height: result.decodedImageSize.height,
          width: result.decodedImageSize.width,
        ),
      );
      await FaceMLDataDB.instance.bulkInsertFaces(faces);
      return true;
    } catch (e, s) {
      _logger.severe(
        "Failed to analyze using FaceML for image with ID: ${enteFile.uploadedFileID}",
        e,
        s,
      );
      return true;
    }
  }

  void pauseIndexing() {
    isImageIndexRunning = false;
  }

  /// Analyzes the given image data by running the full pipeline for faces, using [analyzeImageSync] in the isolate.
  Future<FaceMlResult?> analyzeImageInSingleIsolate(EnteFile enteFile) async {
    _checkEnteFileForID(enteFile);
    await ensureInitialized();

    final String? filePath =
        await _getImagePathForML(enteFile, typeOfData: FileDataForML.fileData);

    if (filePath == null) {
      _logger.severe(
        "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID}",
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
      final resultBuilder = FaceMlResultBuilder.fromEnteFile(enteFile);
      return resultBuilder.buildErrorOccurred();
    }
    stopwatch.stop();
    _logger.info(
      "Finished Analyze image (${result.faces.length} faces) with uploadedFileID ${enteFile.uploadedFileID}, in "
      "${stopwatch.elapsedMilliseconds} ms (including time waiting for inference engine availability)",
    );

    return result;
  }

  static Future<FaceMlResult> analyzeImageSync(Map args) async {
    try {
      final int enteFileID = args["enteFileID"] as int;
      final String imagePath = args["filePath"] as String;
      final int faceDetectionAddress = args["faceDetectionAddress"] as int;
      final int faceEmbeddingAddress = args["faceEmbeddingAddress"] as int;

      final resultBuilder = FaceMlResultBuilder.fromEnteFileID(enteFileID);

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
          await FaceMlService.detectFacesSync(
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
        return resultBuilder.buildNoFaceDetected();
      }

      stopwatch.reset();
      // Align the faces
      final Float32List faceAlignmentResult =
          await FaceMlService.alignFacesSync(
        image,
        imgByteData,
        faceDetectionResult,
        resultBuilder: resultBuilder,
      );

      dev.log("Completed `alignFacesSync` function, in "
          "${stopwatch.elapsedMilliseconds} ms");

      stopwatch.reset();
      // Get the embeddings of the faces
      final embeddings = await FaceMlService.embedFacesSync(
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

      return resultBuilder.build();
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
          file = await getThumbnailForUploadedFile(enteFile);
        } else {
          file = await getFile(enteFile, isOrigin: true);
        }
        if (file == null) {
          _logger.warning("Could not get file for $enteFile");
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

      case FileDataForML.compressedFileData:
        _logger.warning(
          "Getting compressed file data for uploadedFileID ${enteFile.uploadedFileID} is not implemented yet",
        );
        imagePath = null;
        break;
    }

    return imagePath;
  }

  @Deprecated('Deprecated in favor of `_getImagePathForML`')
  Future<Uint8List?> _getDataForML(
    EnteFile enteFile, {
    FileDataForML typeOfData = FileDataForML.fileData,
  }) async {
    Uint8List? data;

    switch (typeOfData) {
      case FileDataForML.fileData:
        final stopwatch = Stopwatch()..start();
        final File? actualIoFile = await getFile(enteFile, isOrigin: true);
        if (actualIoFile != null) {
          data = await actualIoFile.readAsBytes();
        }
        stopwatch.stop();
        _logger.info(
          "Getting file data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
        );

        break;

      case FileDataForML.thumbnailData:
        final stopwatch = Stopwatch()..start();
        data = await getThumbnail(enteFile);
        stopwatch.stop();
        _logger.info(
          "Getting thumbnail data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
        );
        break;

      case FileDataForML.compressedFileData:
        final stopwatch = Stopwatch()..start();
        final String tempPath = Configuration.instance.getTempDirectory() +
            "${enteFile.uploadedFileID!}";
        final File? actualIoFile = await getFile(enteFile);
        if (actualIoFile != null) {
          final compressResult = await FlutterImageCompress.compressAndGetFile(
            actualIoFile.path,
            tempPath + ".jpg",
          );
          if (compressResult != null) {
            data = await compressResult.readAsBytes();
          }
        }
        stopwatch.stop();
        _logger.info(
          "Getting compressed file data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
        );
        break;
    }

    return data;
  }

  /// Detects faces in the given image data.
  ///
  /// `imageData`: The image data to analyze.
  ///
  /// Returns a list of face detection results.
  ///
  /// Throws [CouldNotInitializeFaceDetector], [CouldNotRunFaceDetector] or [GeneralFaceMlException] if something goes wrong.
  Future<List<FaceDetectionRelative>> _detectFacesIsolate(
    String imagePath,
    // Uint8List fileData,
    {
    FaceMlResultBuilder? resultBuilder,
  }) async {
    try {
      // Get the bounding boxes of the faces
      final (List<FaceDetectionRelative> faces, dataSize) =
          await FaceDetectionService.instance.predictInComputer(imagePath);

      // Add detected faces to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addNewlyDetectedFaces(faces, dataSize);
      }

      return faces;
    } on YOLOFaceInterpreterInitializationException {
      throw CouldNotInitializeFaceDetector();
    } on YOLOFaceInterpreterRunException {
      throw CouldNotRunFaceDetector();
    } catch (e) {
      _logger.severe('Face detection failed: $e');
      throw GeneralFaceMlException('Face detection failed: $e');
    }
  }

  /// Detects faces in the given image data.
  ///
  /// `imageData`: The image data to analyze.
  ///
  /// Returns a list of face detection results.
  ///
  /// Throws [CouldNotInitializeFaceDetector], [CouldNotRunFaceDetector] or [GeneralFaceMlException] if something goes wrong.
  static Future<List<FaceDetectionRelative>> detectFacesSync(
    Image image,
    ByteData imageByteData,
    int interpreterAddress, {
    FaceMlResultBuilder? resultBuilder,
  }) async {
    try {
      // Get the bounding boxes of the faces
      final (List<FaceDetectionRelative> faces, dataSize) =
          await FaceDetectionService.predictSync(
        image,
        imageByteData,
        interpreterAddress,
      );

      // Add detected faces to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addNewlyDetectedFaces(faces, dataSize);
      }

      return faces;
    } on YOLOFaceInterpreterInitializationException {
      throw CouldNotInitializeFaceDetector();
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
  ///
  /// Throws [CouldNotWarpAffine] or [GeneralFaceMlException] if the face alignment fails.
  Future<Float32List> _alignFaces(
    String imagePath,
    List<FaceDetectionRelative> faces, {
    FaceMlResultBuilder? resultBuilder,
  }) async {
    try {
      final (alignedFaces, alignmentResults, _, blurValues, _) =
          await ImageMlIsolate.instance
              .preprocessMobileFaceNetOnnx(imagePath, faces);

      if (resultBuilder != null) {
        resultBuilder.addAlignmentResults(
          alignmentResults,
          blurValues,
        );
      }

      return alignedFaces;
    } catch (e, s) {
      _logger.severe('Face alignment failed: $e', e, s);
      throw CouldNotWarpAffine();
    }
  }

  /// Aligns multiple faces from the given image data.
  ///
  /// `imageData`: The image data in [Uint8List] that contains the faces.
  /// `faces`: The face detection results in a list of [FaceDetectionAbsolute] for the faces to align.
  ///
  /// Returns a list of the aligned faces as image data.
  ///
  /// Throws [CouldNotWarpAffine] or [GeneralFaceMlException] if the face alignment fails.
  static Future<Float32List> alignFacesSync(
    Image image,
    ByteData imageByteData,
    List<FaceDetectionRelative> faces, {
    FaceMlResultBuilder? resultBuilder,
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

  /// Embeds multiple faces from the given input matrices.
  ///
  /// `facesMatrices`: The input matrices of the faces to embed.
  ///
  /// Returns a list of the face embeddings as lists of doubles.
  ///
  /// Throws [CouldNotInitializeFaceEmbeddor], [CouldNotRunFaceEmbeddor], [InputProblemFaceEmbeddor] or [GeneralFaceMlException] if the face embedding fails.
  Future<List<List<double>>> _embedFaces(
    Float32List facesList, {
    FaceMlResultBuilder? resultBuilder,
  }) async {
    try {
      // Get the embedding of the faces
      final List<List<double>> embeddings =
          await FaceEmbeddingService.instance.predictInComputer(facesList);

      // Add the embeddings to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addEmbeddingsToExistingFaces(embeddings);
      }

      return embeddings;
    } on MobileFaceNetInterpreterInitializationException {
      throw CouldNotInitializeFaceEmbeddor();
    } on MobileFaceNetInterpreterRunException {
      throw CouldNotRunFaceEmbeddor();
    } on MobileFaceNetEmptyInput {
      throw InputProblemFaceEmbeddor("Input is empty");
    } on MobileFaceNetWrongInputSize {
      throw InputProblemFaceEmbeddor("Input size is wrong");
    } on MobileFaceNetWrongInputRange {
      throw InputProblemFaceEmbeddor("Input range is wrong");
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _logger.severe('Face embedding (batch) failed: $e');
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }

  static Future<List<List<double>>> embedFacesSync(
    Float32List facesList,
    int interpreterAddress, {
    FaceMlResultBuilder? resultBuilder,
  }) async {
    try {
      // Get the embedding of the faces
      final List<List<double>> embeddings =
          await FaceEmbeddingService.predictSync(facesList, interpreterAddress);

      // Add the embeddings to the resultBuilder
      if (resultBuilder != null) {
        resultBuilder.addEmbeddingsToExistingFaces(embeddings);
      }

      return embeddings;
    } on MobileFaceNetInterpreterInitializationException {
      throw CouldNotInitializeFaceEmbeddor();
    } on MobileFaceNetInterpreterRunException {
      throw CouldNotRunFaceEmbeddor();
    } on MobileFaceNetEmptyInput {
      throw InputProblemFaceEmbeddor("Input is empty");
    } on MobileFaceNetWrongInputSize {
      throw InputProblemFaceEmbeddor("Input size is wrong");
    } on MobileFaceNetWrongInputRange {
      throw InputProblemFaceEmbeddor("Input range is wrong");
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      dev.log('[SEVERE] Face embedding (batch) failed: $e');
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }

  /// Checks if the ente file to be analyzed actually can be analyzed: it must be uploaded and in the correct format.
  void _checkEnteFileForID(EnteFile enteFile) {
    if (_skipAnalysisEnteFile(enteFile, <int, int>{})) {
      _logger.warning(
        '''Skipped analysis of image with enteFile, it might be the wrong format or has no uploadedFileID, or MLController doesn't allow it to run.
        enteFile: ${enteFile.toString()}
        isImageIndexRunning: $isImageIndexRunning
        canRunML: $canRunMLController
        ''',
      );
      throw CouldNotRetrieveAnyFileData();
    }
  }

  Future<double> _getIndexedDoneRatio() async {
    final w = (kDebugMode ? EnteWatch('_getIndexedDoneRatio') : null)?..start();

    final int alreadyIndexedCount = await FaceMLDataDB.instance
        .getIndexedFileCount(minimumMlVersion: faceMlVersion);
    final int totalIndexableCount = await getIndexableFilesCount();
    final ratio = alreadyIndexedCount / totalIndexableCount;

    w?.log('getIndexedDoneRatio');

    return ratio;
  }

  static Future<int> getIndexableFilesCount() async {
    // final indexableFileIDs = await FilesDB.instance
    //     .getOwnedFileIDs(Configuration.instance.getUserID()!);
    final allFiles = await SearchService.instance.getAllFiles();
    final indexableFiles = allFiles.where((file) {
      return file.isUploaded && file.isOwner;
    }).toList();

    return indexableFiles.length;
  }

  bool _skipAnalysisEnteFile(EnteFile enteFile, Map<int, int> indexedFileIds) {
    if (isImageIndexRunning == false || canRunMLController == false) {
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
}
