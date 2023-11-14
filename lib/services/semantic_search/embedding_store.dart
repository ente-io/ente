import "dart:convert";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/object_box.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/objectbox.g.dart";
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

  bool isSyncing = false;

  Future<void> init(SharedPreferences preferences) async {
    _preferences = preferences;
  }

  Future<void> pullEmbeddings() async {
    if (isSyncing) {
      return;
    }
    isSyncing = true;
    var remoteEmbeddings = await _getRemoteEmbeddings();
    await _storeRemoteEmbeddings(remoteEmbeddings.embeddings);
    while (remoteEmbeddings.hasMore) {
      remoteEmbeddings = await _getRemoteEmbeddings();
      await _storeRemoteEmbeddings(remoteEmbeddings.embeddings);
    }
    isSyncing = false;
  }

  Future<void> pushEmbeddings() async {
    final query = (ObjectBox.instance
            .getEmbeddingBox()
            .query(Embedding_.updationTime.isNull()))
        .build();
    final pendingItems = query.find();
    query.close();
    for (final item in pendingItems) {
      final file = await FilesDB.instance.getAnyUploadedFile(item.fileID);
      await _pushEmbedding(file!, item);
    }
  }

  Future<void> storeEmbedding(EnteFile file, Embedding embedding) async {
    ObjectBox.instance.getEmbeddingBox().put(embedding);
    _pushEmbedding(file, embedding);
  }

  Future<void> _pushEmbedding(EnteFile file, Embedding embedding) async {
    final encryptionKey = getFileKey(file);
    final embeddingJSON = jsonEncode(embedding.embedding);
    final encryptedEmbedding = await CryptoUtil.encryptChaCha(
      utf8.encode(embeddingJSON) as Uint8List,
      encryptionKey,
    );
    final encryptedData =
        CryptoUtil.bin2base64(encryptedEmbedding.encryptedData!);
    final header = CryptoUtil.bin2base64(encryptedEmbedding.header!);
    try {
      final response = await _dio.put(
        "/embeddings",
        data: {
          "fileID": embedding.fileID,
          "model": embedding.model,
          "encryptedEmbedding": encryptedData,
          "decryptionHeader": header,
        },
      );
      final updationTime = response.data["updationTime"];
      embedding.updationTime = updationTime;
      ObjectBox.instance.getEmbeddingBox().put(embedding);
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }

  Future<RemoteEmbeddings> _getRemoteEmbeddings({
    int limit = 500,
  }) async {
    final remoteEmbeddings = <RemoteEmbedding>[];
    try {
      final sinceTime = _preferences.getInt(kEmbeddingsSyncTimeKey) ?? 0;
      _logger.info("Fetching embeddings since $sinceTime");
      final response = await _dio.get(
        "/embeddings/diff",
        queryParameters: {
          "sinceTime": sinceTime,
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

    _logger.info("${remoteEmbeddings.length} embeddings fetched");
    return RemoteEmbeddings(
      remoteEmbeddings,
      remoteEmbeddings.length == limit,
    );
  }

  Future<void> _storeRemoteEmbeddings(
    List<RemoteEmbedding> remoteEmbeddings,
  ) async {
    if (remoteEmbeddings.isEmpty) {
      return;
    }
    final embeddings = <Embedding>[];
    for (final embedding in remoteEmbeddings) {
      final file = await FilesDB.instance.getAnyUploadedFile(embedding.fileID);
      if (file == null) {
        continue;
      }
      final fileKey = getFileKey(file);
      final embeddingData = await CryptoUtil.decryptChaCha(
        CryptoUtil.base642bin(embedding.encryptedEmbedding),
        fileKey,
        CryptoUtil.base642bin(embedding.decryptionHeader),
      );
      final List<double> decodedEmbedding =
          jsonDecode(utf8.decode(embeddingData))
              .map((item) => item.toDouble())
              .cast<double>()
              .toList();

      embeddings.add(
        Embedding(
          fileID: embedding.fileID,
          model: embedding.model,
          embedding: decodedEmbedding,
          updationTime: embedding.updatedAt,
        ),
      );
    }
    await ObjectBox.instance.getEmbeddingBox().putManyAsync(embeddings);
    _logger.info("${embeddings.length} embeddings stored");
    await _preferences.setInt(
      kEmbeddingsSyncTimeKey,
      embeddings.last.updationTime!,
    );
  }
}
