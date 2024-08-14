import "dart:io";
import "dart:typed_data";

import "package:path/path.dart";
import 'package:path_provider/path_provider.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/embedding_updated_event.dart";
import "package:photos/models/embedding.dart";
import "package:sqlite_async/sqlite_async.dart";

class EmbeddingsDB {
  EmbeddingsDB._privateConstructor();

  static final EmbeddingsDB instance = EmbeddingsDB._privateConstructor();

  static const databaseName = "ente.embeddings.db";
  static const tableName = "clip_embedding";
  static const oldTableName = "embeddings";
  static const columnFileID = "file_id";
  static const columnEmbedding = "embedding";
  static const columnVersion = "version";

  @Deprecated("")
  static const columnUpdationTime = "updation_time";

  static Future<SqliteDatabase>? _dbFuture;

  Future<SqliteDatabase> get _database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await _clearDeprecatedStores(dir);
  }

  Future<SqliteDatabase> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, databaseName);
    final migrations = SqliteMigrations()
      ..add(
        SqliteMigration(
          1,
          (tx) async {
            // Avoid creating the old table
            // await tx.execute(
            //   'CREATE TABLE $oldTableName ($columnFileID INTEGER NOT NULL, $columnEmbedding BLOB NOT NULL, $columnUpdationTime INTEGER, UNIQUE ($columnFileID))',
            // );
          },
        ),
      )
      ..add(
        SqliteMigration(
          2,
          (tx) async {
            // delete old table
            await tx.execute('DROP TABLE IF EXISTS $oldTableName');
            await tx.execute(
              'CREATE TABLE $tableName ($columnFileID INTEGER NOT NULL, $columnEmbedding BLOB NOT NULL, $columnVersion INTEGER, UNIQUE ($columnFileID))',
            );
          },
        ),
      );
    final database = SqliteDatabase(path: path);
    await migrations.migrate(database);
    return database;
  }

  Future<void> clearTable() async {
    final db = await _database;
    await db.execute('DELETE FROM $tableName');
  }

  Future<List<ClipEmbedding>> getAll() async {
    final db = await _database;
    final results = await db.getAll('SELECT * FROM $tableName');
    return _convertToEmbeddings(results);
  }

  // Get indexed FileIDs
  Future<Map<int, int>> getIndexedFileIds() async {
    final db = await _database;
    final maps = await db
        .getAll('SELECT $columnFileID , $columnVersion FROM $tableName');
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[columnFileID] as int] = map[columnVersion] as int;
    }
    return result;
  }

  // TODO: Add actual colomn for version and use here, similar to faces
  Future<int> getIndexedFileCount() async {
    final db = await _database;
    const String query =
        'SELECT COUNT(DISTINCT $columnFileID) as count FROM $tableName';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.first['count'] as int;
  }

  Future<void> put(ClipEmbedding embedding) async {
    final db = await _database;
    await db.execute(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnEmbedding, $columnVersion) VALUES (?, ?, ?)',
      _getRowFromEmbedding(embedding),
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> putMany(List<ClipEmbedding> embeddings) async {
    final db = await _database;
    final inputs = embeddings.map((e) => _getRowFromEmbedding(e)).toList();
    await db.executeBatch(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnEmbedding, $columnVersion) values(?, ?, ?)',
      inputs,
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> deleteEmbeddings(List<int> fileIDs) async {
    final db = await _database;
    await db.execute(
      'DELETE FROM $tableName WHERE $columnFileID IN (${fileIDs.join(", ")})',
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.execute('DELETE FROM $tableName');
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  List<ClipEmbedding> _convertToEmbeddings(List<Map<String, dynamic>> results) {
    final List<ClipEmbedding> embeddings = [];
    for (final result in results) {
      final embedding = _getEmbeddingFromRow(result);
      if (embedding.isEmpty) continue;
      embeddings.add(embedding);
    }
    return embeddings;
  }

  ClipEmbedding _getEmbeddingFromRow(Map<String, dynamic> row) {
    final fileID = row[columnFileID];
    final bytes = row[columnEmbedding] as Uint8List;
    final version = row[columnVersion] as int;
    final list = Float32List.view(bytes.buffer);
    return ClipEmbedding(fileID: fileID, embedding: list, version: version);
  }

  List<Object?> _getRowFromEmbedding(ClipEmbedding embedding) {
    return [
      embedding.fileID,
      Float32List.fromList(embedding.embedding).buffer.asUint8List(),
      embedding.version,
    ];
  }

  Future<void> _clearDeprecatedStores(Directory dir) async {
    final deprecatedObjectBox = Directory(dir.path + "/object-box-store");
    if (await deprecatedObjectBox.exists()) {
      await deprecatedObjectBox.delete(recursive: true);
    }
    final deprecatedIsar = File(dir.path + "/default.isar");
    if (await deprecatedIsar.exists()) {
      await deprecatedIsar.delete();
    }
  }
}
