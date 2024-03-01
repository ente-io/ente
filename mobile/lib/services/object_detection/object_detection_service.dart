// import "dart:isolate";
// import "dart:math";
// import "dart:typed_data";

// import "package:logging/logging.dart";
// import "package:photos/services/object_detection/models/predictions.dart";
// import 'package:photos/services/object_detection/models/recognition.dart';
// import 'package:photos/services/object_detection/tflite/cocossd_classifier.dart';
// import "package:photos/services/object_detection/tflite/mobilenet_classifier.dart";
// import "package:photos/services/object_detection/tflite/scene_classifier.dart";
// import "package:photos/services/object_detection/utils/isolate_utils.dart";

// class ObjectDetectionService {
//   static const scoreThreshold = 0.35;

//   final _logger = Logger("ObjectDetectionService");

//   late CocoSSDClassifier _objectClassifier;
//   late MobileNetClassifier _mobileNetClassifier;
//   late SceneClassifier _sceneClassifier;

//   late IsolateUtils _isolateUtils;

//   ObjectDetectionService._privateConstructor();
//   bool inInitiated = false;

//   Future<void> init() async {
//     _isolateUtils = IsolateUtils();
//     await _isolateUtils.start();
//     try {
//       _objectClassifier = CocoSSDClassifier();
//     } catch (e, s) {
//       _logger.severe("Could not initialize cocossd", e, s);
//     }
//     try {
//       _mobileNetClassifier = MobileNetClassifier();
//     } catch (e, s) {
//       _logger.severe("Could not initialize mobilenet", e, s);
//     }
//     try {
//       _sceneClassifier = SceneClassifier();
//     } catch (e, s) {
//       _logger.severe("Could not initialize sceneclassifier", e, s);
//     }
//     inInitiated = true;
//   }

//   static ObjectDetectionService instance =
//       ObjectDetectionService._privateConstructor();

//   Future<Map<String, double>> predict(Uint8List bytes) async {
//     try {
//       if (!inInitiated) {
//         return Future.error("ObjectDetectionService init is not completed");
//       }
//       final results = <String, double>{};
//       final methods = [_getObjects, _getMobileNetResults, _getSceneResults];

//       for (var method in methods) {
//         final methodResults = await method(bytes);
//         methodResults.forEach((key, value) {
//           results.update(
//             key,
//             (existingValue) => max(existingValue, value),
//             ifAbsent: () => value,
//           );
//         });
//       }
//       return results;
//     } catch (e, s) {
//       _logger.severe(e, s);
//       rethrow;
//     }
//   }

//   Future<Map<String, double>> _getObjects(Uint8List bytes) async {
//     try {
//       final isolateData = IsolateData(
//         bytes,
//         _objectClassifier.interpreter.address,
//         _objectClassifier.labels,
//         ClassifierType.cocossd,
//       );
//       return _getPredictions(isolateData);
//     } catch (e, s) {
//       _logger.severe("Could not run cocossd", e, s);
//     }
//     return {};
//   }

//   Future<Map<String, double>> _getMobileNetResults(Uint8List bytes) async {
//     try {
//       final isolateData = IsolateData(
//         bytes,
//         _mobileNetClassifier.interpreter.address,
//         _mobileNetClassifier.labels,
//         ClassifierType.mobilenet,
//       );
//       return _getPredictions(isolateData);
//     } catch (e, s) {
//       _logger.severe("Could not run mobilenet", e, s);
//     }
//     return {};
//   }

//   Future<Map<String, double>> _getSceneResults(Uint8List bytes) async {
//     try {
//       final isolateData = IsolateData(
//         bytes,
//         _sceneClassifier.interpreter.address,
//         _sceneClassifier.labels,
//         ClassifierType.scenes,
//       );
//       return _getPredictions(isolateData);
//     } catch (e, s) {
//       _logger.severe("Could not run scene detection", e, s);
//     }
//     return {};
//   }

//   Future<Map<String, double>> _getPredictions(IsolateData isolateData) async {
//     final predictions = await _inference(isolateData);
//     final Map<String, double> results = {};

//     if (predictions.error == null) {
//       for (final Recognition result in predictions.recognitions!) {
//         if (result.score > scoreThreshold) {
//           // Update the result score only if it's higher than the current score
//           if (!results.containsKey(result.label) ||
//               results[result.label]! < result.score) {
//             results[result.label] = result.score;
//           }
//         }
//       }

//       _logger.info(
//         "Time taken for ${isolateData.type}: ${predictions.stats!.totalElapsedTime}ms",
//       );
//     } else {
//       _logger.severe(
//         "Error while fetching predictions for ${isolateData.type}",
//         predictions.error,
//       );
//     }

//     return results;
//   }

//   /// Runs inference in another isolate
//   Future<Predictions> _inference(IsolateData isolateData) async {
//     final responsePort = ReceivePort();
//     _isolateUtils.sendPort.send(
//       isolateData..responsePort = responsePort.sendPort,
//     );
//     return await responsePort.first;
//   }
// }
