import "dart:async";
import "dart:convert";
import "dart:io";

import "package:computer/computer.dart";
import "package:flutter/foundation.dart" show Uint8List, debugPrint;
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/ml_versions.dart";
import 'package:photos/services/machine_learning/file_ml/file_ml.dart';
import "package:photos/services/machine_learning/file_ml/files_ml_data_response.dart";
import "package:photos/services/machine_learning/semantic_search/remote_embedding.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/file_download_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class RemoteFileMLService {
  RemoteFileMLService._privateConstructor();

  static final Computer _computer = Computer.shared();

  static final RemoteFileMLService instance =
      RemoteFileMLService._privateConstructor();

  final _logger = Logger("RemoteFileMLService");
  final _dio = NetworkClient.instance.enteDio;

  void init(SharedPreferences prefs) {}

  Future<void> putFileEmbedding(EnteFile file, RemoteFileML fileML) async {
    throw Exception("need to update implementation");
    final encryptionKey = getFileKey(file);
    final embeddingJSON = jsonEncode(fileML.toJson());
    final encryptedEmbedding = await CryptoUtil.encryptChaCha(
      utf8.encode(embeddingJSON),
      encryptionKey,
    );
    final encryptedData =
        CryptoUtil.bin2base64(encryptedEmbedding.encryptedData!);
    final header = CryptoUtil.bin2base64(encryptedEmbedding.header!);
    try {
      final _ = await _dio.put(
        "/embeddings",
        data: {
          "fileID": file.uploadedFileID!,
          "model": 'file-ml-clip-face',
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

  Future<FilesMLDataResponse> getFileEmbeddings(
    Set<int> fileIds,
  ) async {
    try {
      final res = await _dio.post(
        "/embeddings/files",
        data: {
          "fileIDs": fileIds.toList(),
          "model": 'ggml-clip',
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

Uint8List ungzipUint8List(Uint8List compressedData) {
  final codec = GZipCodec();
  final List<int> decompressedList = codec.decode(compressedData);
  return Uint8List.fromList(decompressedList);
}

Future<Map<int, RemoteFileML>> _decryptFileMLComputer(
  Map<String, dynamic> args,
) async {
  final result = <int, RemoteFileML>{};
  final inputs = args["inputs"] as List<EmbeddingsDecoderInput>;
  for (final input in inputs) {
    final decryptArgs = <String, dynamic>{};
    decryptArgs["source"] =
        CryptoUtil.base642bin(input.embedding.encryptedEmbedding);
    decryptArgs["key"] = input.decryptionKey;
    decryptArgs["header"] =
        CryptoUtil.base642bin(input.embedding.decryptionHeader);
    final embeddingData = chachaDecryptData(decryptArgs);
    // unzip the gzip data
    final unzippedData = ungzipUint8List(embeddingData);
    final decodedJson = jsonDecode(utf8.decode(unzippedData));
    final RemoteFileML decodedEmbedding = RemoteFileML.fromRemote(
      input.embedding.fileID,
      decodedJson as Map<String, dynamic>,
    );
    result[input.embedding.fileID] = decodedEmbedding;
  }
  return result;
}

class EmbeddingsDecoderInput {
  final RemoteEmbedding embedding;
  final Uint8List decryptionKey;

  EmbeddingsDecoderInput(this.embedding, this.decryptionKey);
}

bool shouldDiscardRemoteEmbedding(RemoteFileML fileMl) {
  if (fileMl.faceEmbedding.version < faceMlVersion) {
    debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
        "because version is ${fileMl.faceEmbedding.version} and we need $faceMlVersion");
    return true;
  }
  // are all landmarks equal?
  bool allLandmarksEqual = true;
  if (fileMl.faceEmbedding.faces.isEmpty) {
    debugPrint("No face for ${fileMl.fileID}");
    allLandmarksEqual = false;
  }
  for (final face in fileMl.faceEmbedding.faces) {
    if (face.detection.landmarks.isEmpty) {
      allLandmarksEqual = false;
      break;
    }
    if (face.detection.landmarks.any((landmark) => landmark.x != landmark.y)) {
      allLandmarksEqual = false;
      break;
    }
  }
  if (allLandmarksEqual) {
    debugPrint("Discarding remote embedding for fileID ${fileMl.fileID} "
        "because landmarks are equal");
    debugPrint(
      fileMl.faceEmbedding.faces
          .map((e) => e.detection.landmarks.toString())
          .toList()
          .toString(),
    );
    return true;
  }

  return false;
}
