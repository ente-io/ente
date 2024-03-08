import "dart:convert" show jsonEncode, jsonDecode;

import "package:flutter/material.dart" show Size, debugPrint, immutable;
import "package:logging/logging.dart";
import "package:photos/db/ml_data_db.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/face_ml/blur_detection/blur_constants.dart";
import "package:photos/services/face_ml/face_alignment/alignment_result.dart";
import "package:photos/services/face_ml/face_clustering/cosine_distance.dart";
import "package:photos/services/face_ml/face_detection/detection.dart";
import "package:photos/services/face_ml/face_feedback.dart/cluster_feedback.dart";
import "package:photos/services/face_ml/face_ml_methods.dart";

final _logger = Logger('ClusterResult_FaceMlResult');

// TODO: should I add [faceMlVersion] and [clusterMlVersion] to the [ClusterResult] class?
class ClusterResult {
  final int personId;
  String? userDefinedName;
  bool get hasUserDefinedName => userDefinedName != null;

  String _thumbnailFaceId;
  bool thumbnailFaceIdIsUserDefined;

  final List<int> _fileIds;
  final List<String> _faceIds;

  final Embedding medoid;
  double medoidDistanceThreshold;

  List<int> get uniqueFileIds => _fileIds.toSet().toList();
  List<int> get fileIDsIncludingPotentialDuplicates => _fileIds;

  List<String> get faceIDs => _faceIds;

  String get thumbnailFaceId => _thumbnailFaceId;

  int get thumbnailFileId => _getFileIdFromFaceId(_thumbnailFaceId);

  /// Sets the thumbnail faceId to the given faceId.
  /// Throws an exception if the faceId is not in the list of faceIds.
  set setThumbnailFaceId(String faceId) {
    if (!_faceIds.contains(faceId)) {
      throw Exception(
        "The faceId $faceId is not in the list of faceIds: $faceId",
      );
    }
    _thumbnailFaceId = faceId;
    thumbnailFaceIdIsUserDefined = true;
  }

  /// Sets the [userDefinedName] to the given [customName]
  set setUserDefinedName(String customName) {
    userDefinedName = customName;
  }

  int get clusterSize => _fileIds.toSet().length;

  ClusterResult({
    required this.personId,
    required String thumbnailFaceId,
    required List<int> fileIds,
    required List<String> faceIds,
    required this.medoid,
    required this.medoidDistanceThreshold,
    this.userDefinedName,
    this.thumbnailFaceIdIsUserDefined = false,
  })  : _thumbnailFaceId = thumbnailFaceId,
        _faceIds = faceIds,
        _fileIds = fileIds;

  void addFileIDsAndFaceIDs(List<int> fileIDs, List<String> faceIDs) {
    assert(fileIDs.length == faceIDs.length);
    _fileIds.addAll(fileIDs);
    _faceIds.addAll(faceIDs);
  }

  // TODO: Consider if we should recalculated the medoid and threshold when deleting or adding a file from the cluster
  int removeFileId(int fileId) {
    assert(_fileIds.length == _faceIds.length);
    if (!_fileIds.contains(fileId)) {
      throw Exception(
        "The fileId $fileId is not in the list of fileIds: $fileId, so it's not in the cluster and cannot be removed.",
      );
    }

    int removedCount = 0;
    for (var i = 0; i < _fileIds.length; i++) {
      if (_fileIds[i] == fileId) {
        assert(_getFileIdFromFaceId(_faceIds[i]) == fileId);
        _fileIds.removeAt(i);
        _faceIds.removeAt(i);
        debugPrint(
          "Removed fileId $fileId from cluster $personId at index ${i + removedCount}}",
        );
        i--; // Adjust index due to removal
        removedCount++;
      }
    }

    _ensureClusterSizeIsAboveMinimum();

    return removedCount;
  }

  int addFileID(int fileID) {
    assert(_fileIds.length == _faceIds.length);
    if (_fileIds.contains(fileID)) {
      return 0;
    }

    _fileIds.add(fileID);
    _faceIds.add(FaceDetectionRelative.toFaceIDEmpty(fileID: fileID));

    return 1;
  }

  void ensureThumbnailFaceIdIsInCluster() {
    if (!_faceIds.contains(_thumbnailFaceId)) {
      _thumbnailFaceId = _faceIds[0];
    }
  }

  void _ensureClusterSizeIsAboveMinimum() {
    if (clusterSize < minimumClusterSize) {
      throw Exception(
        "Cluster size is below minimum cluster size of $minimumClusterSize",
      );
    }
  }

  Map<String, dynamic> _toJson() => {
        'personId': personId,
        'thumbnailFaceId': _thumbnailFaceId,
        'fileIds': _fileIds,
        'faceIds': _faceIds,
        'medoid': medoid,
        'medoidDistanceThreshold': medoidDistanceThreshold,
        if (userDefinedName != null) 'userDefinedName': userDefinedName,
        'thumbnailFaceIdIsUserDefined': thumbnailFaceIdIsUserDefined,
      };

  String toJsonString() => jsonEncode(_toJson());

  static ClusterResult _fromJson(Map<String, dynamic> json) {
    return ClusterResult(
      personId: json['personId'] ?? -1,
      thumbnailFaceId: json['thumbnailFaceId'] ?? '',
      fileIds:
          (json['fileIds'] as List?)?.map((item) => item as int).toList() ?? [],
      faceIds:
          (json['faceIds'] as List?)?.map((item) => item as String).toList() ??
              [],
      medoid:
          (json['medoid'] as List?)?.map((item) => item as double).toList() ??
              [],
      medoidDistanceThreshold: json['medoidDistanceThreshold'] ?? 0,
      userDefinedName: json['userDefinedName'],
      thumbnailFaceIdIsUserDefined:
          json['thumbnailFaceIdIsUserDefined'] as bool,
    );
  }

  static ClusterResult fromJsonString(String jsonString) {
    return _fromJson(jsonDecode(jsonString));
  }
}

class ClusterResultBuilder {
  int personId = -1;
  String? userDefinedName;
  String thumbnailFaceId = '';
  bool thumbnailFaceIdIsUserDefined = false;

  List<int> fileIds = <int>[];
  List<String> faceIds = <String>[];

  List<Embedding> embeddings = <Embedding>[];
  Embedding medoid = <double>[];
  double medoidDistanceThreshold = 0;
  bool medoidAndThresholdCalculated = false;
  final int k = 5;

  ClusterResultBuilder.createFromIndices({
    required List<int> clusterIndices,
    required List<int> labels,
    required List<Embedding> allEmbeddings,
    required List<int> allFileIds,
    required List<String> allFaceIds,
  }) {
    final clusteredFileIds =
        clusterIndices.map((fileIndex) => allFileIds[fileIndex]).toList();
    final clusteredFaceIds =
        clusterIndices.map((fileIndex) => allFaceIds[fileIndex]).toList();
    final clusteredEmbeddings =
        clusterIndices.map((fileIndex) => allEmbeddings[fileIndex]).toList();
    personId = labels[clusterIndices[0]];
    fileIds = clusteredFileIds;
    faceIds = clusteredFaceIds;
    thumbnailFaceId = faceIds[0];
    embeddings = clusteredEmbeddings;
  }

  void calculateAndSetMedoidAndThreshold() {
    if (embeddings.isEmpty) {
      throw Exception("Cannot calculate medoid and threshold for empty list");
    }

    // Calculate the medoid and threshold
    final (tempMedoid, distanceThreshold) =
        _calculateMedoidAndDistanceTreshold(embeddings);

    // Update the medoid
    medoid = List.from(tempMedoid);

    // Update the medoidDistanceThreshold as the distance of the medoid to its k-th nearest neighbor
    medoidDistanceThreshold = distanceThreshold;

    medoidAndThresholdCalculated = true;
  }

  (List<double>, double) _calculateMedoidAndDistanceTreshold(
    List<List<double>> embeddings,
  ) {
    double minDistance = double.infinity;
    List<double>? medoid;

    // Calculate the distance between all pairs
    for (int i = 0; i < embeddings.length; ++i) {
      double totalDistance = 0;
      for (int j = 0; j < embeddings.length; ++j) {
        if (i != j) {
          totalDistance += cosineDistance(embeddings[i], embeddings[j]);

          // Break early if we already exceed minDistance
          if (totalDistance > minDistance) {
            break;
          }
        }
      }

      // Find the minimum total distance
      if (totalDistance < minDistance) {
        minDistance = totalDistance;
        medoid = embeddings[i];
      }
    }

    // Now, calculate k-th nearest neighbor for the medoid
    final List<double> distancesToMedoid = [];
    for (List<double> embedding in embeddings) {
      if (embedding != medoid) {
        distancesToMedoid.add(cosineDistance(medoid!, embedding));
      }
    }
    distancesToMedoid.sort();
    // TODO: empirically find the best k. Probably it should be dynamic in some way, so for instance larger for larger clusters and smaller for smaller clusters, especially since there are a lot of really small clusters and a few really large ones.
    final double kthDistance = distancesToMedoid[
        distancesToMedoid.length >= k ? k - 1 : distancesToMedoid.length - 1];

    return (medoid!, kthDistance);
  }

  Future<bool> _checkIfClusterIsDeleted() async {
    assert(medoidAndThresholdCalculated);

    // Check if the medoid is the default medoid for deleted faces
    if (cosineDistance(medoid, List.filled(medoid.length, 10.0)) < 0.001) {
      return true;
    }

    final tempFeedback = DeleteClusterFeedback(
      medoid: medoid,
      medoidDistanceThreshold: medoidDistanceThreshold,
    );
    return await MlDataDB.instance
        .doesSimilarClusterFeedbackExist(tempFeedback);
  }

  Future<void> _checkAndAddPhotos() async {
    assert(medoidAndThresholdCalculated);

    final tempFeedback = AddPhotosClusterFeedback(
      medoid: medoid,
      medoidDistanceThreshold: medoidDistanceThreshold,
      addedPhotoFileIDs: [],
    );
    final allAddPhotosFeedbacks =
        await MlDataDB.instance.getAllMatchingClusterFeedback(tempFeedback);

    for (final addPhotosFeedback in allAddPhotosFeedbacks) {
      final fileIDsToAdd = addPhotosFeedback.addedPhotoFileIDs;
      final faceIDsToAdd = fileIDsToAdd
          .map((fileID) => FaceDetectionRelative.toFaceIDEmpty(fileID: fileID))
          .toList();
      addFileIDsAndFaceIDs(fileIDsToAdd, faceIDsToAdd);
    }
  }

  Future<void> _checkAndAddCustomName() async {
    assert(medoidAndThresholdCalculated);

    final tempFeedback = RenameOrCustomThumbnailClusterFeedback(
      medoid: medoid,
      medoidDistanceThreshold: medoidDistanceThreshold,
      customName: 'test',
    );
    final allRenameFeedbacks =
        await MlDataDB.instance.getAllMatchingClusterFeedback(tempFeedback);

    for (final nameFeedback in allRenameFeedbacks) {
      userDefinedName ??= nameFeedback.customName;
      if (!thumbnailFaceIdIsUserDefined) {
        thumbnailFaceId = nameFeedback.customThumbnailFaceId ?? thumbnailFaceId;
        thumbnailFaceIdIsUserDefined =
            nameFeedback.customThumbnailFaceId != null;
      }
    }
    return;
  }

  void changeThumbnailFaceId(String faceId) {
    if (!faceIds.contains(faceId)) {
      throw Exception(
        "The faceId $faceId is not in the list of faceIds: $faceIds",
      );
    }
    thumbnailFaceId = faceId;
  }

  void addFileIDsAndFaceIDs(List<int> addedFileIDs, List<String> addedFaceIDs) {
    assert(addedFileIDs.length == addedFaceIDs.length);
    fileIds.addAll(addedFileIDs);
    faceIds.addAll(addedFaceIDs);
  }

  static Future<List<ClusterResult>> buildClusters(
    List<ClusterResultBuilder> clusterBuilders,
  ) async {
    final List<int> deletedClusterIndices = [];
    for (var i = 0; i < clusterBuilders.length; i++) {
      final clusterBuilder = clusterBuilders[i];
      clusterBuilder.calculateAndSetMedoidAndThreshold();

      // Check if the cluster has been deleted
      if (await clusterBuilder._checkIfClusterIsDeleted()) {
        deletedClusterIndices.add(i);
      }

      await clusterBuilder._checkAndAddPhotos();
    }

    // Check if a cluster should be merged with another cluster
    for (var i = 0; i < clusterBuilders.length; i++) {
      // Don't check for clusters that have been deleted
      if (deletedClusterIndices.contains(i)) {
        continue;
      }
      final clusterBuilder = clusterBuilders[i];
      final List<MergeClusterFeedback> allMatchingMergeFeedback =
          await MlDataDB.instance.getAllMatchingClusterFeedback(
        MergeClusterFeedback(
          medoid: clusterBuilder.medoid,
          medoidDistanceThreshold: clusterBuilder.medoidDistanceThreshold,
          medoidToMoveTo: clusterBuilder.medoid,
        ),
      );
      if (allMatchingMergeFeedback.isEmpty) {
        continue;
      }
      // Merge the cluster with the first merge feedback
      final mainFeedback = allMatchingMergeFeedback.first;
      if (allMatchingMergeFeedback.length > 1) {
        // This is the BUG!!!!
        _logger.warning(
          "There are ${allMatchingMergeFeedback.length} merge feedbacks for cluster ${clusterBuilder.personId}. Using the first one.",
        );
      }
      for (var j = 0; j < clusterBuilders.length; j++) {
        if (i == j) continue;
        final clusterBuilderToMergeTo = clusterBuilders[j];
        final distance = cosineDistance(
          // BUG: it hasn't calculated the medoid for every clusterBuilder yet!!!
          mainFeedback.medoidToMoveTo,
          clusterBuilderToMergeTo.medoid,
        );
        if (distance < mainFeedback.medoidDistanceThreshold ||
            distance < clusterBuilderToMergeTo.medoidDistanceThreshold) {
          clusterBuilderToMergeTo.addFileIDsAndFaceIDs(
            clusterBuilder.fileIds,
            clusterBuilder.faceIds,
          );
          deletedClusterIndices.add(i);
        }
      }
    }

    final clusterResults = <ClusterResult>[];
    for (var i = 0; i < clusterBuilders.length; i++) {
      // Don't build the cluster if it has been deleted or merged
      if (deletedClusterIndices.contains(i)) {
        continue;
      }
      final clusterBuilder = clusterBuilders[i];
      // Check if the cluster has a custom name or thumbnail
      await clusterBuilder._checkAndAddCustomName();

      // Build the clusterResult
      clusterResults.add(
        ClusterResult(
          personId: clusterBuilder.personId,
          thumbnailFaceId: clusterBuilder.thumbnailFaceId,
          fileIds: clusterBuilder.fileIds,
          faceIds: clusterBuilder.faceIds,
          medoid: clusterBuilder.medoid,
          medoidDistanceThreshold: clusterBuilder.medoidDistanceThreshold,
          userDefinedName: clusterBuilder.userDefinedName,
          thumbnailFaceIdIsUserDefined:
              clusterBuilder.thumbnailFaceIdIsUserDefined,
        ),
      );
    }

    return clusterResults;
  }

  // TODO: This function should include the feedback from the user. Should also be nullable, since user might want to delete the cluster.
  Future<ClusterResult?> _buildSingleCluster() async {
    calculateAndSetMedoidAndThreshold();
    if (await _checkIfClusterIsDeleted()) {
      return null;
    }
    await _checkAndAddCustomName();
    return ClusterResult(
      personId: personId,
      thumbnailFaceId: thumbnailFaceId,
      fileIds: fileIds,
      faceIds: faceIds,
      medoid: medoid,
      medoidDistanceThreshold: medoidDistanceThreshold,
    );
  }
}

@immutable
class FaceMlResult {
  final int fileId;

  final List<FaceResult> faces;

  final Size? faceDetectionImageSize;
  final Size? faceAlignmentImageSize;

  final int mlVersion;
  final bool errorOccured;
  final bool onlyThumbnailUsed;

  bool get hasFaces => faces.isNotEmpty;
  int get numberOfFaces => faces.length;

  List<Embedding> get allFaceEmbeddings {
    return faces.map((face) => face.embedding).toList();
  }

  List<String> get allFaceIds {
    return faces.map((face) => face.faceId).toList();
  }

  List<int> get fileIdForEveryFace {
    return List<int>.filled(faces.length, fileId);
  }

  FaceDetectionMethod get faceDetectionMethod =>
      FaceDetectionMethod.fromMlVersion(mlVersion);
  FaceAlignmentMethod get faceAlignmentMethod =>
      FaceAlignmentMethod.fromMlVersion(mlVersion);
  FaceEmbeddingMethod get faceEmbeddingMethod =>
      FaceEmbeddingMethod.fromMlVersion(mlVersion);

  const FaceMlResult({
    required this.fileId,
    required this.faces,
    required this.mlVersion,
    required this.errorOccured,
    required this.onlyThumbnailUsed,
    required this.faceDetectionImageSize,
    this.faceAlignmentImageSize,
  });

  Map<String, dynamic> _toJson() => {
        'fileId': fileId,
        'faces': faces.map((face) => face.toJson()).toList(),
        'mlVersion': mlVersion,
        'errorOccured': errorOccured,
        'onlyThumbnailUsed': onlyThumbnailUsed,
        if (faceDetectionImageSize != null)
          'faceDetectionImageSize': {
            'width': faceDetectionImageSize!.width,
            'height': faceDetectionImageSize!.height,
          },
        if (faceAlignmentImageSize != null)
          'faceAlignmentImageSize': {
            'width': faceAlignmentImageSize!.width,
            'height': faceAlignmentImageSize!.height,
          },
      };

  String toJsonString() => jsonEncode(_toJson());

  static FaceMlResult _fromJson(Map<String, dynamic> json) {
    return FaceMlResult(
      fileId: json['fileId'],
      faces: (json['faces'] as List)
          .map((item) => FaceResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      mlVersion: json['mlVersion'],
      errorOccured: json['errorOccured'] ?? false,
      onlyThumbnailUsed: json['onlyThumbnailUsed'] ?? false,
      faceDetectionImageSize: json['faceDetectionImageSize'] == null
          ? null
          : Size(
              json['faceDetectionImageSize']['width'],
              json['faceDetectionImageSize']['height'],
            ),
      faceAlignmentImageSize: json['faceAlignmentImageSize'] == null
          ? null
          : Size(
              json['faceAlignmentImageSize']['width'],
              json['faceAlignmentImageSize']['height'],
            ),
    );
  }

  static FaceMlResult fromJsonString(String jsonString) {
    return _fromJson(jsonDecode(jsonString));
  }

  /// Sets the embeddings of the faces with the given faceIds to [10, 10,..., 10].
  ///
  /// Throws an exception if a faceId is not found in the FaceMlResult.
  void setEmbeddingsToTen(List<String> faceIds) {
    for (final faceId in faceIds) {
      final faceIndex = faces.indexWhere((face) => face.faceId == faceId);
      if (faceIndex == -1) {
        throw Exception("No face found with faceId $faceId");
      }
      for (var i = 0; i < faces[faceIndex].embedding.length; i++) {
        faces[faceIndex].embedding[i] = 10;
      }
    }
  }

  FaceDetectionRelative getDetectionForFaceId(String faceId) {
    final faceIndex = faces.indexWhere((face) => face.faceId == faceId);
    if (faceIndex == -1) {
      throw Exception("No face found with faceId $faceId");
    }
    return faces[faceIndex].detection;
  }
}

class FaceMlResultBuilder {
  int fileId;

  List<FaceResultBuilder> faces = <FaceResultBuilder>[];

  Size? faceDetectionImageSize;
  Size? faceAlignmentImageSize;

  int mlVersion;
  bool errorOccured;
  bool onlyThumbnailUsed;

  FaceMlResultBuilder({
    this.fileId = -1,
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
  });

  FaceMlResultBuilder.fromEnteFile(
    EnteFile file, {
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
  }) : fileId = file.uploadedFileID ?? -1;

  FaceMlResultBuilder.fromEnteFileID(
    int fileID, {
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
  }) : fileId = fileID;

  void addNewlyDetectedFaces(
    List<FaceDetectionRelative> faceDetections,
    Size originalSize,
  ) {
    faceDetectionImageSize = originalSize;
    for (var i = 0; i < faceDetections.length; i++) {
      faces.add(
        FaceResultBuilder.fromFaceDetection(
          faceDetections[i],
          resultBuilder: this,
        ),
      );
    }
  }

  void addAlignmentResults(
    List<AlignmentResult> alignmentResults,
    List<double> blurValues,
    Size imageSizeUsedForAlignment,
  ) {
    if (alignmentResults.length != faces.length) {
      throw Exception(
        "The amount of alignment results (${alignmentResults.length}) does not match the number of faces (${faces.length})",
      );
    }

    for (var i = 0; i < alignmentResults.length; i++) {
      faces[i].alignment = alignmentResults[i];
      faces[i].blurValue = blurValues[i];
    }
    faceAlignmentImageSize = imageSizeUsedForAlignment;
  }

  void addEmbeddingsToExistingFaces(
    List<Embedding> embeddings,
  ) {
    if (embeddings.length != faces.length) {
      throw Exception(
        "The amount of embeddings (${embeddings.length}) does not match the number of faces (${faces.length})",
      );
    }
    for (var faceIndex = 0; faceIndex < faces.length; faceIndex++) {
      faces[faceIndex].embedding = embeddings[faceIndex];
    }
  }

  FaceMlResult build() {
    final faceResults = <FaceResult>[];
    for (var i = 0; i < faces.length; i++) {
      faceResults.add(faces[i].build());
    }
    return FaceMlResult(
      fileId: fileId,
      faces: faceResults,
      mlVersion: mlVersion,
      errorOccured: errorOccured,
      onlyThumbnailUsed: onlyThumbnailUsed,
      faceDetectionImageSize: faceDetectionImageSize,
      faceAlignmentImageSize: faceAlignmentImageSize,
    );
  }

  FaceMlResult buildNoFaceDetected() {
    faces = <FaceResultBuilder>[];
    return build();
  }

  FaceMlResult buildErrorOccurred() {
    faces = <FaceResultBuilder>[];
    errorOccured = true;
    return build();
  }
}

@immutable
class FaceResult {
  final FaceDetectionRelative detection;
  final double blurValue;
  final AlignmentResult alignment;
  final Embedding embedding;
  final int fileId;
  final String faceId;

  bool get isBlurry => blurValue < kLaplacianThreshold;

  const FaceResult({
    required this.detection,
    required this.blurValue,
    required this.alignment,
    required this.embedding,
    required this.fileId,
    required this.faceId,
  });

  Map<String, dynamic> toJson() => {
        'detection': detection.toJson(),
        'blurValue': blurValue,
        'alignment': alignment.toJson(),
        'embedding': embedding,
        'fileId': fileId,
        'faceId': faceId,
      };

  static FaceResult fromJson(Map<String, dynamic> json) {
    return FaceResult(
      detection: FaceDetectionRelative.fromJson(json['detection']),
      blurValue: json['blurValue'],
      alignment: AlignmentResult.fromJson(json['alignment']),
      embedding: Embedding.from(json['embedding']),
      fileId: json['fileId'],
      faceId: json['faceId'],
    );
  }
}

class FaceResultBuilder {
  FaceDetectionRelative detection =
      FaceDetectionRelative.defaultInitialization();
  double blurValue = 1000;
  AlignmentResult alignment = AlignmentResult.empty();
  Embedding embedding = <double>[];
  int fileId = -1;
  String faceId = '';

  bool get isBlurry => blurValue < kLaplacianThreshold;

  FaceResultBuilder({
    required this.fileId,
    required this.faceId,
  });

  FaceResultBuilder.fromFaceDetection(
    FaceDetectionRelative faceDetection, {
    required FaceMlResultBuilder resultBuilder,
  }) {
    fileId = resultBuilder.fileId;
    faceId = faceDetection.toFaceID(fileID: resultBuilder.fileId);
    detection = faceDetection;
  }

  FaceResult build() {
    assert(detection.allKeypoints[0][0] <= 1);
    assert(detection.box[0] <= 1);
    return FaceResult(
      detection: detection,
      blurValue: blurValue,
      alignment: alignment,
      embedding: embedding,
      fileId: fileId,
      faceId: faceId,
    );
  }
}

int _getFileIdFromFaceId(String faceId) {
  return int.parse(faceId.split("_")[0]);
}
