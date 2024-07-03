import "dart:async";
import "dart:developer" as dev show log;
import "dart:io" show File;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui show Image;

import "package:computer/computer.dart";
import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/face/model/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_postprocessing.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/image_ml_util.dart";

class YOLOFaceInterpreterRunException implements Exception {}

/// This class is responsible for running the face detection model (YOLOv5Face) on ONNX runtime, and can be accessed through the singleton instance [FaceDetectionService.instance].
class FaceDetectionService {
  static final _logger = Logger('FaceDetectionService');

  final _computer = Computer.shared();

  int sessionAddress = 0;

  static const String kModelBucketEndpoint = "https://models.ente.io/";
  static const String kRemoteBucketModelPath =
      "yolov5s_face_640_640_dynamic.onnx";
  static const String modelRemotePath =
      kModelBucketEndpoint + kRemoteBucketModelPath;

  static const int kInputWidth = 640;
  static const int kInputHeight = 640;
  static const double kIouThreshold = 0.4;
  static const double kMinScoreSigmoidThreshold = 0.7;
  static const int kNumKeypoints = 5;

  bool isInitialized = false;

  // Singleton pattern
  FaceDetectionService._privateConstructor();
  static final instance = FaceDetectionService._privateConstructor();
  factory FaceDetectionService() => instance;

  /// Check if the interpreter is initialized, if not initialize it with `loadModel()`
  Future<void> init() async {
    if (!isInitialized) {
      _logger.info('init is called');
      final model =
          await RemoteAssetsService.instance.getAsset(modelRemotePath);
      final startTime = DateTime.now();
      sessionAddress = await _computer.compute(
        _loadModel,
        param: {
          "modelPath": model.path,
        },
      );
      final endTime = DateTime.now();
      _logger.info(
        "Face detection model loaded, took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
      );
      if (sessionAddress != -1) {
        isInitialized = true;
      }
    }
  }

  Future<void> release() async {
    if (isInitialized) {
      await _computer
          .compute(_releaseModel, param: {'address': sessionAddress});
      isInitialized = false;
      sessionAddress = 0;
    }
  }

  /// Detects faces in the given image data.
  static Future<(List<FaceDetectionRelative>, Dimensions)> predict(
    ui.Image image,
    ByteData imageByteData,
    int sessionAddress,
  ) async {
    assert(sessionAddress != 0 && sessionAddress != -1);

    final stopwatch = Stopwatch()..start();

    final stopwatchPreprocessing = Stopwatch()..start();
    final (inputImageList, originalSize, newSize) =
        await preprocessImageToFloat32ChannelsFirst(
      image,
      imageByteData,
      normalization: 1,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
    );

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
    stopwatchPreprocessing.stop();
    dev.log(
      'Face detection image preprocessing is finished, in ${stopwatchPreprocessing.elapsedMilliseconds}ms',
    );
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchPreprocessing.elapsedMilliseconds}ms',
    );
    _logger.info('original size: $originalSize \n new size: $newSize');

    // Run inference
    final stopwatchInterpreter = Stopwatch()..start();
    List<OrtValue?>? outputs;
    try {
      final runOptions = OrtRunOptions();
      final session = OrtSession.fromAddress(sessionAddress);
      outputs = session.run(runOptions, inputs);
      // inputOrt.release();
      // runOptions.release();
    } catch (e, s) {
      _logger.severe('Error while running inference: $e \n $s');
      throw YOLOFaceInterpreterRunException();
    }
    stopwatchInterpreter.stop();
    _logger.info(
      'interpreter.run is finished, in ${stopwatchInterpreter.elapsedMilliseconds} ms',
    );

    final relativeDetections = _yoloPostProcessOutputs(outputs, newSize);

    stopwatch.stop();
    _logger.info(
      'predict() face detection executed in ${stopwatch.elapsedMilliseconds}ms',
    );

    return (relativeDetections, originalSize);
  }

  static List<FaceDetectionRelative> _yoloPostProcessOutputs(
    List<OrtValue?>? outputs,
    Dimensions newSize,
  ) {
    // // Get output tensors
    final nestedResults =
        outputs?[0]?.value as List<List<List<double>>>; // [1, 25200, 16]
    final firstResults = nestedResults[0]; // [25200, 16]

    // Filter output
    var relativeDetections = yoloOnnxFilterExtractDetections(
      kMinScoreSigmoidThreshold,
      kInputWidth,
      kInputHeight,
      results: firstResults,
    );

    // Release outputs
    // outputs?.forEach((element) {
    //   element?.release();
    // });

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

  /// Initialize the interpreter by loading the model file.
  static Future<int> _loadModel(Map args) async {
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      final session =
          OrtSession.fromFile(File(args["modelPath"]), sessionOptions);
      return session.address;
    } catch (e, s) {
      _logger.severe('Face detection model not loaded', e, s);
    }
    return -1;
  }

  static Future<void> _releaseModel(Map args) async {
    final address = args['address'] as int;
    if (address == 0) {
      return;
    }
    final session = OrtSession.fromAddress(address);
    session.release();
    return;
  }
}
