import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/remote_sync_event.dart';
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
            for (final fileItem in diff) {
              final file = File();
              file.uploadedFileID = fileItem["id"];
              file.ownerID = fileItem["ownerID"];
              file.updationTime = fileItem["updationTime"];
              file.isEncrypted = true;
              file.encryptedPassword = fileItem["encryptedPassword"];
              file.encryptedPasswordIV = fileItem["encryptedPasswordIV"];
              Map<String, dynamic> metadata = jsonDecode(utf8.decode(
                  await CryptoUtil.decryptDataToData(
                      base64.decode(fileItem["encryptedMetadata"]),
                      file.getPassword())));
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
