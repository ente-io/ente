import 'package:photos/services/machine_learning/face_ml/face_ml_version.dart';

/// Represents a face detection method with a specific version.
class FaceDetectionMethod extends VersionedMethod {
  /// Creates a [FaceDetectionMethod] instance with a specific `method` and `version` (default `1`)
  FaceDetectionMethod(String method, {int version = 1})
      : super(method, version);

  /// Creates a [FaceDetectionMethod] instance with 'Empty method' as the method, and a specific `version` (default `1`)
  const FaceDetectionMethod.empty() : super.empty();

  /// Creates a [FaceDetectionMethod] instance with 'BlazeFace' as the method, and a specific `version` (default `1`)
  FaceDetectionMethod.blazeFace({int version = 1})
      : super('BlazeFace', version);

  static FaceDetectionMethod fromMlVersion(int version) {
    switch (version) {
      case 1:
        return FaceDetectionMethod.blazeFace(version: version);
      default:
        return const FaceDetectionMethod.empty();
    }
  }

  static FaceDetectionMethod fromJson(Map<String, dynamic> json) {
    return FaceDetectionMethod(
      json['method'],
      version: json['version'],
    );
  }
}

/// Represents a face alignment method with a specific version.
class FaceAlignmentMethod extends VersionedMethod {
  /// Creates a [FaceAlignmentMethod] instance with a specific `method` and `version` (default `1`)
  FaceAlignmentMethod(String method, {int version = 1})
      : super(method, version);

  /// Creates a [FaceAlignmentMethod] instance with 'Empty method' as the method, and a specific `version` (default `1`)
  const FaceAlignmentMethod.empty() : super.empty();

  /// Creates a [FaceAlignmentMethod] instance with 'affineTransform' as the method, and a specific `version` (default `1`)
  FaceAlignmentMethod.affineTransform({int version = 1}) : super('affineTransform', version);

  static FaceAlignmentMethod fromMlVersion(int version) {
    switch (version) {
      case 1:
        return FaceAlignmentMethod.affineTransform(version: version);
      default:
        return const FaceAlignmentMethod.empty();
    }
  }

  static FaceAlignmentMethod fromJson(Map<String, dynamic> json) {
    return FaceAlignmentMethod(
      json['method'],
      version: json['version'],
    );
  }
}

/// Represents a face embedding method with a specific version.
class FaceEmbeddingMethod extends VersionedMethod {
  /// Creates a [FaceEmbeddingMethod] instance with a specific `method` and `version` (default `1`)
  FaceEmbeddingMethod(String method, {int version = 1})
      : super(method, version);

  /// Creates a [FaceEmbeddingMethod] instance with 'Empty method' as the method, and a specific `version` (default `1`)
  const FaceEmbeddingMethod.empty() : super.empty();

  /// Creates a [FaceEmbeddingMethod] instance with 'MobileFaceNet' as the method, and a specific `version` (default `1`)
  FaceEmbeddingMethod.mobileFaceNet({int version = 1})
      : super('MobileFaceNet', version);

  static FaceEmbeddingMethod fromMlVersion(int version) {
    switch (version) {
      case 1:
        return FaceEmbeddingMethod.mobileFaceNet(version: version);
      default:
        return const FaceEmbeddingMethod.empty();
    }
  }

  static FaceEmbeddingMethod fromJson(Map<String, dynamic> json) {
    return FaceEmbeddingMethod(
      json['method'],
      version: json['version'],
    );
  }
}
