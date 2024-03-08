import "package:photos/face/model/detection.dart";
import "package:photos/services/face_ml/blur_detection/blur_constants.dart";

class Face {
  final int fileID;
  final String faceID;
  final List<double> embedding;
  Detection detection;
  final double score;
  final double blur;

  bool get isBlurry => blur < kLaplacianThreshold;

  Face(
    this.faceID,
    this.fileID,
    this.embedding,
    this.score,
    this.detection,
    this.blur,
  );

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
