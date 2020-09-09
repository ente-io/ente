import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/file_repository.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/file_upload_manager.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/utils/crypto_util.dart';
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
  final _uploadManager = FileUploadManager();
  bool _isSyncInProgress = false;
  Future<void> _existingSync;
  SharedPreferences _prefs;

  static final _syncTimeKey = "sync_time";
  static final _encryptedFilesSyncTimeKey = "encrypted_files_sync_time";
  static final _dbUpdationTimeKey = "db_updation_time";
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
    return _prefs.containsKey(_dbUpdationTimeKey);
  }

  Future<void> _doSync() async {
    final result = await PhotoManager.requestPermission();
    if (!result) {
      _logger.severe("Did not get permission");
    }
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    var lastDBUpdationTime = _prefs.getInt(_dbUpdationTimeKey);
    if (lastDBUpdationTime == null) {
      lastDBUpdationTime = 0;
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
    await _downloadEncryptedFilesDiff();
    await _uploadDiff();
    await _deletePhotosOnServer();
  }

  Future<void> _downloadDiff() async {
    final diff = await _getDiff(_getSyncTime(), _diffLimit);
    if (diff != null && diff.isNotEmpty) {
      await _storeDiff(diff, _syncTimeKey);
      FileRepository.instance.reloadFiles();
      if (diff.length == _diffLimit) {
        return await _downloadDiff();
      }
    }
  }

  int _getSyncTime() {
    var syncTime = _prefs.getInt(_syncTimeKey);
    if (syncTime == null) {
      syncTime = 0;
    }
    return syncTime;
  }

  Future<void> _downloadEncryptedFilesDiff() async {
    final diff =
        await _getEncryptedFilesDiff(_getEncryptedFilesSyncTime(), _diffLimit);
    if (diff.isNotEmpty) {
      await _storeDiff(diff, _encryptedFilesSyncTimeKey);
      FileRepository.instance.reloadFiles();
      if (diff.length == _diffLimit) {
        return await _downloadEncryptedFilesDiff();
      }
    }
  }

  int _getEncryptedFilesSyncTime() {
    var syncTime = _prefs.getInt(_encryptedFilesSyncTimeKey);
    if (syncTime == null) {
      syncTime = 0;
    }
    return syncTime;
  }

  Future<void> _uploadDiff() async {
    List<File> photosToBeUploaded = await _db.getFilesToBeUploaded();
    for (int i = 0; i < photosToBeUploaded.length; i++) {
      File file = photosToBeUploaded[i];
      _logger.info("Uploading " + file.toString());
      try {
        if (file.fileType == FileType.video) {
          continue;
        }
        var uploadedFile;
        if (Configuration.instance.hasOptedForE2E()) {
          uploadedFile = await _uploadManager.encryptAndUploadFile(file);
        } else {
          uploadedFile = await _uploadManager.uploadFile(file);
        }
        await _db.update(file.generatedID, uploadedFile.uploadedFileID,
            uploadedFile.updationTime, file.encryptedKey, file.encryptedKeyIV);
        _prefs.setInt(_syncTimeKey, uploadedFile.updationTime);
        Bus.instance.fire(PhotoUploadEvent(
            completed: i + 1, total: photosToBeUploaded.length));
      } catch (e) {
        Bus.instance.fire(PhotoUploadEvent(hasError: true));
        throw e;
      }
    }
  }

  Future _storeDiff(List<File> diff, String prefKey) async {
    for (File file in diff) {
      try {
        final existingPhoto = await _db.getMatchingFile(
            file.localID,
            file.title,
            file.deviceFolder,
            file.creationTime,
            file.modificationTime,
            file.encryptedKey,
            file.encryptedKeyIV,
            alternateTitle: getHEICFileNameForJPG(file));
        await _db.update(existingPhoto.generatedID, file.uploadedFileID,
            file.updationTime, file.encryptedKey, file.encryptedKeyIV);
      } catch (e) {
        file.localID = null; // File uploaded from a different device
        await _db.insert(file);
      }
      await _prefs.setInt(prefKey, file.updationTime);
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

  Future<List<File>> _getEncryptedFilesDiff(int lastSyncTime, int limit) async {
    return _dio
        .get(
          Configuration.instance.getHttpEndpoint() + "/encrypted-files/diff",
          queryParameters: {
            "token": Configuration.instance.getToken(),
            "sinceTimestamp": lastSyncTime,
            "limit": limit,
          },
        )
        .catchError((e) => _logger.severe(e))
        .then((response) async {
          final files = List<File>();
          if (response != null) {
            Bus.instance.fire(RemoteSyncEvent(true));
            final diff = response.data["diff"] as List;
            for (final fileItem in diff) {
              final file = File();
              file.uploadedFileID = fileItem["id"];
              file.ownerID = fileItem["ownerID"];
              file.updationTime = fileItem["updationTime"];
              file.isEncrypted = true;
              file.encryptedKey = fileItem["encryptedKey"];
              file.encryptedKeyIV = fileItem["encryptedKeyIV"];
              final key = CryptoUtil.aesDecrypt(
                  base64.decode(file.encryptedKey),
                  Configuration.instance.getKey(),
                  base64.decode(file.encryptedKeyIV));
              Map<String, dynamic> metadata = jsonDecode(utf8.decode(
                  await CryptoUtil.decryptDataToData(fileItem["metadata"], key)));
              file.applyMetadata(metadata);
              files.add(file);
            }
          } else {
            Bus.instance.fire(RemoteSyncEvent(false));
          }
          return files;
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

  Future<bool> _insertFilesToDB(List<File> files, int timestamp) async {
    await _db.insertMultiple(files);
    _logger.info("Inserted " + files.length.toString() + " files.");
    return await _prefs.setInt(_dbUpdationTimeKey, timestamp);
  }
}
