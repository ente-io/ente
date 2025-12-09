import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/social/comment.dart';
import 'package:photos/models/social/reaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SocialDB {
  static final Logger _logger = Logger("SocialDB");
  static const _databaseName = "ente.social.db";
  static const _databaseVersion = 1;

  static const commentsTable = 'comments';
  static const reactionsTable = 'reactions';

  SocialDB._privateConstructor();
  static final SocialDB instance = SocialDB._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path: $path");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $commentsTable (
        id TEXT PRIMARY KEY NOT NULL,
        collection_id INTEGER NOT NULL,
        file_id INTEGER,
        data TEXT NOT NULL,
        parent_comment_id TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        user_id INTEGER NOT NULL,
        anon_user_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $reactionsTable (
        id TEXT PRIMARY KEY NOT NULL,
        collection_id INTEGER NOT NULL,
        file_id INTEGER,
        comment_id TEXT,
        data TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        user_id INTEGER NOT NULL,
        anon_user_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // Comment methods

  Future<Comment?> addComment(Comment comment) async {
    if (comment.data.trim().isEmpty) {
      debugPrint('addComment: Cannot add comment with empty data');
      return null;
    }

    if (comment.parentCommentID != null) {
      final parentExists = await _commentExists(comment.parentCommentID!);
      if (!parentExists) {
        debugPrint(
          'addComment: Parent comment ${comment.parentCommentID} does not exist',
        );
        return null;
      }
    }

    final db = await database;
    await db.insert(
      commentsTable,
      _commentToRow(comment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return comment;
  }

  Future<Comment?> deleteComment(String id) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) {
      debugPrint('deleteComment: Comment $id does not exist');
      return null;
    }

    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      commentsTable,
      {'is_deleted': 1, 'updated_at': updatedAt},
      where: 'id = ?',
      whereArgs: [id],
    );

    final updatedRows = await db.query(
      commentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return _rowToComment(updatedRows.first);
  }

  Future<List<Comment>> getCommentsForFile(int fileID) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'file_id = ? AND is_deleted = 0',
      whereArgs: [fileID],
    );
    return rows.map(_rowToComment).toList();
  }

  Future<int> getCommentCountForFile(int fileID) async {
    final comments = await getCommentsForFile(fileID);
    return comments.length;
  }

  Future<List<Comment>> getCommentsForCollection(int collectionID) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'collection_id = ? AND file_id IS NULL AND is_deleted = 0',
      whereArgs: [collectionID],
    );
    return rows.map(_rowToComment).toList();
  }

  Future<List<Comment>> getRepliesForComment(String commentID) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'parent_comment_id = ? AND is_deleted = 0',
      whereArgs: [commentID],
    );
    return rows.map(_rowToComment).toList();
  }

  /// Fetch a single comment by ID (for parent lookup)
  Future<Comment?> getCommentById(String id) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _rowToComment(rows.first);
  }

  /// Paginated fetch for file comments
  Future<List<Comment>> getCommentsForFilePaginated(
    int fileID, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'file_id = ? AND is_deleted = 0',
      whereArgs: [fileID],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_rowToComment).toList();
  }

  /// Paginated fetch for collection comments
  Future<List<Comment>> getCommentsForCollectionPaginated(
    int collectionID, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'collection_id = ? AND file_id IS NULL AND is_deleted = 0',
      whereArgs: [collectionID],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_rowToComment).toList();
  }

  /// Delete all comments from the database
  Future<int> deleteAllComments() async {
    final db = await database;
    final deletedCount = await db.delete(commentsTable);
    _logger.info('Deleted $deletedCount comments');
    return deletedCount;
  }

  /// Delete all reactions from the database
  Future<int> deleteAllReactions() async {
    final db = await database;
    final deletedCount = await db.delete(reactionsTable);
    _logger.info('Deleted $deletedCount reactions');
    return deletedCount;
  }

  /// Seeds the database with example comments and reactions for testing.
  Future<void> seedExampleData() async {}

  // Reaction methods

  Future<Reaction?> addReaction(Reaction reaction) async {
    if (reaction.commentID != null) {
      final commentExists = await _commentExists(reaction.commentID!);
      if (!commentExists) {
        debugPrint(
          'addReaction: Comment ${reaction.commentID} does not exist',
        );
        return null;
      }
    }

    final db = await database;
    await db.insert(
      reactionsTable,
      _reactionToRow(reaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return reaction;
  }

  Future<Reaction?> toggleReaction({
    required int userID,
    required int collectionID,
    int? fileID,
    String? commentID,
  }) async {
    final existingReaction = await _findExistingReaction(
      userID: userID,
      collectionID: collectionID,
      fileID: fileID,
      commentID: commentID,
    );

    if (existingReaction != null) {
      // Toggle is_deleted on existing reaction
      final db = await database;
      final updatedAt = DateTime.now().millisecondsSinceEpoch;
      final newIsDeleted = existingReaction.isDeleted ? 0 : 1;

      await db.update(
        reactionsTable,
        {'is_deleted': newIsDeleted, 'updated_at': updatedAt},
        where: 'id = ?',
        whereArgs: [existingReaction.id],
      );

      final updatedRows = await db.query(
        reactionsTable,
        where: 'id = ?',
        whereArgs: [existingReaction.id],
      );
      return _rowToReaction(updatedRows.first);
    } else {
      // Create new reaction
      final now = DateTime.now().millisecondsSinceEpoch;
      final reaction = Reaction(
        id: const Uuid().v4(),
        collectionID: collectionID,
        fileID: fileID,
        commentID: commentID,
        data: '',
        userID: userID,
        createdAt: now,
        updatedAt: now,
      );
      return addReaction(reaction);
    }
  }

  Future<List<Reaction>> getReactionsForFile(int fileID) async {
    final db = await database;
    final rows = await db.query(
      reactionsTable,
      where: 'file_id = ? AND comment_id IS NULL AND is_deleted = 0',
      whereArgs: [fileID],
    );
    return rows.map(_rowToReaction).toList();
  }

  Future<List<Reaction>> getReactionsForComment(String commentID) async {
    final db = await database;
    final rows = await db.query(
      reactionsTable,
      where: 'comment_id = ? AND is_deleted = 0',
      whereArgs: [commentID],
    );
    return rows.map(_rowToReaction).toList();
  }

  Future<List<Reaction>> getReactionsForCollection(int collectionID) async {
    final db = await database;
    final rows = await db.query(
      reactionsTable,
      where:
          'collection_id = ? AND file_id IS NULL AND comment_id IS NULL AND is_deleted = 0',
      whereArgs: [collectionID],
    );
    return rows.map(_rowToReaction).toList();
  }

  // Helper methods

  Future<bool> _commentExists(String id) async {
    final db = await database;
    final rows = await db.query(
      commentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isNotEmpty;
  }

  Future<Reaction?> _findExistingReaction({
    required int userID,
    required int collectionID,
    int? fileID,
    String? commentID,
  }) async {
    final db = await database;
    String where;
    List<Object?> whereArgs;

    if (commentID != null) {
      where = 'user_id = ? AND comment_id = ?';
      whereArgs = [userID, commentID];
    } else if (fileID != null) {
      where = 'user_id = ? AND file_id = ? AND comment_id IS NULL';
      whereArgs = [userID, fileID];
    } else {
      where =
          'user_id = ? AND collection_id = ? AND file_id IS NULL AND comment_id IS NULL';
      whereArgs = [userID, collectionID];
    }

    final rows = await db.query(
      reactionsTable,
      where: where,
      whereArgs: whereArgs,
    );

    if (rows.isEmpty) return null;
    return _rowToReaction(rows.first);
  }

  Map<String, dynamic> _commentToRow(Comment comment) {
    final map = comment.toMap();
    return {
      'id': map['id'],
      'collection_id': map['collectionID'],
      'file_id': map['fileID'],
      'data': map['data'],
      'parent_comment_id': map['parentCommentID'],
      'is_deleted': map['isDeleted'] == true ? 1 : 0,
      'user_id': map['userID'],
      'anon_user_id': map['anonUserID'],
      'created_at': map['createdAt'],
      'updated_at': map['updatedAt'],
    };
  }

  Comment _rowToComment(Map<String, dynamic> row) {
    return Comment.fromMap({
      'id': row['id'],
      'collectionID': row['collection_id'],
      'fileID': row['file_id'],
      'data': row['data'],
      'parentCommentID': row['parent_comment_id'],
      'isDeleted': row['is_deleted'] == 1,
      'userID': row['user_id'],
      'anonUserID': row['anon_user_id'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }

  Map<String, dynamic> _reactionToRow(Reaction reaction) {
    final map = reaction.toMap();
    return {
      'id': map['id'],
      'collection_id': map['collectionID'],
      'file_id': map['fileID'],
      'comment_id': map['commentID'],
      'data': map['data'],
      'is_deleted': map['isDeleted'] == true ? 1 : 0,
      'user_id': map['userID'],
      'anon_user_id': map['anonUserID'],
      'created_at': map['createdAt'],
      'updated_at': map['updatedAt'],
    };
  }

  Reaction _rowToReaction(Map<String, dynamic> row) {
    return Reaction.fromMap({
      'id': row['id'],
      'collectionID': row['collection_id'],
      'fileID': row['file_id'],
      'commentID': row['comment_id'],
      'data': row['data'],
      'isDeleted': row['is_deleted'] == 1,
      'userID': row['user_id'],
      'anonUserID': row['anon_user_id'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }
}
