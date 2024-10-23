import "dart:async";
import "dart:math" show min;
import 'dart:typed_data' show Int32List, Uint8List;
import 'dart:ui' as ui show Image;

import 'package:logging/logging.dart';
import "package:onnx_dart/onnx_dart.dart";
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/models/ml/face/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import "package:photos/services/machine_learning/ml_model.dart";

class YOLOFaceInterpreterRunException implements Exception {}

/// This class is responsible for running the face detection model (YOLOv5Face) on ONNX runtime, and can be accessed through the singleton instance [FaceDetectionService.instance].
class FaceDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_face_opset18_rgba_opt_nosplits.onnx";
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
  static const double kMinScoreSigmoidThreshold = 0.7;
  static const int kNumKeypoints = 5;

  // Singleton pattern
  FaceDetectionService._privateConstructor();

  static final instance = FaceDetectionService._privateConstructor();

  factory FaceDetectionService() => instance;

  /// Detects faces in the given image data.
  static Future<List<FaceDetectionRelative>> predict(
    ui.Image image,
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
    final inputShape = <int>[image.height, image.width, 4]; // [H, W, C]
    final scaledSize = _getScaledSize(image.width, image.height);

    // Run inference
    List<List<double>>? nestedResults = [];
    try {
      if (MlModel.usePlatformPlugin) {
        nestedResults =
            await _runPlatformPluginPredict(rawRgbaBytes, inputShape);
      } else {
        nestedResults = _runFFIBasedPredict(
          rawRgbaBytes,
          inputShape,
          sessionAddress,
        ); // [detections, 16]
      }
      final inferenceTime = DateTime.now();
      _logger.info(
        'Face detection is finished, in ${inferenceTime.difference(startTime).inMilliseconds} ms',
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

  static List<List<double>>? _runFFIBasedPredict(
    Uint8List inputImageList,
    List<int> inputImageShape,
    int sessionAddress,
  ) {
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      inputImageShape,
    );
    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();
    final session = OrtSession.fromAddress(sessionAddress);
    final List<OrtValue?> outputs = session.run(runOptions, inputs);
    final result = outputs[0]?.value as List<List<double>>; // [detections, 16]
    inputOrt.release();
    runOptions.release();
    for (var element in outputs) {
      element?.release();
    }

    return result;
  }

  static Future<List<List<double>>> _runPlatformPluginPredict(
    Uint8List inputImageList,
    List<int> inputImageShape,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predictRgba(
      inputImageList,
      Int32List.fromList(inputImageShape),
      _modelName,
    );

    final int resultLength = result!.length;
    assert(resultLength % 16 == 0);
    final int detections = resultLength ~/ 16;
    return List.generate(
      detections,
      (index) => result.sublist(index * 16, (index + 1) * 16).toList(),
    );
  }

  static List<FaceDetectionRelative> _yoloPostProcessOutputs(
    List<List<double>> nestedResults,
    Dimensions scaledSize,
  ) {
    // Filter output
    final relativeDetections = _yoloOnnxFilterExtractDetections(
      kMinScoreSigmoidThreshold,
      kInputWidth,
      kInputHeight,
      results: nestedResults,
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

    return relativeDetections;
  }

  static Dimensions _getScaledSize(int imageWidth, int imageHeight) {
    final scale = min(kInputWidth / imageWidth, kInputHeight / imageHeight);
    final scaledWidth = (imageWidth * scale).round().clamp(0, kInputWidth);
    final scaledHeight = (imageHeight * scale).round().clamp(0, kInputHeight);

    return Dimensions(width: scaledWidth, height: scaledHeight);
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