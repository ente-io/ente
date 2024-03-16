import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/face/model/face.dart";
import "package:photos/face/model/file_ml.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/file_download_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class RemoteEmbeddingService {
  RemoteEmbeddingService._privateConstructor();

  static final RemoteEmbeddingService instance =
      RemoteEmbeddingService._privateConstructor();

  static const kEmbeddingsSyncTimeKey = "sync_time_embeddings_v2";

  final _logger = Logger("RemoteEmbeddingService");
  final _dio = NetworkClient.instance.enteDio;
  final _computer = Computer.shared();

  late SharedPreferences _preferences;

  Completer<void>? _syncStatus;

  void init(SharedPreferences prefs) {
    _preferences = prefs;
  }

  Future<void> putFaceEmbedding(EnteFile file, FileMl fileML) async {
    _logger.info("Pushing embedding for $file");
    final encryptionKey = getFileKey(file);
    final embeddingJSON = jsonEncode(fileML.toJson());
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
          "fileID": file.uploadedFileID!,
          "model": 'onnx-yolo5-mobile',
          "encryptedEmbedding": encryptedData,
          "decryptionHeader": header,
        },
      );
      // final updationTime = response.data["updatedAt"];
    } catch (e, s) {
      _logger.severe("Failed to put embedding", e, s);
      rethrow;
    }
  }
}
