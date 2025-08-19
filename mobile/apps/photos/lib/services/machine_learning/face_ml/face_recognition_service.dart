import "dart:async" show unawaited;
import "dart:typed_data" show Uint8List, Float32List;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/image_ml_util.dart";

class FaceRecognitionService {
  static final _logger = Logger("FaceRecognitionService");

  FaceRecognitionService() {
    _logger.info("FaceRecognitionService constructor");
    init();
  }

  bool _isInitialized = false;

  bool _shouldReconcilePeople = false;
  bool _isSyncing = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _logger.info("init called");

    // Listen on DiffSync
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      unawaited(syncPersonFeedback());
    });

    // Listen on PeopleChanged
    Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.syncDone) return;
      _shouldReconcilePeople = true;
    });

    _isInitialized = true;
    _logger.info('init done');
  }

  Future<void> syncPersonFeedback() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      if (_shouldReconcilePeople) {
        await PersonService.instance.reconcileClusters();
        Bus.instance.fire(PeopleChangedEvent(type: PeopleEventType.syncDone));
        _shouldReconcilePeople = false;
      } else {
        final bool didChange =
            await PersonService.instance.fetchRemoteClusterFeedback();
        if (didChange) {
          _logger.info("people: got remote data update ");
          Bus.instance.fire(PeopleChangedEvent(type: PeopleEventType.syncDone));
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Future<List<FaceResult>> runFacesPipeline(
    int enteFileID,
    Dimensions dim,
    Uint8List rawRgbaBytes,
    int faceDetectionAddress,
    int faceEmbeddingAddress,
  ) async {
    final faceResults = <FaceResult>[];
    final startTime = DateTime.now();

    // Get the faces
    final List<FaceDetectionRelative> faceDetectionResult =
        await _detectFacesSync(
      enteFileID,
      dim,
      rawRgbaBytes,
      faceDetectionAddress,
      faceResults,
    );
    final detectFacesTime = DateTime.now();
    final detectFacesMs = detectFacesTime.difference(startTime).inMilliseconds;

    // If no faces were detected, return a result with no faces. Otherwise, continue.
    if (faceDetectionResult.isEmpty) {
      _logger.info(
        "Finished runFacesPipeline with fileID $enteFileID in $detectFacesMs ms (${faceDetectionResult.length} faces, detectFaces: $detectFacesMs ms)",
      );
      return [];
    }

    // Align the faces
    final Float32List faceAlignmentResult = await _alignFacesSync(
      dim,
      rawRgbaBytes,
      faceDetectionResult,
      faceResults,
    );
    final alignFacesTime = DateTime.now();
    final alignFacesMs =
        alignFacesTime.difference(detectFacesTime).inMilliseconds;

    // Get the embeddings of the faces
    await _embedFacesSync(
      faceAlignmentResult,
      faceEmbeddingAddress,
      faceResults,
    );
    final embedFacesTime = DateTime.now();
    final embedFacesMs =
        embedFacesTime.difference(alignFacesTime).inMilliseconds;
    final totalMs = DateTime.now().difference(startTime).inMilliseconds;

    _logger.info(
      "Finished runFacesPipeline with fileID $enteFileID in $totalMs ms (${faceDetectionResult.length} faces, detectFaces: $detectFacesMs ms, alignFaces: $alignFacesMs ms, embedFaces: $embedFacesMs ms)",
    );

    return faceResults;
  }

  /// Runs face recognition on the given image data.
  static Future<List<FaceDetectionRelative>> _detectFacesSync(
    int fileID,
    Dimensions dimensions,
    Uint8List rawRgbaBytes,
    int interpreterAddress,
    List<FaceResult> faceResults,
  ) async {
    try {
      // Get the bounding boxes of the faces
      final List<FaceDetectionRelative> faces =
          await FaceDetectionService.predict(
        dimensions,
        rawRgbaBytes,
        interpreterAddress,
      );

      // Add detected faces to the faceResults
      for (var i = 0; i < faces.length; i++) {
        faceResults.add(
          FaceResult.fromFaceDetection(
            faces[i],
            fileID,
          ),
        );
      }

      return faces;
    } on YOLOFaceInterpreterRunException {
      throw CouldNotRunFaceDetector();
    } catch (e, s) {
      _logger.severe('Face detection failed', e, s);
      throw GeneralFaceMlException('Face detection failed: $e');
    }
  }

  /// Aligns multiple faces from the given image data.
  /// Returns a list of the aligned faces as image data.
  static Future<Float32List> _alignFacesSync(
    Dimensions dim,
    Uint8List rawRgbaBytes,
    List<FaceDetectionRelative> faces,
    List<FaceResult> faceResults,
  ) async {
    try {
      final (alignedFaces, alignmentResults, _, blurValues, _) =
          await preprocessToMobileFaceNetFloat32List(
        dim,
        rawRgbaBytes,
        faces,
      );

      // Store the results
      if (alignmentResults.length != faces.length) {
        _logger.severe(
          "The amount of alignment results (${alignmentResults.length}) does not match the number of faces (${faces.length})",
        );
        throw Exception(
          "The amount of alignment results (${alignmentResults.length}) does not match the number of faces (${faces.length})",
        );
      }
      for (var i = 0; i < alignmentResults.length; i++) {
        faceResults[i].alignment = alignmentResults[i];
        faceResults[i].blurValue = blurValues[i];
      }

      return alignedFaces;
    } catch (e, s) {
      _logger.severe('Face alignment failed: $e $s');
      throw CouldNotWarpAffine();
    }
  }

  static Future<List<List<double>>> _embedFacesSync(
    Float32List facesList,
    int interpreterAddress,
    List<FaceResult> faceResults,
  ) async {
    try {
      // Get the embedding of the faces
      final List<List<double>> embeddings = await FaceEmbeddingService.predict(
        facesList,
        interpreterAddress,
      );

      // Store the results
      if (embeddings.length != faceResults.length) {
        _logger.severe(
          "The amount of embeddings (${embeddings.length}) does not match the number of faces (${faceResults.length})",
        );
        throw Exception(
          "The amount of embeddings (${embeddings.length}) does not match the number of faces (${faceResults.length})",
        );
      }
      for (var faceIndex = 0; faceIndex < faceResults.length; faceIndex++) {
        faceResults[faceIndex].embedding = embeddings[faceIndex];
      }

      return embeddings;
    } on MobileFaceNetInterpreterRunException {
      throw CouldNotRunFaceEmbeddor();
    } catch (e, s) {
      _logger.severe('Face embedding (batch) failed', e, s);
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }
}
