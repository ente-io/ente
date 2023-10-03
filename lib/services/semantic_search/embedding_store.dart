import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/embedding.dart";
import "package:photos/services/semantic_search/remote_embedding.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/file_download_util.dart";
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

  Future<void> fetchEmbeddings() async {
    final remoteEmbeddings = await _getRemoteEmbeddings();
    await _storeEmbeddings(remoteEmbeddings.embeddings);
    if (remoteEmbeddings.hasMore) {
      return fetchEmbeddings();
    }
  }

  Future<RemoteEmbeddings> _getRemoteEmbeddings({
    int limit = 500,
  }) async {
    final remoteEmbeddings = <RemoteEmbedding>[];
    try {
      final response = await _dio.get(
        "/embeddings/diff",
        queryParameters: {
          "sinceTime": _preferences.getInt(kEmbeddingsSyncTimeKey) ?? 0,
          "limit": limit,
        },
      );
      final diff = response.data["diff"] as List;
      for (var entry in diff) {
        final embedding = RemoteEmbedding.fromMap(entry);
        remoteEmbeddings.add(embedding);
      }
    } catch (e, s) {
      _logger.severe(e, s);
    }
    return RemoteEmbeddings(
      remoteEmbeddings,
      remoteEmbeddings.length == limit,
    );
  }

  Future<void> _storeEmbeddings(List<RemoteEmbedding> remoteEmbeddings) async {
    final embeddings = <Embedding>[];
    for (final embedding in remoteEmbeddings) {
      final file = await FilesDB.instance.getAnyUploadedFile(embedding.fileID);
      if (file == null) {
        continue;
      }
      final fileKey = getFileKey(file);
      final encodedEmbedding = await CryptoUtil.decryptChaCha(
        CryptoUtil.base642bin(embedding.encryptedEmbedding),
        fileKey,
        CryptoUtil.base642bin(embedding.decryptionHeader),
      );
      final decodedEmbedding = Float64List.view(encodedEmbedding.buffer);

      embeddings.add(
        Embedding(
          embedding.fileID,
          embedding.model,
          decodedEmbedding,
          embedding.updationTime,
        ),
      );
    }
    await FilesDB.instance.insertEmbeddings(embeddings);
  }
}
