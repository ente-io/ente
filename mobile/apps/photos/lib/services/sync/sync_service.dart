import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/events/trigger_logout_event.dart';
import "package:photos/main.dart";
import 'package:photos/models/file/file_type.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/language_service.dart";
import 'package:photos/services/notification_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final _logger = Logger("SyncService");
  final _localSyncService = LocalSyncService.instance;
  final _remoteSyncService = RemoteSyncService.instance;
  final _uploader = FileUploader.instance;
  bool _syncStopRequested = false;
  Completer<bool>? _existingSync;
  late SharedPreferences _prefs;
  SyncStatusUpdate? _lastSyncStatusEvent;

  static const kLastStorageLimitExceededNotificationPushTime =
      "last_storage_limit_exceeded_notification_push_time";

  SyncService._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploader.clearQueue(SilentlyCancelUploadsError());
      sync();
    });

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _logger.info("Connectivity change detected " + result.toString());
      if (Configuration.instance.hasConfiguredAccount()) {
        sync();
      }
    });

    Bus.instance.on<SyncStatusUpdate>().listen((event) {
      _logger.info("Sync status received " + event.toString());
      _lastSyncStatusEvent = event;
    });
  }

  static final SyncService instance = SyncService._privateConstructor();

  Future<void> init(SharedPreferences preferences) async {
    _prefs = preferences;
    if (Platform.isIOS) {
      _logger.info("Clearing file cache");
      await PhotoManager.clearFileCache();
      _logger.info("Cleared file cache");
    }
  }

  // Note: Do not use this future for anything except log out.
  // This is prone to bugs due to any potential race conditions
  Future<bool> existingSync() async {
    return _existingSync?.future ?? Future.value(true);
  }

  Future<bool> sync() async {
    _syncStopRequested = false;
    if (_existingSync != null) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync!.future;
    }
    _existingSync = Completer<bool>();
    bool successful = false;
    try {
      await _doSync();
      if (_lastSyncStatusEvent != null &&
          _lastSyncStatusEvent!.status !=
              SyncStatus.completedFirstGalleryImport &&
          _lastSyncStatusEvent!.status != SyncStatus.completedBackup) {
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
      }
      successful = true;
    } on WiFiUnavailableError {
      _logger.warning("Not uploading over mobile data");
      Bus.instance.fire(
        SyncStatusUpdate(SyncStatus.paused, reason: "Waiting for WiFi..."),
      );
    } on SyncStopRequestedError {
      _syncStopRequested = false;
      Bus.instance.fire(
        SyncStatusUpdate(SyncStatus.completedBackup, wasStopped: true),
      );
    } on NoActiveSubscriptionError {
      Bus.instance.fire(
        SyncStatusUpdate(
          SyncStatus.error,
          error: NoActiveSubscriptionError(),
        ),
      );
    } on StorageLimitExceededError {
      _showStorageLimitExceededNotification();
      Bus.instance.fire(
        SyncStatusUpdate(
          SyncStatus.error,
          error: StorageLimitExceededError(),
        ),
      );
    } on UnauthorizedError {
      _logger.info("Logging user out");
      Bus.instance.fire(TriggerLogoutEvent());
    } on NoMediaLocationAccessError {
      _logger.severe("Not uploading due to no media location access");
      Bus.instance.fire(
        SyncStatusUpdate(
          SyncStatus.error,
          error: NoMediaLocationAccessError(),
        ),
      );
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.unknown) {
          Bus.instance.fire(
            SyncStatusUpdate(
              SyncStatus.paused,
              reason: "Waiting for network...",
            ),
          );
          _logger.severe("unable to connect", e, StackTrace.current);
          return false;
        }
      }
      _logger.severe("backup failed", e, StackTrace.current);
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.error));
      rethrow;
    } finally {
      _existingSync?.complete(successful);
      _existingSync = null;
      _lastSyncStatusEvent = null;
      _logger.info("Syncing completed");
    }
    return successful;
  }

  void stopSync() {
    _logger.info("Sync stop requested");
    _syncStopRequested = true;
  }

  bool shouldStopSync() {
    return _syncStopRequested;
  }

  bool isSyncInProgress() {
    return _existingSync != null;
  }

  SyncStatusUpdate? getLastSyncStatusEvent() {
    return _lastSyncStatusEvent;
  }

  Future<void> onPermissionGranted() async {
    _doSync().ignore();
  }

  void onDeviceCollectionSet(Set<int> collectionIDs) {
    _uploader.removeFromQueueWhere(
      (file) {
        return !collectionIDs.contains(file.collectionID);
      },
      UserCancelledUploadError(),
    );
  }

  void onVideoBackupPaused() {
    _uploader.removeFromQueueWhere(
      (file) {
        return file.fileType == FileType.video;
      },
      UserCancelledUploadError(),
    );
  }

  Future<void> _doSync() async {
    await _localSyncService.sync();
    if (_localSyncService.hasCompletedFirstImport()) {
      await _remoteSyncService.sync();
      final shouldSync = await _localSyncService.syncAll();
      if (shouldSync) {
        await _remoteSyncService.sync();
      }
      if (!isProcessBg) {
        await smartAlbumsService.syncSmartAlbums();
      }
    }
  }

  void _showStorageLimitExceededNotification() async {
    final lastNotificationShownTime =
        _prefs.getInt(kLastStorageLimitExceededNotificationPushTime) ?? 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    if ((now - lastNotificationShownTime) > microSecondsInDay) {
      await _prefs.setInt(kLastStorageLimitExceededNotificationPushTime, now);
      final s = await LanguageService.locals;
      // ignore: unawaited_futures
      NotificationService.instance.showNotification(
        s.storageLimitExceeded,
        s.sorryWeHadToPauseYourBackups,
      );
    }
  }
}
