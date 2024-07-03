import "dart:io";
import "dart:typed_data";

import "package:path/path.dart";
import 'package:path_provider/path_provider.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/embedding_updated_event.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:sqlite_async/sqlite_async.dart";

class EmbeddingsDB {
  EmbeddingsDB._privateConstructor();

  static final EmbeddingsDB instance = EmbeddingsDB._privateConstructor();

  static const databaseName = "ente.embeddings.db";
  static const tableName = "embeddings";
  static const columnFileID = "file_id";
  static const columnEmbedding = "embedding";
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
            await tx.execute(
              'CREATE TABLE $tableName ($columnFileID INTEGER NOT NULL, $columnEmbedding BLOB NOT NULL, $columnUpdationTime INTEGER, UNIQUE ($columnFileID))',
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

  Future<List<Embedding>> getAll() async {
    final db = await _database;
    final results = await db.getAll('SELECT * FROM $tableName');
    return _convertToEmbeddings(results);
  }

  // Get indexed FileIDs
  Future<Map<int, int>> getIndexedFileIds() async {
    final db = await _database;
    final maps = await db.getAll('SELECT $columnFileID FROM $tableName');
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[columnFileID] as int] =
          clipMlVersion; // TODO: Add an actual column for version
    }
    return result;
  }

  Future<void> put(Embedding embedding) async {
    final db = await _database;
    await db.execute(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnEmbedding, $columnUpdationTime) VALUES (?, ?, ?, ?)',
      _getRowFromEmbedding(embedding),
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> putMany(List<Embedding> embeddings) async {
    final db = await _database;
    final inputs = embeddings.map((e) => _getRowFromEmbedding(e)).toList();
    await db.executeBatch(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnEmbedding, $columnUpdationTime) values(?, ?, ?, ?)',
      inputs,
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<List<Embedding>> getUnsyncedEmbeddings() async {
    final db = await _database;
    final results = await db.getAll(
      'SELECT * FROM $tableName WHERE $columnUpdationTime IS NULL',
    );
    return _convertToEmbeddings(results);
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

  List<Embedding> _convertToEmbeddings(List<Map<String, dynamic>> results) {
    final List<Embedding> embeddings = [];
    for (final result in results) {
      final embedding = _getEmbeddingFromRow(result);
      if (embedding.isEmpty) continue;
      embeddings.add(embedding);
    }
    return embeddings;
  }

  Embedding _getEmbeddingFromRow(Map<String, dynamic> row) {
    final fileID = row[columnFileID];
    final bytes = row[columnEmbedding] as Uint8List;
    final list = Float32List.view(bytes.buffer);
    return Embedding(fileID: fileID, embedding: list);
  }

  List<Object?> _getRowFromEmbedding(Embedding embedding) {
    return [
      embedding.fileID,
      Float32List.fromList(embedding.embedding).buffer.asUint8List(),
      embedding.updationTime,
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
