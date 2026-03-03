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

  /// Photos shared by others to user's albums
  sharedPhoto,
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

  /// Whether the target of this action is owned by the current user.
  ///
  /// For photoLike/comment: whether the user owns the file.
  /// For reply: whether the user wrote the parent comment.
  /// For commentLike/replyLike: whether the user wrote the liked comment/reply.
  final bool isOwnedByCurrentUser;

  /// File IDs for shared photo items (multiple photos can be grouped).
  /// Only populated for [FeedItemType.sharedPhoto].
  final List<int>? sharedFileIDs;

  /// Collection name for display in shared photo items.
  /// Only populated for [FeedItemType.sharedPhoto].
  final String? collectionName;

  const FeedItem({
    required this.type,
    required this.collectionID,
    this.fileID,
    this.commentID,
    required this.actorUserIDs,
    required this.actorAnonIDs,
    required this.createdAt,
    required this.isOwnedByCurrentUser,
    this.sharedFileIDs,
    this.collectionName,
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

  /// Number of shared files in this feed item.
  /// Only meaningful for [FeedItemType.sharedPhoto].
  int get sharedFileCount => sharedFileIDs?.length ?? 0;

  @override
  String toString() {
    return 'FeedItem(type: $type, collectionID: $collectionID, '
        'fileID: $fileID, commentID: $commentID, '
        'actorCount: $actorCount, createdAt: $createdAt, '
        'sharedFileCount: $sharedFileCount)';
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

  /// Creates a copy of this FeedItem with the given fields replaced.
  FeedItem copyWith({
    FeedItemType? type,
    int? collectionID,
    int? fileID,
    String? commentID,
    List<int>? actorUserIDs,
    List<String?>? actorAnonIDs,
    int? createdAt,
    bool? isOwnedByCurrentUser,
    List<int>? sharedFileIDs,
    String? collectionName,
  }) {
    return FeedItem(
      type: type ?? this.type,
      collectionID: collectionID ?? this.collectionID,
      fileID: fileID ?? this.fileID,
      commentID: commentID ?? this.commentID,
      actorUserIDs: actorUserIDs ?? this.actorUserIDs,
      actorAnonIDs: actorAnonIDs ?? this.actorAnonIDs,
      createdAt: createdAt ?? this.createdAt,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      sharedFileIDs: sharedFileIDs ?? this.sharedFileIDs,
      collectionName: collectionName ?? this.collectionName,
    );
  }
}
