import 'dart:isolate';
import "dart:typed_data";

import 'package:image/image.dart' as imgLib;
import 'package:photos/services/object_detection/tflite/cocossd_classifier.dart';
import "package:photos/services/object_detection/tflite/mobilenet_classifier.dart";
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String debugName = "InferenceIsolate";

  late SendPort _sendPort;
  final _receivePort = ReceivePort();

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      final classifier = isolateData.type == ClassifierType.cocossd
          ? CocoSSDClassifier(
              interpreter:
                  Interpreter.fromAddress(isolateData.interpreterAddress),
              labels: isolateData.labels,
            )
          : MobileNetClassifier(
              interpreter:
                  Interpreter.fromAddress(isolateData.interpreterAddress),
              labels: isolateData.labels,
            );
      final image = imgLib.decodeImage(isolateData.input);
      final results = classifier.predict(image!);
      isolateData.responsePort.send(results);
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  Uint8List input;
  int interpreterAddress;
  List<String> labels;
  ClassifierType type;
  late SendPort responsePort;

  IsolateData(
    this.input,
    this.interpreterAddress,
    this.labels,
    this.type,
  );
}

enum ClassifierType {
  cocossd,
  mobilenet,
}
