import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/core/network/network.dart";
import "package:photos/db/remote/table/files_table.dart";
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import "package:photos/main.dart" show isProcessBg;
import 'package:photos/models/file/file.dart';
import "package:photos/models/local/asset_upload_queue.dart";
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/module/upload/service/file_uploader.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/hidden_service.dart";
import "package:photos/services/language_service.dart";
import 'package:photos/services/local_file_update_service.dart';
import "package:photos/services/notification_service.dart";
import "package:photos/services/remote/fetch/files_diff.dart";
import "package:photos/services/remote/fetch/remote_diff.dart";
import "package:photos/services/sync/upload_candidate.dart";
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSyncService {
  final _logger = Logger("RemoteSyncService");
  final FileUploader _uploader = FileUploader.instance;
  final Configuration _config = Configuration.instance;
  final CollectionsService _collectionsService = CollectionsService.instance;
  final LocalFileUpdateService _localFileUpdateService =
      LocalFileUpdateService.instance;
  final UploadCandidateService _uploadCandidateService =
      UploadCandidateService.instance;
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
      // Handle first-time sync vs subsequent syncs
      final bool isFirstSync = !_prefs.containsKey(_isFirstRemoteSyncDone);
      if (isFirstSync) {
        // For first sync, pull remote diff first, then queue uploads

        await remoteDiff.syncFromRemote();
        await trashSyncService.syncTrash();
        await _prefs.setBool(_isFirstRemoteSyncDone, true);
        await _uploadCandidateService.markLocalAssetForAutoUpload();
      } else {
        // For subsequent syncs, queue uploads before remote sync
        await _uploadCandidateService.markLocalAssetForAutoUpload();
        await remoteDiff.syncFromRemote();
        await trashSyncService.syncTrash();
      }

      if (
          // We don't need syncFDStatus here if in background
          !isProcessBg) {
        fileDataService.syncFDStatus().ignore();
      }

      final hasUploadedFiles = await _uploadFiles();
      if (hasUploadedFiles) {
        await remoteDiff.syncFromRemote();
        _existingSync?.complete();
        _existingSync = null;
        await _uploadCandidateService.markLocalAssetForAutoUpload();
        final hasMoreFilesToBackup =
            await localDB.hasAssetQueueOrSharedAsset(_config.getUserID()!);
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
        // If nothing is pending for upload, we can safely remove stale files
        if (!await localDB.hasAssetQueueOrSharedAsset(
          _config.getUserID()!,
        )) {
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

  Future<bool> _uploadFiles() async {
    _completedUploads = 0;
    _ignoredUploads = 0;
    final int ownerID = _config.getUserID()!;
    final bool includeVideos = _config.shouldBackupVideos();

    final candidate = await _uploadCandidateService.getLocalAssetsForUploads(
      ownerID,
      includeVideos,
    );
    _logger.info("Upload candaites $candidate");
    final int toBeUploaded = candidate.own.length + candidate.shared.length;
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
    for (final entry in candidate.own) {
      futures.add(_uploadDirectlyToCollection(entry.$1, entry.$2));
    }
    for (final entry in candidate.shared) {
      futures.add(_uploadToUncategorizedThenMove(entry.$1, entry.$2));
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
    if (futures.isNotEmpty) {
      _logger.info("Files ${futures.length} queued for upload, completed: "
          "$_completedUploads, ignored $_ignoredUploads");
    } else {
      _logger.info("No files to upload for this session");
    }
    return _completedUploads > 0;
  }

  Future<void> _uploadToUncategorizedThenMove(
    AssetUploadQueue queueEntry,
    EnteFile file,
  ) async {
    try {
      final uncategorizedCollection =
          await _collectionsService.getUncategorizedCollection();
      final uploadedFile = await _uploader.upload(
        file,
        uncategorizedCollection.id,
        queue: queueEntry,
      );
      await _collectionsService.addOrCopyToCollection(
        queueEntry.destCollectionId,
        [uploadedFile],
      );
      _onFileUploaded(uploadedFile, queueEntry: queueEntry);
    } catch (error, stackTrace) {
      _onFileUploadError(error, stackTrace, file);
    }
  }

  Future<void> _uploadDirectlyToCollection(
    AssetUploadQueue queueEntry,
    EnteFile file,
  ) async {
    try {
      final uploadedFile = await _uploader
          .upload(file, queueEntry.destCollectionId, queue: queueEntry);
      _onFileUploaded(uploadedFile);
    } catch (error, stackTrace) {
      _onFileUploadError(error, stackTrace, file);
    }
  }

  void _onFileUploaded(
    EnteFile file, {
    AssetUploadQueue? queueEntry,
  }) {
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
      // On invalid file errors, we are not throwing the errors to
      // ensure that the upload queue is not interrupted.
      _ignoredUploads++;
      _logger.warning("Invalid file error", error, stackTrace);
    } else {
      throw error;
    }
  }

  bool _shouldThrottleSync() {
    return !flagService.enableMobMultiPart ||
        !localSettings.userEnabledMultiplePart;
  }

  bool _shouldNotifyNewFiles() {
    final isForeground = AppLifecycleService.instance.isForeground;
    final bool showNotification =
        NotificationService.instance.shouldShowNotificationsForSharedPhotos() &&
            isFirstRemoteSyncDone() &&
            !isForeground;
    _logger.info("notification: $showNotification isAppInFg: $isForeground");
    return showNotification;
  }

  Future<void> _notifyOnCollectionChange(List<int> collectionIDs) async {
    try {
      if (!_shouldNotifyNewFiles()) {
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
          final s = await LanguageService.locals;
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
