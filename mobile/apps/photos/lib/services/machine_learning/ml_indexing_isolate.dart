import "dart:async";

import "package:flutter/foundation.dart" show debugPrint;
import "package:logging/logging.dart";
import 'package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart';
import 'package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart';
import "package:photos/services/machine_learning/ml_models_overview.dart";
import 'package:photos/services/machine_learning/ml_result.dart';
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/isolate/isolate_operations.dart";
import "package:photos/utils/isolate/super_isolate.dart";
import "package:photos/utils/ml_util.dart";
import "package:photos/utils/network_util.dart";
import "package:synchronized/synchronized.dart";

@pragma('vm:entry-point')
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

  int _loadedModelsCount = 0;
  int _deloadedModelsCount = 0;

  final _initModelLock = Lock();
  final _downloadModelLock = Lock();

  bool areModelsDownloaded = false;

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

  void triggerModelsDownload() {
    if (!areModelsDownloaded && !_downloadModelLock.locked) {
      _logger.info("Models not downloaded, starting download");
      unawaited(ensureDownloadedModels());
    }
  }

  Future<void> ensureDownloadedModels([bool forceRefresh = false]) async {
    if (_downloadModelLock.locked) {
      _logger.info("Download models already in progress");
      return;
    }
    return _downloadModelLock.synchronized(() async {
      if (areModelsDownloaded) {
        return;
      }
      final goodInternet = await canUseHighBandwidth();
      if (!goodInternet) {
        _logger.info(
          "Cannot download models because user is not connected to wifi",
        );
        return;
      }
      _logger.info('Downloading models');
      await Future.wait([
        FaceDetectionService.instance.downloadModel(forceRefresh),
        FaceEmbeddingService.instance.downloadModel(forceRefresh),
        ClipImageEncoder.instance.downloadModel(forceRefresh),
      ]);
      areModelsDownloaded = true;
      _logger.info('Downloaded models');
    });
  }

  Future<void> ensureLoadedModels(FileMLInstruction instruction) async {
    return _initModelLock.synchronized(() async {
      final faceDetectionLoaded = FaceDetectionService.instance.isInitialized;
      final faceEmbeddingLoaded = FaceEmbeddingService.instance.isInitialized;
      final facesModelsLoaded = faceDetectionLoaded && faceEmbeddingLoaded;
      final clipModelsLoaded = ClipImageEncoder.instance.isInitialized;

      final shouldLoadFaces = instruction.shouldRunFaces && !facesModelsLoaded;
      final shouldLoadClip = instruction.shouldRunClip && !clipModelsLoaded;
      if (!shouldLoadFaces && !shouldLoadClip) {
        return;
      }

      _logger.info(
        'Loading models. faces: $shouldLoadFaces, clip: $shouldLoadClip',
      );
      _loadedModelsCount++;
      _logger.info(
        "Loaded models count: $_loadedModelsCount, deloaded models count: $_deloadedModelsCount",
      );
      await MLIndexingIsolate.instance
          ._loadModels(loadFaces: shouldLoadFaces, loadClip: shouldLoadClip);
      _logger.info('Models loaded');
    });
  }

  Future<void> _loadModels({
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

  /// WARNING: This method is only for debugging purposes. It should not be used in production.
  Future<void> debugLoadSingleModel(MLModels model) {
    return _initModelLock.synchronized(() async {
      final modelInstance = model.model;
      if (modelInstance.isInitialized) {
        _logger.info("Model ${model.name} already loaded");
        return;
      }
      final modelName = modelInstance.modelName;
      final modelPath = await modelInstance.downloadModelSafe();
      if (modelPath == null) {
        _logger.severe("Could not download model, no wifi");
        return;
      }
      final address = await runInIsolate(IsolateOperation.loadModel, {
        "modelName": modelName,
        "modelPath": modelPath,
      }) as int;
      modelInstance.storeSessionAddress(address);
    });
  }

  Future<void> cleanupLocalIndexingModels({bool delete = false}) async {
    if (!areModelsDownloaded) return;
    await _releaseModels();

    if (delete) {
      final List<String> remoteModelPaths = [];

      for (final model in MLModels.values) {
        if (!model.isIndexingModel) continue;
        final mlModel = model.model;
        remoteModelPaths.add(mlModel.modelRemotePath);
      }
      await RemoteAssetsService.instance
          .cleanupSelectedModels(remoteModelPaths);

      areModelsDownloaded = false;
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
      _logger.info("Releasing models $modelNames");
      _deloadedModelsCount++;
      _logger.info(
        "Loaded models count: $_loadedModelsCount, deloaded models count: $_deloadedModelsCount",
      );
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
