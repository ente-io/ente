import 'package:logging/logging.dart';
import 'package:photos/db/ml/db.dart';
import 'package:photos/services/machine_learning/ml_computer.dart';

class TextEmbeddingsCacheService {
  static final _logger = Logger('TextEmbeddingsCacheService');

  TextEmbeddingsCacheService._privateConstructor();
  static final instance = TextEmbeddingsCacheService._privateConstructor();

  Future<List<double>> getEmbedding(String query) async {
    // 1. Check database cache
    final dbResult =
        await MLDataDB.instance.getRepeatedTextEmbeddingCache(query);
    if (dbResult != null) {
      _logger.info('Text embedding cache hit for query');
      return dbResult;
    }

    // 2. Compute new embedding
    _logger.info('Computing new text embedding for query');
    final embedding = await MLComputer.instance.runClipText(query);

    // 3. Store in database cache
    await MLDataDB.instance.putRepeatedTextEmbeddingCache(query, embedding);

    return embedding;
  }
}
