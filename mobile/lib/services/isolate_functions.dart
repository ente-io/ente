import "dart:io" show File;
import 'dart:typed_data' show Uint8List;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart";
import "package:photos/utils/image_ml_util.dart";

enum IsolateOperation {
  /// [MLComputer]
  generateFaceThumbnails,

  /// [MLComputer]
  loadModel,

  /// [MLComputer]
  initializeClipTokenizer,

  /// [MLComputer]
  runClipText,

  /// [MLComputer]
  testLogging,
}

/// WARNING: Only return primitives unless you know the method is only going
/// to be used on regular isolates as opposed to DartUI and Flutter isolates
///  https://api.flutter.dev/flutter/dart-isolate/SendPort/send.html
Future<dynamic> isolateFunction(
  IsolateOperation function,
  Map<String, dynamic> args,
) async {
  switch (function) {
    // Cases for MLComputer
    case IsolateOperation.generateFaceThumbnails:
      final imagePath = args['imagePath'] as String;
      final Uint8List imageData = await File(imagePath).readAsBytes();
      final faceBoxesJson = args['faceBoxesList'] as List<Map<String, dynamic>>;
      final List<FaceBox> faceBoxes =
          faceBoxesJson.map((json) => FaceBox.fromJson(json)).toList();
      final List<Uint8List> results = await generateFaceThumbnailsUsingCanvas(
        imageData,
        faceBoxes,
      );
      return List.from(results);
    case IsolateOperation.loadModel:
      final modelName = args['modelName'] as String;
      final modelPath = args['modelPath'] as String;
      final int address = await MlModel.loadModel(
        modelName,
        modelPath,
      );
      return address;
    case IsolateOperation.initializeClipTokenizer:
      final vocabPath = args["vocabPath"] as String;
      await ClipTextTokenizer.instance.init(vocabPath);
      return true;
    case IsolateOperation.runClipText:
      //TODO:lau check logging here
      final textEmbedding = await ClipTextEncoder.predict(args);
      return List<double>.from(textEmbedding, growable: false);
    case IsolateOperation.testLogging:
      final logger = Logger('XXX MLComputerTestLogging');
      logger.info("XXX logging from isolate is working!!!");
      throw Exception("XXX logging from isolate testing exception handling");
      return true;
  }
}
