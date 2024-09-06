import "dart:async";

import "package:flutter/foundation.dart" show debugPrint;
import "package:logging/logging.dart";
import "package:photos/services/isolate_functions.dart";
import "package:photos/services/isolate_service.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import "package:photos/services/machine_learning/ml_models_overview.dart";
import 'package:photos/services/machine_learning/ml_result.dart';
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/utils/ml_util.dart";

class MLIndexingIsolate extends SuperIsolate {
  @override
  Logger get logger => _logger;
  final _logger = Logger("MLIndexingIsolate");

  @override
  bool get isDartUiIsolate => true;

  @override
  String get isolateName => "MLIndexingIsolate";

  @override
  bool get shouldAutomaticDispose => true;

  @override
  Future<void> onDispose() async {
    await _releaseModels();
  }

  @override
  bool postFunctionlockStop(IsolateOperation operation) {
    if (operation == IsolateOperation.analyzeImage &&
        shouldPauseIndexingAndClustering) {
      return true;
    }
    return false;
  }

  bool shouldPauseIndexingAndClustering = false;

  // Singleton pattern
  MLIndexingIsolate._privateConstructor();
  static final instance = MLIndexingIsolate._privateConstructor();
  factory MLIndexingIsolate() => instance;

  /// Analyzes the given image data by running the full pipeline for faces, using [analyzeImageStatic] in the isolate.
  Future<MLResult?> analyzeImage(
    FileMLInstruction instruction,
    String filePath,
  ) async {
    late MLResult result;

    try {
      final resultJsonString =
          await runInIsolate(IsolateOperation.analyzeImage, {
        "enteFileID": instruction.file.uploadedFileID ?? -1,
        "filePath": filePath,
        "runFaces": instruction.shouldRunFaces,
        "runClip": instruction.shouldRunClip,
        "faceDetectionAddress": FaceDetectionService.instance.sessionAddress,
        "faceEmbeddingAddress": FaceEmbeddingService.instance.sessionAddress,
        "clipImageAddress": ClipImageEncoder.instance.sessionAddress,
      }) as String?;
      if (resultJsonString == null) {
        if (!shouldPauseIndexingAndClustering) {
          _logger.severe('Analyzing image in isolate is giving back null');
        }
        return null;
      }
      result = MLResult.fromJsonString(resultJsonString);
    } catch (e, s) {
      _logger.severe(
        "Could not analyze image with ID ${instruction.file.uploadedFileID} \n",
        e,
        s,
      );
      debugPrint(
        "This image with fileID ${instruction.file.uploadedFileID} has name ${instruction.file.displayName}.",
      );
      rethrow;
    }

    return result;
  }

  Future<void> loadModels({
    required bool loadFaces,
    required bool loadClip,
  }) async {
    if (!loadFaces && !loadClip) return;
    final List<MLModels> models = [];
    final List<String> modelNames = [];
    final List<String> modelPaths = [];
    if (loadFaces) {
      models.addAll([MLModels.faceDetection, MLModels.faceEmbedding]);
      final faceDetection =
          await FaceDetectionService.instance.getModelNameAndPath();
      modelNames.add(faceDetection.$1);
      modelPaths.add(faceDetection.$2);
      final faceEmbedding =
          await FaceEmbeddingService.instance.getModelNameAndPath();
      modelNames.add(faceEmbedding.$1);
      modelPaths.add(faceEmbedding.$2);
    }
    if (loadClip) {
      models.add(MLModels.clipImageEncoder);
      final clipImage = await ClipImageEncoder.instance.getModelNameAndPath();
      modelNames.add(clipImage.$1);
      modelPaths.add(clipImage.$2);
    }

    try {
      final addresses =
          await runInIsolate(IsolateOperation.loadIndexingModels, {
        "modelNames": modelNames,
        "modelPaths": modelPaths,
      }) as List<int>;
      for (int i = 0; i < models.length; i++) {
        final model = models[i].model;
        final address = addresses[i];
        model.storeSessionAddress(address);
      }
    } catch (e, s) {
      _logger.severe("Could not load models in MLIndexingIsolate", e, s);
      rethrow;
    }
  }

  Future<void> _releaseModels() async {
    final List<String> modelNames = [];
    final List<int> modelAddresses = [];
    final List<MLModels> models = [];
    for (final model in MLModels.values) {
      if (!model.isIndexingModel) continue;
      final mlModel = model.model;
      if (mlModel.isInitialized) {
        models.add(model);
        modelNames.add(mlModel.modelName);
        modelAddresses.add(mlModel.sessionAddress);
      }
    }
    if (modelNames.isEmpty) return;
    try {
      await runInIsolate(IsolateOperation.releaseIndexingModels, {
        "modelNames": modelNames,
        "modelAddresses": modelAddresses,
      });
      for (final model in models) {
        model.model.releaseSessionAddress();
      }
      _logger.info("Indexing models released in isolate");
    } catch (e, s) {
      _logger.severe("Could not release models in MLIndexingIsolate", e, s);
      rethrow;
    }
  }
}
