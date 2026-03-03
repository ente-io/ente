import "dart:io" show Directory, File, Platform;
import "dart:math" as math show sqrt, min, max;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/services.dart" show PlatformException;
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/filedata.dart";
import "package:photos/db/offline_files_db.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/src/rust/api/ml_indexing_api.dart" as rust_ml;
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/network_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("MlUtil");

enum FileDataForML { thumbnailData, fileData }

enum MLMode { online, offline }

class IndexStatus {
  final int indexedItems, pendingItems;
  final bool? hasWifiEnabled;

  IndexStatus(this.indexedItems, this.pendingItems, [this.hasWifiEnabled]);
}

class FileMLInstruction {
  final EnteFile file;
  final MLMode mode;
  final int? offlineFileKey;
  bool shouldRunFaces;
  bool shouldRunClip;
  FileDataEntity? existingRemoteFileML;

  FileMLInstruction({
    required this.file,
    required this.mode,
    this.offlineFileKey,
    required this.shouldRunFaces,
    required this.shouldRunClip,
  });
  // Returns true if the file should be indexed for either faces or clip
  bool get pendingML => shouldRunFaces || shouldRunClip;
  bool get isOffline => mode == MLMode.offline;
  int get fileKey => isOffline ? offlineFileKey! : file.uploadedFileID!;
}

Future<IndexStatus> getIndexStatus() async {
  try {
    final MLMode mode = isOfflineMode ? MLMode.offline : MLMode.online;
    final mlDataDB =
        mode == MLMode.offline ? MLDataDB.offlineInstance : MLDataDB.instance;
    final int indexableFiles = await _getIndexableFileCount(mode: mode);
    final int facesIndexedFiles = await mlDataDB.getFaceIndexedFileCount();
    final int clipIndexedFiles = await mlDataDB.getClipIndexedFileCount();
    final int indexedFiles = math.min(facesIndexedFiles, clipIndexedFiles);

    final showIndexedFiles = math.min(indexedFiles, indexableFiles);
    final showPendingFiles = math.max(indexableFiles - indexedFiles, 0);
    final hasWifiEnabled = await canUseHighBandwidth();
    _logger.info(
      "Shown IndexStatus: indexedFiles: $showIndexedFiles, pendingFiles: $showPendingFiles, hasWifiEnabled: $hasWifiEnabled, ifOffline: $isOfflineMode. Real values: indexedFiles: $indexedFiles (faces: $facesIndexedFiles, clip: $clipIndexedFiles), indexableFiles: $indexableFiles",
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
    if (enteFile.uploadedFileID == null || enteFile.uploadedFileID == -1) {
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
      mode: MLMode.online,
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
    if (enteFile.uploadedFileID == null || enteFile.uploadedFileID == -1) {
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
      mode: MLMode.online,
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

Future<List<FileMLInstruction>> getOfflineFilesForMlIndexing() async {
  _logger.info('getOfflineFilesForMlIndexing called');
  final mlDataDB = MLDataDB.offlineInstance;
  final Map<int, int> faceIndexedFileIDs = await mlDataDB.faceIndexedFileIds();
  final Map<int, int> clipIndexedFileIDs =
      await mlDataDB.clipIndexedFileWithVersion();
  final Set<int> queuedFileIDs = {};

  final enteFiles = await SearchService.instance.getAllFilesForSearch();
  final candidateFiles = <EnteFile>[];
  final localIds = <String>[];
  final List<FileMLInstruction> instructions = [];

  for (final EnteFile enteFile in enteFiles) {
    if (enteFile.fileType == FileType.other) {
      continue;
    }
    if ((enteFile.localID ?? '').isEmpty ||
        (enteFile.uploadedFileID != null && enteFile.uploadedFileID != -1)) {
      continue;
    }
    final localID = enteFile.localID!;
    candidateFiles.add(enteFile);
    localIds.add(localID);
  }

  final localIdToIntId =
      await OfflineFilesDB.instance.ensureLocalIntIds(localIds);

  for (final enteFile in candidateFiles) {
    final localID = enteFile.localID!;
    final localIntId = localIdToIntId[localID];
    if (localIntId == null) {
      continue;
    }
    if (queuedFileIDs.contains(localIntId)) {
      continue;
    }
    queuedFileIDs.add(localIntId);
    final shouldRunFaces = _shouldRunIndexingWithFileId(
      localIntId,
      faceIndexedFileIDs,
      faceMlVersion,
    );
    final shouldRunClip = _shouldRunIndexingWithFileId(
      localIntId,
      clipIndexedFileIDs,
      clipMlVersion,
    );
    if (!shouldRunFaces && !shouldRunClip) {
      continue;
    }
    instructions.add(
      FileMLInstruction(
        file: enteFile,
        mode: MLMode.offline,
        offlineFileKey: localIntId,
        shouldRunFaces: shouldRunFaces,
        shouldRunClip: shouldRunClip,
      ),
    );
  }
  _logger.info(
    "Getting list of ${instructions.length} files to index for offline ML",
  );
  return instructions;
}

Stream<List<FileMLInstruction>> fetchEmbeddingsAndInstructions(
  int yieldSize, {
  required MLMode mode,
}) async* {
  if (mode == MLMode.offline) {
    final List<FileMLInstruction> filesToIndex =
        await getOfflineFilesForMlIndexing();
    final List<List<FileMLInstruction>> chunks = filesToIndex.chunks(yieldSize);
    for (final batch in chunks) {
      yield batch;
    }
    return;
  }
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

Future<int> _getIndexableFileCount({required MLMode mode}) async {
  if (mode == MLMode.offline) {
    final files = await SearchService.instance.getAllFilesForSearch();
    return files
        .where(
          (file) =>
              (file.localID ?? '').isNotEmpty &&
              (file.uploadedFileID == null || file.uploadedFileID == -1) &&
              file.fileType != FileType.other,
        )
        .length;
  }
  return getIndexableFileCount();
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
  return _shouldRunIndexingWithFileId(id, indexedFileIds, newestVersion);
}

bool _shouldRunIndexingWithFileId(
  int fileId,
  Map<int, int> indexedFileIds,
  int newestVersion,
) {
  return !indexedFileIds.containsKey(fileId) ||
      indexedFileIds[fileId]! < newestVersion;
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

Future<MLResult> analyzeImageRust(Map args) async {
  try {
    final int enteFileID = args["enteFileID"] as int;
    final String imagePath = args["filePath"] as String;
    final bool runFaces = args["runFaces"] as bool;
    final bool runClip = args["runClip"] as bool;
    final String? faceDetectionModelPath =
        args["faceDetectionModelPath"] as String?;
    final String? faceEmbeddingModelPath =
        args["faceEmbeddingModelPath"] as String?;
    final String? clipImageModelPath = args["clipImageModelPath"] as String?;
    final bool preferCoreml = args["preferCoreml"] as bool? ?? true;
    final bool preferNnapi = args["preferNnapi"] as bool? ?? true;
    final bool preferXnnpack = args["preferXnnpack"] as bool? ?? false;
    final bool allowCpuFallback = args["allowCpuFallback"] as bool? ?? true;

    bool isMissingModelPath(String? path) =>
        path == null || path.trim().isEmpty;
    final missingModelPaths = <String>[];
    if (runFaces) {
      if (isMissingModelPath(faceDetectionModelPath)) {
        missingModelPaths.add("faceDetectionModelPath");
      }
      if (isMissingModelPath(faceEmbeddingModelPath)) {
        missingModelPaths.add("faceEmbeddingModelPath");
      }
    }
    if (runClip && isMissingModelPath(clipImageModelPath)) {
      missingModelPaths.add("clipImageModelPath");
    }
    if (missingModelPaths.isNotEmpty) {
      throw Exception(
        "RustMLMissingModelPath: Missing required model paths: ${missingModelPaths.join(', ')}",
      );
    }

    final modelPaths = rust_ml.RustModelPaths(
      faceDetection: faceDetectionModelPath ?? "",
      faceEmbedding: faceEmbeddingModelPath ?? "",
      clipImage: clipImageModelPath ?? "",
    );
    final providerPolicy = rust_ml.RustExecutionProviderPolicy(
      preferCoreml: preferCoreml,
      preferNnapi: preferNnapi,
      preferXnnpack: preferXnnpack,
      allowCpuFallback: allowCpuFallback,
    );

    Future<rust_ml.AnalyzeImageResult> runRustAnalyzeForPath(
      String analyzePath,
    ) {
      return rust_ml.analyzeImageRust(
        req: rust_ml.AnalyzeImageRequest(
          fileId: enteFileID,
          imagePath: analyzePath,
          runFaces: runFaces,
          runClip: runClip,
          modelPaths: modelPaths,
          providerPolicy: providerPolicy,
        ),
      );
    }

    final fileFormat = getExtension(imagePath);
    rust_ml.AnalyzeImageResult rustResult;
    try {
      rustResult = await runRustAnalyzeForPath(imagePath);
    } catch (e, s) {
      if (!_isRustDecodeIssue(e)) {
        _logger.severe(
          "Rust pipeline failed (non-decode) for fileID $enteFileID (format: $fileFormat)",
          e,
          s,
        );
        rethrow;
      }

      _logger.warning(
        "Rust decode failed for fileID $enteFileID (format: $fileFormat), retrying with JPEG fallback",
        e,
        s,
      );
      final fallback =
          await _createJpegDecodeFallbackFile(imagePath: imagePath);
      if (fallback == null) {
        _logger.severe(
          "JPEG fallback conversion returned null/empty bytes for fileID $enteFileID (format: $fileFormat)",
          e,
          s,
        );
        rethrow;
      }

      try {
        rustResult = await runRustAnalyzeForPath(fallback.file.path);
        _logger.info(
          "Rust decode fallback succeeded for fileID $enteFileID (original format: $fileFormat)",
        );
      } catch (retryError, retryStack) {
        _logger.severe(
          "Rust decode fallback retry failed for fileID $enteFileID (original format: $fileFormat)",
          retryError,
          retryStack,
        );
        rethrow;
      } finally {
        await _cleanupDecodeFallback(fallback);
      }
    }

    final result = MLResult.fromEnteFileID(enteFileID);
    result.decodedImageSize = Dimensions(
      width: rustResult.decodedImageSize.width,
      height: rustResult.decodedImageSize.height,
    );

    if (runFaces) {
      final rustFaces = rustResult.faces ?? const <rust_ml.RustFaceResult>[];
      result.faces = rustFaces.map((face) {
        final detection = FaceDetectionRelative(
          score: face.detection.score,
          box: face.detection.boxXyxy.toList(growable: false),
          allKeypoints: face.detection.allKeypoints
              .map((point) => point.toList(growable: false))
              .toList(growable: false),
        );
        final alignment = AlignmentResult(
          affineMatrix: face.alignment.affineMatrix
              .map((row) => row.toList(growable: false))
              .toList(growable: false),
          center: face.alignment.center.toList(growable: false),
          size: face.alignment.size,
          rotation: face.alignment.rotation,
        );
        return FaceResult(
          fileId: enteFileID,
          faceId: face.faceId,
          detection: detection,
          blurValue: face.blurValue,
          alignment: alignment,
          embedding: face.embedding,
        );
      }).toList(growable: false);
    }

    if (runClip) {
      final rustClip = rustResult.clip;
      if (rustClip == null) {
        throw Exception("RustMLMissingClipOutput: clip output was null");
      }
      result.clip = ClipResult(
        fileID: enteFileID,
        embedding: rustClip.embedding,
      );
    }

    return result;
  } catch (e, s) {
    _logger.severe("Could not analyze image with Rust pipeline", e, s);
    rethrow;
  }
}

bool _isRustDecodeIssue(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains("decode error");
}

class _DecodeFallbackFile {
  final File file;
  final Directory directory;

  const _DecodeFallbackFile({
    required this.file,
    required this.directory,
  });
}

Future<_DecodeFallbackFile?> _createJpegDecodeFallbackFile({
  required String imagePath,
}) async {
  final convertedData = await FlutterImageCompress.compressWithFile(
    imagePath,
    format: CompressFormat.jpeg,
    minWidth: 20000,
    minHeight: 20000,
  );
  if (convertedData == null || convertedData.isEmpty) {
    return null;
  }

  final tempDirectory = await Directory.systemTemp.createTemp(
    "ente_ml_decode_fallback_",
  );
  final fallbackFile = File("${tempDirectory.path}/ml_decode_retry.jpg");
  await fallbackFile.writeAsBytes(convertedData, flush: true);
  return _DecodeFallbackFile(file: fallbackFile, directory: tempDirectory);
}

Future<void> _cleanupDecodeFallback(_DecodeFallbackFile fallback) async {
  try {
    if (await fallback.file.exists()) {
      await fallback.file.delete();
    }
    if (await fallback.directory.exists()) {
      await fallback.directory.delete(recursive: true);
    }
  } catch (e, s) {
    _logger.warning("Could not cleanup decode fallback file", e, s);
  }
}
