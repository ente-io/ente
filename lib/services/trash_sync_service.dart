import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/models/trash_item_request.dart';
import 'package:photos/utils/trash_diff_fetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrashSyncService {
  final _logger = Logger("TrashSyncService");
  final _diffFetcher = TrashDiffFetcher();
  final _filesDB = FilesDB.instance;
  final _trashDB = TrashDB.instance;
  static const kDiffLimit = 2500;
  static const kLastTrashSyncTime = "last_trash_sync_time";
  SharedPreferences _prefs;

  TrashSyncService._privateConstructor();

  static final TrashSyncService instance =
      TrashSyncService._privateConstructor();
  final _dio = Network.instance.getDio();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> syncTrash() async {
    final lastSyncTime = getSyncTime();
    _logger.fine('sync trash sinceTime : $lastSyncTime');
    var diff = await _diffFetcher.getTrashFilesDiff(lastSyncTime, kDiffLimit);
    if (diff.trashedFiles.isNotEmpty) {
      _logger.fine("inserting ${diff.trashedFiles.length} items in trash");
      await _trashDB.insertMultiple(diff.trashedFiles);
    }
    if (diff.deletedFiles.isNotEmpty) {
      _logger.fine("discard ${diff.deletedFiles.length} deleted items");
      await _trashDB
          .delete(diff.deletedFiles.map((e) => e.file.uploadedFileID).toList());
    }
    if (diff.restoredFiles.isNotEmpty) {
      _logger.fine("discard ${diff.restoredFiles.length} restored items");
      await _trashDB.delete(
          diff.restoredFiles.map((e) => e.file.uploadedFileID).toList());
    }
    if (diff.lastSyncedTimeStamp != 0) {
      await setSyncTime(diff.lastSyncedTimeStamp);
    }
    if (diff.fetchCount == kDiffLimit) {
      return await syncTrash();
    }
  }

  Future<void> setSyncTime(int time) async {
    if (time == null) {
      return _prefs.remove(kLastTrashSyncTime);
    }
    return _prefs.setInt(kLastTrashSyncTime, time);
  }

  int getSyncTime() {
    return _prefs.getInt(kLastTrashSyncTime) ?? 0;
  }

  Future<void> trashFilesOnServer(List<TrashRequest> trashRequestItems) async {
    final params = <String, dynamic>{};
    params["items"] = [];
    for (final item in trashRequestItems) {
      params["items"].add(item.toJson());
    }
    return await _dio.post(
      Configuration.instance.getHttpEndpoint() + "/files/trash",
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
        },
      ),
      data: params,
    );
  }
}
