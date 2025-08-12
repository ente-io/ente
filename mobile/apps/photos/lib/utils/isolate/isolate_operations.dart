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
import "package:photos/src/rust/frb_generated.dart" show RustLib;
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

final Map<String, dynamic> _isolateCache = {};

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
      final MLResult result = await analyzeImageStatic(args);
      return result.toJsonString();

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
      final faceBoxesJson = args['faceBoxesList'] as List<Map<String, dynamic>>;
      final List<FaceBox> faceBoxes =
          faceBoxesJson.map((json) => FaceBox.fromJson(json)).toList();
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
      _ensureRustDisposed();
      _isolateCache.clear();
      return true;

    /// Cases for Caching stop here
  }
}

Future<void> _ensureRustLoaded() async {
  final bool loaded = _isolateCache["rustLibLoaded"] as bool? ?? false;
  if (!loaded) {
    await RustLib.init();
    _isolateCache["rustLibLoaded"] = true;
  }
}

void _ensureRustDisposed() {
  final bool loaded = _isolateCache["rustLibLoaded"] as bool? ?? false;
  if (loaded) {
    RustLib.dispose();
    _isolateCache.remove("rustLibLoaded");
  }
}
