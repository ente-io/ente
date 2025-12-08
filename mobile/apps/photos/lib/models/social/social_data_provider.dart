import "package:photos/db/social_db.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";

class SocialDataProvider {
  SocialDataProvider._();
  static final instance = SocialDataProvider._();

  final _db = SocialDB.instance;

  // Query methods

  Future<List<Comment>> getCommentsForFile(int fileID) {
    return _db.getCommentsForFile(fileID);
  }

  Future<int> getCommentCountForFile(int fileID) {
    return _db.getCommentCountForFile(fileID);
  }

  Future<List<Reaction>> getReactionsForFile(int fileID) {
    return _db.getReactionsForFile(fileID);
  }

  Future<List<Comment>> getRepliesForComment(String commentID) {
    return _db.getRepliesForComment(commentID);
  }

  Future<List<Reaction>> getReactionsForComment(String commentID) {
    return _db.getReactionsForComment(commentID);
  }

  Future<Comment?> getCommentById(String id) {
    return _db.getCommentById(id);
  }

  Future<List<Comment>> getCommentsForFilePaginated(
    int fileID, {
    int limit = 20,
    int offset = 0,
  }) {
    return _db.getCommentsForFilePaginated(
      fileID,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Comment>> getCommentsForCollectionPaginated(
    int collectionID, {
    int limit = 20,
    int offset = 0,
  }) {
    return _db.getCommentsForCollectionPaginated(
      collectionID,
      limit: limit,
      offset: offset,
    );
  }

  // Collection-level queries

  Future<List<Comment>> getCommentsForCollection(int collectionID) {
    return _db.getCommentsForCollection(collectionID);
  }

  Future<List<Reaction>> getReactionsForCollection(int collectionID) {
    return _db.getReactionsForCollection(collectionID);
  }

  // Comment mutation methods

  Future<Comment?> addComment(Comment comment) {
    return _db.addComment(comment);
  }

  Future<Comment?> deleteComment(String id) {
    return _db.deleteComment(id);
  }

  // Reaction mutation methods

  Future<Reaction?> toggleReaction({
    required int userID,
    required int collectionID,
    int? fileID,
    String? commentID,
  }) {
    return _db.toggleReaction(
      userID: userID,
      collectionID: collectionID,
      fileID: fileID,
      commentID: commentID,
    );
  }
}
