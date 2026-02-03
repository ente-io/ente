import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/social_db.dart';
import 'package:photos/extensions/user_extension.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/social/comment.dart';
import 'package:photos/models/social/feed_item.dart';
import 'package:photos/models/social/reaction.dart';
import 'package:photos/models/social/social_data_provider.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/language_service.dart';
import 'package:photos/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SocialNotificationTrigger {
  remoteSync,
  feedRefresh,
}

class SocialNotificationCoordinator {
  static const String kLastSocialActivityNotificationTime =
      'last_social_activity_notification_time';
  static const String kLastSocialSeenTime = 'last_social_seen_time';
  static const String kIsFirstRemoteSyncDoneKey = 'isFirstRemoteSyncDone';

  static final SocialNotificationCoordinator instance =
      SocialNotificationCoordinator._privateConstructor();

  SocialNotificationCoordinator._privateConstructor();

  final _logger = Logger('SocialNotificationCoordinator');
  late final FilesDB _filesDb = FilesDB.instance;
  late final CollectionsService _collectionsService =
      CollectionsService.instance;

  SharedPreferences? _prefs;
  bool _isNotifying = false;

  void init(SharedPreferences preferences) {
    _prefs = preferences;
  }

  Future<void> markSocialSeen({int? timestampMicros}) async {
    final prefs = await _ensurePrefs();
    final now = timestampMicros ?? DateTime.now().microsecondsSinceEpoch;
    final lastSeen = prefs.getInt(kLastSocialSeenTime) ?? 0;
    if (now > lastSeen) {
      await prefs.setInt(kLastSocialSeenTime, now);
    }
  }

  Future<void> notifyAfterSocialSync({
    required SocialNotificationTrigger trigger,
  }) async {
    if (_isNotifying) {
      _logger.info('Social notification already in progress; skipping');
      return;
    }
    _isNotifying = true;
    try {
      _logger.info('Evaluating social notifications after ${trigger.name}');
      await _notifyNewSocialActivity();
    } finally {
      _isNotifying = false;
    }
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  bool _shouldShowSocialNotifications(SharedPreferences prefs) {
    return prefs.containsKey(kIsFirstRemoteSyncDoneKey) &&
        NotificationService.instance.shouldShowSocialNotifications();
  }

  int _getCutoffTime(SharedPreferences prefs) {
    final lastNotified = prefs.getInt(kLastSocialActivityNotificationTime) ?? 0;
    final hasSeenKey = prefs.containsKey(kLastSocialSeenTime);
    final lastSeen = hasSeenKey ? (prefs.getInt(kLastSocialSeenTime) ?? 0) : 0;
    final lastAppOpen =
        prefs.getInt(AppLifecycleService.keyLastAppOpenTime) ?? 0;
    final fallback = hasSeenKey ? lastSeen : lastAppOpen;
    final cutoff = max(lastNotified, fallback);
    if (cutoff == 0) {
      return DateTime.now().microsecondsSinceEpoch;
    }
    return cutoff;
  }

  Future<void> _notifyNewSocialActivity() async {
    final prefs = await _ensurePrefs();
    if (!_shouldShowSocialNotifications(prefs)) {
      return;
    }
    if (!flagService.isSocialEnabled) {
      return;
    }
    final userID = Configuration.instance.getUserID();
    if (userID == null) {
      return;
    }

    final cutoffTime = _getCutoffTime(prefs);

    final hiddenCollectionIds = _collectionsService.getHiddenCollectionIds();
    final latestByKey = <String, _SocialActivityCandidate>{};

    void considerCandidate(_SocialActivityCandidate candidate) {
      if (!_isSocialNotificationEnabledForType(candidate.type)) {
        return;
      }
      if (candidate.createdAt <= cutoffTime) {
        return;
      }
      if (hiddenCollectionIds.contains(candidate.collectionID)) {
        return;
      }
      if (candidate.fileID == null) {
        return;
      }
      final group = _notificationGroupForType(candidate.type);
      final key =
          '${candidate.collectionID}_${candidate.fileID}_${group.index}';
      final existing = latestByKey[key];
      if (existing == null || candidate.createdAt > existing.createdAt) {
        latestByKey[key] = candidate;
      }
    }

    final db = SocialDB.instance;

    final List<Comment> fileComments = await db.getCommentsOnFilesSince(
      excludeUserID: userID,
      sinceTime: cutoffTime,
    );
    for (final comment in fileComments) {
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.comment,
          collectionID: comment.collectionID,
          fileID: comment.fileID,
          commentID: comment.id,
          createdAt: comment.createdAt,
          actorUserID: comment.userID,
          actorAnonID: comment.anonUserID,
        ),
      );
    }

    final List<Comment> replies = await db.getRepliesSince(
      excludeUserID: userID,
      sinceTime: cutoffTime,
    );
    final List<Reaction> photoLikes = await db.getReactionsOnFilesSince(
      excludeUserID: userID,
      sinceTime: cutoffTime,
    );

    for (final reply in replies) {
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.reply,
          collectionID: reply.collectionID,
          fileID: reply.fileID,
          commentID: reply.id,
          createdAt: reply.createdAt,
          actorUserID: reply.userID,
          actorAnonID: reply.anonUserID,
          parentCommentUserID: reply.parentCommentUserID,
        ),
      );
    }

    final allFileIDs = <int>{};
    for (final reaction in photoLikes) {
      if (reaction.fileID != null) allFileIDs.add(reaction.fileID!);
    }
    for (final comment in fileComments) {
      if (comment.fileID != null) allFileIDs.add(comment.fileID!);
    }

    final filesByID =
        await _filesDb.getFileIDToFileFromIDs(allFileIDs.toList());

    bool isOwnedByUser(int? fileID) {
      if (fileID == null) {
        return false;
      }
      final file = filesByID[fileID];
      return file != null && file.ownerID == userID;
    }

    for (final reaction in photoLikes) {
      if (!isOwnedByUser(reaction.fileID)) {
        continue;
      }
      considerCandidate(
        _SocialActivityCandidate(
          type: FeedItemType.photoLike,
          collectionID: reaction.collectionID,
          fileID: reaction.fileID,
          createdAt: reaction.createdAt,
          actorUserID: reaction.userID,
          actorAnonID: reaction.anonUserID,
        ),
      );
    }

    if (latestByKey.isEmpty) {
      return;
    }

    final candidates = latestByKey.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final s = await LanguageService.locals;

    int? latestSentNotificationTime;
    for (final candidate in candidates) {
      final fileID = candidate.fileID;
      if (fileID == null) {
        continue;
      }
      try {
        final fileType = filesByID[fileID]?.fileType;
        final isOwn = switch (candidate.type) {
          FeedItemType.photoLike => isOwnedByUser(fileID),
          FeedItemType.comment => isOwnedByUser(fileID),
          FeedItemType.reply => candidate.parentCommentUserID == userID,
          FeedItemType.commentLike => false,
          FeedItemType.replyLike => false,
        };
        final title = await _getSocialNotificationTitle(candidate);
        await NotificationService.instance.showNotification(
          title,
          _getSocialNotificationBody(candidate.type, s, fileType, isOwn),
          channelID: 'social_activity',
          channelName: 'Ente Feed',
          payload: _buildSocialNotificationPayload(candidate),
          id: _buildSocialNotificationId(
            candidate.collectionID,
            fileID,
            _notificationGroupForType(candidate.type),
          ),
        );
        latestSentNotificationTime ??= candidate.createdAt;
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to prepare social notification',
          e,
          stackTrace,
        );
      }
    }

    if (latestSentNotificationTime != null) {
      await prefs.setInt(
        kLastSocialActivityNotificationTime,
        latestSentNotificationTime,
      );
    }
  }

  bool _isSocialNotificationEnabledForType(FeedItemType type) {
    switch (type) {
      case FeedItemType.comment:
      case FeedItemType.reply:
      case FeedItemType.photoLike:
        return true;
      case FeedItemType.commentLike:
      case FeedItemType.replyLike:
        return false;
    }
  }

  _SocialNotificationGroup _notificationGroupForType(FeedItemType type) {
    switch (type) {
      case FeedItemType.comment:
      case FeedItemType.reply:
        return _SocialNotificationGroup.comment;
      case FeedItemType.photoLike:
      case FeedItemType.commentLike:
      case FeedItemType.replyLike:
        return _SocialNotificationGroup.like;
    }
  }

  int _buildSocialNotificationId(
    int collectionID,
    int fileID,
    _SocialNotificationGroup group,
  ) {
    const int base = 0x10000000;
    int hash = collectionID & 0x7fffffff;
    hash = ((hash * 31) ^ fileID) & 0x7fffffff;
    hash = ((hash * 31) ^ (group == _SocialNotificationGroup.comment ? 1 : 0)) &
        0x7fffffff;
    return base | (hash & 0x0fffffff);
  }

  Future<String> _getSocialNotificationTitle(
    _SocialActivityCandidate candidate,
  ) async {
    final userID = candidate.actorUserID;
    final anonID = candidate.actorAnonID;
    if (userID <= 0 && anonID != null) {
      return SocialDataProvider.instance.getAnonDisplayName(
        anonID,
        candidate.collectionID,
        fallback: anonID,
      );
    }
    final user =
        _collectionsService.getFileOwner(userID, candidate.collectionID);
    return user.nameOrEmail;
  }

  String _getSocialNotificationBody(
    FeedItemType type,
    AppLocalizations s,
    FileType? fileType,
    bool isOwn,
  ) {
    return _getSocialNotificationDetail(type, s, fileType, isOwn);
  }

  String _getSocialNotificationDetail(
    FeedItemType type,
    AppLocalizations s,
    FileType? fileType,
    bool isOwn,
  ) {
    final isVideo = fileType == FileType.video;
    switch (type) {
      case FeedItemType.photoLike:
        return isVideo ? s.likedYourVideo : s.likedYourPhoto;
      case FeedItemType.comment:
        if (isOwn) {
          return isVideo ? s.commentedOnYourVideo : s.commentedOnYourPhoto;
        }
        return isVideo ? s.commentedOnAVideo : s.commentedOnAPhoto;
      case FeedItemType.reply:
        return isOwn ? s.repliedToYourComment : s.repliedToAComment;
      case FeedItemType.commentLike:
        return s.likedYourComment;
      case FeedItemType.replyLike:
        return s.likedYourReply;
    }
  }

  String _buildSocialNotificationPayload(_SocialActivityCandidate candidate) {
    final params = <String, String>{
      'type': candidate.type.name,
      'collectionID': candidate.collectionID.toString(),
    };
    if (candidate.fileID != null) {
      params['fileID'] = candidate.fileID.toString();
    }
    if (candidate.commentID != null) {
      params['commentID'] = candidate.commentID!;
    }
    return Uri(
      scheme: 'ente',
      host: 'feed',
      queryParameters: params,
    ).toString();
  }
}

class _SocialActivityCandidate {
  final FeedItemType type;
  final int collectionID;
  final int? fileID;
  final String? commentID;
  final int createdAt;
  final int actorUserID;
  final String? actorAnonID;
  final int? parentCommentUserID;

  _SocialActivityCandidate({
    required this.type,
    required this.collectionID,
    required this.createdAt,
    required this.actorUserID,
    this.fileID,
    this.commentID,
    this.actorAnonID,
    this.parentCommentUserID,
  });
}

enum _SocialNotificationGroup {
  comment,
  like,
}
