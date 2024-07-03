import "dart:async" show unawaited;
import "dart:developer" as dev show log;
import "dart:typed_data" show ByteData, Float32List;
import "dart:ui" show Image;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/list.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/face.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/face_ml/face_ml_result.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/file_ml/file_ml.dart";
import "package:photos/services/machine_learning/file_ml/remote_fileml_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/ml_util.dart";

class FaceRecognitionService {
  final _logger = Logger("FaceRecognitionService");

  // Singleton pattern
  FaceRecognitionService._privateConstructor();
  static final instance = FaceRecognitionService._privateConstructor();
  factory FaceRecognitionService() => instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  bool _shouldSyncPeople = false;
  bool _isSyncing = false;

  static const _embeddingFetchLimit = 200;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _logger.info("init called");

    // Listen on DiffSync
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      unawaited(_syncPersonFeedback());
    });

    // Listen on PeopleChanged
    Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.syncDone) return;
      _shouldSyncPeople = true;
    });

    _isInitialized = true;
    _logger.info('init done');
  }

  Future<void> sync() async {
    await _syncPersonFeedback();
    if (LocalSettings.instance.remoteFetchEnabled) {
      await _syncFaceEmbeddings();
    } else {
      _logger.severe(
        'Not fetching embeddings because user manually disabled it in debug options',
      );
    }
  }

  Future<void> _syncPersonFeedback() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    if (_shouldSyncPeople) {
      await PersonService.instance.reconcileClusters();
      Bus.instance.fire(PeopleChangedEvent(type: PeopleEventType.syncDone));
      _shouldSyncPeople = false;
    }
    _isSyncing = false;
  }

  Future<void> _syncFaceEmbeddings({int retryFetchCount = 10}) async {
    final filesToIndex = await getFilesForMlIndexing();

    final List<List<FileMLInstruction>> chunks =
        filesToIndex.chunks(_embeddingFetchLimit); // Chunks of 200

    int fetchedCount = 0;
    for (final chunk in chunks) {
      // Fetching and storing remote embeddings
      try {
        final fileIds = chunk
            .map((instruction) => instruction.enteFile.uploadedFileID!)
            .toSet();
        _logger.info('starting remote fetch for ${fileIds.length} files');
        final res =
            await RemoteFileMLService.instance.getFilessEmbedding(fileIds);
        _logger.info('fetched ${res.mlData.length} embeddings');
        fetchedCount += res.mlData.length;
        final List<Face> faces = [];
        final remoteFileIdToVersion = <int, int>{};
        for (FileMl fileMl in res.mlData.values) {
          if (shouldDiscardRemoteEmbedding(fileMl)) continue;
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
          remoteFileIdToVersion[fileMl.fileID] = fileMl.faceEmbedding.version;
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
        _logger.info(
          'stored embeddings, already indexed files ${remoteFileIdToVersion.length}',
        );
      } catch (e, s) {
        _logger.severe("err while getting files embeddings", e, s);
        if (retryFetchCount < 1000) {
          Future.delayed(Duration(seconds: retryFetchCount), () {
            unawaited(
              _syncFaceEmbeddings(retryFetchCount: retryFetchCount * 2),
            );
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
    _logger.info('Fetched $fetchedCount embeddings');
  }

  static Future<FaceMlResult> runFacesPipeline(
    int enteFileID,
    Image image,
    ByteData imageByteData,
    int faceDetectionAddress,
    int faceEmbeddingAddress,
  ) async {
    final resultBuilder = FaceMlResult.fromEnteFileID(enteFileID);

    final Stopwatch stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();

    // Get the faces
    final List<FaceDetectionRelative> faceDetectionResult =
        await _detectFacesSync(
      image,
      imageByteData,
      faceDetectionAddress,
      resultBuilder,
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
    final Float32List faceAlignmentResult = await _alignFacesSync(
      image,
      imageByteData,
      faceDetectionResult,
      resultBuilder,
    );
    dev.log("Completed `alignFacesSync` function, in "
        "${stopwatch.elapsedMilliseconds} ms");

    stopwatch.reset();
    // Get the embeddings of the faces
    final embeddings = await _embedFacesSync(
      faceAlignmentResult,
      faceEmbeddingAddress,
      resultBuilder,
    );
    dev.log("Completed `embedFacesSync` function, in "
        "${stopwatch.elapsedMilliseconds} ms");
    stopwatch.stop();

    dev.log("Finished faces pipeline (${embeddings.length} faces) with "
        "uploadedFileID $enteFileID, in "
        "${DateTime.now().difference(startTime).inMilliseconds} ms");

    return resultBuilder;
  }

  /// Runs face recognition on the given image data.
  static Future<List<FaceDetectionRelative>> _detectFacesSync(
    Image image,
    ByteData imageByteData,
    int interpreterAddress,
    FaceMlResult resultBuilder,
  ) async {
    try {
      // Get the bounding boxes of the faces
      final (List<FaceDetectionRelative> faces, dataSize) =
          await FaceDetectionService.predict(
        image,
        imageByteData,
        interpreterAddress,
      );

      // Add detected faces to the resultBuilder
      resultBuilder.addNewlyDetectedFaces(faces, dataSize);

      return faces;
    } on YOLOFaceInterpreterRunException {
      throw CouldNotRunFaceDetector();
    } catch (e) {
      dev.log('[SEVERE] Face detection failed: $e');
      throw GeneralFaceMlException('Face detection failed: $e');
    }
  }

  /// Aligns multiple faces from the given image data.
  /// Returns a list of the aligned faces as image data.
  static Future<Float32List> _alignFacesSync(
    Image image,
    ByteData imageByteData,
    List<FaceDetectionRelative> faces,
    FaceMlResult resultBuilder,
  ) async {
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

      resultBuilder.addAlignmentResults(
        alignmentResults,
        blurValues,
      );

      return alignedFaces;
    } catch (e, s) {
      dev.log('[SEVERE] Face alignment failed: $e $s');
      throw CouldNotWarpAffine();
    }
  }

  static Future<List<List<double>>> _embedFacesSync(
    Float32List facesList,
    int interpreterAddress,
    FaceMlResult resultBuilder,
  ) async {
    try {
      // Get the embedding of the faces
      final List<List<double>> embeddings =
          await FaceEmbeddingService.predict(facesList, interpreterAddress);

      // Add the embeddings to the resultBuilder
      resultBuilder.addEmbeddingsToExistingFaces(embeddings);

      return embeddings;
    } on MobileFaceNetInterpreterRunException {
      throw CouldNotRunFaceEmbeddor();
    } catch (e) {
      dev.log('[SEVERE] Face embedding (batch) failed: $e');
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }
}
