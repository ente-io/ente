import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class TrashDiffFetcher {
  final _logger = Logger("TrashDiffFetcher");
  final _enteDio = Network.instance.enteDio;

  Future<Diff> getTrashFilesDiff(int sinceTime) async {
    try {
      final response = await _enteDio.get(
        "/trash/v2/diff",
        queryParameters: {
          "sinceTime": sinceTime,
        },
      );
      int latestUpdatedAtTime = 0;
      final trashedFiles = <TrashFile>[];
      final deletedUploadIDs = <int>[];
      final restoredFiles = <TrashFile>[];

      final diff = response.data["diff"] as List;
      final bool hasMore = response.data["hasMore"] as bool;
      final startTime = DateTime.now();
      for (final item in diff) {
        final trash = TrashFile();
        trash.createdAt = item['createdAt'];
        trash.updateAt = item['updatedAt'];
        latestUpdatedAtTime = max(latestUpdatedAtTime, trash.updateAt);
        if (item["isDeleted"]) {
          deletedUploadIDs.add(item["file"]["id"]);
          continue;
        }

        trash.deleteBy = item['deleteBy'];
        trash.uploadedFileID = item["file"]["id"];
        trash.collectionID = item["file"]["collectionID"];
        trash.updationTime = item["file"]["updationTime"];
        trash.ownerID = item["file"]["ownerID"];
        trash.encryptedKey = item["file"]["encryptedKey"];
        trash.keyDecryptionNonce = item["file"]["keyDecryptionNonce"];
        trash.fileDecryptionHeader = item["file"]["file"]["decryptionHeader"];
        trash.thumbnailDecryptionHeader =
            item["file"]["thumbnail"]["decryptionHeader"];
        trash.metadataDecryptionHeader =
            item["file"]["metadata"]["decryptionHeader"];
        final fileDecryptionKey = decryptFileKey(trash);
        final encodedMetadata = await CryptoUtil.decryptChaCha(
          CryptoUtil.base642bin(item["file"]["metadata"]["encryptedData"]),
          fileDecryptionKey,
          CryptoUtil.base642bin(trash.metadataDecryptionHeader!),
        );
        final Map<String, dynamic> metadata =
            jsonDecode(utf8.decode(encodedMetadata));
        trash.applyMetadata(metadata);
        if (item["file"]['magicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(item["file"]['magicMetadata']['data']),
            fileDecryptionKey,
            CryptoUtil.base642bin(item["file"]['magicMetadata']['header']),
          );
          trash.mMdEncodedJson = utf8.decode(utfEncodedMmd);
          trash.mMdVersion = item["file"]['magicMetadata']['version'];
        }
        if (item["file"]['pubMagicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(item["file"]['pubMagicMetadata']['data']),
            fileDecryptionKey,
            CryptoUtil.base642bin(item["file"]['pubMagicMetadata']['header']),
          );
          trash.pubMmdEncodedJson = utf8.decode(utfEncodedMmd);
          trash.pubMmdVersion = item["file"]['pubMagicMetadata']['version'];
          trash.pubMagicMetadata =
              PubMagicMetadata.fromEncodedJson(trash.pubMmdEncodedJson!);
        }
        if (item['isRestored']) {
          restoredFiles.add(trash);
          continue;
        }
        trashedFiles.add(trash);
      }

      final endTime = DateTime.now();
      _logger.info(
        "time for parsing " +
            diff.length.toString() +
            ": " +
            Duration(
              microseconds: (endTime.microsecondsSinceEpoch -
                  startTime.microsecondsSinceEpoch),
            ).inMilliseconds.toString(),
      );
      return Diff(
        trashedFiles,
        restoredFiles,
        deletedUploadIDs,
        hasMore,
        latestUpdatedAtTime,
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class Diff {
  final List<TrashFile> trashedFiles;
  final List<TrashFile> restoredFiles;
  final List<int> deletedUploadIDs;
  final bool hasMore;
  final int lastSyncedTimeStamp;

  Diff(
    this.trashedFiles,
    this.restoredFiles,
    this.deletedUploadIDs,
    this.hasMore,
    this.lastSyncedTimeStamp,
  );
}
