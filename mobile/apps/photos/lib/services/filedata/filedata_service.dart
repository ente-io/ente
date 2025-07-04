import "dart:async";

import "package:computer/computer.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart" show Uint8List;
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/filedata.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/filedata/model/enc_file_data.dart";
import "package:photos/services/filedata/model/file_data.dart";
import "package:photos/services/filedata/model/response.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/gzip.dart";
import "package:shared_preferences/shared_preferences.dart";

class FileDataService {
  static final Computer _computer = Computer.shared();
  final _logger = Logger("FileDataService");
  final Dio _dio;
  final SharedPreferences _prefs;
  late Map<int, PreviewInfo> previewIds;

  FileDataService(this._prefs, this._dio) {
    _logger.info("FileDataService constructor called");
    previewIds = <int, PreviewInfo>{};
  }

  /// Used to not sync preview ids everytime a chunking and preview
  /// upload is successful, instead update the local copy of those
  /// preview ids
  void appendPreview(int id, String objectId, int objectSize) {
    if (previewIds.containsKey(id)) return;
    previewIds[id] = PreviewInfo(
      objectId: objectId,
      objectSize: objectSize,
    );
  }

  Future<void> putFileData(EnteFile file, FileDataEntity data) async {
    data.validate();
    final ChaChaEncryptionResult encryptionResult = await gzipAndEncryptJson(
      data.remoteRawData,
      getFileKey(file),
    );

    try {
      final _ = await _dio.put(
        "/files/data",
        data: {
          "fileID": file.uploadedFileID!,
          "type": data.type.toJson(),
          "encryptedData": encryptionResult.encData,
          "decryptionHeader": encryptionResult.header,
        },
      );
    } catch (e, s) {
      _logger.severe("putDerivedMetaData failed", e, s);
      rethrow;
    }
  }

  Future<FileDataResponse> getFilesData(
    Set<int> fileIds, {
    DataType type = DataType.mlData,
  }) async {
    try {
      final res = await _dio.post(
        "/files/data/fetch",
        data: {
          "fileIDs": fileIds.toList(),
          "type": type.toJson(),
        },
      );
      final remoteEntries = res.data['data'] as List;
      final pendingIndexFiles = res.data['pendingIndexFileIDs'] as List;
      final errFileIds = res.data['errFileIDs'] as List;

      final List<EncryptedFileData> encFileData = <EncryptedFileData>[];
      for (var entry in remoteEntries) {
        encFileData.add(EncryptedFileData.fromMap(entry));
      }
      final fileIdToDataMap = await decryptRemoteFileData(encFileData);
      return FileDataResponse(
        fileIdToDataMap,
        fetchErrorFileIDs: Set<int>.from(errFileIds.map((x) => x as int)),
        pendingIndexFileIDs:
            Set<int>.from(pendingIndexFiles.map((x) => x as int)),
      );
    } catch (e, s) {
      _logger.severe("Failed to get embeddings", e, s);
      rethrow;
    }
  }

  Future<Map<int, FileDataEntity>> decryptRemoteFileData(
    List<EncryptedFileData> remoteData,
  ) async {
    final result = <int, FileDataEntity>{};
    if (remoteData.isEmpty) {
      return result;
    }
    final inputs = <_DecoderInput>[];
    final fileMap = await FilesDB.instance
        .getFileIDToFileFromIDs(remoteData.map((e) => e.fileID).toList());
    for (final data in remoteData) {
      final file = fileMap[data.fileID];
      if (file == null) {
        continue;
      }
      final fileKey = getFileKey(file);
      final input = _DecoderInput(data, fileKey);
      inputs.add(input);
    }
    return _computer.compute<Map<String, dynamic>, Map<int, FileDataEntity>>(
      _decryptFileDataComputer,
      param: {
        "inputs": inputs,
      },
    );
  }

  Future<void> syncFDStatus() async {
    try {
      bool hasMoreData = false;
      do {
        final lastTime = _prefs.getInt("fd.lastSyncTime") ?? 0;
        final res = await _dio.post(
          "/files/data/status-diff",
          data: {
            "lastUpdatedAt": lastTime,
          },
        );
        final r = res.data;
        final data = (r["diff"] ?? []) as List;
        final List<FDStatus> result = [];
        int maxUpdatedAt = lastTime;
        for (var entry in data) {
          result.add(FDStatus.fromJson(entry));
          if (entry["updatedAt"] > maxUpdatedAt) {
            maxUpdatedAt = entry["updatedAt"];
          }
        }
        await MLDataDB.instance.putFDStatus(result);
        await _prefs.setInt("fd.lastSyncTime", maxUpdatedAt);
        _logger.info('found ${result.length} fd entries');
        hasMoreData = result.isNotEmpty;
        previewIds = await MLDataDB.instance.getFileIDsVidPreview();
      } while (hasMoreData);
    } catch (e) {
      if (previewIds.isEmpty) {
        previewIds = await MLDataDB.instance.getFileIDsVidPreview();
      }
      _logger.severe("Failed to syncDiff", e);
      rethrow;
    }
  }
}

Future<Map<int, FileDataEntity>> _decryptFileDataComputer(
  Map<String, dynamic> args,
) async {
  final result = <int, FileDataEntity>{};
  final inputs = args["inputs"] as List<_DecoderInput>;
  for (final input in inputs) {
    final decodedJson = decryptAndUnzipJsonSync(
      input.decryptionKey,
      encryptedData: input.data.encryptedData,
      header: input.data.decryptionHeader,
    );
    result[input.data.fileID] = FileDataEntity.fromRemote(
      input.data.fileID,
      input.data.type,
      decodedJson,
    );
  }
  return result;
}

class _DecoderInput {
  final EncryptedFileData data;
  final Uint8List decryptionKey;

  _DecoderInput(this.data, this.decryptionKey);
}
