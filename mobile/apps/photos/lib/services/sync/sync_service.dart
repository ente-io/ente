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
import "package:photos/generated/l10n.dart";
import "package:photos/main.dart";
import "package:photos/models/social/comment.dart";
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:photos/services/language_service.dart";
import 'package:photos/services/notification_service.dart';
import 'package:photos/services/social_sync_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:photos/db/social_db.dart";

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
  static const kLastSocialActivityNotificationTime =
      "last_social_activity_notification_time";

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
    _logger.info("[SYNC] Starting local sync");
    await _localSyncService.sync();

    final bool allowRemoteSync =
        _localSyncService.hasCompletedFirstImportOrBypassed();

    if (allowRemoteSync) {
      _logger.info("[SYNC] Starting remote sync");
      await _remoteSyncService.sync();

      final shouldSync = await _localSyncService.syncAll();
      if (shouldSync) {
        _logger.info("[SYNC] Starting second remote sync");
        await _remoteSyncService.sync();
      }

      if (!isProcessBg) {
        await smartAlbumsService.syncSmartAlbums();
      }

      // Sync social data for shared collections
      try {
        _logger.info("[SYNC] Starting social sync");
        await SocialSyncService.instance.syncAllSharedCollections();
        await _notifyNewSocialActivity();
      } catch (e) {
        _logger.warning("[SYNC] Social sync failed, continuing", e);
      }
    } else {
      _logger.info("[SYNC] First import not completed, skipping remote");
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

  Future<void> _notifyNewSocialActivity() async {
    if (!_shouldShowSocialNotifications()) {
      return;
    }
    if (!flagService.internalUser) {
      return;
    }
    if (!flagService.isSocialEnabled) {
      return;
    }
    final userID = Configuration.instance.getUserID();
    if (userID == null) {
      return;
    }
    final appOpenTime = AppLifecycleService.instance.getLastAppOpenTime();
    if (appOpenTime <= 0) {
      return;
    }

    final lastNotifiedTime =
        _prefs.getInt(kLastSocialActivityNotificationTime) ?? 0;
    final cutoffTime = lastNotifiedTime > appOpenTime
        ? lastNotifiedTime
        : appOpenTime;

    final hiddenCollectionIds = collectionsService.getHiddenCollectionIds();

    _SocialActivityCandidate? latest;
    void considerCandidate(_SocialActivityCandidate candidate) {
      if (candidate.createdAt <= cutoffTime) {
        return;
      }
      if (hiddenCollectionIds.contains(candidate.collectionID)) {
        return;
      }
      if (latest == null || candidate.createdAt > latest!.createdAt) {
        latest = candidate;
      }
    }

    final db = SocialDB.instance;

    final List<Reaction> photoLikes =
        await db.getReactionsOnFiles(excludeUserID: userID, limit: 1);
    if (photoLikes.isNotEmpty) {
      final reaction = photoLikes.first;
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.photoLike,
          collectionID: reaction.collectionID,
          fileID: reaction.fileID,
          createdAt: reaction.createdAt,
        ),
      );
    }

    final List<Comment> fileComments =
        await db.getCommentsOnFiles(excludeUserID: userID, limit: 1);
    if (fileComments.isNotEmpty) {
      final comment = fileComments.first;
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.comment,
          collectionID: comment.collectionID,
          fileID: comment.fileID,
          createdAt: comment.createdAt,
        ),
      );
    }

    final List<Comment> replies =
        await db.getRepliesToUserComments(targetUserID: userID, limit: 1);
    if (replies.isNotEmpty) {
      final reply = replies.first;
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.reply,
          collectionID: reply.collectionID,
          fileID: reply.fileID,
          createdAt: reply.createdAt,
        ),
      );
    }

    final List<Reaction> commentLikes =
        await db.getReactionsOnUserComments(targetUserID: userID, limit: 1);
    if (commentLikes.isNotEmpty) {
      final reaction = commentLikes.first;
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.commentLike,
          collectionID: reaction.collectionID,
          fileID: reaction.fileID,
          createdAt: reaction.createdAt,
        ),
      );
    }

    final List<Reaction> replyLikes =
        await db.getReactionsOnUserReplies(targetUserID: userID, limit: 1);
    if (replyLikes.isNotEmpty) {
      final reaction = replyLikes.first;
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.replyLike,
          collectionID: reaction.collectionID,
          fileID: reaction.fileID,
          createdAt: reaction.createdAt,
        ),
      );
    }

    if (latest == null) {
      return;
    }

    final s = await LanguageService.locals;
    final message = _getSocialNotificationMessage(latest!.type, s);
    final collection = collectionsService.getCollectionByID(
      latest!.collectionID,
    );
    final title = collection?.displayName ?? "ente";

    await NotificationService.instance.showNotification(
      title,
      message,
      channelID: "social_activity",
      channelName: "Activity",
      payload: "ente://feed",
    );
    await _prefs.setInt(
      kLastSocialActivityNotificationTime,
      latest!.createdAt,
    );
  }

  bool _shouldShowSocialNotifications() {
    return NotificationService.instance
            .shouldShowNotificationsForSharedPhotos() &&
        RemoteSyncService.instance.isFirstRemoteSyncDone() &&
        !AppLifecycleService.instance.isForeground;
  }

  String _getSocialNotificationMessage(
    FeedItemType type,
    AppLocalizations s,
  ) {
    switch (type) {
      case FeedItemType.photoLike:
        return s.likedYourPhoto;
      case FeedItemType.comment:
        return s.commentedOnYourPhoto;
      case FeedItemType.reply:
        return s.repliedToYourComment;
      case FeedItemType.commentLike:
        return s.likedYourComment;
      case FeedItemType.replyLike:
        return s.likedYourReply;
    }
  }
}

class _SocialActivityCandidate {
  final FeedItemType type;
  final int collectionID;
  final int? fileID;
  final int createdAt;

  _SocialActivityCandidate({
    required this.type,
    required this.collectionID,
    required this.createdAt,
    this.fileID,
  });
}
