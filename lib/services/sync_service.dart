import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/file_downloader.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:photos/models/file.dart';

import 'package:photos/core/configuration.dart';

class SyncService {
  final _logger = Logger("PhotoSyncManager");
  final _dio = Dio();
  final _db = FilesDB.instance;
  final _uploader = FileUploader.instance;
  final _collectionsService = CollectionsService.instance;
  final _downloader = DiffFetcher();
  bool _isSyncInProgress = false;
  bool _syncStopRequested = false;
  Future<void> _existingSync;
  SharedPreferences _prefs;

  static final _collectionSyncTimeKeyPrefix = "collection_sync_time_";
  static final _dbUpdationTimeKey = "db_updation_time";
  static final _diffLimit = 100;

  SyncService._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final SyncService instance = SyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> sync() async {
    _syncStopRequested = false;
    if (_isSyncInProgress) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync;
    }
    _isSyncInProgress = true;
    _existingSync = Future<void>(() async {
      _logger.info("Syncing...");
      try {
        await _doSync();
      } catch (e, s) {
        _logger.severe(e, s);
      } finally {
        _isSyncInProgress = false;
      }
    });
    return _existingSync;
  }

  void stopSync() {
    _logger.info("Sync stop requested");
    _syncStopRequested = true;
  }

  bool shouldStopSync() {
    return _syncStopRequested;
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
    if (files.isNotEmpty) {
      await _insertFilesToDB(files, syncStartTime);
      await FileRepository.instance.reloadFiles();
    }
    await syncWithRemote();
  }

  Future<List<AssetPathEntity>> _getGalleryList(
      final int fromTimestamp, final int toTimestamp) async {
    final filterOptionGroup = FilterOptionGroup();
    filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
    filterOptionGroup.setOption(AssetType.video, FilterOption(needTitle: true));
    filterOptionGroup.createTimeCond = DateTimeCond(
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

  Future<void> syncWithRemote() async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      return Future.error("Account not configured yet");
    }
    await _collectionsService.sync();
    final collections = _collectionsService.getCollections();
    for (final collection in collections) {
      await _fetchEncryptedFilesDiff(collection.id);
    }
    await _uploadDiff();
    await deleteFilesOnServer();
  }

  Future<void> _fetchEncryptedFilesDiff(int collectionID) async {
    final diff = await _downloader.getEncryptedFilesDiff(
      collectionID,
      _getCollectionSyncTime(collectionID),
      _diffLimit,
    );
    if (diff.isNotEmpty) {
      await _storeDiff(diff, collectionID);
      FileRepository.instance.reloadFiles();
      Bus.instance.fire(CollectionUpdatedEvent(collectionID: collectionID));
      if (diff.length == _diffLimit) {
        return await _fetchEncryptedFilesDiff(collectionID);
      }
    }
  }

  int _getCollectionSyncTime(int collectionID) {
    var syncTime =
        _prefs.getInt(_collectionSyncTimeKeyPrefix + collectionID.toString());
    if (syncTime == null) {
      syncTime = 0;
    }
    return syncTime;
  }

  Future<void> _setCollectionSyncTime(int collectionID, int time) async {
    return _prefs.setInt(
        _collectionSyncTimeKeyPrefix + collectionID.toString(), time);
  }

  Future<void> _uploadDiff() async {
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    List<File> filesToBeUploaded =
        await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    for (int i = 0; i < filesToBeUploaded.length; i++) {
      if (_syncStopRequested) {
        _syncStopRequested = false;
        Bus.instance.fire(PhotoUploadEvent(wasStopped: true));
        return;
      }
      File file = filesToBeUploaded[i];
      try {
        file.collectionID = (await CollectionsService.instance
                .getOrCreateForPath(file.deviceFolder))
            .id;
        final existingFile = await _db.getFile(file.generatedID);
        if (existingFile == null) {
          // File was deleted locally while being uploaded
          await _deleteFileOnServer(file.uploadedFileID);
          continue;
        }
        if (existingFile.uploadedFileID != null) {
          // The file was uploaded outside this loop
          // Eg: Addition to an album or favorites
          await CollectionsService.instance
              .addToCollection(file.collectionID, [existingFile]);
        } else if (_uploader.getCurrentUploadStatus(file.generatedID) != null) {
          // The file is currently being uploaded outside this loop
          // Eg: Addition to an album or favorites
          await _uploader.getCurrentUploadStatus(file.generatedID);
          await CollectionsService.instance
              .addToCollection(file.collectionID, [existingFile]);
        } else {
          final uploadedFile = await _uploader.encryptAndUploadFile(file);
          await _db.update(uploadedFile);
        }
        Bus.instance
            .fire(CollectionUpdatedEvent(collectionID: file.collectionID));
        Bus.instance.fire(PhotoUploadEvent(
            completed: i + 1, total: filesToBeUploaded.length));
      } catch (e) {
        Bus.instance.fire(PhotoUploadEvent(hasError: true));
        throw e;
      }
    }
  }

  Future _storeDiff(List<File> diff, int collectionID) async {
    for (File file in diff) {
      final existingFiles = await _db.getMatchingFiles(file.title,
          file.deviceFolder, file.creationTime, file.modificationTime,
          alternateTitle: getHEICFileNameForJPG(file));
      if (existingFiles == null) {
        // File uploaded from a different device
        file.localID = null;
        await _db.insert(file);
      } else {
        // File exists on device
        bool wasUploadedOnAPreviousInstallation =
            existingFiles.length == 1 && existingFiles[0].collectionID == null;
        file.localID = existingFiles[0]
            .localID; // File should ideally have the same localID
        if (wasUploadedOnAPreviousInstallation) {
          file.generatedID = existingFiles[0].generatedID;
          await _db.update(file);
        } else {
          bool wasUpdatedInExistingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID) {
              file.generatedID = existingFile.generatedID;
              wasUpdatedInExistingCollection = true;
              break;
            }
          }
          if (wasUpdatedInExistingCollection) {
            await _db.update(file);
          } else {
            // Added to a new collection
            await _db.insert(file);
          }
        }
      }
      await _setCollectionSyncTime(collectionID, file.updationTime);
    }
  }

  Future<void> deleteFilesOnServer() async {
    return _db.getDeletedFileIDs().then((ids) async {
      for (int id in ids) {
        await _deleteFileOnServer(id);
        await _db.delete(id);
      }
    });
  }

  Future<void> _deleteFileOnServer(int fileID) async {
    return _dio
        .delete(
          Configuration.instance.getHttpEndpoint() +
              "/files/" +
              fileID.toString(),
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
