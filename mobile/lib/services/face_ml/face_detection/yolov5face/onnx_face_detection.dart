import "dart:async";
import "dart:developer" as dev show log;
import "dart:io" show File;
import "dart:isolate";
import 'dart:typed_data' show Float32List, Uint8List;

import "package:computer/computer.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/services/face_ml/face_detection/detection.dart";
import "package:photos/services/face_ml/face_detection/naive_non_max_suppression.dart";
import "package:photos/services/face_ml/face_detection/yolov5face/yolo_face_detection_exceptions.dart";
import "package:photos/services/face_ml/face_detection/yolov5face/yolo_filter_extract_detections.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/image_ml_isolate.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:synchronized/synchronized.dart";

enum FaceDetectionOperation { yoloInferenceAndPostProcessing }

class YoloOnnxFaceDetection {
  static final _logger = Logger('YOLOFaceDetectionService');

  final _computer = Computer.shared();

  int sessionAddress = 0;

  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kRemoteBucketModelPath = "yolov5s_face_640_640_dynamic.onnx";
  // static const kRemoteBucketModelPath = "yolov5n_face_640_640.onnx";
  static const modelRemotePath = kModelBucketEndpoint + kRemoteBucketModelPath;

  static const kInputWidth = 640;
  static const kInputHeight = 640;
  static const kIouThreshold = 0.4;
  static const kMinScoreSigmoidThreshold = 0.8;

  bool isInitialized = false;

  // Isolate things
  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 30);

  final _initLock = Lock();
  final _computerLock = Lock();

  late Isolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;
  bool isRunning = false;

  // singleton pattern
  YoloOnnxFaceDetection._privateConstructor();

  /// Use this instance to access the FaceDetection service. Make sure to call `init()` before using it.
  /// e.g. `await FaceDetection.instance.init();`
  ///
  /// Then you can use `predict()` to get the bounding boxes of the faces, so `FaceDetection.instance.predict(imageData)`
  ///
  /// config options: yoloV5FaceN //
  static final instance = YoloOnnxFaceDetection._privateConstructor();

  factory YoloOnnxFaceDetection() => instance;

  /// Check if the interpreter is initialized, if not initialize it with `loadModel()`
  Future<void> init() async {
    if (!isInitialized) {
      _logger.info('init is called');
      final model =
          await RemoteAssetsService.instance.getAsset(modelRemotePath);
      final startTime = DateTime.now();
      // Doing this from main isolate since `rootBundle` cannot be accessed outside it
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

  Future<void> initIsolate() async {
    return _initLock.synchronized(() async {
      if (isSpawned) return;

      _receivePort = ReceivePort();

      try {
        _isolate = await Isolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        isSpawned = true;

        _resetInactivityTimer();
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        isSpawned = false;
      }
    });
  }

  Future<void> ensureSpawnedIsolate() async {
    if (!isSpawned) {
      await initIsolate();
    }
  }

  /// The main execution function of the isolate.
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = FaceDetectionOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case FaceDetectionOperation.yoloInferenceAndPostProcessing:
            final inputImageList = args['inputImageList'] as Float32List;
            final inputShape = args['inputShape'] as List<int>;
            final newSize = args['newSize'] as Size;
            final sessionAddress = args['sessionAddress'] as int;
            final timeSentToIsolate = args['timeNow'] as DateTime;
            final delaySentToIsolate =
                DateTime.now().difference(timeSentToIsolate).inMilliseconds;

            final Stopwatch stopwatchPrepare = Stopwatch()..start();
            final inputOrt = OrtValueTensor.createTensorWithDataList(
              inputImageList,
              inputShape,
            );
            final inputs = {'input': inputOrt};
            stopwatchPrepare.stop();
            dev.log(
              '[YOLOFaceDetectionService] data preparation is finished, in ${stopwatchPrepare.elapsedMilliseconds}ms',
            );

            stopwatchPrepare.reset();
            stopwatchPrepare.start();
            final runOptions = OrtRunOptions();
            final session = OrtSession.fromAddress(sessionAddress);
            stopwatchPrepare.stop();
            dev.log(
              '[YOLOFaceDetectionService] session preparation is finished, in ${stopwatchPrepare.elapsedMilliseconds}ms',
            );

            final stopwatchInterpreter = Stopwatch()..start();
            late final List<OrtValue?> outputs;
            try {
              outputs = session.run(runOptions, inputs);
            } catch (e, s) {
              dev.log(
                '[YOLOFaceDetectionService] Error while running inference: $e \n $s',
              );
              throw YOLOInterpreterRunException();
            }
            stopwatchInterpreter.stop();
            dev.log(
              '[YOLOFaceDetectionService] interpreter.run is finished, in ${stopwatchInterpreter.elapsedMilliseconds} ms',
            );

            final relativeDetections =
                _yoloPostProcessOutputs(outputs, newSize);

            sendPort
                .send((relativeDetections, delaySentToIsolate, DateTime.now()));
            break;
        }
      } catch (e, stackTrace) {
        sendPort
            .send({'error': e.toString(), 'stackTrace': stackTrace.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (FaceDetectionOperation, Map<String, dynamic>) message,
  ) async {
    await ensureSpawnedIsolate();
    _resetInactivityTimer();
    final completer = Completer<dynamic>();
    final answerPort = ReceivePort();

    _mainSendPort.send([message.$1.index, message.$2, answerPort.sendPort]);

    answerPort.listen((receivedMessage) {
      if (receivedMessage is Map && receivedMessage.containsKey('error')) {
        // Handle the error
        final errorMessage = receivedMessage['error'];
        final errorStackTrace = receivedMessage['stackTrace'];
        final exception = Exception(errorMessage);
        final stackTrace = StackTrace.fromString(errorStackTrace);
        completer.completeError(exception, stackTrace);
      } else {
        completer.complete(receivedMessage);
      }
    });

    return completer.future;
  }

  /// Resets a timer that kills the isolate after a certain amount of inactivity.
  ///
  /// Should be called after initialization (e.g. inside `init()`) and after every call to isolate (e.g. inside `_runInIsolate()`)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      _logger.info(
        'Face detection (YOLO ONNX) Isolate has been inactive for ${_inactivityDuration.inSeconds} seconds. Killing isolate.',
      );
      disposeIsolate();
    });
  }

  /// Disposes the isolate worker.
  void disposeIsolate() {
    if (!isSpawned) return;

    isSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  /// Detects faces in the given image data.
  Future<(List<FaceDetectionRelative>, Size)> predict(
    Uint8List imageData,
  ) async {
    assert(isInitialized);

    final stopwatch = Stopwatch()..start();

    final stopwatchDecoding = Stopwatch()..start();
    final (inputImageList, originalSize, newSize) =
        await ImageMlIsolate.instance.preprocessImageYoloOnnx(
      imageData,
      normalize: true,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
      quality: FilterQuality.medium,
    );

    // final input = [inputImageList];
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
    stopwatchDecoding.stop();
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
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
      throw YOLOInterpreterRunException();
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

  /// Detects faces in the given image data.
  static Future<(List<FaceDetectionRelative>, Size)> predictSync(
    String imagePath,
    int sessionAddress,
  ) async {
    assert(sessionAddress != 0 && sessionAddress != -1);

    final stopwatch = Stopwatch()..start();

    final stopwatchDecoding = Stopwatch()..start();
    final imageData = await File(imagePath).readAsBytes();
    final (inputImageList, originalSize, newSize) =
        await preprocessImageToFloat32ChannelsFirst(
      imageData,
      normalization: 1,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
      quality: FilterQuality.medium,
    );

    // final input = [inputImageList];
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
    stopwatchDecoding.stop();
    dev.log(
      'Face detection image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
    );
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
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
      throw YOLOInterpreterRunException();
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

  /// Detects faces in the given image data.
  Future<(List<FaceDetectionRelative>, Size)> predictInIsolate(
    Uint8List imageData,
  ) async {
    await ensureSpawnedIsolate();
    assert(isInitialized);

    _logger.info('predictInIsolate() is called');

    final stopwatch = Stopwatch()..start();

    final stopwatchDecoding = Stopwatch()..start();
    final (inputImageList, originalSize, newSize) =
        await ImageMlIsolate.instance.preprocessImageYoloOnnx(
      imageData,
      normalize: true,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
      quality: FilterQuality.medium,
    );
    // final input = [inputImageList];
    final inputShape = [
      1,
      3,
      kInputHeight,
      kInputWidth,
    ];

    stopwatchDecoding.stop();
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
    );
    _logger.info('original size: $originalSize \n new size: $newSize');

    final (
      List<FaceDetectionRelative> relativeDetections,
      delaySentToIsolate,
      timeSentToMain
    ) = await _runInIsolate(
      (
        FaceDetectionOperation.yoloInferenceAndPostProcessing,
        {
          'inputImageList': inputImageList,
          'inputShape': inputShape,
          'newSize': newSize,
          'sessionAddress': sessionAddress,
          'timeNow': DateTime.now(),
        }
      ),
    ) as (List<FaceDetectionRelative>, int, DateTime);

    final delaySentToMain =
        DateTime.now().difference(timeSentToMain).inMilliseconds;

    stopwatch.stop();
    _logger.info(
      'predictInIsolate() face detection executed in ${stopwatch.elapsedMilliseconds}ms, with ${delaySentToIsolate}ms delay sent to isolate, and ${delaySentToMain}ms delay sent to main, for a total of ${delaySentToIsolate + delaySentToMain}ms delay due to isolate',
    );

    return (relativeDetections, originalSize);
  }

  Future<(List<FaceDetectionRelative>, Size)> predictInComputer(
    String imagePath,
  ) async {
    assert(isInitialized);

    _logger.info('predictInComputer() is called');

    final stopwatch = Stopwatch()..start();

    final stopwatchDecoding = Stopwatch()..start();
    final imageData = await File(imagePath).readAsBytes();
    final (inputImageList, originalSize, newSize) =
        await ImageMlIsolate.instance.preprocessImageYoloOnnx(
      imageData,
      normalize: true,
      requiredWidth: kInputWidth,
      requiredHeight: kInputHeight,
      maintainAspectRatio: true,
      quality: FilterQuality.medium,
    );
    // final input = [inputImageList];
    return await _computerLock.synchronized(() async {
      final inputShape = [
        1,
        3,
        kInputHeight,
        kInputWidth,
      ];

      stopwatchDecoding.stop();
      _logger.info(
        'Image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
      );
      _logger.info('original size: $originalSize \n new size: $newSize');

      final (
        List<FaceDetectionRelative> relativeDetections,
        delaySentToIsolate,
        timeSentToMain
      ) = await _computer.compute(
        inferenceAndPostProcess,
        param: {
          'inputImageList': inputImageList,
          'inputShape': inputShape,
          'newSize': newSize,
          'sessionAddress': sessionAddress,
          'timeNow': DateTime.now(),
        },
      ) as (List<FaceDetectionRelative>, int, DateTime);

      final delaySentToMain =
          DateTime.now().difference(timeSentToMain).inMilliseconds;

      stopwatch.stop();
      _logger.info(
        'predictInIsolate() face detection executed in ${stopwatch.elapsedMilliseconds}ms, with ${delaySentToIsolate}ms delay sent to isolate, and ${delaySentToMain}ms delay sent to main, for a total of ${delaySentToIsolate + delaySentToMain}ms delay due to isolate',
      );

      return (relativeDetections, originalSize);
    });
  }

  /// Detects faces in the given image data.
  /// This method is optimized for batch processing.
  ///
  /// `imageDataList`: The image data to analyze.
  ///
  /// WARNING: Currently this method only returns the detections for the first image in the batch.
  /// Change the function to output all detection before actually using it in production.
  Future<List<FaceDetectionRelative>> predictBatch(
    List<Uint8List> imageDataList,
  ) async {
    assert(isInitialized);

    final stopwatch = Stopwatch()..start();

    final stopwatchDecoding = Stopwatch()..start();
    final List<Float32List> inputImageDataLists = [];
    final List<(Size, Size)> originalAndNewSizeList = [];
    int concatenatedImageInputsLength = 0;
    for (final imageData in imageDataList) {
      final (inputImageList, originalSize, newSize) =
          await ImageMlIsolate.instance.preprocessImageYoloOnnx(
        imageData,
        normalize: true,
        requiredWidth: kInputWidth,
        requiredHeight: kInputHeight,
        maintainAspectRatio: true,
        quality: FilterQuality.medium,
      );
      inputImageDataLists.add(inputImageList);
      originalAndNewSizeList.add((originalSize, newSize));
      concatenatedImageInputsLength += inputImageList.length;
    }

    final inputImageList = Float32List(concatenatedImageInputsLength);

    int offset = 0;
    for (int i = 0; i < inputImageDataLists.length; i++) {
      final inputImageData = inputImageDataLists[i];
      inputImageList.setRange(
        offset,
        offset + inputImageData.length,
        inputImageData,
      );
      offset += inputImageData.length;
    }

    // final input = [inputImageList];
    final inputShape = [
      inputImageDataLists.length,
      3,
      kInputHeight,
      kInputWidth,
    ];
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      inputShape,
    );
    final inputs = {'input': inputOrt};
    stopwatchDecoding.stop();
    _logger.info(
      'Image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
    );
    // _logger.info('original size: $originalSize \n new size: $newSize');

    _logger.info('interpreter.run is called');
    // Run inference
    final stopwatchInterpreter = Stopwatch()..start();
    List<OrtValue?>? outputs;
    try {
      final runOptions = OrtRunOptions();
      final session = OrtSession.fromAddress(sessionAddress);
      outputs = session.run(runOptions, inputs);
      inputOrt.release();
      runOptions.release();
    } catch (e, s) {
      _logger.severe('Error while running inference: $e \n $s');
      throw YOLOInterpreterRunException();
    }
    stopwatchInterpreter.stop();
    _logger.info(
      'interpreter.run is finished, in ${stopwatchInterpreter.elapsedMilliseconds} ms, or ${stopwatchInterpreter.elapsedMilliseconds / inputImageDataLists.length} ms per image',
    );

    _logger.info('outputs: $outputs');

    const int imageOutputToUse = 0;

    // // Get output tensors
    final nestedResults =
        outputs[0]?.value as List<List<List<double>>>; // [b, 25200, 16]
    final selectedResults = nestedResults[imageOutputToUse]; // [25200, 16]

    // final rawScores = <double>[];
    // for (final result in firstResults) {
    //   rawScores.add(result[4]);
    // }
    // final rawScoresCopy = List<double>.from(rawScores);
    // rawScoresCopy.sort();
    // _logger.info('rawScores minimum: ${rawScoresCopy.first}');
    // _logger.info('rawScores maximum: ${rawScoresCopy.last}');

    var relativeDetections = yoloOnnxFilterExtractDetections(
      kMinScoreSigmoidThreshold,
      kInputWidth,
      kInputHeight,
      results: selectedResults,
    );

    // Release outputs
    for (var element in outputs) {
      element?.release();
    }

    // Account for the fact that the aspect ratio was maintained
    for (final faceDetection in relativeDetections) {
      faceDetection.correctForMaintainedAspectRatio(
        Size(
          kInputWidth.toDouble(),
          kInputHeight.toDouble(),
        ),
        originalAndNewSizeList[imageOutputToUse].$2,
      );
    }

    // Non-maximum suppression to remove duplicate detections
    relativeDetections = naiveNonMaxSuppression(
      detections: relativeDetections,
      iouThreshold: kIouThreshold,
    );

    if (relativeDetections.isEmpty) {
      _logger.info('No face detected');
      return <FaceDetectionRelative>[];
    }

    stopwatch.stop();
    _logger.info(
      'predict() face detection executed in ${stopwatch.elapsedMilliseconds}ms',
    );

    return relativeDetections;
  }

  static List<FaceDetectionRelative> _yoloPostProcessOutputs(
    List<OrtValue?>? outputs,
    Size newSize,
  ) {
    // // Get output tensors
    final nestedResults =
        outputs?[0]?.value as List<List<List<double>>>; // [1, 25200, 16]
    final firstResults = nestedResults[0]; // [25200, 16]

    // final rawScores = <double>[];
    // for (final result in firstResults) {
    //   rawScores.add(result[4]);
    // }
    // final rawScoresCopy = List<double>.from(rawScores);
    // rawScoresCopy.sort();
    // _logger.info('rawScores minimum: ${rawScoresCopy.first}');
    // _logger.info('rawScores maximum: ${rawScoresCopy.last}');

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
        Size(
          kInputWidth.toDouble(),
          kInputHeight.toDouble(),
        ),
        newSize,
      );
    }

    // Non-maximum suppression to remove duplicate detections
    relativeDetections = naiveNonMaxSuppression(
      detections: relativeDetections,
      iouThreshold: kIouThreshold,
    );

    dev.log(
      '[YOLOFaceDetectionService] ${relativeDetections.length} faces detected',
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
      // _logger.info('Loading face embedding model');
      final session =
          OrtSession.fromFile(File(args["modelPath"]), sessionOptions);
      // _logger.info('Face embedding model loaded');
      return session.address;
    } catch (e, _) {
      // _logger.severe('Face embedding model not loaded', e, s);
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

  static Future<(List<FaceDetectionRelative>, int, DateTime)>
      inferenceAndPostProcess(
    Map args,
  ) async {
    final inputImageList = args['inputImageList'] as Float32List;
    final inputShape = args['inputShape'] as List<int>;
    final newSize = args['newSize'] as Size;
    final sessionAddress = args['sessionAddress'] as int;
    final timeSentToIsolate = args['timeNow'] as DateTime;
    final delaySentToIsolate =
        DateTime.now().difference(timeSentToIsolate).inMilliseconds;

    final Stopwatch stopwatchPrepare = Stopwatch()..start();
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      inputShape,
    );
    final inputs = {'input': inputOrt};
    stopwatchPrepare.stop();
    dev.log(
      '[YOLOFaceDetectionService] data preparation is finished, in ${stopwatchPrepare.elapsedMilliseconds}ms',
    );

    stopwatchPrepare.reset();
    stopwatchPrepare.start();
    final runOptions = OrtRunOptions();
    final session = OrtSession.fromAddress(sessionAddress);
    stopwatchPrepare.stop();
    dev.log(
      '[YOLOFaceDetectionService] session preparation is finished, in ${stopwatchPrepare.elapsedMilliseconds}ms',
    );

    final stopwatchInterpreter = Stopwatch()..start();
    late final List<OrtValue?> outputs;
    try {
      outputs = session.run(runOptions, inputs);
    } catch (e, s) {
      dev.log(
        '[YOLOFaceDetectionService] Error while running inference: $e \n $s',
      );
      throw YOLOInterpreterRunException();
    }
    stopwatchInterpreter.stop();
    dev.log(
      '[YOLOFaceDetectionService] interpreter.run is finished, in ${stopwatchInterpreter.elapsedMilliseconds} ms',
    );

    final relativeDetections = _yoloPostProcessOutputs(outputs, newSize);

    return (relativeDetections, delaySentToIsolate, DateTime.now());
  }
}
