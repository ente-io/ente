import "dart:io" show File;
import 'dart:typed_data' show Uint8List;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

enum IsolateOperation {
  /// [MLIndexingIsolate]
  analyzeImage,

  /// [MLIndexingIsolate]
  loadIndexingModels,

  /// [MLIndexingIsolate]
  releaseIndexingModels,

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

  /// [FaceClusteringService]
  linearIncrementalClustering
}

/// WARNING: Only return primitives unless you know the method is only going
/// to be used on regular isolates as opposed to DartUI and Flutter isolates
///  https://api.flutter.dev/flutter/dart-isolate/SendPort/send.html
Future<dynamic> isolateFunction(
  IsolateOperation function,
  Map<String, dynamic> args,
) async {
  switch (function) {
    /// Cases for MLIndexingIsolate start here

    /// MLIndexingIsolate
    case IsolateOperation.analyzeImage:
      final MLResult result = await analyzeImageStatic(args);
      return result.toJsonString();

    /// MLIndexingIsolate
    case IsolateOperation.loadIndexingModels:
      final modelNames = args['modelNames'] as List<String>;
      final modelPaths = args['modelPaths'] as List<String>;
      final addresses = <int>[];
      for (int i = 0; i < modelNames.length; i++) {
        // TODO:lau check logging here
        final int address = await MlModel.loadModel(
          modelNames[i],
          modelPaths[i],
        );
        addresses.add(address);
      }
      return List<int>.from(addresses, growable: false);

    /// MLIndexingIsolate
    case IsolateOperation.releaseIndexingModels:
      // TODO:lau check logging here
      final modelNames = args['modelNames'] as List<String>;
      final modelAddresses = args['modelAddresses'] as List<int>;
      for (int i = 0; i < modelNames.length; i++) {
        await MlModel.releaseModel(
          modelNames[i],
          modelAddresses[i],
        );
      }
      return true;

    /// Cases for MLIndexingIsolate stop here

    /// Cases for MLComputer start here

    /// MLComputer
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

    /// MLComputer
    case IsolateOperation.loadModel:
      final modelName = args['modelName'] as String;
      final modelPath = args['modelPath'] as String;
      final int address = await MlModel.loadModel(
        modelName,
        modelPath,
      );
      return address;

    /// MLComputer
    case IsolateOperation.initializeClipTokenizer:
      final vocabPath = args["vocabPath"] as String;
      await ClipTextTokenizer.instance.init(vocabPath);
      return true;

    /// MLComputer
    case IsolateOperation.runClipText:
      //TODO:lau check logging here
      final textEmbedding = await ClipTextEncoder.predict(args);
      return List<double>.from(textEmbedding, growable: false);

    /// MLComputer
    case IsolateOperation.testLogging:
      final logger = Logger('XXX MLComputerTestLogging');
      logger.info("XXX logging from isolate is working!!!");
      // throw Exception("XXX logging from isolate testing exception handling");
      return true;

    /// Cases for MLComputer end here

    /// Cases for FaceClusteringService start here

    /// FaceClusteringService
    case IsolateOperation.linearIncrementalClustering:
      final ClusteringResult result = runLinearClustering(args);
      return result;

    /// Cases for FaceClusteringService end here
  }
}
