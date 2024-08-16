import "dart:io" show File;
import "dart:math" as math show sqrt, min, max;
import "dart:typed_data" show ByteData;

import "package:flutter/services.dart" show PlatformException;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/clip_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("MlUtil");

enum FileDataForML { thumbnailData, fileData }

class IndexStatus {
  final int indexedItems, pendingItems;

  IndexStatus(this.indexedItems, this.pendingItems);
}

class FileMLInstruction {
  final EnteFile file;
  bool shouldRunFaces;
  bool shouldRunClip;
  FileDataEntity? existingRemoteFileML;

  FileMLInstruction({
    required this.file,
    required this.shouldRunFaces,
    required this.shouldRunClip,
  });
  // Returns true if the file should be indexed for either faces or clip
  bool get pendingML => shouldRunFaces || shouldRunClip;
}

Future<IndexStatus> getIndexStatus() async {
  try {
    final int indexableFiles = (await getIndexableFileIDs()).length;
    final int facesIndexedFiles = await MLDataDB.instance.getIndexedFileCount();
    final int clipIndexedFiles =
        await MLDataDB.instance.getClipIndexedFileCount();
    final int indexedFiles = math.min(facesIndexedFiles, clipIndexedFiles);

    final showIndexedFiles = math.min(indexedFiles, indexableFiles);
    final showPendingFiles = math.max(indexableFiles - indexedFiles, 0);
    return IndexStatus(showIndexedFiles, showPendingFiles);
  } catch (e, s) {
    _logger.severe('Error getting ML status', e, s);
    rethrow;
  }
}

Future<List<FileMLInstruction>> getFilesForMlIndexing() async {
  _logger.info('getFilesForMlIndexing called');
  final time = DateTime.now();
  // Get indexed fileIDs for each ML service
  final Map<int, int> faceIndexedFileIDs =
      await MLDataDB.instance.getIndexedFileIds();
  final Map<int, int> clipIndexedFileIDs =
      await MLDataDB.instance.clipIndexedFileWithVersion();
  final Set<int> queuedFiledIDs = {};

  // Get all regular files and all hidden files
  final enteFiles = await SearchService.instance.getAllFiles();
  final hiddenFiles = await SearchService.instance.getHiddenFiles();

  // Sort out what should be indexed and in what order
  final List<FileMLInstruction> filesWithLocalID = [];
  final List<FileMLInstruction> filesWithoutLocalID = [];
  final List<FileMLInstruction> hiddenFilesToIndex = [];
  for (final EnteFile enteFile in enteFiles) {
    if (_skipAnalysisEnteFile(enteFile)) {
      continue;
    }
    if (queuedFiledIDs.contains(enteFile.uploadedFileID)) {
      continue;
    }
    queuedFiledIDs.add(enteFile.uploadedFileID!);

    final shouldRunFaces =
        _shouldRunIndexing(enteFile, faceIndexedFileIDs, faceMlVersion);
    final shouldRunClip =
        _shouldRunIndexing(enteFile, clipIndexedFileIDs, clipMlVersion);
    if (!shouldRunFaces && !shouldRunClip) {
      continue;
    }
    final instruction = FileMLInstruction(
      file: enteFile,
      shouldRunFaces: shouldRunFaces,
      shouldRunClip: shouldRunClip,
    );
    if ((enteFile.localID ?? '').isEmpty) {
      filesWithoutLocalID.add(instruction);
    } else {
      filesWithLocalID.add(instruction);
    }
  }
  for (final EnteFile enteFile in hiddenFiles) {
    if (_skipAnalysisEnteFile(enteFile)) {
      continue;
    }
    if (queuedFiledIDs.contains(enteFile.uploadedFileID)) {
      continue;
    }
    queuedFiledIDs.add(enteFile.uploadedFileID!);
    final shouldRunFaces =
        _shouldRunIndexing(enteFile, faceIndexedFileIDs, faceMlVersion);
    final shouldRunClip =
        _shouldRunIndexing(enteFile, clipIndexedFileIDs, clipMlVersion);
    if (!shouldRunFaces && !shouldRunClip) {
      continue;
    }
    final instruction = FileMLInstruction(
      file: enteFile,
      shouldRunFaces: shouldRunFaces,
      shouldRunClip: shouldRunClip,
    );
    hiddenFilesToIndex.add(instruction);
  }
  final sortedBylocalID = <FileMLInstruction>[
    ...filesWithLocalID,
    ...filesWithoutLocalID,
    ...hiddenFilesToIndex,
  ];
  _logger.info(
    "Getting list of files to index for ML took ${DateTime.now().difference(time).inMilliseconds} ms",
  );
  return sortedBylocalID;
}

bool shouldDiscardRemoteEmbedding(FileDataEntity fileML) {
  final fileID = fileML.fileID;
  final RemoteFaceEmbedding? faceEmbedding = fileML.faceEmbedding;
  if (faceEmbedding == null || faceEmbedding.version < faceMlVersion) {
    _logger.info("Discarding remote embedding for fileID $fileID "
        "because version is ${faceEmbedding?.version} and we need $faceMlVersion");
    return true;
  }
  // are all landmarks equal?
  bool allLandmarksEqual = true;
  if (faceEmbedding.faces.isEmpty) {
    allLandmarksEqual = false;
  }
  for (final face in faceEmbedding.faces) {
    if (face.detection.landmarks.isEmpty) {
      allLandmarksEqual = false;
      break;
    }
    if (face.detection.landmarks.any((landmark) => landmark.x != landmark.y)) {
      allLandmarksEqual = false;
      break;
    }
  }
  if (allLandmarksEqual) {
    _logger.info("Discarding remote embedding for fileID $fileID "
        "because landmarks are equal");
    _logger.info(
      faceEmbedding.faces
          .map((e) => e.detection.landmarks.toString())
          .toList()
          .toString(),
    );
    return true;
  }

  return false;
}

Future<Set<int>> getIndexableFileIDs() async {
  final fileIDs = await FilesDB.instance
      .getOwnedFileIDs(Configuration.instance.getUserID()!);
  return fileIDs.toSet();
}

Future<String> getImagePathForML(EnteFile enteFile) async {
  String? imagePath;

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
  imagePath = file?.path;
  stopwatch.stop();
  _logger.info(
    "Getting file data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
  );

  if (imagePath == null) {
    _logger.warning(
      "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID} since its file path is null",
    );
    throw CouldNotRetrieveAnyFileData();
  }

  return imagePath;
}

bool _skipAnalysisEnteFile(EnteFile enteFile) {
  // Skip if the file is not uploaded or not owned by the user
  if (!enteFile.isUploaded || enteFile.isOwner == false) {
    return true;
  }
  // I don't know how motionPhotos and livePhotos work, so I'm also just skipping them for now
  if (enteFile.fileType == FileType.other) {
    return true;
  }
  return false;
}

bool _shouldRunIndexing(
  EnteFile enteFile,
  Map<int, int> indexedFileIds,
  int newestVersion,
) {
  final id = enteFile.uploadedFileID!;
  return !indexedFileIds.containsKey(id) || indexedFileIds[id]! < newestVersion;
}

void normalizeEmbedding(List<double> embedding) {
  double normalization = 0;
  for (int i = 0; i < embedding.length; i++) {
    normalization += embedding[i] * embedding[i];
  }
  final double sqrtNormalization = math.sqrt(normalization);
  for (int i = 0; i < embedding.length; i++) {
    embedding[i] = embedding[i] / sqrtNormalization;
  }
}

Future<MLResult> analyzeImageStatic(Map args) async {
  try {
    final int enteFileID = args["enteFileID"] as int;
    final String imagePath = args["filePath"] as String;
    final bool runFaces = args["runFaces"] as bool;
    final bool runClip = args["runClip"] as bool;
    final int faceDetectionAddress = args["faceDetectionAddress"] as int;
    final int faceEmbeddingAddress = args["faceEmbeddingAddress"] as int;
    final int clipImageAddress = args["clipImageAddress"] as int;

    _logger.info(
      "Start analyzing image with uploadedFileID: $enteFileID inside the isolate",
    );
    final time = DateTime.now();

    // Decode the image once to use for both face detection and alignment
    final imageData = await File(imagePath).readAsBytes();
    final image = await decodeImageFromData(imageData);
    final ByteData imageByteData = await getByteDataFromImage(image);
    _logger.info('Reading and decoding image took '
        '${DateTime.now().difference(time).inMilliseconds} ms');
    final decodedImageSize =
        Dimensions(height: image.height, width: image.width);
    final result = MLResult.fromEnteFileID(enteFileID);
    result.decodedImageSize = decodedImageSize;

    if (runFaces) {
      final resultFaces = await FaceRecognitionService.runFacesPipeline(
        enteFileID,
        image,
        imageByteData,
        faceDetectionAddress,
        faceEmbeddingAddress,
      );
      if (resultFaces.isEmpty) {
        result.faces = <FaceResult>[];
      } else {
        result.faces = resultFaces;
      }
    }

    if (runClip) {
      final clipResult = await SemanticSearchService.runClipImage(
        enteFileID,
        image,
        imageByteData,
        clipImageAddress,
      );
      result.clip = clipResult;
    }

    return result;
  } catch (e, s) {
    _logger.severe("Could not analyze image", e, s);
    rethrow;
  }
}
