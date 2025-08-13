import 'dart:async';

import "package:logging/logging.dart";
import "package:photos/models/ml/vector.dart";
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

  @override
  bool get isDartUiIsolate => false;

  @override
  String get isolateName => "MLComputerIsolate";

  @override
  bool get shouldAutomaticDispose => false;

  // Singleton pattern
  MLComputer._privateConstructor();
  static final MLComputer instance = MLComputer._privateConstructor();
  factory MLComputer() => instance;

  Future<List<double>> runClipText(String query) async {
    try {
      await _ensureLoadedClipTextModel();
      final int clipAddress = ClipTextEncoder.instance.sessionAddress;
      final textEmbedding = await runInIsolate(IsolateOperation.runClipText, {
        "text": query,
        "address": clipAddress,
      }) as List<double>;
      return textEmbedding;
    } catch (e, s) {
      _logger.severe("Could not run clip text in isolate", e, s);
      rethrow;
    }
  }

  Future<void> _ensureLoadedClipTextModel() async {
    return _initModelLock.synchronized(() async {
      if (ClipTextEncoder.instance.isInitialized) return;
      try {
        // Initialize ClipText tokenizer
        final String tokenizerRemotePath =
            ClipTextEncoder.instance.vocabRemotePath;
        final String tokenizerVocabPath = await RemoteAssetsService.instance
            .getAssetPath(tokenizerRemotePath);
        await runInIsolate(
          IsolateOperation.initializeClipTokenizer,
          {'vocabPath': tokenizerVocabPath},
        );

        // Load ClipText model
        final String modelName = ClipTextEncoder.instance.modelName;
        final String? modelPath =
            await ClipTextEncoder.instance.downloadModelSafe();
        if (modelPath == null) {
          throw Exception("Could not download clip text model, no wifi");
        }
        final address = await runInIsolate(
          IsolateOperation.loadModel,
          {
            'modelName': modelName,
            'modelPath': modelPath,
          },
        ) as int;
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

  Future<void> cacheImageEmbeddings(List<EmbeddingVector> embeddings) async {
    try {
      await runInIsolate(
        IsolateOperation.setIsolateCache,
        {
          'key': imageEmbeddingsKey,
          'value': embeddings,
        },
      ) as bool;
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
      await runInIsolate(
        IsolateOperation.clearIsolateCache,
        {'key': imageEmbeddingsKey},
      ) as bool;
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
