import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/embeddings_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/semantic_search/remote_embedding.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/file_download_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class EmbeddingStore {
  EmbeddingStore._privateConstructor();

  static final EmbeddingStore instance = EmbeddingStore._privateConstructor();

  static const kEmbeddingsSyncTimeKey = "sync_time_embeddings_v2";

  final _logger = Logger("EmbeddingStore");
  final _dio = NetworkClient.instance.enteDio;
  final _computer = Computer.shared();

  late SharedPreferences _preferences;

  Completer<void>? _syncStatus;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> pullEmbeddings(Model model) async {
    if (_syncStatus != null) {
      return _syncStatus!.future;
    }
    _syncStatus = Completer();
    var remoteEmbeddings = await _getRemoteEmbeddings(model);
    await _storeRemoteEmbeddings(remoteEmbeddings.embeddings);
    while (remoteEmbeddings.hasMore) {
      remoteEmbeddings = await _getRemoteEmbeddings(model);
      await _storeRemoteEmbeddings(remoteEmbeddings.embeddings);
    }
    _syncStatus!.complete();
    _syncStatus = null;
  }

  Future<void> pushEmbeddings() async {
    final pendingItems = await EmbeddingsDB.instance.getUnsyncedEmbeddings();
    for (final item in pendingItems) {
      final file = await FilesDB.instance.getAnyUploadedFile(item.fileID);
      await _pushEmbedding(file!, item);
    }
  }

  Future<void> storeEmbedding(EnteFile file, Embedding embedding) async {
    await EmbeddingsDB.instance.put(embedding);
    unawaited(_pushEmbedding(file, embedding));
  }

  Future<void> clearEmbeddings(Model model) async {
    await EmbeddingsDB.instance.deleteAllForModel(model);
    await _preferences.remove(kEmbeddingsSyncTimeKey);
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
          "model": embedding.model.name,
          "encryptedEmbedding": encryptedData,
          "decryptionHeader": header,
        },
      );
      final updationTime = response.data["updationTime"];
      embedding.updationTime = updationTime;
      await EmbeddingsDB.instance.put(embedding);
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }

  Future<RemoteEmbeddings> _getRemoteEmbeddings(
    Model model, {
    int limit = 500,
  }) async {
    final remoteEmbeddings = <RemoteEmbedding>[];
    try {
      final sinceTime = _preferences.getInt(kEmbeddingsSyncTimeKey) ?? 0;
      _logger.info("Fetching embeddings since $sinceTime");
      final response = await _dio.get(
        "/embeddings/diff",
        queryParameters: {
          "model": model.name,
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
    final inputs = <EmbeddingsDecoderInput>[];
    for (final embedding in remoteEmbeddings) {
      final file = await FilesDB.instance.getAnyUploadedFile(embedding.fileID);
      if (file == null) {
        continue;
      }
      final fileKey = getFileKey(file);
      final input = EmbeddingsDecoderInput(embedding, fileKey);
      inputs.add(input);
    }
    final embeddings = await _computer.compute(
      decodeEmbeddings,
      param: {
        "inputs": inputs,
      },
    );
    _logger.info("${embeddings.length} embeddings decoded");
    await EmbeddingsDB.instance.putMany(embeddings);
    await _preferences.setInt(
      kEmbeddingsSyncTimeKey,
      embeddings.last.updationTime!,
    );
    _logger.info("${embeddings.length} embeddings stored");
  }
}

Future<List<Embedding>> decodeEmbeddings(Map<String, dynamic> args) async {
  final embeddings = <Embedding>[];

  final inputs = args["inputs"] as List<EmbeddingsDecoderInput>;

  for (final input in inputs) {
    final decryptArgs = <String, dynamic>{};
    decryptArgs["source"] =
        CryptoUtil.base642bin(input.embedding.encryptedEmbedding);
    decryptArgs["key"] = input.decryptionKey;
    decryptArgs["header"] =
        CryptoUtil.base642bin(input.embedding.decryptionHeader);
    final embeddingData = chachaDecryptData(decryptArgs);

    final List<double> decodedEmbedding = jsonDecode(utf8.decode(embeddingData))
        .map((item) => item.toDouble())
        .cast<double>()
        .toList();

    embeddings.add(
      Embedding(
        fileID: input.embedding.fileID,
        model: deserialize(input.embedding.model),
        embedding: decodedEmbedding,
        updationTime: input.embedding.updatedAt,
      ),
    );
  }

  return embeddings;
}

class EmbeddingsDecoderInput {
  final RemoteEmbedding embedding;
  final Uint8List decryptionKey;

  EmbeddingsDecoderInput(this.embedding, this.decryptionKey);
}
