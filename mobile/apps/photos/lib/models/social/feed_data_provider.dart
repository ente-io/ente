import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/social_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import 'package:photos/services/social_notification_coordinator.dart';
import "package:photos/services/social_sync_service.dart";

/// Provider for feed data.
///
/// Aggregates social activity (comments, reactions) into feed items
/// for display in the activity feed.
class FeedDataProvider {
  FeedDataProvider._();
  static final instance = FeedDataProvider._();

  final _logger = Logger('FeedDataProvider');
  final _db = SocialDB.instance;
  static const _kSharedPhotoSessionGapMicros = 1000 * 1000 * 60 * 10;
  static const _kSharedPhotoFetchPageSize = 200;
  static const _kSharedPhotoFetchMaxPages = 5;
  static const _kSharedPhotoFetchMaxRows =
      _kSharedPhotoFetchPageSize * _kSharedPhotoFetchMaxPages;

  /// Gets feed items aggregated from local database.
  ///
  /// Feed items are sorted by most recent activity.
  /// Each item represents a unique (type, fileID, commentID) combination.
  /// Items from hidden collections or associated with deleted files are filtered out.
  Future<List<FeedItem>> getFeedItems({
    int limit = 50,
  }) async {
    final userID = Configuration.instance.getUserID();
    if (userID == null) {
      _logger.warning('No user ID found, returning empty feed');
      return [];
    }

    final feedItems = <FeedItem>[];

    // Fetch all activity types in parallel
    final results = await Future.wait([
      _db.getReactionsOnFiles(excludeUserID: userID, limit: limit),
      _db.getCommentsOnFiles(excludeUserID: userID, limit: limit),
      _db.getReplies(excludeUserID: userID, limit: limit),
      _db.getReactionsOnUserComments(targetUserID: userID, limit: limit),
      _db.getReactionsOnUserReplies(targetUserID: userID, limit: limit),
    ]);

    final photoLikeReactions = results[0] as List<Reaction>;
    final fileComments = results[1] as List<Comment>;
    final replies = results[2] as List<Comment>;
    final commentLikeReactions = results[3] as List<Reaction>;
    final replyLikeReactions = results[4] as List<Reaction>;

    // Collect all fileIDs for batch loading to resolve ownership
    final fileIDs = <int>{};
    for (final r in photoLikeReactions) {
      if (r.fileID != null) fileIDs.add(r.fileID!);
    }
    for (final c in fileComments) {
      if (c.fileID != null) fileIDs.add(c.fileID!);
    }
    final filesByID = fileIDs.isNotEmpty
        ? await FilesDB.instance.getFileIDToFileFromIDs(fileIDs.toList())
        : <int, EnteFile>{};

    // Aggregate photo likes by file
    feedItems.addAll(
      _aggregateReactionsByFile(
        photoLikeReactions,
        FeedItemType.photoLike,
        filesByID: filesByID,
        userID: userID,
      ),
    );

    // Aggregate comments by file
    feedItems.addAll(
      _aggregateCommentsByFile(
        fileComments,
        filesByID: filesByID,
        userID: userID,
      ),
    );

    // Aggregate replies by parent comment
    feedItems.addAll(_aggregateRepliesByParent(replies, userID: userID));

    // Aggregate comment likes by comment
    feedItems.addAll(
      await _aggregateReactionsByComment(
        commentLikeReactions,
        FeedItemType.commentLike,
        userID: userID,
      ),
    );

    // Aggregate reply likes by reply
    feedItems.addAll(
      await _aggregateReactionsByComment(
        replyLikeReactions,
        FeedItemType.replyLike,
        userID: userID,
      ),
    );

    // Aggregate shared photos (files added by others to user's collections)
    feedItems.addAll(await _getSharedPhotoFeedItems(userID: userID));

    // Filter out items where the associated file doesn't exist or collection is hidden
    final validItems = await _filterFeedItems(feedItems);

    // Sort by most recent activity
    validItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limit total results
    if (validItems.length > limit) {
      return validItems.sublist(0, limit);
    }

    return validItems;
  }

  /// Gets a single feed item for preview display.
  Future<FeedItem?> getLatestFeedItem() async {
    final items = await getFeedItems(limit: 1);
    return items.isNotEmpty ? items.first : null;
  }

  /// Triggers background sync for all shared collections.
  Future<void> syncAllSharedCollections() async {
    try {
      await SocialSyncService.instance.syncAllSharedCollections();
      await SocialNotificationCoordinator.instance.notifyAfterSocialSync(
        trigger: SocialNotificationTrigger.feedRefresh,
      );
    } catch (e) {
      _logger.warning('Failed to sync shared collections', e);
    }
  }

  /// Aggregates reactions on files by (collectionID, fileID).
  List<FeedItem> _aggregateReactionsByFile(
    List<Reaction> reactions,
    FeedItemType type, {
    required Map<int, EnteFile> filesByID,
    required int userID,
  }) {
    final groupedByFile = <String, List<Reaction>>{};

    for (final reaction in reactions) {
      if (reaction.fileID == null) continue;
      final key = '${reaction.collectionID}_${reaction.fileID}';
      groupedByFile.putIfAbsent(key, () => []).add(reaction);
    }

    return groupedByFile.entries.map((entry) {
      final reactions = entry.value;
      // Sort by created_at DESC to get most recent first
      reactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Dedupe actors by userID, keeping order (most recent first)
      final seenUserIDs = <int>{};
      final uniqueUserIDs = <int>[];
      final uniqueAnonIDs = <String?>[];
      for (final r in reactions) {
        if (!seenUserIDs.contains(r.userID)) {
          seenUserIDs.add(r.userID);
          uniqueUserIDs.add(r.userID);
          uniqueAnonIDs.add(r.anonUserID);
        }
      }

      final fileID = reactions.first.fileID;
      return FeedItem(
        type: type,
        collectionID: reactions.first.collectionID,
        fileID: fileID,
        actorUserIDs: uniqueUserIDs,
        actorAnonIDs: uniqueAnonIDs,
        createdAt: reactions.first.createdAt,
        isOwnedByCurrentUser:
            fileID != null && filesByID[fileID]?.ownerID == userID,
      );
    }).toList();
  }

  /// Aggregates comments on files by (collectionID, fileID).
  List<FeedItem> _aggregateCommentsByFile(
    List<Comment> comments, {
    required Map<int, EnteFile> filesByID,
    required int userID,
  }) {
    final groupedByFile = <String, List<Comment>>{};

    for (final comment in comments) {
      if (comment.fileID == null) continue;
      final key = '${comment.collectionID}_${comment.fileID}';
      groupedByFile.putIfAbsent(key, () => []).add(comment);
    }

    return groupedByFile.entries.map((entry) {
      final comments = entry.value;
      // Sort by created_at DESC to get most recent first
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Dedupe actors by userID, keeping order (most recent first)
      final seenUserIDs = <int>{};
      final uniqueUserIDs = <int>[];
      final uniqueAnonIDs = <String?>[];
      for (final c in comments) {
        if (!seenUserIDs.contains(c.userID)) {
          seenUserIDs.add(c.userID);
          uniqueUserIDs.add(c.userID);
          uniqueAnonIDs.add(c.anonUserID);
        }
      }

      final fileID = comments.first.fileID;
      return FeedItem(
        type: FeedItemType.comment,
        collectionID: comments.first.collectionID,
        fileID: fileID,
        commentID: comments.first.id,
        actorUserIDs: uniqueUserIDs,
        actorAnonIDs: uniqueAnonIDs,
        createdAt: comments.first.createdAt,
        isOwnedByCurrentUser:
            fileID != null && filesByID[fileID]?.ownerID == userID,
      );
    }).toList();
  }

  /// Aggregates replies by parent comment ID.
  List<FeedItem> _aggregateRepliesByParent(
    List<Comment> replies, {
    required int userID,
  }) {
    final groupedByParent = <String, List<Comment>>{};

    for (final reply in replies) {
      if (reply.parentCommentID == null) continue;
      final key = '${reply.collectionID}_${reply.parentCommentID}';
      groupedByParent.putIfAbsent(key, () => []).add(reply);
    }

    return groupedByParent.entries.map((entry) {
      final replies = entry.value;
      // Sort by created_at DESC to get most recent first
      replies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Dedupe actors by userID, keeping order (most recent first)
      final seenUserIDs = <int>{};
      final uniqueUserIDs = <int>[];
      final uniqueAnonIDs = <String?>[];
      for (final r in replies) {
        if (!seenUserIDs.contains(r.userID)) {
          seenUserIDs.add(r.userID);
          uniqueUserIDs.add(r.userID);
          uniqueAnonIDs.add(r.anonUserID);
        }
      }

      return FeedItem(
        type: FeedItemType.reply,
        collectionID: replies.first.collectionID,
        fileID: replies.first.fileID,
        commentID: replies.first.id,
        actorUserIDs: uniqueUserIDs,
        actorAnonIDs: uniqueAnonIDs,
        createdAt: replies.first.createdAt,
        isOwnedByCurrentUser: replies.first.parentCommentUserID == userID,
      );
    }).toList();
  }

  /// Aggregates reactions by comment ID.
  Future<List<FeedItem>> _aggregateReactionsByComment(
    List<Reaction> reactions,
    FeedItemType type, {
    required int userID,
  }) async {
    if (reactions.isEmpty) return [];

    final groupedByComment = <String, List<Reaction>>{};
    final commentIDs = <String>{};

    for (final reaction in reactions) {
      if (reaction.commentID == null) continue;
      final key = '${reaction.collectionID}_${reaction.commentID}';
      commentIDs.add(reaction.commentID!);
      groupedByComment.putIfAbsent(key, () => []).add(reaction);
    }

    if (groupedByComment.isEmpty) return [];

    final commentsByID = await _db.getCommentsByIds(commentIDs);

    return groupedByComment.entries
        .map((entry) {
          final reactions = entry.value;
          // Sort by created_at DESC to get most recent first
          reactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Dedupe actors by userID, keeping order (most recent first)
          final seenUserIDs = <int>{};
          final uniqueUserIDs = <int>[];
          final uniqueAnonIDs = <String?>[];
          for (final r in reactions) {
            if (!seenUserIDs.contains(r.userID)) {
              seenUserIDs.add(r.userID);
              uniqueUserIDs.add(r.userID);
              uniqueAnonIDs.add(r.anonUserID);
            }
          }

          final commentID = reactions.first.commentID;
          final comment = commentID != null ? commentsByID[commentID] : null;
          if (comment == null) {
            return null;
          }

          return FeedItem(
            type: type,
            collectionID: reactions.first.collectionID,
            fileID: comment.fileID,
            commentID: commentID,
            actorUserIDs: uniqueUserIDs,
            actorAnonIDs: uniqueAnonIDs,
            createdAt: reactions.first.createdAt,
            isOwnedByCurrentUser: comment.userID == userID,
          );
        })
        .whereType<FeedItem>()
        .toList();
  }

  /// Gets shared photo feed items.
  ///
  /// Groups files added by others into session-like buckets using
  /// (collectionID, ownerID) + a short addedTime gap.
  /// Hidden collections are filtered downstream in _filterFeedItems.
  Future<List<FeedItem>> _getSharedPhotoFeedItems({
    required int userID,
    int limit = 50,
  }) async {
    if (!flagService.internalUser) {
      return [];
    }

    final sharedPhotoFeedCutoffTime =
        await localSettings.getOrCreateSharedPhotoFeedCutoffTime();

    // Build collection ID -> name map for display
    final allCollections = CollectionsService.instance.getCollectionsForUI(
      includedShared: true,
      includeCollab: true,
    );
    final hiddenCollectionIds =
        CollectionsService.instance.getHiddenCollectionIds();
    final collectionNames = <int, String>{};
    for (final c in allCollections) {
      collectionNames[c.id] = c.displayName;
    }

    final groupingState = _SharedPhotoGroupingState(
      sessionGapMicros: _kSharedPhotoSessionGapMicros,
    );
    var retainedRows = 0;
    var oldestFetchedAddedTime = 0;

    for (var page = 0; page < _kSharedPhotoFetchMaxPages; page++) {
      final pageFiles = await FilesDB.instance.getRecentlySharedFiles(
        currentUserID: userID,
        limit: _kSharedPhotoFetchPageSize,
        offset: page * _kSharedPhotoFetchPageSize,
        addedTimeAfterOrEqualTo: sharedPhotoFeedCutoffTime,
      );
      if (pageFiles.isEmpty) {
        break;
      }

      for (final file in pageFiles) {
        final collectionID = file.collectionID;
        final addedTime = file.addedTime;
        if (collectionID == null ||
            addedTime == null ||
            hiddenCollectionIds.contains(collectionID)) {
          continue;
        }
        oldestFetchedAddedTime = addedTime;
        groupingState.addFile(file);
        retainedRows++;
        if (retainedRows >= _kSharedPhotoFetchMaxRows) {
          break;
        }
      }

      final reachedEnd = pageFiles.length < _kSharedPhotoFetchPageSize ||
          retainedRows >= _kSharedPhotoFetchMaxRows;
      if (retainedRows == 0) {
        if (reachedEnd) {
          break;
        }
        continue;
      }

      if (groupingState.roughGroupCount >= limit) {
        final grouped = groupingState.buildSnapshotSorted();
        if (grouped.length < limit) {
          if (reachedEnd) {
            return _toSharedPhotoFeedItems(grouped, collectionNames);
          }
          continue;
        }
        final topGroups = grouped.take(limit).toList();
        var minOldestAddedTime = topGroups.first.oldestAddedTime;
        for (final group in topGroups.skip(1)) {
          if (group.oldestAddedTime < minOldestAddedTime) {
            minOldestAddedTime = group.oldestAddedTime;
          }
        }

        // Once we've scanned older than this threshold, unseen rows cannot
        // extend any of the top groups.
        final topGroupsAreClosed = oldestFetchedAddedTime <
            (minOldestAddedTime - _kSharedPhotoSessionGapMicros);
        if (topGroupsAreClosed || reachedEnd) {
          return _toSharedPhotoFeedItems(grouped, collectionNames);
        }
      }

      if (reachedEnd) {
        break;
      }
    }

    if (retainedRows == 0) {
      return [];
    }

    final grouped = groupingState.buildSnapshotSorted();
    return _toSharedPhotoFeedItems(grouped, collectionNames);
  }

  List<FeedItem> _toSharedPhotoFeedItems(
    List<_SharedPhotoGroup> groups,
    Map<int, String> collectionNames,
  ) {
    return groups
        .map(
          (group) => FeedItem(
            type: FeedItemType.sharedPhoto,
            collectionID: group.collectionID,
            fileID: group.sharedFileIDs.first,
            actorUserIDs: [group.ownerID],
            actorAnonIDs: [null],
            createdAt: group.createdAt,
            isOwnedByCurrentUser: false,
            sharedFileIDs: group.sharedFileIDs,
            collectionName: collectionNames[group.collectionID],
          ),
        )
        .toList();
  }

  /// Filters out feed items that should not be displayed.
  ///
  /// Removes items where:
  /// - The associated file no longer exists in FilesDB
  /// - The collection is hidden
  ///
  /// For sharedPhoto items, filters out deleted files from sharedFileIDs
  /// and only removes the item if ALL shared files are deleted.
  Future<List<FeedItem>> _filterFeedItems(
    List<FeedItem> items,
  ) async {
    if (items.isEmpty) return items;

    // Get hidden collection IDs to filter out
    final hiddenCollectionIds =
        CollectionsService.instance.getHiddenCollectionIds();

    // Collect unique (fileID, collectionID) pairs - include all sharedFileIDs
    final filesToCheck = <(int, int)>{};
    for (final item in items) {
      if (item.type == FeedItemType.sharedPhoto && item.sharedFileIDs != null) {
        // For shared items, check all files in the list
        for (final fileID in item.sharedFileIDs!) {
          filesToCheck.add((fileID, item.collectionID));
        }
      } else if (item.fileID != null) {
        filesToCheck.add((item.fileID!, item.collectionID));
      }
    }

    if (filesToCheck.isEmpty) {
      // Still filter hidden collections even if no files to check
      return items
          .where((item) => !hiddenCollectionIds.contains(item.collectionID))
          .toList();
    }

    // Check which files exist using batch query (single DB call)
    final existingFiles =
        await FilesDB.instance.getExistingFileKeys(filesToCheck);

    // Filter and transform items
    final result = <FeedItem>[];
    for (final item in items) {
      // Exclude hidden collections
      if (hiddenCollectionIds.contains(item.collectionID)) {
        continue;
      }

      // Handle sharedPhoto items specially
      if (item.type == FeedItemType.sharedPhoto && item.sharedFileIDs != null) {
        // Filter to only existing files
        final existingSharedFiles = item.sharedFileIDs!.where((fileID) {
          final key = '${item.collectionID}_$fileID';
          return existingFiles.contains(key);
        }).toList();

        // Only keep item if at least one file still exists
        if (existingSharedFiles.isNotEmpty) {
          // Update item with filtered sharedFileIDs and new fileID
          result.add(
            item.copyWith(
              sharedFileIDs: existingSharedFiles,
              fileID: existingSharedFiles.first,
            ),
          );
        }
        continue;
      }

      // Items without fileID (collection-level activity) are kept
      if (item.fileID == null) {
        result.add(item);
        continue;
      }

      // Exclude items where file no longer exists
      final key = '${item.collectionID}_${item.fileID}';
      if (existingFiles.contains(key)) {
        result.add(item);
      }
    }

    return result;
  }
}

class _SharedPhotoGroup {
  final int collectionID;
  final int ownerID;
  final int createdAt;
  final int oldestAddedTime;
  final List<int> sharedFileIDs;

  const _SharedPhotoGroup({
    required this.collectionID,
    required this.ownerID,
    required this.createdAt,
    required this.oldestAddedTime,
    required this.sharedFileIDs,
  });
}

class _SharedPhotoGroupBuilder {
  final int collectionID;
  final int ownerID;
  final int createdAt;
  int oldestAddedTime;
  final List<int> sharedFileIDs;

  _SharedPhotoGroupBuilder({
    required this.collectionID,
    required this.ownerID,
    required this.createdAt,
    required int firstFileID,
  })  : oldestAddedTime = createdAt,
        sharedFileIDs = [firstFileID];

  void add(int fileID, int addedTime) {
    sharedFileIDs.add(fileID);
    oldestAddedTime = addedTime;
  }

  _SharedPhotoGroup build() {
    return _SharedPhotoGroup(
      collectionID: collectionID,
      ownerID: ownerID,
      createdAt: createdAt,
      oldestAddedTime: oldestAddedTime,
      sharedFileIDs: List<int>.from(sharedFileIDs),
    );
  }
}

class _SharedPhotoGroupingState {
  final int sessionGapMicros;
  final Map<String, _SharedPhotoGroupBuilder> _activeGroups = {};
  final List<_SharedPhotoGroup> _closedGroups = [];

  _SharedPhotoGroupingState({
    required this.sessionGapMicros,
  });

  int get roughGroupCount => _closedGroups.length + _activeGroups.length;

  void addFile(EnteFile file) {
    final addedTime = file.addedTime;
    final ownerID = file.ownerID;
    final collectionID = file.collectionID;
    final uploadedFileID = file.uploadedFileID;
    if (addedTime == null ||
        ownerID == null ||
        collectionID == null ||
        uploadedFileID == null) {
      return;
    }

    final key = '${collectionID}_$ownerID';
    final currentGroup = _activeGroups[key];
    if (currentGroup == null) {
      _activeGroups[key] = _SharedPhotoGroupBuilder(
        collectionID: collectionID,
        ownerID: ownerID,
        createdAt: addedTime,
        firstFileID: uploadedFileID,
      );
      return;
    }

    final gapFromCurrentGroup = currentGroup.oldestAddedTime - addedTime;
    if (gapFromCurrentGroup <= sessionGapMicros) {
      currentGroup.add(uploadedFileID, addedTime);
      return;
    }

    _closedGroups.add(currentGroup.build());
    _activeGroups[key] = _SharedPhotoGroupBuilder(
      collectionID: collectionID,
      ownerID: ownerID,
      createdAt: addedTime,
      firstFileID: uploadedFileID,
    );
  }

  List<_SharedPhotoGroup> buildSnapshotSorted() {
    final groups = <_SharedPhotoGroup>[
      ..._closedGroups,
      ..._activeGroups.values.map((g) => g.build()),
    ];
    groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }
}
