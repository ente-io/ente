import 'dart:math' as math show max, min;

import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';

List<FaceDetectionRelative> naiveNonMaxSuppression({
  required List<FaceDetectionRelative> detections,
  required double iouThreshold,
}) {
  // Sort the detections by score, the highest first
  detections.sort((a, b) => b.score.compareTo(a.score));

  // Loop through the detections and calculate the IOU
  for (var i = 0; i < detections.length - 1; i++) {
    for (var j = i + 1; j < detections.length; j++) {
      final iou = _calculateIOU(detections[i], detections[j]);
      if (iou >= iouThreshold) {
        detections.removeAt(j);
        j--;
      }
    }
  }
  return detections;
}

double _calculateIOU(
  FaceDetectionRelative detectionA,
  FaceDetectionRelative detectionB,
) {
  final areaA = detectionA.width * detectionA.height;
  final areaB = detectionB.width * detectionB.height;

  final intersectionMinX = math.max(detectionA.xMinBox, detectionB.xMinBox);
  final intersectionMinY = math.max(detectionA.yMinBox, detectionB.yMinBox);
  final intersectionMaxX = math.min(detectionA.xMaxBox, detectionB.xMaxBox);
  final intersectionMaxY = math.min(detectionA.yMaxBox, detectionB.yMaxBox);

  final intersectionWidth = intersectionMaxX - intersectionMinX;
  final intersectionHeight = intersectionMaxY - intersectionMinY;

  if (intersectionWidth < 0 || intersectionHeight < 0) {
    return 0.0; // If boxes do not overlap, IoU is 0
  }

  final intersectionArea = intersectionWidth * intersectionHeight;

  final unionArea = areaA + areaB - intersectionArea;

  return intersectionArea / unionArea;
}
