import 'dart:async';

import 'package:logging/logging.dart';
import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/db/ml/db.dart';
import 'package:photos/services/machine_learning/ml_computer.dart';
import 'package:synchronized/synchronized.dart';

class TextEmbeddingsCacheService {
  static final _logger = Logger('TextEmbeddingsCacheService');

  LRUMap<String, List<double>> _memoryCache = LRUMap<String, List<double>>(50);
  final _cacheLock = Lock();

  TextEmbeddingsCacheService._privateConstructor();
  static final instance = TextEmbeddingsCacheService._privateConstructor();

  Future<List<double>> getEmbedding(String query) async {
    return _cacheLock.synchronized(() async {
      // 1. Check memory cache
      final cachedResult = _memoryCache.get(query);
      if (cachedResult != null) {
        _logger.info('Text embedding cache hit (memory) for query');
        return cachedResult;
      }

      // 2. Check database
      final dbResult =
          await MLDataDB.instance.getRepeatedTextEmbeddingCache(query);
      if (dbResult != null) {
        _logger.info('Text embedding cache hit (database) for query');
        _memoryCache.put(query, dbResult);
        return dbResult;
      }

      // 3. Compute new embedding
      _logger.info('Computing new text embedding for query');
      final embedding = await MLComputer.instance.runClipText(query);

      // 4. Store in both caches
      _memoryCache.put(query, embedding);
      await MLDataDB.instance.putRepeatedTextEmbeddingCache(query, embedding);

      return embedding;
    });
  }

  void clearMemoryCache() {
    _memoryCache = LRUMap<String, List<double>>(50);
    _logger.info('Cleared text embeddings memory cache');
  }
}
