import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/file_db.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/file_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:photos/models/file.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/events/remote_sync_event.dart';

class PhotoSyncManager {
  final _logger = Logger("PhotoSyncManager");
  final _dio = Dio();
  final _db = FileDB.instance;
  bool _isSyncInProgress = false;
  Future<void> _existingSync;

  static final _lastSyncTimestampKey = "last_sync_timestamp_0";
  static final _lastDBUpdateTimestampKey = "last_db_update_timestamp";
  static final _diffLimit = 100;

  PhotoSyncManager._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final PhotoSyncManager instance =
      PhotoSyncManager._privateConstructor();

  Future<void> sync() async {
    if (_isSyncInProgress) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync;
    }
    _isSyncInProgress = true;
    _existingSync = Future<void>(() async {
      _logger.info("Syncing...");
      try {
        await _doSync();
      } catch (e) {
        throw e;
      } finally {
        _isSyncInProgress = false;
      }
    });
    return _existingSync;
  }

  Future<bool> hasScannedDisk() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_lastDBUpdateTimestampKey);
  }

  Future<void> _doSync() async {
    final prefs = await SharedPreferences.getInstance();
    final syncStartTimestamp = DateTime.now().microsecondsSinceEpoch;
    var lastDBUpdateTimestamp = prefs.getInt(_lastDBUpdateTimestampKey);
    if (lastDBUpdateTimestamp == null) {
      lastDBUpdateTimestamp = 0;
      await _initializeDirectories();
    }

    final pathEntities =
        await _getGalleryList(lastDBUpdateTimestamp, syncStartTimestamp);
    final files = List<File>();
    AssetPathEntity recents;
    for (AssetPathEntity pathEntity in pathEntities) {
      if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
        recents = pathEntity;
      } else {
        await _addToPhotos(pathEntity, lastDBUpdateTimestamp, files);
      }
    }
    if (recents != null) {
      await _addToPhotos(recents, lastDBUpdateTimestamp, files);
    }

    if (files.isNotEmpty) {
      files.sort(
          (first, second) => first.creationTime.compareTo(second.creationTime));
      await _updateDatabase(
          files, prefs, lastDBUpdateTimestamp, syncStartTimestamp);
      await FileRepository.instance.reloadFiles();
    }
    await _syncWithRemote(prefs);
  }

  Future<List<AssetPathEntity>> _getGalleryList(
      final int fromTimestamp, final int toTimestamp) async {
    var result = await PhotoManager.requestPermission();
    if (!result) {
      print("Did not get permission");
    }
    final filterOptionGroup = FilterOptionGroup();
    filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
    filterOptionGroup.setOption(AssetType.video, FilterOption(needTitle: true));
    filterOptionGroup.dateTimeCond = DateTimeCond(
      min: DateTime.fromMicrosecondsSinceEpoch(fromTimestamp),
      max: DateTime.fromMicrosecondsSinceEpoch(toTimestamp),
    );
    var galleryList = await PhotoManager.getAssetPathList(
      hasAll: true,
      type: RequestType.common,
      filterOption: filterOptionGroup,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    return galleryList;
  }

  Future _addToPhotos(AssetPathEntity pathEntity, int lastDBUpdateTimestamp,
      List<File> files) async {
    final assetList = await pathEntity.assetList;
    for (AssetEntity entity in assetList) {
      if (max(entity.createDateTime.microsecondsSinceEpoch,
              entity.modifiedDateTime.microsecondsSinceEpoch) >
          lastDBUpdateTimestamp) {
        try {
          final file = await File.fromAsset(pathEntity, entity);
          if (!files.contains(file)) {
            files.add(file);
          }
        } catch (e) {
          _logger.severe(e);
        }
      }
    }
  }

  Future<void> _syncWithRemote(SharedPreferences prefs) async {
    // TODO:  Fix race conditions triggered due to concurrent syncs.
    //        Add device_id/last_sync_timestamp to the upload request?
    if (!Configuration.instance.hasConfiguredAccount()) {
      return Future.error("Account not configured yet");
    }
    await _downloadDiff(prefs);
    await _uploadDiff(prefs);
    await _deletePhotosOnServer();
  }

  Future<bool> _updateDatabase(final List<File> files, SharedPreferences prefs,
      int lastDBUpdateTimestamp, int syncStartTimestamp) async {
    var filesToBeAdded = List<File>();
    for (File file in files) {
      if (file.creationTime > lastDBUpdateTimestamp) {
        filesToBeAdded.add(file);
      }
    }
    return await _insertFilesToDB(filesToBeAdded, prefs, syncStartTimestamp);
  }

  Future<void> _downloadDiff(SharedPreferences prefs) async {
    var diff = await _getDiff(_getLastSyncTimestamp(prefs), _diffLimit);
    if (diff != null && diff.isNotEmpty) {
      await _storeDiff(diff, prefs);
      FileRepository.instance.reloadFiles();
      if (diff.length == _diffLimit) {
        return await _downloadDiff(prefs);
      }
    }
  }

  int _getLastSyncTimestamp(SharedPreferences prefs) {
    var lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    return lastSyncTimestamp;
  }

  Future<void> _uploadDiff(SharedPreferences prefs) async {
    List<File> photosToBeUploaded = await _db.getFilesToBeUploaded();
    for (int i = 0; i < photosToBeUploaded.length; i++) {
      File file = photosToBeUploaded[i];
      if (file.fileType == FileType.video) {
        continue;
      }
      _logger.info("Uploading " + file.toString());
      try {
        var uploadedFile = await _uploadFile(file);
        await _db.update(file.generatedId, uploadedFile.uploadedFileId,
            uploadedFile.updationTime);
        prefs.setInt(_lastSyncTimestampKey, uploadedFile.updationTime);

        Bus.instance.fire(PhotoUploadEvent(
            completed: i + 1, total: photosToBeUploaded.length));
      } catch (e) {
        Bus.instance.fire(PhotoUploadEvent(hasError: true));
        throw e;
      }
    }
  }

  Future _storeDiff(List<File> diff, SharedPreferences prefs) async {
    for (File file in diff) {
      try {
        var existingPhoto = await _db.getMatchingFile(file.localId, file.title,
            file.deviceFolder, file.creationTime, file.modificationTime,
            alternateTitle: getHEICFileNameForJPG(file));
        await _db.update(
            existingPhoto.generatedId, file.uploadedFileId, file.updationTime);
      } catch (e) {
        await _db.insert(file);
      }
      await prefs.setInt(_lastSyncTimestampKey, file.updationTime);
    }
  }

  Future<List<File>> _getDiff(int lastSyncTimestamp, int limit) async {
    Response response = await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/files/diff",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      queryParameters: {
        "sinceTimestamp": lastSyncTimestamp,
        "limit": limit,
      },
    ).catchError((e) => _logger.severe(e));
    if (response != null) {
      Bus.instance.fire(RemoteSyncEvent(true));
      return (response.data["diff"] as List)
          .map((file) => new File.fromJson(file))
          .toList();
    } else {
      Bus.instance.fire(RemoteSyncEvent(false));
      return null;
    }
  }

  Future<File> _uploadFile(File localPhoto) async {
    final title = getJPGFileNameForHEIC(localPhoto);
    final formData = FormData.fromMap({
      "file": MultipartFile.fromFileSync(
          (await (await localPhoto.getAsset()).originFile).path,
          filename: title),
      "deviceFileID": localPhoto.localId,
      "deviceFolder": localPhoto.deviceFolder,
      "title": title,
      "creationTime": localPhoto.creationTime,
      "modificationTime": localPhoto.modificationTime,
    });
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: formData,
    )
        .then((response) {
      return File.fromJson(response.data);
    });
  }

  Future<void> _deletePhotosOnServer() async {
    return _db.getAllDeleted().then((deletedPhotos) async {
      for (File deletedPhoto in deletedPhotos) {
        await _deleteFileOnServer(deletedPhoto);
        await _db.delete(deletedPhoto);
      }
    });
  }

  Future<void> _deleteFileOnServer(File file) async {
    return _dio
        .delete(
          Configuration.instance.getHttpEndpoint() +
              "/files/" +
              file.uploadedFileId.toString(),
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .catchError((e) => _logger.severe(e));
  }

  Future _initializeDirectories() async {
    var externalPath = (await getApplicationDocumentsDirectory()).path;
    new Directory(externalPath + "/photos/thumbnails")
        .createSync(recursive: true);
  }

  Future<bool> _insertFilesToDB(
      List<File> files, SharedPreferences prefs, int timestamp) async {
    await _db.insertMultiple(files);
    _logger.info("Inserted " + files.length.toString() + " files.");
    return await prefs.setInt(_lastDBUpdateTimestampKey, timestamp);
  }
}
