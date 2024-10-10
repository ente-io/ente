import "dart:async";
import "dart:math" show min;
import 'dart:typed_data' show Int32List, Uint8List;
import 'dart:ui' as ui show Image;

import 'package:logging/logging.dart';
import "package:onnx_dart/onnx_dart.dart";
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/models/ml/face/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_postprocessing.dart";
import "package:photos/services/machine_learning/ml_model.dart";

class YOLOFaceInterpreterRunException implements Exception {}

/// This class is responsible for running the face detection model (YOLOv5Face) on ONNX runtime, and can be accessed through the singleton instance [FaceDetectionService.instance].
class FaceDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_face_opset18_rgba_opt.onnx";
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
    final relativeDetections = yoloOnnxFilterExtractDetections(
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
