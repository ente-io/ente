import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class DiffFetcher {
  final _logger = Logger("DiffFetcher");
  final _enteDio = NetworkClient.instance.enteDio;

  Future<Diff> getEncryptedFilesDiff(int collectionID, int sinceTime) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2/diff",
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
        },
      );
      int latestUpdatedAtTime = 0;
      final diff = response.data["diff"] as List;
      final bool hasMore = response.data["hasMore"] as bool;
      final startTime = DateTime.now();
      late Set<int> existingUploadIDs;
      if(diff.isNotEmpty) {
        existingUploadIDs = await FilesDB.instance.getUploadedFileIDs(collectionID);
      }
      final deletedFiles = <File>[];
      final updatedFiles = <File>[];

      for (final item in diff) {
        final file = File();
        file.uploadedFileID = item["id"];
        file.collectionID = item["collectionID"];
        file.updationTime = item["updationTime"];
        latestUpdatedAtTime = max(latestUpdatedAtTime, file.updationTime!);
        if (item["isDeleted"]) {
          if (existingUploadIDs.contains(file.uploadedFileID)) {
            deletedFiles.add(file);
          }
          continue;
        }
        if (existingUploadIDs.contains(file.uploadedFileID)) {
          final existingFile = await FilesDB.instance
              .getUploadedFile(file.uploadedFileID!, file.collectionID!);
          if (existingFile != null) {
            file.generatedID = existingFile.generatedID;
            file.addedTime = existingFile.addedTime;
          }
        }
        file.ownerID = item["ownerID"];
        file.encryptedKey = item["encryptedKey"];
        file.keyDecryptionNonce = item["keyDecryptionNonce"];
        file.fileDecryptionHeader = item["file"]["decryptionHeader"];
        file.thumbnailDecryptionHeader = item["thumbnail"]["decryptionHeader"];
        file.metadataDecryptionHeader = item["metadata"]["decryptionHeader"];
        if (item["info"] != null) {
          file.fileSize = item["info"]["fileSize"];
        }
        final fileKey = getFileKey(file);
        final encodedMetadata = await CryptoUtil.decryptChaCha(
          CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
          fileKey,
          CryptoUtil.base642bin(file.metadataDecryptionHeader!),
        );
        final Map<String, dynamic> metadata =
            jsonDecode(utf8.decode(encodedMetadata));
        file.applyMetadata(metadata);
        if (item['magicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(item['magicMetadata']['data']),
            fileKey,
            CryptoUtil.base642bin(item['magicMetadata']['header']),
          );
          file.mMdEncodedJson = utf8.decode(utfEncodedMmd);
          file.mMdVersion = item['magicMetadata']['version'];
          file.magicMetadata =
              MagicMetadata.fromEncodedJson(file.mMdEncodedJson!);
        }
        if (item['pubMagicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(item['pubMagicMetadata']['data']),
            fileKey,
            CryptoUtil.base642bin(item['pubMagicMetadata']['header']),
          );
          file.pubMmdEncodedJson = utf8.decode(utfEncodedMmd);
          file.pubMmdVersion = item['pubMagicMetadata']['version'];
          file.pubMagicMetadata =
              PubMagicMetadata.fromEncodedJson(file.pubMmdEncodedJson!);
        }
        updatedFiles.add(file);
      }
      _logger.info('[Collection-$collectionID] parsed ${diff.length} '
          'diff items ( ${updatedFiles.length} updated) in ${DateTime.now()
          .difference(startTime).inMilliseconds}ms');
      return Diff(updatedFiles, deletedFiles, hasMore, latestUpdatedAtTime);
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class Diff {
  final List<File> updatedFiles;
  final List<File> deletedFiles;
  final bool hasMore;
  final int latestUpdatedAtTime;

  Diff(
    this.updatedFiles,
    this.deletedFiles,
    this.hasMore,
    this.latestUpdatedAtTime,
  );
}
