import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/decryption_params.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/crypto_util.dart';

class DiffFetcher {
  final _logger = Logger("FileDownloader");
  final _dio = Dio();

  Future<List<File>> getEncryptedFilesDiff(int lastSyncTime, int limit) async {
    return _dio
        .get(
          Configuration.instance.getHttpEndpoint() + "/encrypted-files/diff",
          queryParameters: {
            "token": Configuration.instance.getToken(),
            "sinceTime": lastSyncTime,
            "limit": limit,
          },
        )
        .catchError((e) => _logger.severe(e))
        .then((response) async {
          final files = List<File>();
          if (response != null) {
            Bus.instance.fire(RemoteSyncEvent(true));
            final diff = response.data["diff"] as List;
            for (final item in diff) {
              final file = File();
              file.uploadedFileID = item["id"];
              file.ownerID = item["ownerID"];
              file.updationTime = item["updationTime"];
              file.isEncrypted = true;
              file.fileDecryptionParams =
                  DecryptionParams.fromMap(item["file"]["decryptionParams"]);
              file.thumbnailDecryptionParams = DecryptionParams.fromMap(
                  item["thumbnail"]["decryptionParams"]);
              file.metadataDecryptionParams = DecryptionParams.fromMap(
                  item["metadata"]["decryptionParams"]);
              final metadataDecryptionKey = await CryptoUtil.decrypt(
                  Sodium.base642bin(file.metadataDecryptionParams.encryptedKey),
                  Configuration.instance.getKey(),
                  Sodium.base642bin(
                      file.metadataDecryptionParams.keyDecryptionNonce));
              final encodedMetadata = await CryptoUtil.decrypt(
                Sodium.base642bin(item["metadata"]["encryptedData"]),
                metadataDecryptionKey,
                Sodium.base642bin(file.metadataDecryptionParams.nonce),
              );
              Map<String, dynamic> metadata =
                  jsonDecode(utf8.decode(encodedMetadata));
              file.applyMetadata(metadata);
              files.add(file);
            }
          } else {
            Bus.instance.fire(RemoteSyncEvent(false));
          }
          return files;
        });
  }

  Future<List<File>> getFilesDiff(int lastSyncTime, int limit) async {
    Response response = await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/files/diff",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      queryParameters: {
        "sinceTime": lastSyncTime,
        "limit": limit,
      },
    ).catchError((e) => _logger.severe(e));
    if (response != null) {
      Bus.instance.fire(RemoteSyncEvent(true));
      return (response.data["diff"] as List)
          .map((file) => new File.fromJson(file))
          .toList();
    } else {
      Bus.instance.fire(RemoteSyncEvent(false));
      return null;
    }
  }
}
