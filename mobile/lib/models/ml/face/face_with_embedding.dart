import "package:photos/models/ml/face/detection.dart";
import "package:photos/models/ml/face/check_is.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/standalone/parse.dart";

class FaceWithoutEmbedding {
  final String faceID;
  final int fileID;
  Detection detection;
  final double score;
  final double blur;

  // Is the image blurry based on Laplacian threshold?
  bool get isBlurry => blur < kLaplacianHardThreshold;

  // Does the face have a high enough confidence score?
  bool get hasHighScore => score > kMinimumQualityFaceScore;

  // Is the face both not blurry and has a high enough score?
  bool get isHighQuality => (!isBlurry) && hasHighScore;

  // Recognition confidence level based on check value
  FaceCheckStatus get checkStatus => detection.box.checkStatus;

  // Shortcut booleans from checkStatus
  bool get isCheckedRecognized => detection.box.isRecognized;
  bool get isCheckedSuggestable => detection.box.isSuggestable;
  bool get isCheckedRejected => detection.box.isRejected;

  FaceWithoutEmbedding(
    this.faceID,
    this.fileID,
    this.score,
    this.detection,
    this.blur,
  );

  factory FaceWithoutEmbedding.fromJson(Map<String, dynamic> json) {
    final String faceID = json['faceID'] as String;
    final int fileID = getFileIdFromFaceId<int>(faceID);
    return FaceWithoutEmbedding(
      faceID,
      fileID,
      parseIntOrDoubleAsDouble(json['score'])!,
      Detection.fromJson(json['detection'] as Map<String, dynamic>),
      parseIntOrDoubleAsDouble(json['blur']) ?? kLapacianDefault,
    );
  }

  // Keep toJson output minimal and in sync with desktop logic
  Map<String, dynamic> toJson() => {
        'faceID': faceID,
        'detection': detection.toJson(),
        'score': score,
        'blur': blur,
      };
}
