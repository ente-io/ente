import "dart:async";

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/embeddings_db.dart";
import "package:shared_preferences/shared_preferences.dart";

class EmbeddingStore {
  EmbeddingStore._privateConstructor();

  static final EmbeddingStore instance = EmbeddingStore._privateConstructor();

  static const kEmbeddingsSyncTimeKey = "sync_time_embeddings_v3";

  final _logger = Logger("EmbeddingStore");
  final _dio = NetworkClient.instance.enteDio;
  final _computer = Computer.shared();

  late SharedPreferences _preferences;

  Completer<bool>? _remoteSyncStatus;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }



  Future<void> clearEmbeddings() async {
    await EmbeddingsDB.instance.deleteAll();
    await _preferences.remove(kEmbeddingsSyncTimeKey);
  }
}
