import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class TrashDiffFetcher {
  final _logger = Logger("TrashDiffFetcher");
  final _dio = Network.instance.getDio();

  Future<Diff> getTrashFilesDiff(int sinceTime, int limit) async {
    try {
      final response = await _dio.get(
        Configuration.instance.getHttpEndpoint() + "/trash/diff",
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        queryParameters: {
          "sinceTime": sinceTime,
          "limit": limit,
        },
      );
      int latestUpdatedAtTime = 0;
      final trashedFiles = <Trash>[];
      final deletedFiles = <Trash>[];
      final restoredFiles = <Trash>[];
      if (response != null) {
        Bus.instance.fire(RemoteSyncEvent(true));
        final diff = response.data["diff"] as List;
        final startTime = DateTime.now();
        for (final item in diff) {
          final trash = Trash();
          trash.createdAt = item['createdAt'];
          trash.updateAt = item['updatedAt'];
          latestUpdatedAtTime = max(latestUpdatedAtTime, trash.updateAt);
          trash.deleteBy = item['deleteBy'];
          trash.file = File();
          trash.file.uploadedFileID = item["file"]["id"];
          trash.file.collectionID = item["file"]["collectionID"];
          trash.file.updationTime = item["file"]["updationTime"];
          trash.file.ownerID = item["file"]["ownerID"];
          trash.file.encryptedKey = item["file"]["encryptedKey"];
          trash.file.keyDecryptionNonce = item["file"]["keyDecryptionNonce"];
          trash.file.fileDecryptionHeader =
              item["file"]["file"]["decryptionHeader"];
          trash.file.thumbnailDecryptionHeader =
              item["file"]["thumbnail"]["decryptionHeader"];
          trash.file.metadataDecryptionHeader =
              item["file"]["metadata"]["decryptionHeader"];
          final fileDecryptionKey = decryptFileKey(trash.file);
          final encodedMetadata = await CryptoUtil.decryptChaCha(
            Sodium.base642bin(item["file"]["metadata"]["encryptedData"]),
            fileDecryptionKey,
            Sodium.base642bin(trash.file.metadataDecryptionHeader),
          );
          Map<String, dynamic> metadata =
              jsonDecode(utf8.decode(encodedMetadata));
          trash.file.applyMetadata(metadata);
          if (item["file"]['magicMetadata'] != null) {
            final utfEncodedMmd = await CryptoUtil.decryptChaCha(
                Sodium.base642bin(item["file"]['magicMetadata']['data']),
                fileDecryptionKey,
                Sodium.base642bin(item["file"]['magicMetadata']['header']));
            trash.file.mMdEncodedJson = utf8.decode(utfEncodedMmd);
            trash.file.mMdVersion = item["file"]['magicMetadata']['version'];
          }
          if (item["isDeleted"]) {
            deletedFiles.add(trash);
            continue;
          }
          if (item['isRestored']) {
            restoredFiles.add(trash);
            continue;
          }
          trashedFiles.add(trash);
        }

        final endTime = DateTime.now();
        _logger.info("time for parsing " +
            diff.length.toString() +
            ": " +
            Duration(
                    microseconds: (endTime.microsecondsSinceEpoch -
                        startTime.microsecondsSinceEpoch))
                .inMilliseconds
                .toString());
        return Diff(trashedFiles, restoredFiles, deletedFiles, diff.length,
            latestUpdatedAtTime);
      } else {
        Bus.instance.fire(RemoteSyncEvent(false));
        return Diff(<Trash>[], <Trash>[], <Trash>[], 0, 0);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class Diff {
  final List<Trash> trashedFiles;
  final List<Trash> restoredFiles;
  final List<Trash> deletedFiles;
  final int fetchCount;
  final int lastSyncedTimeStamp;

  Diff(this.trashedFiles, this.restoredFiles, this.deletedFiles,
      this.fetchCount, this.lastSyncedTimeStamp);
}
