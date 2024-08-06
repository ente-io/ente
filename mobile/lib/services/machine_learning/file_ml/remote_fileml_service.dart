import "dart:async";

import "package:computer/computer.dart";
import "package:flutter/foundation.dart" show Uint8List;
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/services/machine_learning/file_ml/file_ml.dart';
import "package:photos/services/machine_learning/file_ml/files_ml_data_response.dart";
import "package:photos/services/machine_learning/file_ml/remote_embedding.dart";
import "package:photos/utils/file_download_util.dart";
import "package:photos/utils/gzip.dart";
import "package:shared_preferences/shared_preferences.dart";

class RemoteFileMLService {
  RemoteFileMLService._privateConstructor();
  static const String _derivedDataType = "derivedMeta";

  static final Computer _computer = Computer.shared();

  static final RemoteFileMLService instance =
      RemoteFileMLService._privateConstructor();

  final _logger = Logger("RemoteFileMLService");
  final _dio = NetworkClient.instance.enteDio;

  void init(SharedPreferences prefs) {}

  Future<void> putFileEmbedding(
    EnteFile file,
    RemoteFileML fileML, {
    RemoteClipEmbedding? clipEmbedding,
    RemoteFaceEmbedding? faceEmbedding,
  }) async {
    fileML.putClipIfNotNull(clipEmbedding);
    fileML.putFaceIfNotNull(faceEmbedding);
    final ChaChaEncryptionResult encryptionResult = await gzipAndEncryptJson(
      fileML.remoteRawData,
      getFileKey(file),
    );
    try {
      final _ = await _dio.put(
        "/files/data/",
        data: {
          "fileID": file.uploadedFileID!,
          "type": _derivedDataType,
          "encryptedData": encryptionResult.encData,
          "decryptionHeader": encryptionResult.header,
        },
      );
    } catch (e, s) {
      _logger.severe("Failed to put embedding", e, s);
      rethrow;
    }
  }

  Future<FilesMLDataResponse> getFileEmbeddings(
    Set<int> fileIds,
  ) async {
    try {
      final res = await _dio.post(
        "/files/fetch-data/",
        data: {
          "fileIDs": fileIds.toList(),
          "type": _derivedDataType,
        },
      );
      final remoteEmb = res.data['embeddings'] as List;
      final pendingIndexFiles = res.data['pendingIndexFileIDs'] as List;
      final noEmbeddingFiles = res.data['noEmbeddingFileIDs'] as List;
      final errFileIds = res.data['errFileIDs'] as List;

      final List<RemoteEmbedding> remoteEmbeddings = <RemoteEmbedding>[];
      for (var entry in remoteEmb) {
        final embedding = RemoteEmbedding.fromMap(entry);
        remoteEmbeddings.add(embedding);
      }

      final fileIDToFileMl = await decryptFileMLData(remoteEmbeddings);
      return FilesMLDataResponse(
        fileIDToFileMl,
        noEmbeddingFileIDs:
            Set<int>.from(noEmbeddingFiles.map((x) => x as int)),
        fetchErrorFileIDs: Set<int>.from(errFileIds.map((x) => x as int)),
        pendingIndexFileIDs:
            Set<int>.from(pendingIndexFiles.map((x) => x as int)),
      );
    } catch (e, s) {
      _logger.severe("Failed to get embeddings", e, s);
      rethrow;
    }
  }

  Future<Map<int, RemoteFileML>> decryptFileMLData(
    List<RemoteEmbedding> remoteEmbeddings,
  ) async {
    final result = <int, RemoteFileML>{};
    if (remoteEmbeddings.isEmpty) {
      return result;
    }
    final inputs = <EmbeddingsDecoderInput>[];
    final fileMap = await FilesDB.instance
        .getFilesFromIDs(remoteEmbeddings.map((e) => e.fileID).toList());
    for (final embedding in remoteEmbeddings) {
      final file = fileMap[embedding.fileID];
      if (file == null) {
        continue;
      }
      final fileKey = getFileKey(file);
      final input = EmbeddingsDecoderInput(embedding, fileKey);
      inputs.add(input);
    }
    return _computer.compute<Map<String, dynamic>, Map<int, RemoteFileML>>(
      _decryptFileMLComputer,
      param: {
        "inputs": inputs,
      },
    );
  }
}

Future<Map<int, RemoteFileML>> _decryptFileMLComputer(
  Map<String, dynamic> args,
) async {
  final result = <int, RemoteFileML>{};
  final inputs = args["inputs"] as List<EmbeddingsDecoderInput>;
  for (final input in inputs) {
    final decodedJson = decryptAndUnzipJsonSync(
      input.decryptionKey,
      encryptedData: input.embedding.encryptedEmbedding,
      header: input.embedding.decryptionHeader,
    );
    result[input.embedding.fileID] = RemoteFileML.fromRemote(
      input.embedding.fileID,
      decodedJson,
    );
  }
  return result;
}

class EmbeddingsDecoderInput {
  final RemoteEmbedding embedding;
  final Uint8List decryptionKey;

  EmbeddingsDecoderInput(this.embedding, this.decryptionKey);
}
