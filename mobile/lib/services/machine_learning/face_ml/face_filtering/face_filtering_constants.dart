import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';

/// Blur detection threshold
const kLaplacianThreshold = 15;

/// Default blur value
const kLapacianDefault = 10000.0;

/// The minimum score for a face to be considered a high quality face for clustering and person detection
const kMinHighQualityFaceScore = 0.80;

/// The minimum score for a face to be detected, regardless of quality. Use [kMinHighQualityFaceScore] for high quality faces.
const kMinFaceDetectionScore = FaceDetectionService.kMinScoreSigmoidThreshold;
