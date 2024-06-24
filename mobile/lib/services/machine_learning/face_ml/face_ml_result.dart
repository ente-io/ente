import "dart:convert" show jsonEncode, jsonDecode;

import "package:photos/face/model/dimension.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import "package:photos/models/ml/ml_versions.dart";
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

class FaceMlResult {
  int fileId;

  List<FaceResult> faces = <FaceResult>[];

  Dimensions decodedImageSize;

  int mlVersion;
  bool errorOccured;
  bool onlyThumbnailUsed;

  bool get hasFaces => faces.isNotEmpty;

  FaceMlResult({
    this.fileId = -1,
    this.faces = const <FaceResult>[],
    this.mlVersion = faceMlVersion,
    this.errorOccured = false,
    this.onlyThumbnailUsed = false,
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  });

  FaceMlResult.fromEnteFileID(
    fileID, {
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
        FaceResult.fromFaceDetection(
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

  void noFaceDetected() {
    faces = <FaceResult>[];
  }

  void errorOccurred() {
    noFaceDetected();
    errorOccured = true;
  }

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
}

class FaceResult {
  late FaceDetectionRelative detection;
  late double blurValue;
  late AlignmentResult alignment;
  late Embedding embedding;
  late int fileId;
  late String faceId;

  bool get isBlurry => blurValue < kLaplacianHardThreshold;

  FaceResult({
    required this.fileId,
    required this.faceId,
    required this.detection,
    required this.blurValue,
    required this.alignment,
    required this.embedding,
  });

  FaceResult.fromFaceDetection(
    FaceDetectionRelative faceDetection, {
    required FaceMlResult resultBuilder,
  }) {
    fileId = resultBuilder.fileId;
    faceId = faceDetection.toFaceID(fileID: resultBuilder.fileId);
    detection = faceDetection;
  }

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

int getFileIdFromFaceId(String faceId) {
  return int.parse(faceId.split("_").first);
}

int? tryGetFileIdFromFaceId(String faceId) {
  return int.tryParse(faceId.split("_").first);
}
