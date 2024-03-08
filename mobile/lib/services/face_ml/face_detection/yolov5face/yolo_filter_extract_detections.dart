import "package:photos/services/face_ml/face_detection/detection.dart";

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
