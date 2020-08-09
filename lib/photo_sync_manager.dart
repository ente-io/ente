import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
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
  final _db = FilesDB.instance;
  bool _isSyncInProgress = false;
  Future<void> _existingSync;
  SharedPreferences _prefs;

  static final _lastSyncTimeKey = "last_sync_time";
  static final _lastDBUpdationTimeKey = "last_db_updation_time";
  static final _diffLimit = 100;

  PhotoSyncManager._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final PhotoSyncManager instance =
      PhotoSyncManager._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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

  bool hasScannedDisk() {
    return _prefs.containsKey(_lastDBUpdationTimeKey);
  }

  Future<void> _doSync() async {
    final result = await PhotoManager.requestPermission();
    if (!result) {
      _logger.severe("Did not get permission");
    }
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    var lastDBUpdationTime = _prefs.getInt(_lastDBUpdationTimeKey);
    if (lastDBUpdationTime == null) {
      lastDBUpdationTime = 0;
      await _initializeDirectories();
    }

    final pathEntities =
        await _getGalleryList(lastDBUpdationTime, syncStartTime);
    final files = List<File>();
    AssetPathEntity recents;
    for (AssetPathEntity pathEntity in pathEntities) {
      if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
        recents = pathEntity;
      } else {
        await _addToPhotos(pathEntity, lastDBUpdationTime, files);
      }
    }
    if (recents != null) {
      await _addToPhotos(recents, lastDBUpdationTime, files);
    }
    files.sort(
        (first, second) => first.creationTime.compareTo(second.creationTime));

    await _insertFilesToDB(files, syncStartTime);
    await FileRepository.instance.reloadFiles();
    await _syncWithRemote();
  }

  Future<List<AssetPathEntity>> _getGalleryList(
      final int fromTimestamp, final int toTimestamp) async {
    final filterOptionGroup = FilterOptionGroup();
    filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
    filterOptionGroup.setOption(AssetType.video, FilterOption(needTitle: true));
    filterOptionGroup.dateTimeCond = DateTimeCond(
      min: DateTime.fromMicrosecondsSinceEpoch(fromTimestamp),
      max: DateTime.fromMicrosecondsSinceEpoch(toTimestamp),
    );
    final galleryList = await PhotoManager.getAssetPathList(
      hasAll: true,
      type: RequestType.common,
      filterOption: filterOptionGroup,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    return galleryList;
  }

  Future _addToPhotos(AssetPathEntity pathEntity, int lastDBUpdationTime,
      List<File> files) async {
    final assetList = await pathEntity.assetList;
    for (AssetEntity entity in assetList) {
      if (max(entity.createDateTime.microsecondsSinceEpoch,
              entity.modifiedDateTime.microsecondsSinceEpoch) >
          lastDBUpdationTime) {
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

  Future<void> _syncWithRemote() async {
    // TODO:  Fix race conditions triggered due to concurrent syncs.
    //        Add device_id/last_sync_timestamp to the upload request?
    if (!Configuration.instance.hasConfiguredAccount()) {
      return Future.error("Account not configured yet");
    }
    await _downloadDiff();
    await _uploadDiff();
    await _deletePhotosOnServer();
  }

  Future<void> _downloadDiff() async {
    final diff = await _getDiff(_getLastSyncTimestamp(), _diffLimit);
    if (diff != null && diff.isNotEmpty) {
      await _storeDiff(diff);
      FileRepository.instance.reloadFiles();
      if (diff.length == _diffLimit) {
        return await _downloadDiff();
      }
    }
  }

  int _getLastSyncTimestamp() {
    var lastSyncTimestamp = _prefs.getInt(_lastSyncTimeKey);
    if (lastSyncTimestamp == null) {
      lastSyncTimestamp = 0;
    }
    return lastSyncTimestamp;
  }

  Future<void> _uploadDiff() async {
    List<File> photosToBeUploaded = await _db.getFilesToBeUploaded();
    for (int i = 0; i < photosToBeUploaded.length; i++) {
      File file = photosToBeUploaded[i];
      if (file.fileType == FileType.video) {
        continue;
      }
      _logger.info("Uploading " + file.toString());
      try {
        final uploadedFile = await _uploadFile(file);
        await _db.update(file.generatedID, uploadedFile.uploadedFileID,
            uploadedFile.updationTime);
        _prefs.setInt(_lastSyncTimeKey, uploadedFile.updationTime);

        Bus.instance.fire(PhotoUploadEvent(
            completed: i + 1, total: photosToBeUploaded.length));
      } catch (e) {
        Bus.instance.fire(PhotoUploadEvent(hasError: true));
        throw e;
      }
    }
  }

  Future _storeDiff(List<File> diff) async {
    for (File file in diff) {
      try {
        final existingPhoto = await _db.getMatchingFile(
            file.localID,
            file.title,
            file.deviceFolder,
            file.creationTime,
            file.modificationTime,
            alternateTitle: getHEICFileNameForJPG(file));
        await _db.update(
            existingPhoto.generatedID, file.uploadedFileID, file.updationTime);
      } catch (e) {
        file.localID = null; // File uploaded from a different device
        await _db.insert(file);
      }
      await _prefs.setInt(_lastSyncTimeKey, file.updationTime);
    }
  }

  Future<List<File>> _getDiff(int lastSyncTime, int limit) async {
    Response response = await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/files/diff",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      queryParameters: {
        "sinceTimestamp": lastSyncTime,
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
      "deviceFileID": localPhoto.localID,
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
              file.uploadedFileID.toString(),
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .catchError((e) => _logger.severe(e));
  }

  Future _initializeDirectories() async {
    final externalPath = (await getApplicationDocumentsDirectory()).path;
    new Directory(externalPath + "/photos/thumbnails")
        .createSync(recursive: true);
  }

  Future<bool> _insertFilesToDB(List<File> files, int timestamp) async {
    await _db.insertMultiple(files);
    _logger.info("Inserted " + files.length.toString() + " files.");
    return await _prefs.setInt(_lastDBUpdationTimeKey, timestamp);
  }
}
