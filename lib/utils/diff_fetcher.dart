import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class DiffFetcher {
  final _logger = Logger("DiffFetcher");
  final _dio = Network.instance.getDio();

  Future<Diff> getEncryptedFilesDiff(
      int collectionID, int sinceTime, int limit) async {
    try {
      final response = await _dio.get(
        Configuration.instance.getHttpEndpoint() + "/collections/diff",
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
          "limit": limit,
        },
      );
      final files = <File>[];
      if (response != null) {
        Bus.instance.fire(RemoteSyncEvent(true));
        final diff = response.data["diff"] as List;
        final startTime = DateTime.now();
        final existingFiles =
            await FilesDB.instance.getUploadedFileIDs(collectionID);
        final deletedFiles = <File>[];
        for (final item in diff) {
          final file = File();
          file.uploadedFileID = item["id"];
          file.collectionID = item["collectionID"];
          if (item["isDeleted"]) {
            if (existingFiles.contains(file.uploadedFileID)) {
              deletedFiles.add(file);
            }
            continue;
          }
          if (existingFiles.contains(file.uploadedFileID)) {
            final existingFile = await FilesDB.instance
                .getUploadedFile(file.uploadedFileID, file.collectionID);
            if (existingFile != null) {
              file.generatedID = existingFile.generatedID;
            }
          }
          file.updationTime = item["updationTime"];
          file.ownerID = item["ownerID"];
          file.encryptedKey = item["encryptedKey"];
          file.keyDecryptionNonce = item["keyDecryptionNonce"];
          file.fileDecryptionHeader = item["file"]["decryptionHeader"];
          file.thumbnailDecryptionHeader =
              item["thumbnail"]["decryptionHeader"];
          file.metadataDecryptionHeader = item["metadata"]["decryptionHeader"];

          final fileDecryptionKey = decryptFileKey(file);
          final encodedMetadata = await CryptoUtil.decryptChaCha(
            Sodium.base642bin(item["metadata"]["encryptedData"]),
            fileDecryptionKey,
            Sodium.base642bin(file.metadataDecryptionHeader),
          );
          Map<String, dynamic> metadata =
              jsonDecode(utf8.decode(encodedMetadata));
          file.applyMetadata(metadata);
          if (item['magicMetadata'] != null) {
            final utfEncodedMmd = await CryptoUtil.decryptChaCha(
                Sodium.base642bin(item['magicMetadata']['data']),
                fileDecryptionKey,
                Sodium.base642bin(item['magicMetadata']['header']));
            file.mMdEncodedJson = utf8.decode(utfEncodedMmd);
            file.mMdVersion = item['magicMetadata']['version'];
            file.magicMetadata =
                MagicMetadata.fromEncodedJson(file.mMdEncodedJson);
          }
          files.add(file);
        }

        final endTime = DateTime.now();
        _logger.info("time for parsing " +
            files.length.toString() +
            ": " +
            Duration(
                    microseconds: (endTime.microsecondsSinceEpoch -
                        startTime.microsecondsSinceEpoch))
                .inMilliseconds
                .toString());
        return Diff(files, deletedFiles, diff.length);
      } else {
        Bus.instance.fire(RemoteSyncEvent(false));
        return Diff(<File>[], <File>[], 0);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class Diff {
  final List<File> updatedFiles;
  final List<File> deletedFiles;
  final int fetchCount;

  Diff(this.updatedFiles, this.deletedFiles, this.fetchCount);
}
