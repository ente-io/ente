import "dart:async";
import "dart:developer" as dev show log;
import "dart:io" show File;
import "dart:isolate";
import "dart:typed_data" show Uint8List, Float32List, ByteData;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart" show debugPrint, kDebugMode;
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:flutter_isolate/flutter_isolate.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/diff_sync_complete_event.dart";
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
import 'package:photos/services/machine_learning/face_ml/face_clustering/linear_clustering_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import 'package:photos/services/machine_learning/face_ml/face_ml_exceptions.dart';
import 'package:photos/services/machine_learning/face_ml/face_ml_result.dart';
import 'package:photos/services/machine_learning/file_ml/file_ml.dart';
import 'package:photos/services/machine_learning/file_ml/remote_fileml_service.dart';
import "package:photos/services/search_service.dart";
import "package:photos/utils/file_util.dart";
import 'package:photos/utils/image_ml_isolate.dart';
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/local_settings.dart";
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
  late FlutterIsolate _isolate;
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
  bool isImageIndexRunning = false;
  int kParallelism = 15;

  Future<void> init({bool initializeImageMlIsolate = false}) async {
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
    });
  }

  static void initOrtEnv() async {
    OrtEnv.instance.init();
  }

  void listenIndexOnDiffSync() {
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      if (LocalSettings.instance.isFaceIndexingEnabled == false) {
        return;
      }
      // [neeraj] intentional delay in starting indexing on diff sync, this gives time for the user
      // to disable face-indexing in case it's causing crash. In the future, we
      // should have a better way to handle this.
      Future.delayed(const Duration(seconds: 10), () {
        unawaited(indexAllImages());
      });
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
        _isolate = await FlutterIsolate.spawn(
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
            final int enteFileID = args["enteFileID"] as int;
            final String imagePath = args["filePath"] as String;
            final int faceDetectionAddress =
                args["faceDetectionAddress"] as int;
            final int faceEmbeddingAddress =
                args["faceEmbeddingAddress"] as int;

            final resultBuilder =
                FaceMlResultBuilder.fromEnteFileID(enteFileID);

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
              sendPort.send(resultBuilder.buildNoFaceDetected().toJsonString());
              break;
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

            sendPort.send(resultBuilder.build().toJsonString());
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

      if (isImageIndexRunning == false) {
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

  Future<void> indexAndClusterAllImages() async {
    // Run the analysis on all images to make sure everything is analyzed
    await indexAllImages();

    // Cluster all the images
    await clusterAllImages();
  }

  Future<void> clusterAllImages({
    double minFaceScore = kMinHighQualityFaceScore,
    bool clusterInBuckets = false,
  }) async {
    _logger.info("`clusterAllImages()` called");

    try {
      if (clusterInBuckets) {
        // Get a sense of the total number of faces in the database
        final int totalFaces = await FaceMLDataDB.instance
            .getTotalFaceCount(minFaceScore: minFaceScore);

        // read the creation times from Files DB, in a map from fileID to creation time
        final fileIDToCreationTime =
            await FilesDB.instance.getFileIDToCreationTime();

        const int bucketSize = 20000;
        const int batchSize = 20000;
        const int offsetIncrement = 7500;
        int offset = 0;

        while (true) {
          final faceIdToEmbeddingBucket =
              await FaceMLDataDB.instance.getFaceEmbeddingMap(
            minScore: minFaceScore,
            maxFaces: bucketSize,
            offset: offset,
            batchSize: batchSize,
          );
          if (faceIdToEmbeddingBucket.isEmpty) {
            break;
          }
          if (offset > totalFaces) {
            _logger.warning(
              'offset > totalFaces, this should ideally not happen. offset: $offset, totalFaces: $totalFaces',
            );
            break;
          }

          final faceIdToCluster = await FaceClustering.instance.predictLinear(
            faceIdToEmbeddingBucket,
            fileIDToCreationTime: fileIDToCreationTime,
          );
          if (faceIdToCluster == null) {
            _logger.warning("faceIdToCluster is null");
            return;
          }

          await FaceMLDataDB.instance.updateClusterIdToFaceId(faceIdToCluster);
          offset += offsetIncrement;
        }
      } else {
        // Read all the embeddings from the database, in a map from faceID to embedding
        final clusterStartTime = DateTime.now();
        final faceIdToEmbedding =
            await FaceMLDataDB.instance.getFaceEmbeddingMap(
          minScore: minFaceScore,
        );
        final gotFaceEmbeddingsTime = DateTime.now();
        _logger.info(
          'read embeddings ${faceIdToEmbedding.length} in ${gotFaceEmbeddingsTime.difference(clusterStartTime).inMilliseconds} ms',
        );

        // Read the creation times from Files DB, in a map from fileID to creation time
        final fileIDToCreationTime =
            await FilesDB.instance.getFileIDToCreationTime();
        _logger.info('read creation times from FilesDB in '
            '${DateTime.now().difference(gotFaceEmbeddingsTime).inMilliseconds} ms');

        // Cluster the embeddings using the linear clustering algorithm, returning a map from faceID to clusterID
        final faceIdToCluster = await FaceClustering.instance.predictLinear(
          faceIdToEmbedding,
          fileIDToCreationTime: fileIDToCreationTime,
        );
        if (faceIdToCluster == null) {
          _logger.warning("faceIdToCluster is null");
          return;
        }
        final clusterDoneTime = DateTime.now();
        _logger.info(
          'done with clustering ${faceIdToEmbedding.length} in ${clusterDoneTime.difference(clusterStartTime).inSeconds} seconds ',
        );

        // Store the updated clusterIDs in the database
        _logger.info(
          'Updating ${faceIdToCluster.length} FaceIDs with clusterIDs in the DB',
        );
        await FaceMLDataDB.instance.updateClusterIdToFaceId(faceIdToCluster);
        _logger.info('Done updating FaceIDs with clusterIDs in the DB, in '
            '${DateTime.now().difference(clusterDoneTime).inSeconds} seconds');
      }
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
  Future<void> indexAllImages() async {
    if (isImageIndexRunning) {
      _logger.warning("indexAllImages is already running, skipping");
      return;
    }
    // verify indexing is enabled
    if (LocalSettings.instance.isFaceIndexingEnabled == false) {
      _logger.warning("indexAllImages is disabled");
      return;
    }
    try {
      isImageIndexRunning = true;
      _logger.info('starting image indexing');
      final List<EnteFile> enteFiles =
          await SearchService.instance.getAllFiles();
      final Map<int, int> alreadyIndexedFiles =
          await FaceMLDataDB.instance.getIndexedFileIds();

      // Make sure the image conversion isolate is spawned
      // await ImageMlIsolate.instance.ensureSpawned();
      await ensureInitialized();

      int fileAnalyzedCount = 0;
      int fileSkippedCount = 0;
      final stopwatch = Stopwatch()..start();
      final List<EnteFile> filesWithLocalID = <EnteFile>[];
      final List<EnteFile> filesWithoutLocalID = <EnteFile>[];
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

      // list of files where files with localID are first
      final sortedBylocalID = <EnteFile>[];
      sortedBylocalID.addAll(filesWithLocalID);
      sortedBylocalID.addAll(filesWithoutLocalID);
      final List<List<EnteFile>> chunks = sortedBylocalID.chunks(kParallelism);
      outerLoop:
      for (final chunk in chunks) {
        final futures = <Future<bool>>[];
        final List<int> fileIds = [];
        // Try to find embeddings on the remote server
        for (final f in chunk) {
          fileIds.add(f.uploadedFileID!);
        }
        try {
          final EnteWatch? w = kDebugMode ? EnteWatch("face_em_fetch") : null;
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
            remoteFileIdToVersion[fileMl.fileID] = fileMl.faceEmbedding.version;
          }
          await FaceMLDataDB.instance.bulkInsertFaces(faces);
          w?.logAndReset('stored embeddings');
          for (final entry in remoteFileIdToVersion.entries) {
            alreadyIndexedFiles[entry.key] = entry.value;
          }
          _logger.info('already indexed files ${remoteFileIdToVersion.length}');
        } catch (e, s) {
          _logger.severe("err while getting files embeddings", e, s);
          rethrow;
        }

        for (final enteFile in chunk) {
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

        // TODO: remove this cooldown later. Cooldown of one minute every 400 images
        if (fileAnalyzedCount > 400 && fileAnalyzedCount % 400 < kParallelism) {
          _logger.info(
            "indexAllImages() analyzed $fileAnalyzedCount images, cooldown for 1 minute",
          );
        }
      }

      stopwatch.stop();
      _logger.info(
        "`indexAllImages()` finished. Analyzed $fileAnalyzedCount images, in ${stopwatch.elapsed.inSeconds} seconds (avg of ${stopwatch.elapsed.inSeconds / fileAnalyzedCount} seconds per image, skipped $fileSkippedCount images)",
      );

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
          Face(
            '${result.fileId}-0',
            result.fileId,
            <double>[],
            result.errorOccured ? -1.0 : 0.0,
            face_detection.Detection.empty(),
            0.0,
          ),
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

  /// Analyzes the given image data by running the full pipeline (face detection, face alignment, face embedding).
  ///
  /// [enteFile] The ente file to analyze.
  ///
  /// [preferUsingThumbnailForEverything] If true, the thumbnail will be used for everything (face detection, face alignment, face embedding), and file data will be used only if a thumbnail is unavailable.
  /// If false, thumbnail will only be used for detection, and the original image will be used for face alignment and face embedding.
  ///
  /// Returns an immutable [FaceMlResult] instance containing the results of the analysis.
  /// Does not store the result in the database, for that you should use [indexImage].
  /// Throws [CouldNotRetrieveAnyFileData] or [GeneralFaceMlException] if something goes wrong.
  /// TODO: improve function such that it only uses full image if it is already on the device, otherwise it uses thumbnail. And make sure to store what is used!
  Future<FaceMlResult> analyzeImageInComputerAndImageIsolate(
    EnteFile enteFile, {
    bool preferUsingThumbnailForEverything = false,
    bool disposeImageIsolateAfterUse = true,
  }) async {
    _checkEnteFileForID(enteFile);

    final String? thumbnailPath = await _getImagePathForML(
      enteFile,
      typeOfData: FileDataForML.thumbnailData,
    );
    String? filePath;

    // // TODO: remove/optimize this later. Not now though: premature optimization
    // fileData =
    //     await _getDataForML(enteFile, typeOfData: FileDataForML.fileData);

    if (thumbnailPath == null) {
      filePath = await _getImagePathForML(
        enteFile,
        typeOfData: FileDataForML.fileData,
      );
      if (thumbnailPath == null && filePath == null) {
        _logger.severe(
          "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID}",
        );
        throw CouldNotRetrieveAnyFileData();
      }
    }
    // TODO: use smallData and largeData instead of thumbnailData and fileData again!
    final String smallDataPath = thumbnailPath ?? filePath!;

    final resultBuilder = FaceMlResultBuilder.fromEnteFile(enteFile);

    _logger.info(
      "Analyzing image with uploadedFileID: ${enteFile.uploadedFileID} ${kDebugMode ? enteFile.displayName : ''}",
    );
    final stopwatch = Stopwatch()..start();

    try {
      // Get the faces
      final List<FaceDetectionRelative> faceDetectionResult =
          await _detectFacesIsolate(
        smallDataPath,
        resultBuilder: resultBuilder,
      );

      _logger.info("Completed `detectFaces` function");

      // If no faces were detected, return a result with no faces. Otherwise, continue.
      if (faceDetectionResult.isEmpty) {
        _logger.info(
            "No faceDetectionResult, Completed analyzing image with uploadedFileID ${enteFile.uploadedFileID}, in "
            "${stopwatch.elapsedMilliseconds} ms");
        return resultBuilder.buildNoFaceDetected();
      }

      if (!preferUsingThumbnailForEverything) {
        filePath ??= await _getImagePathForML(
          enteFile,
          typeOfData: FileDataForML.fileData,
        );
      }
      resultBuilder.onlyThumbnailUsed = filePath == null;
      final String largeDataPath = filePath ?? thumbnailPath!;

      // Align the faces
      final Float32List faceAlignmentResult = await _alignFaces(
        largeDataPath,
        faceDetectionResult,
        resultBuilder: resultBuilder,
      );

      _logger.info("Completed `alignFaces` function");

      // Get the embeddings of the faces
      final embeddings = await _embedFaces(
        faceAlignmentResult,
        resultBuilder: resultBuilder,
      );

      _logger.info("Completed `embedBatchFaces` function");

      stopwatch.stop();
      _logger.info("Finished Analyze image (${embeddings.length} faces) with "
          "uploadedFileID ${enteFile.uploadedFileID}, in "
          "${stopwatch.elapsedMilliseconds} ms");

      if (disposeImageIsolateAfterUse) {
        // Close the image conversion isolate
        ImageMlIsolate.instance.dispose();
      }

      return resultBuilder.build();
    } catch (e, s) {
      _logger.severe(
        "Could not analyze image with ID ${enteFile.uploadedFileID} \n",
        e,
        s,
      );
      // throw GeneralFaceMlException("Could not analyze image");
      return resultBuilder.buildErrorOccurred();
    }
  }

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
      "${stopwatch.elapsedMilliseconds} ms",
    );

    return result;
  }

  Future<String?> _getImagePathForML(
    EnteFile enteFile, {
    FileDataForML typeOfData = FileDataForML.fileData,
  }) async {
    String? imagePath;

    switch (typeOfData) {
      case FileDataForML.fileData:
        final stopwatch = Stopwatch()..start();
        final File? file = await getFile(enteFile, isOrigin: true);
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
      _logger.severe(
        "Skipped analysis of image with enteFile ${enteFile.toString()} because it is the wrong format or has no uploadedFileID",
      );
      throw CouldNotRetrieveAnyFileData();
    }
  }

  bool _skipAnalysisEnteFile(EnteFile enteFile, Map<int, int> indexedFileIds) {
    if (isImageIndexRunning == false) {
      return true;
    }
    // Skip if the file is not uploaded or not owned by the user
    if (!enteFile.isUploaded || enteFile.isOwner == false) {
      return true;
    }
    // Skip if the file is a video
    if (enteFile.fileType == FileType.video) {
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
