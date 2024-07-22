import "dart:io" show File;
import "dart:math" as math show sqrt, min, max;

import "package:flutter/services.dart" show PlatformException;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/embeddings_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/face/db.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/search_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("MlUtil");

enum FileDataForML { thumbnailData, fileData }

class IndexStatus {
  final int indexedItems, pendingItems;

  IndexStatus(this.indexedItems, this.pendingItems);
}

class FileMLInstruction {
  final EnteFile enteFile;

  final bool shouldRunFaces;
  final bool shouldRunClip;

  FileMLInstruction({
    required this.enteFile,
    required this.shouldRunFaces,
    required this.shouldRunClip,
  });
}

Future<IndexStatus> getIndexStatus() async {
  try {
    final int indexableFiles = (await getIndexableFileIDs()).length;
    final int facesIndexedFiles =
        await FaceMLDataDB.instance.getIndexedFileCount();
    final int clipIndexedFiles =
        await EmbeddingsDB.instance.getIndexedFileCount();
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
      await FaceMLDataDB.instance.getIndexedFileIds();
  final Map<int, int> clipIndexedFileIDs =
      await EmbeddingsDB.instance.getIndexedFileIds();

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
    final shouldRunFaces =
        _shouldRunIndexing(enteFile, faceIndexedFileIDs, faceMlVersion);
    final shouldRunClip =
        _shouldRunIndexing(enteFile, clipIndexedFileIDs, clipMlVersion);
    if (!shouldRunFaces && !shouldRunClip) {
      continue;
    }
    final instruction = FileMLInstruction(
      enteFile: enteFile,
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
    final shouldRunFaces =
        _shouldRunIndexing(enteFile, faceIndexedFileIDs, faceMlVersion);
    final shouldRunClip =
        _shouldRunIndexing(enteFile, clipIndexedFileIDs, clipMlVersion);
    if (!shouldRunFaces && !shouldRunClip) {
      continue;
    }
    final instruction = FileMLInstruction(
      enteFile: enteFile,
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
