import "dart:convert" show jsonEncode, jsonDecode;

import "package:flutter/material.dart" show immutable;
import "package:logging/logging.dart";
import "package:photos/face/model/dimension.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import "package:photos/models/ml/ml_versions.dart";
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

final _logger = Logger('ClusterResult_FaceMlResult');

@immutable
class FaceMlResult {
  final int fileId;

  final List<FaceResult> faces;

  final Dimensions decodedImageSize;

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

  const FaceMlResult({
    required this.fileId,
    required this.faces,
    required this.mlVersion,
    required this.errorOccured,
    required this.onlyThumbnailUsed,
    required this.decodedImageSize,
  });

  Map<String, dynamic> _toJson() => {
        'fileId': fileId,
        'faces': faces.map((face) => face.toJson()).toList(),
        'mlVersion': mlVersion,
        'errorOccured': errorOccured,
        'onlyThumbnailUsed': onlyThumbnailUsed,
        'decodedImageSize': {
          'width': decodedImageSize.width,
          'height': decodedImageSize.height,
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
      decodedImageSize: json['decodedImageSize'] != null
          ? Dimensions(
              width: json['decodedImageSize']['width'],
              height: json['decodedImageSize']['height'],
            )
          : json['faceDetectionImageSize'] == null
              ? const Dimensions(width: -1, height: -1)
              : Dimensions(
                  width: (json['faceDetectionImageSize']['width'] as double)
                      .truncate(),
                  height: (json['faceDetectionImageSize']['height'] as double)
                      .truncate(),
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

  Dimensions decodedImageSize;

  int mlVersion;
  bool errorOccured;
  bool onlyThumbnailUsed;

  FaceMlResultBuilder({
    this.fileId = -1,
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  });

  FaceMlResultBuilder.fromEnteFile(
    EnteFile file, {
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  }) : fileId = file.uploadedFileID ?? -1;

  FaceMlResultBuilder.fromEnteFileID(
    int fileID, {
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  }) : fileId = fileID;

  void addNewlyDetectedFaces(
    List<FaceDetectionRelative> faceDetections,
    Dimensions originalSize,
  ) {
    decodedImageSize = originalSize;
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
      decodedImageSize: decodedImageSize,
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

  bool get isBlurry => blurValue < kLaplacianHardThreshold;

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

  bool get isBlurry => blurValue < kLaplacianHardThreshold;

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

int getFileIdFromFaceId(String faceId) {
  return int.parse(faceId.split("_").first);
}

int? tryGetFileIdFromFaceId(String faceId) {
  return int.tryParse(faceId.split("_").first);
}