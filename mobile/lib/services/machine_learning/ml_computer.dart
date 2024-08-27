import 'dart:async';
import "dart:io" show File;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import "package:dart_ui_isolate/dart_ui_isolate.dart";
import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:synchronized/synchronized.dart";

enum MLComputerOperation {
  generateFaceThumbnails,
  loadModel,
  initializeClipTokenizer,
  runClipText,
}

class MLComputer {
  final _logger = Logger('MLComputer');

  final _initLock = Lock();
  final _functionLock = Lock();
  final _initModelLock = Lock();

  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;

  // Singleton pattern
  MLComputer._privateConstructor();
  static final MLComputer instance = MLComputer._privateConstructor();
  factory MLComputer() => instance;

  Future<void> _init() async {
    return _initLock.synchronized(() async {
      if (isSpawned) return;

      _receivePort = ReceivePort();

      try {
        await DartUiIsolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        isSpawned = true;
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        isSpawned = false;
      }
    });
  }

  @pragma('vm:entry-point')
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = MLComputerOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case MLComputerOperation.generateFaceThumbnails:
            final imagePath = args['imagePath'] as String;
            final Uint8List imageData = await File(imagePath).readAsBytes();
            final faceBoxesJson =
                args['faceBoxesList'] as List<Map<String, dynamic>>;
            final List<FaceBox> faceBoxes =
                faceBoxesJson.map((json) => FaceBox.fromJson(json)).toList();
            final List<Uint8List> results =
                await generateFaceThumbnailsUsingCanvas(
              imageData,
              faceBoxes,
            );
            sendPort.send(List.from(results));
          case MLComputerOperation.loadModel:
            final modelName = args['modelName'] as String;
            final modelPath = args['modelPath'] as String;
            final int address = await MlModel.loadModel(
              modelName,
              modelPath,
            );
            sendPort.send(address);
            break;
          case MLComputerOperation.initializeClipTokenizer:
            final vocabPath = args["vocabPath"] as String;
            await ClipTextTokenizer.instance.init(vocabPath);
            sendPort.send(true);
            break;
          case MLComputerOperation.runClipText:
            final textEmbedding = await ClipTextEncoder.predict(args);
            sendPort.send(List<double>.from(textEmbedding, growable: false));
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
    (MLComputerOperation, Map<String, dynamic>) message,
  ) async {
    await _init();
    return _functionLock.synchronized(() async {
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
    });
  }

  /// Generates face thumbnails for all [faceBoxes] in [imageData].
  ///
  /// Uses [generateFaceThumbnailsUsingCanvas] inside the isolate.
  Future<List<Uint8List>> generateFaceThumbnails(
    String imagePath,
    List<FaceBox> faceBoxes,
  ) async {
    final List<Map<String, dynamic>> faceBoxesJson =
        faceBoxes.map((box) => box.toJson()).toList();
    return await _runInIsolate(
      (
        MLComputerOperation.generateFaceThumbnails,
        {
          'imagePath': imagePath,
          'faceBoxesList': faceBoxesJson,
        },
      ),
    ).then((value) => value.cast<Uint8List>());
  }

  Future<List<double>> runClipText(String query) async {
    try {
      await _ensureLoadedClipTextModel();
      final int clipAddress = ClipTextEncoder.instance.sessionAddress;
      final textEmbedding = await _runInIsolate(
        (
          MLComputerOperation.runClipText,
          {
            "text": query,
            "address": clipAddress,
          }
        ),
      ) as List<double>;
      return textEmbedding;
    } catch (e, s) {
      _logger.severe("Could not run clip text in isolate", e, s);
      rethrow;
    }
  }

  Future<void> _ensureLoadedClipTextModel() async {
    return _initModelLock.synchronized(() async {
      if (ClipTextEncoder.instance.isInitialized) return;
      try {
        // Initialize ClipText tokenizer
        final String tokenizerRemotePath =
            ClipTextEncoder.instance.vocabRemotePath;
        final String tokenizerVocabPath = await RemoteAssetsService.instance
            .getAssetPath(tokenizerRemotePath);
        await _runInIsolate(
          (
            MLComputerOperation.initializeClipTokenizer,
            {'vocabPath': tokenizerVocabPath},
          ),
        );

        // Load ClipText model
        final String modelName = ClipTextEncoder.instance.modelName;
        final String? modelPath = await ClipTextEncoder.instance.downloadModelSafe();
        if (modelPath == null) {
          throw Exception("Could not download clip text model, no wifi");
        }
        final address = await _runInIsolate(
          (
            MLComputerOperation.loadModel,
            {
              'modelName': modelName,
              'modelPath': modelPath,
            },
          ),
        ) as int;
        ClipTextEncoder.instance.storeSessionAddress(address);
      } catch (e, s) {
        _logger.severe("Could not load clip text model in MLComputer", e, s);
        rethrow;
      }
    });
  }
}
