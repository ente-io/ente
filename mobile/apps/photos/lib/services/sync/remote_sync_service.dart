import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import "package:photo_manager/photo_manager.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/core/network/network.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/db/local/table/path_config_table.dart";
import "package:photos/db/local/table/upload_queue_table.dart";
import "package:photos/db/remote/table/files_table.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/local/path_config.dart";
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/models/upload_strategy.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import "package:photos/services/language_service.dart";
import 'package:photos/services/local_file_update_service.dart';
import "package:photos/services/notification_service.dart";
import "package:photos/services/remote/fetch/files_diff.dart";
import "package:photos/services/remote/fetch/remote_diff.dart";
import 'package:photos/services/sync/sync_service.dart';
import "package:photos/services/video_preview_service.dart";
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSyncService {
  final _logger = Logger("RemoteSyncService");
  final _db = FilesDB.instance;
  final FileUploader _uploader = FileUploader.instance;
  final Configuration _config = Configuration.instance;
  final CollectionsService _collectionsService = CollectionsService.instance;
  final LocalFileUpdateService _localFileUpdateService =
      LocalFileUpdateService.instance;
  int _completedUploads = 0;
  int _ignoredUploads = 0;
  late SharedPreferences _prefs;
  Completer<void>? _existingSync;
  bool _isExistingSyncSilent = false;

  late RemoteDiffService remoteDiff;

  static const kHasSyncedArchiveKey = "has_synced_archive";
  /* This setting is used to maintain a list of local IDs for videos that the user has manually
 marked for upload, even if the global video upload setting is currently disabled.
 When the global video upload setting is disabled, we typically ignore all video uploads. However, for videos that have been added to this list, we
 want to still allow them to be uploaded, despite the global setting being disabled.

 This allows users to queue up videos for upload, and have them successfully upload
 even if they later toggle the global video upload setting to disabled.
   */
  static const _ignoreBackUpSettingsForIDs_ = "ignoreBackUpSettingsForIDs";
  final String _isFirstRemoteSyncDone = "isFirstRemoteSyncDone";

  // 29 October, 2021 3:56:40 AM IST
  static const kEditTimeFeatureReleaseTime = 1635460000000000;

  static const kMaximumPermissibleUploadsInThrottledMode = 4;

  static final RemoteSyncService instance =
      RemoteSyncService._privateConstructor();

  RemoteSyncService._privateConstructor();

  void init(SharedPreferences preferences) {
    _prefs = preferences;
    remoteDiff = RemoteDiffService(
      _collectionsService,
      RemoteFileDiffService(NetworkClient.instance.enteDio),
      _config,
      onCollectionSynced: _notifyOnCollectionChange,
    );

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) async {
      if (event.type == EventType.addedOrUpdated) {
        if (_existingSync == null) {
          // ignore: unawaited_futures
          sync();
        }
      }
    });
  }

  Future<void> sync({bool silently = false}) async {
    if (!_config.hasConfiguredAccount()) {
      _logger.info("Skipping remote sync since account is not configured");
      return;
    }
    if (_existingSync != null) {
      _logger.info("Remote sync already in progress, skipping");
      // if current sync is silent but request sync is non-silent (demands UI
      // updates), update the syncSilently flag
      if (_isExistingSyncSilent && !silently) {
        _isExistingSyncSilent = false;
      }
      return _existingSync?.future;
    }
    _existingSync = Completer<void>();
    _isExistingSyncSilent = silently;
    _logger.info(
      "Starting remote sync " +
          (silently ? "silently" : " with status updates"),
    );

    try {
      // use flag to decide if we should start marking files for upload before
      // remote-sync is done. This is done to avoid adding existing files to
      // the same or different collection when user had already uploaded them
      // before.
      final bool hasSyncedBefore = _prefs.containsKey(_isFirstRemoteSyncDone);
      if (hasSyncedBefore) {
        await queueLocalAssetForUpload();
      }
      await _pullDiff();
      await trashSyncService.syncTrash();
      if (!hasSyncedBefore) {
        await _prefs.setBool(_isFirstRemoteSyncDone, true);
        await queueLocalAssetForUpload();
      }

      if (
          // Only Uploading Previews in fg to prevent heating issues
          AppLifecycleService.instance.isForeground &&
              // if ML is enabled the MLService will queue when ML is done
              !flagService.hasGrantedMLConsent) {
        fileDataService.syncFDStatus().then((_) {
          VideoPreviewService.instance.queueFiles();
        }).ignore();
      }

      final filesToBeUploaded = await _getFilesToBeUploaded();
      final hasUploadedFiles = await _uploadFiles(filesToBeUploaded);
      if (filesToBeUploaded.isNotEmpty) {
        _logger.info(
            "Files ${filesToBeUploaded.length} queued for upload, completed: "
            "$_completedUploads, ignored $_ignoredUploads");
      } else {
        _logger.info("No files to upload for this session");
      }
      if (hasUploadedFiles) {
        await _pullDiff();
        _existingSync?.complete();
        _existingSync = null;
        await queueLocalAssetForUpload();
        final hasMoreFilesToBackup = (await _getFilesToBeUploaded()).isNotEmpty;
        _logger.info("hasMoreFilesToBackup?" + hasMoreFilesToBackup.toString());
        if (hasMoreFilesToBackup && !_shouldThrottleSync()) {
          // Skipping a resync to ensure that files that were ignored in this
          // session are not processed now
          await sync();
        } else {
          _logger.info("Fire backup completed event");
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
        }
      } else {
        // if filesToBeUploaded is empty, clear any stale files in the temp
        // directory
        if (filesToBeUploaded.isEmpty) {
          await _uploader.removeStaleFiles();
        }
        if (_ignoredUploads > 0) {
          _logger.info("Ignored $_ignoredUploads files for upload, fire "
              "backup done");
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
        }
        _existingSync?.complete();
        _existingSync = null;
      }
    } catch (e, s) {
      _existingSync?.complete();
      _existingSync = null;
      _logger.warning("Error executing remote sync", e, s);

      if (flagService.internalUser ||
          // rethrow whitelisted error so that UI status can be updated correctly.
          {
            UnauthorizedError,
            NoActiveSubscriptionError,
            WiFiUnavailableError,
            StorageLimitExceededError,
            SyncStopRequestedError,
            NoMediaLocationAccessError,
          }.contains(e.runtimeType)) {
        rethrow;
      }
    } finally {
      _existingSync?.complete();
      _existingSync = null;
      _isExistingSyncSilent = false;
    }
  }

  bool isFirstRemoteSyncDone() {
    return _prefs.containsKey(_isFirstRemoteSyncDone);
  }

  Future<bool> whiteListVideoForUpload(EnteFile file) async {
    if (file.fileType == FileType.video &&
        !_config.shouldBackupVideos() &&
        file.localID != null) {
      final List<String> whitelistedIDs =
          _prefs.getStringList(_ignoreBackUpSettingsForIDs_) ?? <String>[];
      whitelistedIDs.add(file.localID!);
      return _prefs.setStringList(_ignoreBackUpSettingsForIDs_, whitelistedIDs);
    }
    return false;
  }

  Future<void> _pullDiff() async {
    await remoteDiff.syncFromRemote();
    return;
    unawaited(_localFileUpdateService.markUpdatedFilesForReUpload());
  }

  Future<void> _syncCollectionFiles(int collectionID, int sinceTime) async {
    _logger.info(
      "[Collection-$collectionID] fetch diff silently: $_isExistingSyncSilent "
      "since: $sinceTime",
    );
    if (!_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    _logger.info("[Collection-$collectionID] synced");
  }

  Future<void> joinAndSyncCollection(
    BuildContext context,
    int collectionID,
  ) async {
    await _collectionsService.joinPublicCollection(context, collectionID);
    await _collectionsService.sync();
    await _syncCollectionFiles(collectionID, 0);
  }

  Future<void> queueLocalAssetForUpload() async {
    _logger.info("Syncing device collections to be uploaded");
    final int ownerID = _config.getUserID()!;

    final devicePathConfigs = await localDB.getPathConfigs(ownerID);
    final assetPaths = await localDB.getAssetPaths();
    final Map<String, AssetPathEntity> pathIDToAssetPath = {};
    for (final assetPath in assetPaths) {
      pathIDToAssetPath[assetPath.id] = assetPath;
    }
    devicePathConfigs.removeWhere((element) => !element.shouldBackup);

    final pathIdToLocalIDs = await localDB.pathToAssetIDs();
    devicePathConfigs.sort(
      (a, b) => (pathIdToLocalIDs[a.pathID]?.length ?? 0)
          .compareTo((pathIdToLocalIDs[b.pathID]?.length ?? 0)),
    );
    // Sort by count to ensure that photos in iOS are first inserted in
    // smallest album marked for backup. This is to ensure that photo is
    // first attempted to upload in a non-recent album.
    final rlMapping = await remoteDB.getLocalIDToMappingForActiveFiles();
    final Set<String> queuedLocalIDs = await localDB.getQueueAssetIDs(ownerID);
    queuedLocalIDs.addAll(rlMapping.keys);
    bool moreFilesMarkedForBackup = false;
    for (final deviceCollection in devicePathConfigs) {
      final AssetPathEntity? assetPath =
          pathIDToAssetPath[deviceCollection.pathID];
      if (assetPath == null) {
        _logger.warning(
          "AssetPathEntity not found for pathID ${deviceCollection.pathID}",
        );
        continue;
      }
      final Set<String> localIDsToSync =
          pathIdToLocalIDs[deviceCollection.pathID] ?? {};
      if (deviceCollection.uploadStrategy == UploadStrategy.ifMissing) {
        localIDsToSync.removeAll(queuedLocalIDs);
      }
      if (localIDsToSync.isEmpty) {
        continue;
      }
      final collectionID = await _getCollectionID(deviceCollection, assetPath);
      if (collectionID == null) {
        _logger.warning('DeviceCollection was either deleted or missing');
        continue;
      }

      moreFilesMarkedForBackup = true;
      await localDB.insertOrUpdateQueue(
        localIDsToSync,
        collectionID,
        ownerID,
        path: deviceCollection.pathID,
      );
      _logger.info(
        "Queued ${localIDsToSync.length} files for upload in collection "
        "$collectionID for path ${deviceCollection.pathID}",
      );
      queuedLocalIDs.addAll(localIDsToSync);
    }
    if (moreFilesMarkedForBackup && !_config.hasSelectedAllFoldersForBackup()) {
      // "force reload due to display new files"
      Bus.instance.fire(ForceReloadHomeGalleryEvent("newFilesDisplay"));
    }
  }

  Future<void> updateDeviceFolderSyncStatus(
    Map<String, bool> syncStatusUpdate,
  ) async {
    final int ownerID = _config.getUserID()!;
    final Set<int> oldDestCollection =
        await localDB.destCollectionWithBackup(ownerID);
    await localDB.insertOrUpdatePathConfigs(syncStatusUpdate, ownerID);
    final Set<int> newDestCollection =
        await localDB.destCollectionWithBackup(ownerID);
    // Cancel any existing sync if the destination collection has changed
    SyncService.instance.onDeviceCollectionSet(newDestCollection);
    // remove all collectionIDs which are still marked for backup
    oldDestCollection.removeAll(newDestCollection);
    await localDB.clearMappingsWithPath(
      ownerID,
      oldDestCollection,
    );
    if (syncStatusUpdate.values.any((syncStatus) => syncStatus == false)) {
      Configuration.instance.setSelectAllFoldersForBackup(false).ignore();
    }
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(<EnteFile>[], source: "deviceFolderSync"),
    );
    Bus.instance.fire(BackupFoldersUpdatedEvent());
  }

  Future<int?> _getCollectionID(
    PathConfig pathConfig,
    AssetPathEntity assetPath,
  ) async {
    if (pathConfig.destCollectionID != null) {
      final int destCollectionID = pathConfig.destCollectionID!;
      final collection =
          _collectionsService.getCollectionByID(destCollectionID);
      if (collection != null && !collection.isDeleted) {
        return collection.id;
      }
      if (collection == null) {
        // ideally, this should never happen because the app keeps a track of
        // all collections and their IDs. But, if somehow the collection is
        // deleted, we should fetch it again
        _logger.severe("Collection $destCollectionID missing "
            "for pathID ${assetPath.id}");
        _collectionsService.fetchCollectionByID(destCollectionID).ignore();
        // return, by next run collection should be available.
        // we are not waiting on fetch by choice because device might have wrong
        // mapping which will result in breaking upload for other device path
        return null;
      } else if (collection.isDeleted) {
        _logger.warning("Collection $destCollectionID deleted "
            "for pathID ${assetPath.id}, new collection will be created");
      }
    }
    final collection =
        await _collectionsService.getOrCreateForPath(assetPath.name);
    await localDB.updateDestConnection(
      assetPath.id,
      collection.id,
      _config.getUserID()!,
    );
    return collection.id;
  }

  Future<List<EnteFile>> _getFilesToBeUploaded() async {
    final List<EnteFile> originalFiles = await _db.getFilesPendingForUpload();
    if (originalFiles.isEmpty) {
      return originalFiles;
    }
    final bool shouldRemoveVideos =
        !_config.shouldBackupVideos() || _shouldThrottleSync();
    final ignoredIDs = await IgnoredFilesService.instance.idToIgnoreReasonMap;
    bool shouldSkipUploadFunc(EnteFile file) {
      return IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, file);
    }

    final List<EnteFile> filesToBeUploaded = [];
    int ignoredForUpload = 0;
    int skippedVideos = 0;
    final whitelistedIDs =
        (_prefs.getStringList(_ignoreBackUpSettingsForIDs_) ?? <String>[])
            .toSet();
    for (var file in originalFiles) {
      if (shouldRemoveVideos &&
          (file.fileType == FileType.video &&
              !whitelistedIDs.contains(file.localID))) {
        skippedVideos++;
        continue;
      }
      if (shouldSkipUploadFunc(file)) {
        ignoredForUpload++;
        continue;
      }
      filesToBeUploaded.add(file);
    }
    if (skippedVideos > 0 || ignoredForUpload > 0) {
      _logger.info("Skipped $skippedVideos videos and $ignoredForUpload "
          "ignored files for upload");
    }
    _sortByTime(filesToBeUploaded);
    _logger.info("${filesToBeUploaded.length} new files to be uploaded.");
    return filesToBeUploaded;
  }

  Future<bool> _uploadFiles(List<EnteFile> filesToBeUploaded) async {
    final int ownerID = _config.getUserID()!;
    final updatedFileIDs = [];
    // todo: rewrite
    // final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated(ownerID);
    if (updatedFileIDs.isNotEmpty) {
      _logger.info("Identified ${updatedFileIDs.length} files for reupload");
    }

    _completedUploads = 0;
    _ignoredUploads = 0;
    final int toBeUploaded = filesToBeUploaded.length + updatedFileIDs.length;
    if (toBeUploaded > 0) {
      Bus.instance.fire(
        SyncStatusUpdate(SyncStatus.preparingForUpload, total: toBeUploaded),
      );
      await _uploader.verifyMediaLocationAccess();
      await _uploader.checkNetworkForUpload();
      // verify if files upload is allowed based on their subscription plan and
      // storage limit. To avoid creating new endpoint, we are using
      // fetchUploadUrls as alternative method.
      await _uploader.fetchUploadURLs(toBeUploaded);
    }
    final List<Future> futures = [];

    for (final file in filesToBeUploaded) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger.info("Skipping some new files as we are throttling uploads");
        break;
      }
      // prefer existing collection ID for manually uploaded files.
      // See https://github.com/ente-io/photos-app/pull/187
      final collectionID = file.collectionID ??
          (await _collectionsService
                  .getOrCreateForPath(file.deviceFolder ?? 'Unknown Folder'))
              .id;
      _uploadFile(file, collectionID, futures);
    }

    for (final uploadedFileID in updatedFileIDs) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger
            .info("Skipping some updated files as we are throttling uploads");
        break;
      }
      final allFiles = await _db.getFilesInAllCollection(
        uploadedFileID,
        ownerID,
      );
      if (allFiles.isEmpty) {
        _logger.warning("No files found for uploadedFileID $uploadedFileID");
        continue;
      }
      EnteFile? fileInCollectionOwnedByUser;
      for (final file in allFiles) {
        if (file.canReUpload(ownerID)) {
          fileInCollectionOwnedByUser = file;
          break;
        }
      }
      if (fileInCollectionOwnedByUser != null) {
        _uploadFile(
          fileInCollectionOwnedByUser,
          fileInCollectionOwnedByUser.collectionID!,
          futures,
        );
      }
    }

    try {
      await Future.wait(futures);
    } on InvalidFileError {
      // Do nothing
    } on FileSystemException {
      // Do nothing since it's caused mostly due to concurrency issues
      // when the foreground app deletes temporary files, interrupting a background
      // upload
    } on LockAlreadyAcquiredError {
      // Do nothing
    } on SilentlyCancelUploadsError {
      // Do nothing
    } on UserCancelledUploadError {
      // Do nothing
    } catch (e) {
      rethrow;
    }
    return _completedUploads > 0;
  }

  void _uploadFile(EnteFile file, int collectionID, List<Future> futures) {
    final future = _uploader
        .upload(file, collectionID)
        .then((uploadedFile) => _onFileUploaded(uploadedFile))
        .onError(
          (error, stackTrace) => _onFileUploadError(error, stackTrace, file),
        );
    futures.add(future);
  }

  Future<void> _onFileUploaded(EnteFile file) async {
    Bus.instance.fire(
      CollectionUpdatedEvent(file.collectionID, [file], "fileUpload"),
    );
    _completedUploads++;
    final toBeUploadedInThisSession = _uploader.getCurrentSessionUploadCount();
    if (toBeUploadedInThisSession == 0) {
      return;
    }
    if (_completedUploads > toBeUploadedInThisSession ||
        _completedUploads < 0 ||
        toBeUploadedInThisSession < 0) {
      _logger.info(
        "Incorrect sync status",
        InvalidSyncStatusError(
          "Tried to report $_completedUploads as "
          "uploaded out of $toBeUploadedInThisSession",
        ),
      );
      return;
    }
    Bus.instance.fire(
      SyncStatusUpdate(
        SyncStatus.inProgress,
        completed: _completedUploads,
        total: toBeUploadedInThisSession,
      ),
    );
  }

  void _onFileUploadError(
    Object? error,
    StackTrace stackTrace,
    EnteFile file,
  ) {
    if (error == null) {
      return;
    }
    if (error is InvalidFileError) {
      _ignoredUploads++;
      _logger.warning("Invalid file error", error);
    } else {
      throw error;
    }
  }

  bool _shouldThrottleSync() {
    return !flagService.enableMobMultiPart ||
        !localSettings.userEnabledMultiplePart;
  }

  // _sortByTime sort by creation time (desc).
  // This is done to upload most recent photo first.
  void _sortByTime(List<EnteFile> file) {
    file.sort((first, second) {
      // 1. fileType: move videos to end when in bg
      if (!AppLifecycleService.instance.isForeground &&
          first.fileType != second.fileType) {
        if (first.fileType == FileType.video) return 1;
        if (second.fileType == FileType.video) return -1;
      }

      // 2. creationTime descending
      return second.creationTime!.compareTo(first.creationTime!);
    });
  }

  bool _shouldShowNotification() {
    final isForeground = AppLifecycleService.instance.isForeground;
    final bool showNotification =
        NotificationService.instance.shouldShowNotificationsForSharedPhotos() &&
            isFirstRemoteSyncDone() &&
            !isForeground;
    _logger.info(
      " notification: $showNotification isAppInForeground: $isForeground",
    );
    return showNotification;
  }

  Future<void> _notifyOnCollectionChange(List<int> collectionIDs) async {
    try {
      if (!_shouldShowNotification()) {
        return;
      }
      final userID = Configuration.instance.getUserID();
      final appOpenTime = AppLifecycleService.instance.getLastAppOpenTime();
      final data = await remoteDB.getNotificationCandidate(
        collectionIDs,
        appOpenTime,
      );
      for (final collectionID in collectionIDs) {
        // TODO: Add option to opt out of notifications for a specific collection
        // Screen: https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?type=design&node-id=7689-52943&t=IyWOfh0Gsb0p7yVC-4
        final ownerAndMetadataList = data[collectionID] ?? [];
        int sharedFileCount = 0;
        int collectedFileCount = 0;
        for (final (ownerID, metadata) in ownerAndMetadataList) {
          if (ownerID != userID) {
            sharedFileCount = sharedFileCount + 1;
          } else if (metadata?.data.containsKey(uploaderNameKey) ?? false) {
            collectedFileCount = collectedFileCount + 1;
          }
        }
        final totalCount = sharedFileCount + collectedFileCount;
        if (totalCount > 0) {
          final collection =
              _collectionsService.getCollectionByID(collectionID);
          _logger.info(
            'creating notification for ${collection?.displayName} '
            'shared: $sharedFileCount, collected: $collectedFileCount files',
          );
          final s = await LanguageService.s;
          // ignore: unawaited_futures
          NotificationService.instance.showNotification(
            collection!.displayName,
            totalCount.toString() + s.newPhotosEmoji,
            channelID: "collection:" + collectionID.toString(),
            channelName: collection.displayName,
            payload:
                "ente://collection/?collectionID=" + collectionID.toString(),
          );
        }
      }
    } catch (e, s) {
      _logger.warning("Error notifying new files", e, s);
      // Do nothing
    }
  }
}
