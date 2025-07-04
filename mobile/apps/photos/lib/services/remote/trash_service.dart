import 'dart:async';
import "dart:math";
import "dart:typed_data";

import 'package:dio/dio.dart';
import "package:ente_crypto/ente_crypto.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/db/remote/table/collection_files.dart";
import "package:photos/db/remote/table/trash.dart";
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/events/trash_updated_event.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/api/collection/trash_item_request.dart';
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/diff/trash_time.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/ignored_file.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/remote/fetch/files_diff.dart";
import "package:shared_preferences/shared_preferences.dart";

class TrashSyncService {
  final _logger = Logger("TrashSyncService");

  static const kLastTrashSyncTime = "last_trash_sync_time_v2";
  final SharedPreferences _prefs;
  final Dio _enteDio;

  TrashSyncService(this._prefs, this._enteDio) {
    _logger.fine("TrashSyncService constructor");
  }

  Future<void> syncTrash() async {
    bool hasMore = true;
    do {
      final diff = await getTrashFilesDiff(_getSyncTime());
      bool isLocalTrashUpdated = false;
      if (diff.trashedFiles.isNotEmpty) {
        isLocalTrashUpdated = true;
        await remoteDB.insertTrashDiffItems(diff.trashedFiles);
      }
      if (diff.deletedIDs.isNotEmpty || diff.restoredIDs.isNotEmpty) {
        _logger.fine(
          "deleting ${diff.deletedIDs.length} deleted items and restoring ${diff.restoredIDs.length} restored items",
        );
        final ids = diff.deletedIDs + diff.restoredIDs;
        final itemsDeleted = await remoteDB.removeTrashItems(ids);
        isLocalTrashUpdated = isLocalTrashUpdated || itemsDeleted > 0;
      }

      await _updateIgnoredFiles(diff);
      if (diff.lastSyncedTimeStamp != 0) {
        await _setSyncTime(diff.lastSyncedTimeStamp);
      }
      if (isLocalTrashUpdated) {
        Bus.instance.fire(TrashUpdatedEvent());
      }
      hasMore = diff.hasMore;
    } while (hasMore);
  }

  Future<void> _updateIgnoredFiles(TrashDiff diff) async {
    final ignoredFiles = <IgnoredFile>[];
    for (DiffItem t in diff.trashedFiles) {
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
    final ownedCollectionIDs =
        CollectionsService.instance.getAllOwnedCollectionIDs();
    for (final item in trashRequestItems) {
      if (!includedFileIDs.contains(item.fileID)) {
        // Check if the collectionID in the request is owned by the user
        if (ownedCollectionIDs.contains(item.collectionID)) {
          uniqueItems.add(item);
          includedFileIDs.add(item.fileID);
        } else {
          // If not owned, use a different owned collectionID
          bool foundAnotherOwnedCollection = false;
          final fileCollectionIDs =
              await remoteDB.getAllCollectionIDsOfFile(item.fileID);

          for (final collectionID in fileCollectionIDs) {
            if (ownedCollectionIDs.contains(collectionID)) {
              final newItem = TrashRequest(item.fileID, collectionID);
              uniqueItems.add(newItem);
              includedFileIDs.add(item.fileID);
              foundAnotherOwnedCollection = true;
              break;
            }
          }
          if (!foundAnotherOwnedCollection) {
            _logger.severe(
              "File ${item.fileID} is not owned by the user and has no other owned collection",
            );
          }
        }
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
    await remoteDB.deleteFiles(includedFileIDs.toList());
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
      final trashedFiles = <DiffItem>[];
      final deletedUploadIDs = <int>[];
      final restoredFiles = <int>[];

      final diff = response.data["diff"] as List;
      final bool hasMore = response.data["hasMore"] as bool;
      for (final trashItem in diff) {
        final TrashTime trashTime = TrashTime.fromMap(trashItem);
        final int id = trashItem["file"]["id"] as int;
        latestUpdatedAtTime = max(latestUpdatedAtTime, trashTime.updatedAt);
        if (trashItem["isDeleted"]) {
          deletedUploadIDs.add(id);
          continue;
        }
        if (trashItem['isRestored']) {
          restoredFiles.add(id);
          continue;
        }

        final item = trashItem["file"];
        final int collectionID = item["collectionID"];
        final int cfUpdatedAt = item["updationTime"];

        final Uint8List encFileKey =
            CryptoUtil.base642bin(item["encryptedKey"]);
        final Uint8List encFileKeyNonce =
            CryptoUtil.base642bin(item["keyDecryptionNonce"]);

        final collectionKey =
            CollectionsService.instance.getCollectionKey(collectionID);

        final fileItem = RemoteFileDiffService.constructFileItem(
          item,
          collectionKey,
          CryptoUtil.base642bin(item["encryptedKey"]),
          CryptoUtil.base642bin(item["keyDecryptionNonce"]),
        );
        final diffItem = DiffItem(
          collectionID: collectionID,
          updatedAt: cfUpdatedAt,
          encFileKey: encFileKey,
          encFileKeyNonce: encFileKeyNonce,
          isDeleted: false,
          createdAt: item["createdAt"] ?? DateTime.now().millisecondsSinceEpoch,
          fileItem: fileItem,
          trashTime: trashTime,
        );
        trashedFiles.add(diffItem);
      }
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
        await remoteDB.removeTrashItems(batch);
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
      await remoteDB.clearTrash();
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
  final List<DiffItem> trashedFiles;
  final List<int> restoredIDs;
  final List<int> deletedIDs;
  final bool hasMore;
  final int lastSyncedTimeStamp;
  TrashDiff(
    this.trashedFiles,
    this.restoredIDs,
    this.deletedIDs,
    this.hasMore,
    this.lastSyncedTimeStamp,
  );
}
