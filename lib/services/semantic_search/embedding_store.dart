import "package:photos/services/semantic_search/remote_embedding.dart";
import "package:shared_preferences/shared_preferences.dart";

class EmbeddingStore {
  EmbeddingStore._privateConstructor();

  static final EmbeddingStore instance = EmbeddingStore._privateConstructor();

  late SharedPreferences _preferences;

  Future<void> init(SharedPreferences preferences) async {
    _preferences = preferences;
  }

  Future<List<RemoteEmbedding>> fetchEmbeddings() async {
    return [];
  }
}
