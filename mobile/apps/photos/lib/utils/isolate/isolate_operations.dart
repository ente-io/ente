import 'dart:typed_data' show Uint8List, Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:ml_linalg/linalg.dart";
import "package:photos/db/ml/clip_vector_db.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart";
import "package:photos/services/machine_learning/ml_constants.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart";
import "package:photos/services/machine_learning/semantic_search/query_result.dart";
import "package:photos/src/rust/api/image_processing_api.dart"
    as rust_image_processing;
import "package:photos/src/rust/api/ml_indexing_api.dart" as rust_ml;
import "package:photos/src/rust/frb_generated.dart" show EntePhotosRust;
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

final Map<String, dynamic> _isolateCache = {};
const _rustLibLoadedCacheKey = "rustLibLoaded";
const _rustMlRuntimeConfigCacheKey = "rustMlRuntimeConfig";

enum IsolateOperation {
  /// [MLIndexingIsolate]
  analyzeImage,

  /// [MLIndexingIsolate]
  prepareRustMlRuntime,

  /// [MLIndexingIsolate]
  releaseRustMlRuntime,

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
  computeBulkSimilarities,

  /// [MLComputer]
  bulkVectorSearch,

  /// [MLComputer]
  bulkVectorSearchWithKeys,

  /// [FaceClusteringService]
  linearIncrementalClustering,

  /// Cache operations
  setIsolateCache,
  clearIsolateCache,
  clearAllIsolateCache,
}

/// WARNING: Only return primitives unless you know the method is only going
/// to be used on regular isolates as opposed to DartUI and Flutter isolates
///  https://api.flutter.dev/flutter/dart-isolate/SendPort/send.html
Future<dynamic> isolateFunction(
  IsolateOperation function,
  Map<String, dynamic> args,
) async {
  switch (function) {
    case IsolateOperation.bulkVectorSearchWithKeys:
      await _ensureRustLoaded();
      final potentialKeys = args["potentialKeys"] as Uint64List;
      final exact = args["exact"] as bool;

      return ClipVectorDB.instance.bulkSearchWithKeys(
        potentialKeys,
        BigInt.from(100),
        exact: exact,
      );

    case IsolateOperation.bulkVectorSearch:
      await _ensureRustLoaded();
      final clipFloat32 = args["clipFloat32"] as List<Float32List>;
      final exact = args["exact"] as bool;

      return ClipVectorDB.instance.bulkSearchVectors(
        clipFloat32,
        BigInt.from(100),
        exact: exact,
      );

    /// Cases for MLIndexingIsolate start here

    /// MLIndexingIsolate
    case IsolateOperation.analyzeImage:
      final bool useRustMl = args["useRustMl"] as bool? ?? false;
      if (useRustMl) {
        await _ensureRustLoaded();
      }
      final MLResult result = useRustMl
          ? await analyzeImageRust(args)
          : await analyzeImageStatic(args);
      return result.toJsonString();

    /// MLIndexingIsolate
    case IsolateOperation.prepareRustMlRuntime:
      await _ensureRustLoaded();
      await _ensureRustRuntimePrepared(args);
      return true;

    /// MLIndexingIsolate
    case IsolateOperation.releaseRustMlRuntime:
      await _releaseRustRuntime();
      return true;

    /// MLIndexingIsolate
    case IsolateOperation.loadIndexingModels:
      final modelNames = args['modelNames'] as List<String>;
      final modelPaths = args['modelPaths'] as List<String>;
      final addresses = <int>[];
      for (int i = 0; i < modelNames.length; i++) {
        final int address = await MlModel.loadModel(
          modelNames[i],
          modelPaths[i],
        );
        addresses.add(address);
      }
      return List<int>.from(addresses, growable: false);

    /// MLIndexingIsolate
    case IsolateOperation.releaseIndexingModels:
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
      final useRustForFaceThumbnails =
          args['useRustForFaceThumbnails'] as bool? ?? false;
      final faceBoxesJson = args['faceBoxesList'] as List<Map<String, dynamic>>;
      final List<FaceBox> faceBoxes =
          faceBoxesJson.map((json) => FaceBox.fromJson(json)).toList();
      if (useRustForFaceThumbnails) {
        await _ensureRustLoaded();
        final rustFaceBoxes = faceBoxes
            .map(
              (box) => rust_image_processing.RustFaceBox(
                x: box.x,
                y: box.y,
                width: box.width,
                height: box.height,
              ),
            )
            .toList(growable: false);
        final List<Uint8List> results =
            await rust_image_processing.generateFaceThumbnails(
          imagePath: imagePath,
          faceBoxes: rustFaceBoxes,
        );
        return List.from(results);
      }
      final List<Uint8List> results = await generateFaceThumbnailsUsingCanvas(
        imagePath,
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
      final textEmbedding = await ClipTextEncoder.predict(args);
      return List<double>.from(textEmbedding, growable: false);

    /// MLComputer
    case IsolateOperation.computeBulkSimilarities:
      final imageEmbeddings =
          _isolateCache[imageEmbeddingsKey] as List<EmbeddingVector>;
      final textEmbedding =
          args["textQueryToEmbeddingMap"] as Map<String, List<double>>;
      final minimumSimilarityMap =
          args["minimumSimilarityMap"] as Map<String, double>;
      final result = <String, List<QueryResult>>{};
      for (final MapEntry<String, List<double>> entry
          in textEmbedding.entries) {
        final query = entry.key;
        final textVector = Vector.fromList(entry.value);
        final minimumSimilarity = minimumSimilarityMap[query]!;
        final queryResults = <QueryResult>[];
        for (final imageEmbedding in imageEmbeddings) {
          final similarity = imageEmbedding.vector.dot(textVector);
          if (similarity >= minimumSimilarity) {
            queryResults.add(QueryResult(imageEmbedding.fileID, similarity));
          }
        }
        queryResults
            .sort((first, second) => second.score.compareTo(first.score));
        result[query] = queryResults;
      }
      return result;

    /// Cases for MLComputer end here

    /// Cases for FaceClusteringService start here

    /// FaceClusteringService
    case IsolateOperation.linearIncrementalClustering:
      final ClusteringResult result = runLinearClustering(args);
      return result;

    /// Cases for FaceClusteringService end here

    /// Cases for Caching start here

    /// Caching
    case IsolateOperation.setIsolateCache:
      final key = args['key'] as String;
      final value = args['value'];
      _isolateCache[key] = value;
      return true;

    /// Caching
    case IsolateOperation.clearIsolateCache:
      final key = args['key'] as String;
      _isolateCache.remove(key);
      return true;

    /// Caching
    case IsolateOperation.clearAllIsolateCache:
      await _ensureRustDisposed();
      _isolateCache.clear();
      return true;

    /// Cases for Caching stop here
  }
}

Future<void> _ensureRustLoaded() async {
  final bool loaded = _isolateCache[_rustLibLoadedCacheKey] as bool? ?? false;
  if (!loaded) {
    await EntePhotosRust.init();
    _isolateCache[_rustLibLoadedCacheKey] = true;
  }
}

Future<void> _ensureRustDisposed() async {
  final bool loaded = _isolateCache[_rustLibLoadedCacheKey] as bool? ?? false;
  if (loaded) {
    await _releaseRustRuntime();
    EntePhotosRust.dispose();
    _isolateCache.remove(_rustLibLoadedCacheKey);
  }
}

Future<void> _ensureRustRuntimePrepared(Map<String, dynamic> args) async {
  final modelPaths = rust_ml.RustModelPaths(
    faceDetection: (args["faceDetectionModelPath"] as String?) ?? "",
    faceEmbedding: (args["faceEmbeddingModelPath"] as String?) ?? "",
    clipImage: (args["clipImageModelPath"] as String?) ?? "",
  );
  final providerPolicy = rust_ml.RustExecutionProviderPolicy(
    preferCoreml: args["preferCoreml"] as bool? ?? true,
    preferNnapi: args["preferNnapi"] as bool? ?? true,
    preferXnnpack: args["preferXnnpack"] as bool? ?? false,
    allowCpuFallback: args["allowCpuFallback"] as bool? ?? true,
  );
  final runtimeConfigKey = _runtimeConfigCacheKey(modelPaths, providerPolicy);
  final currentConfigKey =
      _isolateCache[_rustMlRuntimeConfigCacheKey] as String?;
  if (currentConfigKey == runtimeConfigKey) {
    return;
  }

  final missingModelPaths = <String>[];
  if (modelPaths.faceDetection.trim().isEmpty) {
    missingModelPaths.add("faceDetectionModelPath");
  }
  if (modelPaths.faceEmbedding.trim().isEmpty) {
    missingModelPaths.add("faceEmbeddingModelPath");
  }
  if (modelPaths.clipImage.trim().isEmpty) {
    missingModelPaths.add("clipImageModelPath");
  }
  if (missingModelPaths.isNotEmpty) {
    throw Exception(
      "RustMLMissingModelPath: Missing required model paths: ${missingModelPaths.join(', ')}",
    );
  }

  await rust_ml.initMlRuntime(
    config: rust_ml.RustMlRuntimeConfig(
      modelPaths: modelPaths,
      providerPolicy: providerPolicy,
    ),
  );
  _isolateCache[_rustMlRuntimeConfigCacheKey] = runtimeConfigKey;
}

Future<void> _releaseRustRuntime() async {
  final bool loaded = _isolateCache[_rustLibLoadedCacheKey] as bool? ?? false;
  if (!loaded) {
    return;
  }
  try {
    await rust_ml.releaseMlRuntime();
  } catch (_) {
    // no-op: runtime release is best-effort before process-wide bridge dispose.
  }
  _isolateCache.remove(_rustMlRuntimeConfigCacheKey);
}

String _runtimeConfigCacheKey(
  rust_ml.RustModelPaths modelPaths,
  rust_ml.RustExecutionProviderPolicy providerPolicy,
) {
  return [
    modelPaths.faceDetection,
    modelPaths.faceEmbedding,
    modelPaths.clipImage,
    providerPolicy.preferCoreml,
    providerPolicy.preferNnapi,
    providerPolicy.preferXnnpack,
    providerPolicy.allowCpuFallback,
  ].join("|");
}
