import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_key.dart";

class DiffFetcher {
  final _logger = Logger("DiffFetcher");
  final _enteDio = NetworkClient.instance.enteDio;

  Future<List<EnteFile>> getPublicFiles(
    BuildContext context,
    int collectionID,
    bool sortAsc,
  ) async {
    try {
      bool hasMore = false;
      final sharedFiles = <EnteFile>[];
      final headers =
          CollectionsService.instance.publicCollectionHeaders(collectionID);
      int sinceTime = 0;

      do {
        final response = await _enteDio.get(
          "/public-collection/diff",
          options: Options(headers: headers),
          queryParameters: {"sinceTime": sinceTime},
        );

        final diff = response.data["diff"] as List;
        hasMore = response.data["hasMore"] as bool;

        for (final item in diff) {
          final file = EnteFile();
          if (item["isDeleted"]) {
            continue;
          }
          file.uploadedFileID = item["id"];
          file.collectionID = item["collectionID"];
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
          final fileKey = getFileKey(file);
          final encodedMetadata = await CryptoUtil.decryptChaCha(
            CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
            fileKey,
            CryptoUtil.base642bin(file.metadataDecryptionHeader!),
          );
          final Map<String, dynamic> metadata =
              jsonDecode(utf8.decode(encodedMetadata));
          file.applyMetadata(metadata);
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

          // To avoid local file to be used as thumbnail or full file.
          file.localID = null;

          sharedFiles.add(file);
        }

        if (diff.isNotEmpty) {
          sinceTime = diff.last["updationTime"];
        }
      } while (hasMore);
      if (sortAsc) {
        sharedFiles.sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
      }
      return sharedFiles;
    } catch (e, s) {
      _logger.severe("Failed to decrypt collection ", e, s);
      await showErrorDialog(
        context,
        AppLocalizations.of(context).somethingWentWrong,
        e.toString(),
      );
      rethrow;
    }
  }

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
      if (diff.isNotEmpty) {
        existingUploadIDs =
            await FilesDB.instance.getUploadedFileIDs(collectionID);
      }
      final deletedFiles = <EnteFile>[];
      final updatedFiles = <EnteFile>[];

      for (final item in diff) {
        final file = EnteFile();
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
          'diff items ( ${updatedFiles.length} updated) in ${DateTime.now().difference(startTime).inMilliseconds}ms');
      return Diff(updatedFiles, deletedFiles, hasMore, latestUpdatedAtTime);
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class Diff {
  final List<EnteFile> updatedFiles;
  final List<EnteFile> deletedFiles;
  final bool hasMore;
  final int latestUpdatedAtTime;

  Diff(
    this.updatedFiles,
    this.deletedFiles,
    this.hasMore,
    this.latestUpdatedAtTime,
  );
}
