import "dart:async";
import "dart:io" show Platform;
import "dart:isolate";

import "package:dart_ui_isolate/dart_ui_isolate.dart";
import "package:flutter/foundation.dart" show debugPrint, kDebugMode;
import "package:logging/logging.dart";
import "package:photos/core/error-reporting/super_logging.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import 'package:photos/services/machine_learning/ml_result.dart';
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/ml_util.dart";
import "package:synchronized/synchronized.dart";

enum MLOperation { analyzeImage, loadModels, runClipText }

class MLIsolate {
  static final _logger = Logger("MLIsolate");

  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 120);
  int _activeTasks = 0;

  final _functionLock = Lock();
  final _initIsolateLock = Lock();

  late DartUiIsolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool _isIsolateSpawned = false;

  bool shouldPauseIndexingAndClustering = false;

  // Singleton pattern
  MLIsolate._privateConstructor();
  static final instance = MLIsolate._privateConstructor();
  factory MLIsolate() => instance;

  Future<void> _initIsolate() async {
    return _initIsolateLock.synchronized(() async {
      if (_isIsolateSpawned) return;
      _logger.info("initIsolate called");

      _receivePort = ReceivePort();

      try {
        _isolate = await DartUiIsolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        _isIsolateSpawned = true;

        _resetInactivityTimer();
        _logger.info('initIsolate done');
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        _isIsolateSpawned = false;
      }
    });
  }

  /// The main execution function of the isolate.
  @pragma('vm:entry-point')
  static void _isolateMain(SendPort mainSendPort) async {
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((LogRecord rec) {
      debugPrint('[MLIsolate] ${rec.toPrettyString()}');
    });
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = MLOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case MLOperation.analyzeImage:
            final time = DateTime.now();
            final MLResult result = await analyzeImageStatic(args);
            _logger.info(
              "`analyzeImageSync` function executed in ${DateTime.now().difference(time).inMilliseconds} ms",
            );
            sendPort.send(result.toJsonString());
            break;
          case MLOperation.loadModels:
            await FaceDetectionService.instance.loadModel(useEntePlugin: true);
            await FaceEmbeddingService.instance.loadModel(useEntePlugin: true);
            await ClipImageEncoder.instance.loadModel(useEntePlugin: true);
            sendPort.send(true);
            break;
          case MLOperation.runClipText:
            final textEmbedding = await ClipTextEncoder.predict(args);
            sendPort.send(List.from(textEmbedding, growable: false));
            break;
        }
      } catch (e, s) {
        _logger.severe("Error in FaceML isolate", e, s);
        sendPort.send({'error': e.toString(), 'stackTrace': s.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (MLOperation, Map<String, dynamic>) message,
  ) async {
    await _initIsolate();
    return _functionLock.synchronized(() async {
      _resetInactivityTimer();

      if (message.$1 == MLOperation.analyzeImage &&
          shouldPauseIndexingAndClustering) {
        return null;
      }

      final completer = Completer<dynamic>();
      final answerPort = ReceivePort();

      _activeTasks++;
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
      _activeTasks--;

      return completer.future;
    });
  }

  /// Resets a timer that kills the isolate after a certain amount of inactivity.
  ///
  /// Should be called after initialization (e.g. inside `init()`) and after every call to isolate (e.g. inside `_runInIsolate()`)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (_activeTasks > 0) {
        _logger.info('Tasks are still running. Delaying isolate disposal.');
        // Optionally, reschedule the timer to check again later.
        _resetInactivityTimer();
      } else {
        _logger.info(
          'Clustering Isolate has been inactive for ${_inactivityDuration.inSeconds} seconds with no tasks running. Killing isolate.',
        );
        _dispose();
      }
    });
  }

  void _dispose() async {
    if (!_isIsolateSpawned) return;
    _logger.info('Disposing isolate and models');
    // await _releaseModels(); TODO: Implement this
    _isIsolateSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  /// Analyzes the given image data by running the full pipeline for faces, using [_analyzeImageSync] in the isolate.
  Future<MLResult?> analyzeImage(
    FileMLInstruction instruction,
  ) async {
    final String filePath = await getImagePathForML(instruction.enteFile);

    final Stopwatch stopwatch = Stopwatch()..start();
    late MLResult result;

    try {
      final resultJsonString = await _runInIsolate(
        (
          MLOperation.analyzeImage,
          {
            "enteFileID": instruction.enteFile.uploadedFileID ?? -1,
            "filePath": filePath,
            "runFaces": instruction.shouldRunFaces,
            "runClip": instruction.shouldRunClip,
            "faceDetectionAddress":
                FaceDetectionService.instance.sessionAddress,
            "faceEmbeddingAddress":
                FaceEmbeddingService.instance.sessionAddress,
            "clipImageAddress": ClipImageEncoder.instance.sessionAddress,
          }
        ),
      ) as String?;
      if (resultJsonString == null) {
        if (!shouldPauseIndexingAndClustering) {
          _logger.severe('Analyzing image in isolate is giving back null');
        }
        return null;
      }
      result = MLResult.fromJsonString(resultJsonString);
    } catch (e, s) {
      _logger.severe(
        "Could not analyze image with ID ${instruction.enteFile.uploadedFileID} \n",
        e,
        s,
      );
      debugPrint(
        "This image with ID ${instruction.enteFile.uploadedFileID} has name ${instruction.enteFile.displayName}.",
      );
      final resultBuilder =
          MLResult.fromEnteFileID(instruction.enteFile.uploadedFileID!)
            ..errorOccurred();
      return resultBuilder;
    }
    stopwatch.stop();
    _logger.info(
      "Finished Analyze image with uploadedFileID ${instruction.enteFile.uploadedFileID}, in "
      "${stopwatch.elapsedMilliseconds} ms (including time waiting for inference engine availability)",
    );

    return result;
  }

  Future<List<double>> runClipText(String query) async {
    try {
      final int clipAddress = ClipTextEncoder.instance.sessionAddress;
      final String remotePath = ClipTextEncoder.instance.vocabRemotePath;
      final String tokenizerVocabPath =
          await RemoteAssetsService.instance.getAssetPath(remotePath);
      final textEmbedding = await _runInIsolate(
        (
          MLOperation.runClipText,
          {
            "text": query,
            "address": clipAddress,
            "vocabPath": tokenizerVocabPath,
            "useEntePlugin": Platform.isAndroid,
          }
        ),
      ) as List<double>;
      return textEmbedding;
    } catch (e, s) {
      _logger.severe("Could not run clip text in isolate", e, s);
      rethrow;
    }
  }

  Future<void> loadModels() async {
    try {
      await _runInIsolate(
        (MLOperation.loadModels, {}),
      );
    } catch (e, s) {
      _logger.severe("Could not load models in isolate", e, s);
      rethrow;
    }
  }
}
