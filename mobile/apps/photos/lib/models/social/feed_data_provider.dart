import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/social_db.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/services/collections_service.dart";
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
      _db.getRepliesToUserComments(targetUserID: userID, limit: limit),
      _db.getReactionsOnUserComments(targetUserID: userID, limit: limit),
      _db.getReactionsOnUserReplies(targetUserID: userID, limit: limit),
    ]);

    final photoLikeReactions = results[0] as List<Reaction>;
    final fileComments = results[1] as List<Comment>;
    final replies = results[2] as List<Comment>;
    final commentLikeReactions = results[3] as List<Reaction>;
    final replyLikeReactions = results[4] as List<Reaction>;

    // Aggregate photo likes by file
    feedItems.addAll(
      _aggregateReactionsByFile(photoLikeReactions, FeedItemType.photoLike),
    );

    // Aggregate comments by file
    feedItems.addAll(_aggregateCommentsByFile(fileComments));

    // Aggregate replies by parent comment
    feedItems.addAll(_aggregateRepliesByParent(replies));

    // Aggregate comment likes by comment
    feedItems.addAll(
      await _aggregateReactionsByComment(
        commentLikeReactions,
        FeedItemType.commentLike,
      ),
    );

    // Aggregate reply likes by reply
    feedItems.addAll(
      await _aggregateReactionsByComment(
        replyLikeReactions,
        FeedItemType.replyLike,
      ),
    );

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
    } catch (e) {
      _logger.warning('Failed to sync shared collections', e);
    }
  }

  /// Aggregates reactions on files by (collectionID, fileID).
  List<FeedItem> _aggregateReactionsByFile(
    List<Reaction> reactions,
    FeedItemType type,
  ) {
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

      return FeedItem(
        type: type,
        collectionID: reactions.first.collectionID,
        fileID: reactions.first.fileID,
        actorUserIDs: uniqueUserIDs,
        actorAnonIDs: uniqueAnonIDs,
        createdAt: reactions.first.createdAt,
      );
    }).toList();
  }

  /// Aggregates comments on files by (collectionID, fileID).
  List<FeedItem> _aggregateCommentsByFile(List<Comment> comments) {
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

      return FeedItem(
        type: FeedItemType.comment,
        collectionID: comments.first.collectionID,
        fileID: comments.first.fileID,
        commentID: comments.first.id,
        actorUserIDs: uniqueUserIDs,
        actorAnonIDs: uniqueAnonIDs,
        createdAt: comments.first.createdAt,
      );
    }).toList();
  }

  /// Aggregates replies by parent comment ID.
  List<FeedItem> _aggregateRepliesByParent(List<Comment> replies) {
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
      );
    }).toList();
  }

  /// Aggregates reactions by comment ID.
  Future<List<FeedItem>> _aggregateReactionsByComment(
    List<Reaction> reactions,
    FeedItemType type,
  ) async {
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
          );
        })
        .whereType<FeedItem>()
        .toList();
  }

  /// Filters out feed items that should not be displayed.
  ///
  /// Removes items where:
  /// - The associated file no longer exists in FilesDB
  /// - The collection is hidden
  Future<List<FeedItem>> _filterFeedItems(
    List<FeedItem> items,
  ) async {
    if (items.isEmpty) return items;

    // Get hidden collection IDs to filter out
    final hiddenCollectionIds =
        CollectionsService.instance.getHiddenCollectionIds();

    // Collect unique (fileID, collectionID) pairs
    final filesToCheck = <(int, int)>{};
    for (final item in items) {
      if (item.fileID != null) {
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

    // Filter out invalid items
    return items.where((item) {
      // Exclude hidden collections
      if (hiddenCollectionIds.contains(item.collectionID)) {
        return false;
      }
      // Items without fileID (collection-level activity) are kept
      if (item.fileID == null) {
        return true;
      }
      // Exclude items where file no longer exists
      final key = '${item.collectionID}_${item.fileID}';
      return existingFiles.contains(key);
    }).toList();
  }
}
