import 'dart:async';
import "dart:convert";
import "dart:math";

import 'package:dio/dio.dart';
import "package:ente_crypto/ente_crypto.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/events/trash_updated_event.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/api/collection/trash_item_request.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/trash_file.dart';
import 'package:photos/models/ignored_file.dart';
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/services/ignored_files_service.dart';
import "package:photos/utils/file_key.dart";
import 'package:shared_preferences/shared_preferences.dart';

class TrashSyncService {
  final _logger = Logger("TrashSyncService");

  final _trashDB = TrashDB.instance;
  static const kLastTrashSyncTime = "last_trash_sync_time";
  late SharedPreferences _prefs;
  final Dio _enteDio;

  TrashSyncService(this._prefs, this._enteDio) {
    _logger.fine("TrashSyncService constructor");
  }

  void init(SharedPreferences preferences) {
    _prefs = preferences;
  }

  Future<void> syncTrash() async {
    final lastSyncTime = _getSyncTime();
    bool isLocalTrashUpdated = false;
    _logger.fine('sync trash sinceTime : $lastSyncTime');
    final diff = await getTrashFilesDiff(lastSyncTime);
    if (diff.trashedFiles.isNotEmpty) {
      isLocalTrashUpdated = true;
      _logger.fine("inserting ${diff.trashedFiles.length} items in trash");
      await _trashDB.insertMultiple(diff.trashedFiles);
    }
    if (diff.deletedUploadIDs.isNotEmpty) {
      _logger.fine("discard ${diff.deletedUploadIDs.length} deleted items");
      final itemsDeleted = await _trashDB.delete(diff.deletedUploadIDs);
      isLocalTrashUpdated = isLocalTrashUpdated || itemsDeleted > 0;
    }
    if (diff.restoredFiles.isNotEmpty) {
      _logger.fine("discard ${diff.restoredFiles.length} restored items");
      final itemsDeleted = await _trashDB
          .delete(diff.restoredFiles.map((e) => e.uploadedFileID!).toList());
      isLocalTrashUpdated = isLocalTrashUpdated || itemsDeleted > 0;
    }

    await _updateIgnoredFiles(diff);

    if (diff.lastSyncedTimeStamp != 0) {
      await _setSyncTime(diff.lastSyncedTimeStamp);
    }
    if (isLocalTrashUpdated) {
      _logger
          .fine('local trash updated, fire ${(TrashUpdatedEvent).toString()}');
      Bus.instance.fire(TrashUpdatedEvent());
    }
    if (diff.hasMore) {
      return await syncTrash();
    } else if (diff.trashedFiles.isNotEmpty ||
        diff.deletedUploadIDs.isNotEmpty) {
      Bus.instance.fire(
        CollectionUpdatedEvent(
          0,
          <EnteFile>[],
          "trash_change",
        ),
      );
    }
  }

  Future<void> _updateIgnoredFiles(TrashDiff diff) async {
    final ignoredFiles = <IgnoredFile>[];
    for (TrashFile t in diff.trashedFiles) {
      final file = IgnoredFile.fromTrashItem(t);
      if (file != null) {
        ignoredFiles.add(file);
      }
    }
    if (ignoredFiles.isNotEmpty) {
      _logger.fine('updating ${ignoredFiles.length} ignored files ');
      await IgnoredFilesService.instance.cacheAndInsert(ignoredFiles);
    }
  }

  Future<bool> _setSyncTime(int time) async {
    return _prefs.setInt(kLastTrashSyncTime, time);
  }

  int _getSyncTime() {
    return _prefs.getInt(kLastTrashSyncTime) ?? 0;
  }

  Future<void> trashFilesOnServer(List<TrashRequest> trashRequestItems) async {
    final includedFileIDs = <int>{};
    final uniqueItems = <TrashRequest>[];
    for (final item in trashRequestItems) {
      if (!includedFileIDs.contains(item.fileID)) {
        uniqueItems.add(item);
        includedFileIDs.add(item.fileID);
      }
    }
    final requestData = <String, dynamic>{};
    final batchedItems = uniqueItems.chunks(batchSize);
    for (final batch in batchedItems) {
      requestData["items"] = [];
      for (final item in batch) {
        requestData["items"].add(item.toJson());
      }
      await _trashFiles(requestData);
    }
  }

  Future<TrashDiff> getTrashFilesDiff(int sinceTime) async {
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
        final fileDecryptionKey = getFileKey(trash);
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
      return TrashDiff(
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

  Future<Response<dynamic>> _trashFiles(
    Map<String, dynamic> requestData,
  ) async {
    return _enteDio.post(
      "/files/trash",
      data: requestData,
    );
  }

  Future<void> deleteFromTrash(List<EnteFile> files) async {
    final params = <String, dynamic>{};
    final uniqueFileIds = files.map((e) => e.uploadedFileID!).toSet().toList();
    final batchedFileIDs = uniqueFileIds.chunks(batchSize);
    for (final batch in batchedFileIDs) {
      params["fileIDs"] = [];
      for (final fileID in batch) {
        params["fileIDs"].add(fileID);
      }
      try {
        await _enteDio.post(
          "/trash/delete",
          data: params,
        );
        await _trashDB.delete(batch);
        Bus.instance.fire(TrashUpdatedEvent());
      } catch (e, s) {
        _logger.severe("failed to delete from trash", e, s);
        rethrow;
      }
    }
    // no need to await on syncing trash from remote
    unawaited(syncTrash());
  }

  Future<void> emptyTrash() async {
    final params = <String, dynamic>{};
    params["lastUpdatedAt"] = _getSyncTime();
    try {
      await _enteDio.post(
        "/trash/empty",
        data: params,
      );
      await _trashDB.clearTable();
      unawaited(syncTrash());
      Bus.instance.fire(TrashUpdatedEvent());
      Bus.instance.fire(ForceReloadTrashPageEvent());
    } catch (e, s) {
      _logger.severe("failed to empty trash", e, s);
      rethrow;
    }
  }
}

class TrashDiff {
  final List<TrashFile> trashedFiles;
  final List<TrashFile> restoredFiles;
  final List<int> deletedUploadIDs;
  final bool hasMore;
  final int lastSyncedTimeStamp;
  TrashDiff(
    this.trashedFiles,
    this.restoredFiles,
    this.deletedUploadIDs,
    this.hasMore,
    this.lastSyncedTimeStamp,
  );
}
