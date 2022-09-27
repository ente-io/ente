// @dart=2.9

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class DiffFetcher {
  final _logger = Logger("DiffFetcher");
  final _dio = Network.instance.getDio();

  Future<Diff> getEncryptedFilesDiff(int collectionID, int sinceTime) async {
    _logger.info(
      "Fetching diff in collection " +
          collectionID.toString() +
          " since " +
          sinceTime.toString(),
    );
    try {
      final response = await _dio.get(
        Configuration.instance.getHttpEndpoint() + "/collections/v2/diff",
        options: Options(
          headers: {"X-Auth-Token": Configuration.instance.getToken()},
        ),
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
        },
      );
      final files = <File>[];
      int latestUpdatedAtTime = 0;
      if (response != null) {
        final diff = response.data["diff"] as List;
        final bool hasMore = response.data["hasMore"] as bool;
        final startTime = DateTime.now();
        final existingFiles =
            await FilesDB.instance.getUploadedFileIDs(collectionID);
        final deletedFiles = <File>[];
        for (final item in diff) {
          final file = File();
          file.uploadedFileID = item["id"];
          file.collectionID = item["collectionID"];
          file.updationTime = item["updationTime"];
          latestUpdatedAtTime = max(latestUpdatedAtTime, file.updationTime);
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
          file.ownerID = item["ownerID"];
          file.encryptedKey = item["encryptedKey"];
          file.keyDecryptionNonce = item["keyDecryptionNonce"];
          file.fileDecryptionHeader = item["file"]["decryptionHeader"];
          file.thumbnailDecryptionHeader =
              item["thumbnail"]["decryptionHeader"];
          file.metadataDecryptionHeader = item["metadata"]["decryptionHeader"];
          if (item["info"] != null) {
            file.fileSize = item["info"]["fileSize"];
          }

          final fileDecryptionKey = decryptFileKey(file);
          final encodedMetadata = await CryptoUtil.decryptChaCha(
            Sodium.base642bin(item["metadata"]["encryptedData"]),
            fileDecryptionKey,
            Sodium.base642bin(file.metadataDecryptionHeader),
          );
          final Map<String, dynamic> metadata =
              jsonDecode(utf8.decode(encodedMetadata));
          file.applyMetadata(metadata);
          if (item['magicMetadata'] != null) {
            final utfEncodedMmd = await CryptoUtil.decryptChaCha(
              Sodium.base642bin(item['magicMetadata']['data']),
              fileDecryptionKey,
              Sodium.base642bin(item['magicMetadata']['header']),
            );
            file.mMdEncodedJson = utf8.decode(utfEncodedMmd);
            file.mMdVersion = item['magicMetadata']['version'];
            file.magicMetadata =
                MagicMetadata.fromEncodedJson(file.mMdEncodedJson);
          }
          if (item['pubMagicMetadata'] != null) {
            final utfEncodedMmd = await CryptoUtil.decryptChaCha(
              Sodium.base642bin(item['pubMagicMetadata']['data']),
              fileDecryptionKey,
              Sodium.base642bin(item['pubMagicMetadata']['header']),
            );
            file.pubMmdEncodedJson = utf8.decode(utfEncodedMmd);
            file.pubMmdVersion = item['pubMagicMetadata']['version'];
            file.pubMagicMetadata =
                PubMagicMetadata.fromEncodedJson(file.pubMmdEncodedJson);
          }
          files.add(file);
        }

        final endTime = DateTime.now();
        _logger.info(
          "time for parsing " +
              files.length.toString() +
              " items within collection " +
              collectionID.toString() +
              ": " +
              Duration(
                microseconds: (endTime.microsecondsSinceEpoch -
                    startTime.microsecondsSinceEpoch),
              ).inMilliseconds.toString(),
        );
        return Diff(files, deletedFiles, hasMore, latestUpdatedAtTime);
      } else {
        return Diff(<File>[], <File>[], false, 0);
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
  final bool hasMore;
  final int latestUpdatedAtTime;

  Diff(
    this.updatedFiles,
    this.deletedFiles,
    this.hasMore,
    this.latestUpdatedAtTime,
  );
}
