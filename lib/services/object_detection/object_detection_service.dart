import "dart:isolate";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/services/object_detection/models/predictions.dart";
import 'package:photos/services/object_detection/models/recognition.dart';
import "package:photos/services/object_detection/tflite/classifier.dart";
import "package:photos/services/object_detection/utils/isolate_utils.dart";

class ObjectDetectionService {
  static const scoreThreshold = 0.6;

  final _logger = Logger("ObjectDetectionService");

  /// Instance of [ObjectClassifier]
  late ObjectClassifier _classifier;

  /// Instance of [IsolateUtils]
  late IsolateUtils _isolateUtils;

  ObjectDetectionService._privateConstructor();

  Future<void> init() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.start();
    _classifier = ObjectClassifier();
  }

  static ObjectDetectionService instance =
      ObjectDetectionService._privateConstructor();

  Future<List<String>> predict(Uint8List bytes) async {
    try {
      final isolateData = IsolateData(
        bytes,
        _classifier.interpreter.address,
        _classifier.labels,
      );
      final predictions = await _inference(isolateData);
      final Set<String> results = {};
      for (final Recognition result in predictions.recognitions) {
        if (result.score > scoreThreshold) {
          results.add(result.label);
        }
      }
      return results.toList();
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
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
