/// Types of feed activity items.
enum FeedItemType {
  /// Reaction (like) on a photo/file
  photoLike,

  /// Comment on a photo/file
  comment,

  /// Reply to user's comment
  reply,

  /// Reaction (like) on user's comment
  commentLike,

  /// Reaction (like) on user's reply
  replyLike,
}

/// Represents an activity item in the user's feed.
///
/// Feed items are aggregated by type and target (file or comment),
/// showing multiple actors who performed the same action.
class FeedItem {
  final FeedItemType type;
  final int collectionID;
  final int? fileID;
  final String? commentID;

  /// User IDs of users who performed this action.
  /// First user is the most recent actor.
  final List<int> actorUserIDs;

  /// Anonymous user IDs corresponding to actorUserIDs.
  /// Null entries indicate non-anonymous users.
  final List<String?> actorAnonIDs;

  /// Timestamp of the most recent activity (microseconds since epoch).
  final int createdAt;

  const FeedItem({
    required this.type,
    required this.collectionID,
    this.fileID,
    this.commentID,
    required this.actorUserIDs,
    required this.actorAnonIDs,
    required this.createdAt,
  });

  /// Number of users who performed this action.
  int get actorCount => actorUserIDs.length;

  /// Whether this feed item has multiple actors.
  bool get hasMultipleActors => actorCount > 1;

  /// The primary actor's user ID (most recent).
  int get primaryActorUserID => actorUserIDs.first;

  /// The primary actor's anonymous ID (if anonymous).
  String? get primaryActorAnonID => actorAnonIDs.first;

  /// Number of additional actors beyond the primary.
  int get additionalActorCount => actorCount - 1;

  @override
  String toString() {
    return 'FeedItem(type: $type, collectionID: $collectionID, '
        'fileID: $fileID, commentID: $commentID, '
        'actorCount: $actorCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedItem &&
        other.type == type &&
        other.collectionID == collectionID &&
        other.fileID == fileID &&
        other.commentID == commentID &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(type, collectionID, fileID, commentID, createdAt);
  }
}
