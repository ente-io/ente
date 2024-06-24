import 'dart:developer' as dev show log;
import 'dart:math' as math show max, min;

import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';

List<FaceDetectionRelative> yoloOnnxFilterExtractDetections(
  double minScoreSigmoidThreshold,
  int inputWidth,
  int inputHeight, {
  required List<List<double>> results, // // [25200, 16]
}) {
  final outputDetections = <FaceDetectionRelative>[];
  final output = <List<double>>[];

  // Go through the raw output and check the scores
  for (final result in results) {
    // Filter out raw detections with low scores
    if (result[4] < minScoreSigmoidThreshold) {
      continue;
    }

    // Get the raw detection
    final rawDetection = List<double>.from(result);

    // Append the processed raw detection to the output
    output.add(rawDetection);
  }

  if (output.isEmpty) {
    double maxScore = 0;
    for (final result in results) {
      if (result[4] > maxScore) {
        maxScore = result[4];
      }
    }
    dev.log(
      'No face detections found above the minScoreSigmoidThreshold of $minScoreSigmoidThreshold. The max score was $maxScore.',
    );
  }

  for (final List<double> rawDetection in output) {
    // Get absolute bounding box coordinates in format [xMin, yMin, xMax, yMax] https://github.com/deepcam-cn/yolov5-face/blob/eb23d18defe4a76cc06449a61cd51004c59d2697/utils/general.py#L216
    final xMinAbs = rawDetection[0] - rawDetection[2] / 2;
    final yMinAbs = rawDetection[1] - rawDetection[3] / 2;
    final xMaxAbs = rawDetection[0] + rawDetection[2] / 2;
    final yMaxAbs = rawDetection[1] + rawDetection[3] / 2;

    // Get the relative bounding box coordinates in format [xMin, yMin, xMax, yMax]
    final box = [
      xMinAbs / inputWidth,
      yMinAbs / inputHeight,
      xMaxAbs / inputWidth,
      yMaxAbs / inputHeight,
    ];

    // Get the keypoints coordinates in format [x, y]
    final allKeypoints = <List<double>>[
      [
        rawDetection[5] / inputWidth,
        rawDetection[6] / inputHeight,
      ],
      [
        rawDetection[7] / inputWidth,
        rawDetection[8] / inputHeight,
      ],
      [
        rawDetection[9] / inputWidth,
        rawDetection[10] / inputHeight,
      ],
      [
        rawDetection[11] / inputWidth,
        rawDetection[12] / inputHeight,
      ],
      [
        rawDetection[13] / inputWidth,
        rawDetection[14] / inputHeight,
      ],
    ];

    // Get the score
    final score =
        rawDetection[4]; // Or should it be rawDetection[4]*rawDetection[15]?

    // Create the relative detection
    final detection = FaceDetectionRelative(
      score: score,
      box: box,
      allKeypoints: allKeypoints,
    );

    // Append the relative detection to the output
    outputDetections.add(detection);
  }

  return outputDetections;
}

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
