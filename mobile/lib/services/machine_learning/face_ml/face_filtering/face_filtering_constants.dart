import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';

/// Blur detection threshold
const kLaplacianHardThreshold = 10;
const kLaplacianSoftThreshold = 50;
const kLaplacianVerySoftThreshold = 200;

/// Default blur value
const kLapacianDefault = 10000.0;

/// The minimum score for a face to be considered a high quality face for clustering and person detection
const kMinimumQualityFaceScore = 0.80;
const kMediumQualityFaceScore = 0.85;
const kHighQualityFaceScore = 0.90;

/// The minimum score for a face to be detected, regardless of quality. Use [kMinimumQualityFaceScore] for high quality faces.
const kMinFaceDetectionScore = FaceDetectionService.kMinScoreSigmoidThreshold;

/// The minimum cluster size for displaying a cluster in the UI
const kMinimumClusterSizeSearchResult = 10;

/// The minimum cluster sizes to try when the normal minimum doesn't return any results
const kLowerMinimumClusterSizes = [5, 3, 2, 1];
