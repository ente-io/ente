import "dart:io" show File, Platform;
import "dart:math" as math show sqrt, min, max;

import "package:flutter/services.dart" show PlatformException;
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/filedata.dart";
import "package:photos/extensions/list.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/network_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("MlUtil");

enum FileDataForML { thumbnailData, fileData }

class IndexStatus {
  final int indexedItems, pendingItems;
  final bool? hasWifiEnabled;

  IndexStatus(this.indexedItems, this.pendingItems, [this.hasWifiEnabled]);
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
    final mlDataDB = MLDataDB.instance;
    final int indexableFiles = await getIndexableFileCount();
    final int facesIndexedFiles = await mlDataDB.getFaceIndexedFileCount();
    final int clipIndexedFiles = await mlDataDB.getClipIndexedFileCount();
    final int indexedFiles = math.min(facesIndexedFiles, clipIndexedFiles);

    final showIndexedFiles = math.min(indexedFiles, indexableFiles);
    final showPendingFiles = math.max(indexableFiles - indexedFiles, 0);
    final hasWifiEnabled = await canUseHighBandwidth();
    _logger.info(
      "Shown IndexStatus: indexedFiles: $showIndexedFiles, pendingFiles: $showPendingFiles, hasWifiEnabled: $hasWifiEnabled. Real values: indexedFiles: $indexedFiles (faces: $facesIndexedFiles, clip: $clipIndexedFiles), indexableFiles: $indexableFiles",
    );
    return IndexStatus(showIndexedFiles, showPendingFiles, hasWifiEnabled);
  } catch (e, s) {
    _logger.severe('Error getting ML status', e, s);
    rethrow;
  }
}

// _lastFetchTimeForOthersIndexed indicates the last time we tried to
// fetch embeddings for files that are owned by others. This is only used
// when local indexing is disabled.
int _lastFetchTimeForOthersIndexed = 0;

/// Return a list of file instructions for files that should be indexed for ML
Future<List<FileMLInstruction>> getFilesForMlIndexing() async {
  _logger.info('getFilesForMlIndexing called');
  final mlDataDB = MLDataDB.instance;
  final time = DateTime.now();
  // Get indexed fileIDs for each ML service
  final Map<int, int> faceIndexedFileIDs = await mlDataDB.faceIndexedFileIds();
  final Map<int, int> clipIndexedFileIDs =
      await mlDataDB.clipIndexedFileWithVersion();
  final Set<int> queuedFiledIDs = {};

  final Set<int> filesWithFDStatus = await mlDataDB.getFileIDsWithFDData();

  // Get all regular files and all hidden files
  final enteFiles = await SearchService.instance.getAllFilesForSearch();
  final hiddenFiles = await SearchService.instance.getHiddenFiles();

  // Sort out what should be indexed and in what order
  final List<FileMLInstruction> filesWithLocalID = [];
  final List<FileMLInstruction> filesWithoutLocalID = [];
  final List<FileMLInstruction> hiddenFilesToIndex = [];
  for (final EnteFile enteFile in enteFiles) {
    if (enteFile.skipIndex) {
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
    if (enteFile.skipIndex) {
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
  final splitResult = sortedBylocalID.splitMatch(
    (i) => filesWithFDStatus.contains(i.file.uploadedFileID!),
  );

  _logger.info(
    "Getting list of  ${sortedBylocalID.length} files to index for ML took ${DateTime.now().difference(time).inMilliseconds} ms",
  );
  if (!localSettings.isMLLocalIndexingEnabled) {
    final time = DateTime.now().millisecondsSinceEpoch;
    if ((time - _lastFetchTimeForOthersIndexed) > 1000 * 60 * 60 * 24) {
      final filesOwnedByOthers = [];
      for (final instruction in splitResult.unmatched) {
        if (instruction.file.isUploaded && !instruction.file.isOwner) {
          filesOwnedByOthers.add(instruction);
        }
      }
      _logger.info(
        'Checking index for ${filesOwnedByOthers.length} owned by others',
      );
      return [...splitResult.matched, ...filesOwnedByOthers];
    }
    return splitResult.matched;
  }
  return [...splitResult.matched, ...splitResult.unmatched];
}

Stream<List<FileMLInstruction>> fetchEmbeddingsAndInstructions(
  int yieldSize,
) async* {
  final mlDataDB = MLDataDB.instance;
  final List<FileMLInstruction> filesToIndex = await getFilesForMlIndexing();
  final List<List<FileMLInstruction>> chunks =
      filesToIndex.chunks(embeddingFetchLimit);
  List<FileMLInstruction> batchToYield = [];

  for (final chunk in chunks) {
    if (!localSettings.remoteFetchEnabled) {
      _logger.warning("remoteFetchEnabled is false, skiping embedding fetch");
      final batches = chunk.chunks(yieldSize);
      for (final batch in batches) {
        yield batch;
      }
      continue;
    }
    final Set<int> ids = {};
    final Map<int, FileMLInstruction> pendingIndex = {};
    for (final instruction in chunk) {
      ids.add(instruction.file.uploadedFileID!);
      pendingIndex[instruction.file.uploadedFileID!] = instruction;
    }
    _logger.info("fetching embeddings for ${ids.length} files");
    final res = await fileDataService.getFilesData(ids);
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
      final remoteClipEmbedding =
          fileMl.getClipEmbeddingIfCompatible(clipMlVersion);
      if (remoteClipEmbedding != null) {
        clipEmbeddings.add(
          ClipEmbedding(
            fileID: fileMl.fileID,
            embedding: remoteClipEmbedding.embedding,
            version: remoteClipEmbedding.version,
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

    await mlDataDB.bulkInsertFaces(faces);
    await mlDataDB.putClip(clipEmbeddings);
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
  if (_shouldDiscardRemoteEmbedding(fileMl)) {
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

bool _shouldDiscardRemoteEmbedding(FileDataEntity fileML) {
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

Future<int> getIndexableFileCount() async {
  return FilesDB.instance.remoteFileCount();
}

Future<String> getImagePathForML(EnteFile enteFile) async {
  String? imagePath;

  final stopwatch = Stopwatch()..start();
  File? file;
  final bool isVideo = enteFile.fileType == FileType.video;
  if (isVideo) {
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
    // Don't process the file if it's too large (more than 100MB)
    if (enteFile.fileSize != null && enteFile.fileSize! > maxFileDownloadSize) {
      throw Exception(
        "FileSizeTooLargeForMobileIndexing: size is ${enteFile.fileSize}",
      );
    }
    try {
      if (Platform.isIOS && enteFile.localID != null) {
        trackOriginFetchForUploadOrML.put(enteFile.localID!, true);
      }
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
    "Getting file data for fileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
  );

  if (imagePath == null) {
    _logger.severe(
      "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID} and format ${enteFile.displayName.split('.').last} and size ${enteFile.fileSize} since its file path is null (isVideo: $isVideo)",
    );
    throw CouldNotRetrieveAnyFileData();
  }

  return imagePath;
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
      "Start analyzeImageStatic for fileID $enteFileID (runFaces: $runFaces, runClip: $runClip)",
    );
    final startTime = DateTime.now();

    // Decode the image once to use for both face detection and alignment
    final decodedImage = await decodeImageFromPath(
      imagePath,
      includeRgbaBytes: true,
      includeDartUiImage: false,
    );
    final rawRgbaBytes = decodedImage.rawRgbaBytes!;
    final imageDimensions = decodedImage.dimensions;
    final result = MLResult.fromEnteFileID(enteFileID);
    result.decodedImageSize = imageDimensions;
    final decodeTime = DateTime.now();
    final decodeMs = decodeTime.difference(startTime).inMilliseconds;

    String faceMsString = "", clipMsString = "";
    final pipelines = await Future.wait([
      runFaces
          ? FaceRecognitionService.runFacesPipeline(
              enteFileID,
              imageDimensions,
              rawRgbaBytes,
              faceDetectionAddress,
              faceEmbeddingAddress,
            ).then((result) {
              faceMsString =
                  ", faces: ${DateTime.now().difference(decodeTime).inMilliseconds} ms";
              return result;
            })
          : Future.value(null),
      runClip
          ? SemanticSearchService.runClipImage(
              enteFileID,
              imageDimensions,
              rawRgbaBytes,
              clipImageAddress,
            ).then((result) {
              clipMsString =
                  ", clip: ${DateTime.now().difference(decodeTime).inMilliseconds} ms";
              return result;
            })
          : Future.value(null),
    ]);

    if (pipelines[0] != null) result.faces = pipelines[0] as List<FaceResult>;
    if (pipelines[1] != null) result.clip = pipelines[1] as ClipResult;

    final totalMs = DateTime.now().difference(startTime).inMilliseconds;

    _logger.info(
      'Finished analyzeImageStatic for fileID $enteFileID, in $totalMs ms (decode: $decodeMs ms$faceMsString$clipMsString)',
    );

    return result;
  } catch (e, s) {
    _logger.severe("Could not analyze image", e, s);
    rethrow;
  }
}
