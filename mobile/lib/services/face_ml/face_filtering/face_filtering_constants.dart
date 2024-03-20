import "package:photos/services/face_ml/face_detection/yolov5face/onnx_face_detection.dart";

/// Blur detection threshold
const kLaplacianThreshold = 15;

/// Default blur value
const kLapacianDefault = 10000.0;

/// The minimum score for a face to be considered a high quality face for clustering and person detection
const kMinHighQualityFaceScore = 0.78;

/// The minimum score for a face to be detected, regardless of quality. Use [kMinHighQualityFaceScore] for high quality faces.
const kMinFaceDetectionScore = YoloOnnxFaceDetection.kMinScoreSigmoidThreshold;
