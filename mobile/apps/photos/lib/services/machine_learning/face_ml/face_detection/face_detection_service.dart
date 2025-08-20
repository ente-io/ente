import "dart:async";
import 'dart:typed_data' show Float32List, Uint8List;

import 'package:logging/logging.dart';
import "package:onnx_dart/onnx_dart.dart";
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/models/ml/face/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_postprocessing.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/image_ml_util.dart";

class YOLOFaceInterpreterRunException implements Exception {}

/// This class is responsible for running the face detection model (YOLOv5Face) on ONNX runtime, and can be accessed through the singleton instance [FaceDetectionService.instance].
class FaceDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_face_640_640_dynamic.onnx";
  static const _modelName = "YOLOv5Face";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('FaceDetectionService');

  @override
  String get modelName => _modelName;

  static const int kInputWidth = 640;
  static const int kInputHeight = 640;
  static const double kIouThreshold = 0.4;
  static const double kMinScoreSigmoidThreshold = kMinFaceDetectionScore;
  static const int kNumKeypoints = 5;

  // Singleton pattern
  FaceDetectionService._privateConstructor();

  static final instance = FaceDetectionService._privateConstructor();

  factory FaceDetectionService() => instance;

  /// Detects faces in the given image data.
  static Future<List<FaceDetectionRelative>> predict(
    Dimensions dimensions,
    Uint8List rawRgbaBytes,
    int sessionAddress,
  ) async {
    assert(
      !MlModel.usePlatformPlugin
          ? (sessionAddress != 0 && sessionAddress != -1)
          : true,
      'sessionAddress should be valid',
    );

    final startTime = DateTime.now();

    final (inputImageList, scaledSize) = await preprocessImageYoloFace(
      dimensions,
      rawRgbaBytes,
    );
    final preprocessingTime = DateTime.now();
    final preprocessingMs =
        preprocessingTime.difference(startTime).inMilliseconds;

    // Run inference
    List<List<List<double>>>? nestedResults = [];
    try {
      if (MlModel.usePlatformPlugin) {
        nestedResults = await _runPlatformPluginPredict(inputImageList);
      } else {
        nestedResults = _runFFIBasedPredict(
          sessionAddress,
          inputImageList,
        );
      }
      final inferenceTime = DateTime.now();
      final inferenceMs =
          inferenceTime.difference(preprocessingTime).inMilliseconds;
      _logger.info(
        'Face detection is finished, in ${inferenceTime.difference(startTime).inMilliseconds} ms (preprocessing: $preprocessingMs ms, inference: $inferenceMs ms)',
      );
    } catch (e, s) {
      _logger.severe(
        'Error while running inference (PlatformPlugin: ${MlModel.usePlatformPlugin})',
        e,
        s,
      );
      throw YOLOFaceInterpreterRunException();
    }
    try {
      final relativeDetections =
          _yoloPostProcessOutputs(nestedResults!, scaledSize);
      return relativeDetections;
    } catch (e, s) {
      _logger.severe('Error while post processing', e, s);
      rethrow;
    }
  }

  static List<List<List<double>>>? _runFFIBasedPredict(
    int sessionAddress,
    Float32List inputImageList,
  ) {
    const inputShape = [
      1,
      3,
      kInputHeight,
      kInputWidth,
    ];
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      inputShape,
    );
    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();
    final session = OrtSession.fromAddress(sessionAddress);
    final List<OrtValue?> outputs = session.run(runOptions, inputs);
    final result =
        outputs[0]?.value as List<List<List<double>>>; // [1, 25200, 16]
    inputOrt.release();
    runOptions.release();
    for (var element in outputs) {
      element?.release();
    }

    return result;
  }

  static Future<List<List<List<double>>>> _runPlatformPluginPredict(
    Float32List inputImageList,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predict(
      inputImageList,
      _modelName,
    );

    final int resultLength = result!.length;
    assert(resultLength % 25200 * 16 == 0);
    const int outerLength = 1;
    const int middleLength = 25200;
    const int innerLength = 16;
    return List.generate(
      outerLength,
      (_) => List.generate(
        middleLength,
        (j) => result.sublist(j * innerLength, (j + 1) * innerLength).toList(),
      ),
    );
  }

  static List<FaceDetectionRelative> _yoloPostProcessOutputs(
    List<List<List<double>>> nestedResults,
    Dimensions scaledSize,
  ) {
    final firstResults = nestedResults[0]; // [25200, 16]

    // Filter output
    var relativeDetections = _yoloOnnxFilterExtractDetections(
      kMinScoreSigmoidThreshold,
      kInputWidth,
      kInputHeight,
      results: firstResults,
    );

    // Account for the fact that the aspect ratio was maintained
    for (final faceDetection in relativeDetections) {
      faceDetection.correctForMaintainedAspectRatio(
        const Dimensions(
          width: kInputWidth,
          height: kInputHeight,
        ),
        scaledSize,
      );
    }

    // Non-maximum suppression to remove duplicate detections
    relativeDetections = naiveNonMaxSuppression(
      detections: relativeDetections,
      iouThreshold: kIouThreshold,
    );

    return relativeDetections;
  }
}

List<FaceDetectionRelative> _yoloOnnxFilterExtractDetections(
  double minScoreSigmoidThreshold,
  int inputWidth,
  int inputHeight, {
  required List<List<double>> results, // // [detections, 16]
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
    return outputDetections;
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
