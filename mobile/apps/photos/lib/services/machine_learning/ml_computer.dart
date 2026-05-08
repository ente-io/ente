import 'dart:async';
import "dart:io" show Platform;
import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart"
    show Uint64List;
import "package:logging/logging.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart"
    show flagService, isLocalGalleryMode;
import "package:photos/services/machine_learning/ml_constants.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/query_result.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/isolate/isolate_operations.dart";
import "package:photos/utils/isolate/super_isolate.dart";
import "package:synchronized/synchronized.dart";

@pragma('vm:entry-point')
class MLComputer extends SuperIsolate {
  @override
  Logger get logger => _logger;
  final _logger = Logger('MLComputer');

  final _initModelLock = Lock();
  bool _isClipTokenizerInitialized = false;
  String? _clipTextModelPath;
  String? _clipTextVocabPath;
  Future<void>? _clipTextWarmupFuture;

  @override
  bool get isDartUiIsolate => false;

  @override
  String get isolateName => "MLComputerIsolate";

  @override
  bool get shouldAutomaticDispose => false;

  bool get _shouldUseRustMl => flagService.useRustForML || isLocalGalleryMode;

  // Singleton pattern
  MLComputer._privateConstructor();
  static final MLComputer instance = MLComputer._privateConstructor();
  factory MLComputer() => instance;

  Future<(List<Uint64List>, List<Float32List>)> bulkVectorSearch(
    List<Float32List> clipFloat32,
    bool exact,
  ) async {
    try {
      final result = await runInIsolate(IsolateOperation.bulkVectorSearch, {
        "clipFloat32": clipFloat32,
        "exact": exact,
      });
      return result;
    } catch (e, s) {
      _logger.severe("Could not run bulk vector search in MLComputer", e, s);
      rethrow;
    }
  }

  Future<(Uint64List, List<Uint64List>, List<Float32List>)>
      bulkVectorSearchWithKeys(Uint64List potentialKeys, bool exact) async {
    try {
      final result = await runInIsolate(
        IsolateOperation.bulkVectorSearchWithKeys,
        {"potentialKeys": potentialKeys, "exact": exact},
      );
      return result;
    } catch (e, s) {
      _logger.severe("Could not run bulk vector search in MLComputer", e, s);
      rethrow;
    }
  }

  Future<List<double>> runClipText(String query) async {
    try {
      final useRustMl = _shouldUseRustMl;
      await _ensureLoadedClipTextModel(useRustMl);
      final modelPath = _clipTextModelPath;
      final vocabPath = _clipTextVocabPath;
      if (useRustMl && (modelPath == null || modelPath.trim().isEmpty)) {
        throw Exception(
          "RustMLMissingModelPath: Missing required model path: clipTextModelPath",
        );
      }
      if (useRustMl && (vocabPath == null || vocabPath.trim().isEmpty)) {
        throw Exception(
          "RustMLMissingModelPath: Missing required model path: clipTextVocabPath",
        );
      }
      final textEmbedding = await runInIsolate(IsolateOperation.runClipText, {
        "text": query,
        "useRustMl": useRustMl,
        if (useRustMl) ...{
          "clipTextModelPath": modelPath,
          "clipTextVocabPath": vocabPath,
          "preferCoreml": Platform.isIOS,
          "preferNnapi": Platform.isAndroid,
          "preferXnnpack": Platform.isAndroid,
          "allowCpuFallback": true,
        } else ...{
          "address": ClipTextEncoder.instance.sessionAddress,
        },
      }) as List<double>;
      return textEmbedding;
    } catch (e, s) {
      _logger.severe("Could not run clip text in isolate", e, s);
      rethrow;
    }
  }

  Future<void> warmUpClipTextEncoder() {
    _clipTextWarmupFuture ??= _warmUpClipTextEncoderInternal();
    return _clipTextWarmupFuture!;
  }

  Future<void> _warmUpClipTextEncoderInternal() async {
    try {
      await runClipText("warm up text encoder");
    } catch (e, s) {
      _clipTextWarmupFuture = null;
      _logger.warning("Clip text warmup failed in MLComputer", e, s);
      rethrow;
    }
  }

  Future<void> _ensureLoadedClipTextModel(bool useRustMl) async {
    return _initModelLock.synchronized(() async {
      try {
        if (_clipTextVocabPath == null) {
          final tokenizerRemotePath = ClipTextEncoder.instance.vocabRemotePath;
          _clipTextVocabPath = await RemoteAssetsService.instance.getAssetPath(
            tokenizerRemotePath,
          );
        }

        if (useRustMl &&
            _clipTextVocabPath != null &&
            _clipTextModelPath != null) {
          return;
        }

        if (!useRustMl &&
            _isClipTokenizerInitialized &&
            ClipTextEncoder.instance.isInitialized) {
          return;
        }

        if (!useRustMl && !_isClipTokenizerInitialized) {
          await runInIsolate(IsolateOperation.initializeClipTokenizer, {
            'vocabPath': _clipTextVocabPath!,
          });
          _isClipTokenizerInitialized = true;
        }

        final String? downloadedModelPath =
            await ClipTextEncoder.instance.downloadModelSafe();
        if (downloadedModelPath == null) {
          throw Exception("Could not download clip text model, no wifi");
        }
        _clipTextModelPath = downloadedModelPath;

        if (useRustMl || ClipTextEncoder.instance.isInitialized) {
          return;
        }

        final String modelName = ClipTextEncoder.instance.modelName;
        final address = await runInIsolate(IsolateOperation.loadModel, {
          'modelName': modelName,
          'modelPath': downloadedModelPath,
        }) as int;
        ClipTextEncoder.instance.storeSessionAddress(address);
      } catch (e, s) {
        _logger.severe("Could not load clip text model in MLComputer", e, s);
        rethrow;
      }
    });
  }

  Future<Map<String, List<QueryResult>>> computeBulkSimilarities(
    Map<String, List<double>> textQueryToEmbeddingMap,
    Map<String, double> minimumSimilarityMap,
  ) async {
    try {
      final queryToResults =
          await runInIsolate(IsolateOperation.computeBulkSimilarities, {
        "textQueryToEmbeddingMap": textQueryToEmbeddingMap,
        "minimumSimilarityMap": minimumSimilarityMap,
      }) as Map<String, List<QueryResult>>;
      return queryToResults;
    } catch (e, s) {
      _logger.severe(
        "Could not bulk compare embeddings inside MLComputer isolate",
        e,
        s,
      );
      rethrow;
    }
  }

  Future<Map<String, List<QueryResult>>> computeBulkSimilaritiesWithRust(
    Map<String, List<double>> textQueryToEmbeddingMap,
    Map<String, double> minimumSimilarityMap,
  ) async {
    try {
      final queryToResults =
          await runInIsolate(IsolateOperation.computeBulkSimilaritiesWithRust, {
        "textQueryToEmbeddingMap": textQueryToEmbeddingMap,
        "minimumSimilarityMap": minimumSimilarityMap,
      }) as Map<String, List<QueryResult>>;
      return queryToResults;
    } catch (e, s) {
      _logger.severe(
        "Could not bulk compare embeddings with rust inside MLComputer isolate",
        e,
        s,
      );
      rethrow;
    }
  }

  Future<void> cacheImageEmbeddings(
    List<EmbeddingVector> embeddings, {
    bool cacheRustExact = false,
  }) async {
    try {
      await runInIsolate(IsolateOperation.cacheImageEmbeddings, {
        'embeddings': embeddings,
        'cacheRustExact': cacheRustExact,
      }) as bool;
      _logger.info(
        'Cached ${embeddings.length} image embeddings inside MLComputer',
      );
      return;
    } catch (e, s) {
      _logger.severe("Could not cache image embeddings in MLComputer", e, s);
      rethrow;
    }
  }

  Future<void> clearImageEmbeddingsCache() async {
    try {
      await runInIsolate(IsolateOperation.clearIsolateCache, {
        'key': imageEmbeddingsKey,
      }) as bool;
      return;
    } catch (e, s) {
      _logger.severe(
        "Could not clear image embeddings cache in MLComputer",
        e,
        s,
      );
      rethrow;
    }
  }
}
