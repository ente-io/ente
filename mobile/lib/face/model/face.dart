import "package:photos/face/model/detection.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

// FileInfo contains the image width and height of the image the face was detected in.
class FileInfo {
  int? imageWidth;
  int? imageHeight;
  FileInfo({
    this.imageWidth,
    this.imageHeight,
  });
}

class Face {
  final int fileID;
  final String faceID;
  final List<double> embedding;
  Detection detection;
  final double score;
  final double blur;
  FileInfo? fileInfo;

  bool get isBlurry => blur < kLaplacianHardThreshold;

  bool get hasHighScore => score > kMinimumQualityFaceScore;

  bool get isHighQuality => (!isBlurry) && hasHighScore;

  int area({int? w, int? h}) {
    return detection.getFaceArea(
      fileInfo?.imageWidth ?? w ?? 0,
      fileInfo?.imageHeight ?? h ?? 0,
    );
  }

  Face(
    this.faceID,
    this.fileID,
    this.embedding,
    this.score,
    this.detection,
    this.blur, {
    this.fileInfo,
  });

  factory Face.empty(int fileID, {bool error = false}) {
    return Face(
      "$fileID-0",
      fileID,
      <double>[],
      error ? -1.0 : 0.0,
      Detection.empty(),
      0.0,
    );
  }

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      json['faceID'] as String,
      json['fileID'] as int,
      List<double>.from(json['embeddings'] as List),
      json['score'] as double,
      Detection.fromJson(json['detection'] as Map<String, dynamic>),
      // high value means t
      (json['blur'] ?? kLapacianDefault) as double,
    );
  }

  Map<String, dynamic> toJson() => {
        'faceID': faceID,
        'fileID': fileID,
        'embeddings': embedding,
        'detection': detection.toJson(),
        'score': score,
        'blur': blur,
      };
}
