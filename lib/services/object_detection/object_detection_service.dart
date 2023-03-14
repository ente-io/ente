import "dart:isolate";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/services/object_detection/models/predictions.dart";
import 'package:photos/services/object_detection/models/recognition.dart';
import 'package:photos/services/object_detection/tflite/cocossd_classifier.dart';
import "package:photos/services/object_detection/tflite/mobilenet_classifier.dart";
import "package:photos/services/object_detection/utils/isolate_utils.dart";

class ObjectDetectionService {
  static const scoreThreshold = 0.5;

  final _logger = Logger("ObjectDetectionService");

  late CocoSSDClassifier _objectClassifier;
  late MobileNetClassifier _mobileNetClassifier;

  late IsolateUtils _isolateUtils;

  ObjectDetectionService._privateConstructor();

  Future<void> init() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.start();
    _objectClassifier = CocoSSDClassifier();
    _mobileNetClassifier = MobileNetClassifier();
  }

  static ObjectDetectionService instance =
      ObjectDetectionService._privateConstructor();

  Future<List<String>> predict(Uint8List bytes) async {
    try {
      final results = <String>{};
      final objectResults = await _getObjects(bytes);
      results.addAll(objectResults);
      final mobileNetResults = await _getMobileNetResults(bytes);
      results.addAll(mobileNetResults);
      return results.toList();
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<List<String>> _getObjects(Uint8List bytes) async {
    final isolateData = IsolateData(
      bytes,
      _objectClassifier.interpreter.address,
      _objectClassifier.labels,
      ClassifierType.cocossd,
    );
    final predictions = await _inference(isolateData);
    final Set<String> results = {};
    for (final Recognition result in predictions.recognitions) {
      if (result.score > scoreThreshold) {
        results.add(result.label);
      }
    }
    return results.toList();
  }

  Future<List<String>> _getMobileNetResults(Uint8List bytes) async {
    final isolateData = IsolateData(
      bytes,
      _mobileNetClassifier.interpreter.address,
      _mobileNetClassifier.labels,
      ClassifierType.mobilenet,
    );
    final predictions = await _inference(isolateData);
    final Set<String> results = {};
    for (final Recognition result in predictions.recognitions) {
      if (result.score > scoreThreshold) {
        results.add(result.label);
      }
    }
    return results.toList();
  }

  /// Runs inference in another isolate
  Future<Predictions> _inference(IsolateData isolateData) async {
    final responsePort = ReceivePort();
    _isolateUtils.sendPort.send(
      isolateData..responsePort = responsePort.sendPort,
    );
    return await responsePort.first;
  }
}
