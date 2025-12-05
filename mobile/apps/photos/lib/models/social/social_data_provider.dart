import "package:flutter/foundation.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";

class SocialDataProvider {
  SocialDataProvider._();
  static final instance = SocialDataProvider._();

  // Dummy data maps - add your test data here
  // Key: comment/reaction ID
  final Map<String, Comment> _comments = {
    // Example:
    // 'comment-1': Comment(
    //   id: 'comment-1',
    //   collectionID: 1,
    //   fileID: 100,
    //   data: 'Nice photo!',
    //   userID: 1,
    //   createdAt: 1700000000,
    //   updatedAt: 1700000000,
    // ),
  };

  final Map<String, Reaction> _reactions = {
    // Example:
    // 'reaction-1': Reaction(
    //   id: 'reaction-1',
    //   collectionID: 1,
    //   fileID: 100,
    //   data: '',
    //   userID: 1,
    //   createdAt: 1700000000,
    //   updatedAt: 1700000000,
    // ),
  };

  // Query methods

  List<Comment> getCommentsForFile(int fileID) {
    return _comments.values
        .where((c) => c.fileID == fileID && !c.isDeleted)
        .toList();
  }

  List<Reaction> getReactionsForFile(int fileID) {
    return _reactions.values
        .where((r) => r.fileID == fileID && r.commentID == null && !r.isDeleted)
        .toList();
  }

  List<Comment> getRepliesForComment(String commentID) {
    return _comments.values
        .where((c) => c.parentCommentID == commentID && !c.isDeleted)
        .toList();
  }

  List<Reaction> getReactionsForComment(String commentID) {
    return _reactions.values
        .where((r) => r.commentID == commentID && !r.isDeleted)
        .toList();
  }

  // Collection-level queries

  List<Comment> getCommentsForCollection(int collectionID) {
    return _comments.values
        .where(
          (c) =>
              c.collectionID == collectionID &&
              c.fileID == null &&
              !c.isDeleted,
        )
        .toList();
  }

  List<Reaction> getReactionsForCollection(int collectionID) {
    return _reactions.values
        .where(
          (r) =>
              r.collectionID == collectionID &&
              r.fileID == null &&
              r.commentID == null &&
              !r.isDeleted,
        )
        .toList();
  }

  // Comment mutation methods

  Comment? addComment(Comment comment) {
    if (comment.data.trim().isEmpty) {
      debugPrint('addComment: Cannot add comment with empty data');
      return null;
    }
    if (comment.parentCommentID != null &&
        !_comments.containsKey(comment.parentCommentID)) {
      debugPrint(
        'addComment: Parent comment ${comment.parentCommentID} does not exist',
      );
      return null;
    }
    _comments[comment.id] = comment;
    return comment;
  }

  Comment? deleteComment(String id) {
    final existing = _comments[id];
    if (existing == null) {
      debugPrint('deleteComment: Comment $id does not exist');
      return null;
    }
    final updated = existing.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _comments[id] = updated;
    return updated;
  }

  // Reaction mutation methods

  Reaction? addReaction(Reaction reaction) {
    // Validate comment exists if reacting to a comment
    if (reaction.commentID != null &&
        !_comments.containsKey(reaction.commentID)) {
      debugPrint(
        'addReaction: Comment ${reaction.commentID} does not exist',
      );
      return null;
    }

    // Check if reaction already exists for same user + target
    final existing = _reactions.values.where((r) {
      if (r.userID != reaction.userID) return false;
      if (reaction.commentID != null) {
        return r.commentID == reaction.commentID;
      }
      if (reaction.fileID != null) {
        return r.fileID == reaction.fileID && r.commentID == null;
      }
      return r.collectionID == reaction.collectionID &&
          r.fileID == null &&
          r.commentID == null;
    }).firstOrNull;

    if (existing != null) {
      debugPrint(
        'addReaction: Reaction already exists for user ${reaction.userID} on target',
      );
      return null;
    }
    _reactions[reaction.id] = reaction;
    return reaction;
  }

  Reaction? toggleReaction(String id) {
    final existing = _reactions[id];
    if (existing == null) {
      debugPrint('toggleReaction: Reaction $id does not exist');
      return null;
    }
    final updated = existing.copyWith(
      isDeleted: !existing.isDeleted,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _reactions[id] = updated;
    return updated;
  }
}
