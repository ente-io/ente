import "dart:async" show unawaited;
import "dart:developer" as dev show log;
import "dart:typed_data" show ByteData, Float32List;
import "dart:ui" show Image;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/clip_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/list.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/image_ml_util.dart";
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
    if (localSettings.remoteFetchEnabled) {
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

  Stream<List<FileMLInstruction>> syncEmbeddings({
    int yieldSize = 10,
  }) async* {
    final List<FileMLInstruction> filesToIndex = await getFilesForMlIndexing();
    final List<List<FileMLInstruction>> chunks =
        filesToIndex.chunks(_embeddingFetchLimit);
    List<FileMLInstruction> batchToYield = [];

    for (final chunk in chunks) {
      final Set<int> ids = {};
      final Map<int, FileMLInstruction> pendingIndex = {};
      for (final instruction in chunk) {
        ids.add(instruction.file.uploadedFileID!);
        pendingIndex[instruction.file.uploadedFileID!] = instruction;
      }
      _logger.info("fetching embeddings for ${ids.length} files");
      final res = await FileDataService.instance.getFilesData(ids);
      _logger.info("embeddingResponse ${res.debugLog()}");
      final List<Face> faces = [];
      final List<ClipEmbedding> clipEmbeddings = [];
      for (FileDataEntity fileMl in res.data.values) {
        final existingInstruction = pendingIndex[fileMl.fileID]!;
        final facesFromRemoteEmbedding = _getFacesFromRemoteEmbedding(fileMl);
        //Note: Always do null check, empty value means no face was found.
        if (facesFromRemoteEmbedding != null) {
          faces.addAll(facesFromRemoteEmbedding);
          existingInstruction.shouldRunFaces = false;
        }
        if (fileMl.clipEmbedding != null &&
            fileMl.clipEmbedding!.version >= clipMlVersion) {
          clipEmbeddings.add(
            ClipEmbedding(
              fileID: fileMl.fileID,
              embedding: fileMl.clipEmbedding!.embedding,
              version: fileMl.clipEmbedding!.version,
            ),
          );
          existingInstruction.shouldRunClip = false;
        }
        if (!existingInstruction.pendingML) {
          pendingIndex.remove(fileMl.fileID);
        } else {
          existingInstruction.existingRemoteFileML = fileMl;
          pendingIndex[fileMl.fileID] = existingInstruction;
        }
      }
      for (final fileID in pendingIndex.keys) {
        final instruction = pendingIndex[fileID]!;
        if (instruction.pendingML) {
          batchToYield.add(instruction);
          if (batchToYield.length == yieldSize) {
            _logger.info("queueing indexing for  $yieldSize");
            yield batchToYield;
            batchToYield = [];
          }
        }
      }
      await MLDataDB.instance.bulkInsertFaces(faces);
      await MLDataDB.instance.putMany(clipEmbeddings);
    }
    // Yield any remaining instructions
    if (batchToYield.isNotEmpty) {
      _logger.info("queueing indexing for  ${batchToYield.length}");
      yield batchToYield;
    }
  }

  // Returns a list of faces from the given remote fileML. null if the version is less than the current version
  // or if the remote faceEmbedding is null.
  List<Face>? _getFacesFromRemoteEmbedding(FileDataEntity fileMl) {
    final RemoteFaceEmbedding? remoteFaceEmbedding = fileMl.faceEmbedding;
    if (shouldDiscardRemoteEmbedding(fileMl)) {
      return null;
    }
    final List<Face> faces = [];
    if (remoteFaceEmbedding!.faces.isEmpty) {
      faces.add(
        Face.empty(fileMl.fileID),
      );
    } else {
      for (final f in remoteFaceEmbedding.faces) {
        f.fileInfo = FileInfo(
          imageHeight: remoteFaceEmbedding.height,
          imageWidth: remoteFaceEmbedding.width,
        );
        faces.add(f);
      }
    }
    return faces;
  }

  static Future<List<FaceResult>> runFacesPipeline(
    int enteFileID,
    Image image,
    ByteData imageByteData,
    int faceDetectionAddress,
    int faceEmbeddingAddress,
  ) async {
    final faceResults = <FaceResult>[];

    final Stopwatch stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();

    // Get the faces
    final List<FaceDetectionRelative> faceDetectionResult =
        await _detectFacesSync(
      enteFileID,
      image,
      imageByteData,
      faceDetectionAddress,
      faceResults,
    );
    dev.log(
        "${faceDetectionResult.length} faces detected with scores ${faceDetectionResult.map((e) => e.score).toList()}: completed `detectFacesSync` function, in "
        "${stopwatch.elapsedMilliseconds} ms");

    // If no faces were detected, return a result with no faces. Otherwise, continue.
    if (faceDetectionResult.isEmpty) {
      dev.log(
          "No faceDetectionResult, Completed analyzing image with uploadedFileID $enteFileID, in "
          "${stopwatch.elapsedMilliseconds} ms");
      return [];
    }

    stopwatch.reset();
    // Align the faces
    final Float32List faceAlignmentResult = await _alignFacesSync(
      image,
      imageByteData,
      faceDetectionResult,
      faceResults,
    );
    dev.log("Completed `alignFacesSync` function, in "
        "${stopwatch.elapsedMilliseconds} ms");

    stopwatch.reset();
    // Get the embeddings of the faces
    final embeddings = await _embedFacesSync(
      faceAlignmentResult,
      faceEmbeddingAddress,
      faceResults,
    );
    dev.log("Completed `embedFacesSync` function, in "
        "${stopwatch.elapsedMilliseconds} ms");
    stopwatch.stop();

    dev.log("Finished faces pipeline (${embeddings.length} faces) with "
        "uploadedFileID $enteFileID, in "
        "${DateTime.now().difference(startTime).inMilliseconds} ms");

    return faceResults;
  }

  /// Runs face recognition on the given image data.
  static Future<List<FaceDetectionRelative>> _detectFacesSync(
    int fileID,
    Image image,
    ByteData imageByteData,
    int interpreterAddress,
    List<FaceResult> faceResults,
  ) async {
    try {
      // Get the bounding boxes of the faces
      final List<FaceDetectionRelative> faces =
          await FaceDetectionService.predict(
        image,
        imageByteData,
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
    List<FaceResult> faceResults,
  ) async {
    try {
      final (alignedFaces, alignmentResults, _, blurValues, _) =
          await preprocessToMobileFaceNetFloat32List(
        image,
        imageByteData,
        faces,
      );

      // Store the results
      if (alignmentResults.length != faces.length) {
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
      dev.log('[SEVERE] Face alignment failed: $e $s');
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
    } catch (e) {
      dev.log('[SEVERE] Face embedding (batch) failed: $e');
      throw GeneralFaceMlException('Face embedding (batch) failed: $e');
    }
  }
}
