import 'dart:async';
import "dart:io" show File;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import "package:dart_ui_isolate/dart_ui_isolate.dart";
import "package:logging/logging.dart";
import "package:photos/face/model/box.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:synchronized/synchronized.dart";

enum ImageOperation {
  generateFaceThumbnails,
}

class ImageIsolate {
  final _logger = Logger('ImageIsolate');

  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 60);
  int _activeTasks = 0;

  final _initLock = Lock();
  final _functionLock = Lock();

  late DartUiIsolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;

  // Singleton pattern
  ImageIsolate._privateConstructor();
  static final ImageIsolate instance = ImageIsolate._privateConstructor();
  factory ImageIsolate() => instance;

  Future<void> init() async {
    return _initLock.synchronized(() async {
      if (isSpawned) return;

      _receivePort = ReceivePort();

      try {
        _isolate = await DartUiIsolate.spawn(
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

  Future<void> ensureSpawned() async {
    if (!isSpawned) {
      await init();
    }
  }

  @pragma('vm:entry-point')
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = ImageOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case ImageOperation.generateFaceThumbnails:
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
        }
      } catch (e, stackTrace) {
        sendPort
            .send({'error': e.toString(), 'stackTrace': stackTrace.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (ImageOperation, Map<String, dynamic>) message,
  ) async {
    await ensureSpawned();
    return _functionLock.synchronized(() async {
      _resetInactivityTimer();
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
        dispose();
      }
    });
  }

  /// Disposes the isolate worker.
  void dispose() {
    if (!isSpawned) return;

    isSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
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
        ImageOperation.generateFaceThumbnails,
        {
          'imagePath': imagePath,
          'faceBoxesList': faceBoxesJson,
        },
      ),
    ).then((value) => value.cast<Uint8List>());
  }
}
