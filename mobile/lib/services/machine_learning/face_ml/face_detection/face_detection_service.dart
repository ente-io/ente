import "dart:async";
import "dart:developer" as dev show log;
import 'dart:typed_data' show ByteBuffer, ByteData, Float32List, Uint8List;
import 'dart:ui' as ui show Image;

import 'package:logging/logging.dart';
import "package:onnx_dart/onnx_dart.dart";
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/face/model/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_postprocessing.dart";
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
  static const double kMinScoreSigmoidThreshold = 0.7;
  static const int kNumKeypoints = 5;

  // Singleton pattern
  FaceDetectionService._privateConstructor();
  static final instance = FaceDetectionService._privateConstructor();
  factory FaceDetectionService() => instance;

  /// Detects faces in the given image data.
  static Future<List<FaceDetectionRelative>> predict(
    ui.Image image,
    ByteData imageByteData,
    int sessionAddress, {
    bool useEntePlugin = false,
  }) async {
    assert(
      !useEntePlugin ? (sessionAddress != 0 && sessionAddress != -1) : true,
      'sessionAddress should be valid',
    );

    final stopwatch = Stopwatch()..start();

    final stopwatchPreprocessing = Stopwatch()..start();
    final (inputImageList, newSize) =
        await preprocessImageToFloat32ChannelsFirst(
      image,
      imageByteData,
      normalization: 1,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
    );
    stopwatchPreprocessing.stop();
    dev.log(
      'Face detection image preprocessing is finished, in ${stopwatchPreprocessing.elapsedMilliseconds}ms',
    );
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchPreprocessing.elapsedMilliseconds}ms',
    );

    // Run inference
    final stopwatchInterpreter = Stopwatch()..start();

    List<List<List<double>>>? nestedResults = [];
    try {
      if (useEntePlugin) {
        nestedResults = await _runCustomPlugin(inputImageList);
      } else {
        nestedResults = _runJNIBasedPlugin(
          sessionAddress,
          inputImageList,
        ); // [1, 25200, 16]
      }
    } catch (e, s) {
      dev.log('Error while running inference', error: e, stackTrace: s);
      throw YOLOFaceInterpreterRunException();
    }
    stopwatchInterpreter.stop();
    try {
      _logger.info(
        'interpreter.run is finished, in ${stopwatchInterpreter.elapsedMilliseconds} ms',
      );

      final relativeDetections =
          _yoloPostProcessOutputs(nestedResults!, newSize);
      stopwatch.stop();
      _logger.info(
        'predict() face detection executed in ${stopwatch.elapsedMilliseconds}ms',
      );

      return relativeDetections;
    } catch (e, s) {
      _logger.severe('Error while post processing', e, s);
      rethrow;
    }
  }

  static List<List<List<double>>>? _runJNIBasedPlugin(
    int sessionAddress,
    Float32List inputImageList,
  ) {
    final inputShape = [
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
    final List<OrtValue?>? outputs = session.run(runOptions, inputs);
    // inputOrt.release();
    // runOptions.release();
    return outputs?[0]?.value as List<List<List<double>>>; // [1, 25200, 16]
  }

  static Future<List<List<List<double>>>> _runCustomPlugin(
    Float32List inputImageList,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predict(
      inputImageList,
      "YOLO_FACE",
    );
    final List<List<List<double>>> reconstructedTensor = [];
    for (int i = 0; i < result!.length; i += 25200 * 16) {
      final List<List<double>> outerArray = [];
      for (int j = 0; j < 25200; j++) {
        final List<double> innerArray =
            result.sublist(i + j * 16, i + (j + 1) * 16).cast<double>();
        outerArray.add(innerArray);
      }
      reconstructedTensor.add(outerArray);
    }
    return reconstructedTensor;
  }

  static List<FaceDetectionRelative> _yoloPostProcessOutputs(
    List<List<List<double>>> nestedResults,
    Dimensions newSize,
  ) {
    final firstResults = nestedResults[0]; // [25200, 16]

    // Filter output
    var relativeDetections = yoloOnnxFilterExtractDetections(
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
        newSize,
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
