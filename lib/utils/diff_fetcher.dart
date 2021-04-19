import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

class DiffFetcher {
  final _logger = Logger("DiffFetcher");
  final _dio = Network.instance.getDio();

  Future<Diff> getEncryptedFilesDiff(
      int collectionID, int sinceTime, int limit) async {
    return _dio
        .get(
          Configuration.instance.getHttpEndpoint() + "/collections/diff",
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
          queryParameters: {
            "collectionID": collectionID,
            "sinceTime": sinceTime,
            "limit": limit,
          },
        )
        .catchError((e) => _logger.severe(e))
        .then((response) async {
          final files = List<File>();
          if (response != null) {
            Bus.instance.fire(RemoteSyncEvent(true));
            final diff = response.data["diff"] as List;
            final startTime = DateTime.now();
            final existingFiles =
                await FilesDB.instance.getUploadedFileIDs(collectionID);
            for (final item in diff) {
              final file = File();
              file.uploadedFileID = item["id"];
              file.collectionID = item["collectionID"];
              if (item["isDeleted"]) {
                if (existingFiles.contains(file.uploadedFileID)) {
                  await FilesDB.instance.deleteFromCollection(
                      file.uploadedFileID, file.collectionID);
                  Bus.instance.fire(
                      CollectionUpdatedEvent(collectionID: file.collectionID));
                  FileRepository.instance.reloadFiles();
                }
                continue;
              }
              file.updationTime = item["updationTime"];
              if (existingFiles.contains(file.uploadedFileID)) {
                final existingFile = await FilesDB.instance
                    .getUploadedFile(file.uploadedFileID, file.collectionID);
                if (existingFile != null &&
                    existingFile.updationTime == file.updationTime) {
                  continue;
                }
              }
              file.ownerID = item["ownerID"];
              file.encryptedKey = item["encryptedKey"];
              file.keyDecryptionNonce = item["keyDecryptionNonce"];
              file.fileDecryptionHeader = item["file"]["decryptionHeader"];
              file.thumbnailDecryptionHeader =
                  item["thumbnail"]["decryptionHeader"];
              file.metadataDecryptionHeader =
                  item["metadata"]["decryptionHeader"];
              final encodedMetadata = CryptoUtil.decryptChaCha(
                Sodium.base642bin(item["metadata"]["encryptedData"]),
                decryptFileKey(file),
                Sodium.base642bin(file.metadataDecryptionHeader),
              );
              Map<String, dynamic> metadata =
                  jsonDecode(utf8.decode(encodedMetadata));
              file.applyMetadata(metadata);
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
            return Diff(files, diff.length);
          } else {
            Bus.instance.fire(RemoteSyncEvent(false));
            return Diff(List<File>(), 0);
          }
        });
  }
}

class Diff {
  final List<File> updatedFiles;
  final int fetchCount;

  Diff(this.updatedFiles, this.fetchCount);
}
