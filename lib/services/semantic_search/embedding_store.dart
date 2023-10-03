import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/services/semantic_search/remote_embedding.dart";
import "package:shared_preferences/shared_preferences.dart";

class EmbeddingStore {
  EmbeddingStore._privateConstructor();

  static final EmbeddingStore instance = EmbeddingStore._privateConstructor();

  static const kEmbeddingsSyncTimeKey = "embeddings_sync_time";

  final _logger = Logger("EmbeddingStore");
  final _dio = NetworkClient.instance.enteDio;

  late SharedPreferences _preferences;

  Future<void> init(SharedPreferences preferences) async {
    _preferences = preferences;
  }

  Future<List<RemoteEmbedding>> fetchEmbeddings({int limit = 500}) async {
    try {
      final response = await _dio.get(
        "/embeddings/diff",
        queryParameters: {
          "sinceTime": _preferences.getInt(kEmbeddingsSyncTimeKey) ?? 0,
          "limit": limit,
        },
      );
      final remoteEmbeddings = <RemoteEmbedding>[];
      final diff = response.data["diff"] as List;
      for (var entry in diff) {
        final embedding = RemoteEmbedding.fromMap(entry);
        remoteEmbeddings.add(embedding);
      }
      return remoteEmbeddings;
    } catch (e, s) {
      _logger.severe(e, s);
    }
    return [];
  }
}
