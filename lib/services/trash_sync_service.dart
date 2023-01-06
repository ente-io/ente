import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/events/trash_updated_event.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/ignored_file.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/models/trash_item_request.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/utils/trash_diff_fetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrashSyncService {
  final _logger = Logger("TrashSyncService");
  final _diffFetcher = TrashDiffFetcher();
  final _trashDB = TrashDB.instance;
  static const kLastTrashSyncTime = "last_trash_sync_time";
  late SharedPreferences _prefs;

  TrashSyncService._privateConstructor();

  static final TrashSyncService instance =
      TrashSyncService._privateConstructor();
  final _enteDio = Network.instance.enteDio;

  void init(SharedPreferences preferences) {
    _prefs = preferences;
  }

  Future<void> syncTrash() async {
    final lastSyncTime = _getSyncTime();
    bool isLocalTrashUpdated = false;
    _logger.fine('sync trash sinceTime : $lastSyncTime');
    final diff = await _diffFetcher.getTrashFilesDiff(lastSyncTime);
    Set<String>? localFileIDs;
    if (diff.trashedFiles.isNotEmpty) {
      isLocalTrashUpdated = true;
      localFileIDs ??= await FilesDB.instance.getExistingLocalFileIDs();
      _logger.fine("inserting ${diff.trashedFiles.length} items in trash");
      // During sync, if trash file local ID is not present in currently
      // imported files, treat the file as deleted from device
      for (var trash in diff.trashedFiles) {
        if (trash.localID != null && !localFileIDs.contains(trash.localID)) {
          trash.localID = null;
        }
      }
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
          <File>[],
          "trash_change",
        ),
      );
    }
  }

  Future<void> _updateIgnoredFiles(Diff diff) async {
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

  Future<Response<dynamic>> _trashFiles(
    Map<String, dynamic> requestData,
  ) async {
    return _enteDio.post(
      "/files/trash",
      data: requestData,
    );
  }

  Future<void> deleteFromTrash(List<File> files) async {
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
