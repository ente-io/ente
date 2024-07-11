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
  static const tableName = "embeddings";
  static const columnFileID = "file_id";
  static const columnModel = "model";
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
              'CREATE TABLE $tableName ($columnFileID INTEGER NOT NULL, $columnModel INTEGER NOT NULL, $columnEmbedding BLOB NOT NULL, $columnUpdationTime INTEGER, UNIQUE ($columnFileID, $columnModel))',
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

  Future<List<Embedding>> getAll(Model model) async {
    final db = await _database;
    final results = await db.getAll('SELECT * FROM $tableName');
    return _convertToEmbeddings(results);
  }

  // Get FileIDs for a specific model
  Future<Set<int>> getFileIDs(Model model) async {
    final db = await _database;
    final results = await db.getAll(
      'SELECT $columnFileID FROM $tableName WHERE $columnModel = ?',
      [modelToInt(model)!],
    );
    if (results.isEmpty) {
      return <int>{};
    }
    return results.map((e) => e[columnFileID] as int).toSet();
  }

  Future<void> put(Embedding embedding) async {
    final db = await _database;
    await db.execute(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnModel, $columnEmbedding, $columnUpdationTime) VALUES (?, ?, ?, ?)',
      _getRowFromEmbedding(embedding),
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> putMany(List<Embedding> embeddings) async {
    final db = await _database;
    final inputs = embeddings.map((e) => _getRowFromEmbedding(e)).toList();
    await db.executeBatch(
      'INSERT OR REPLACE INTO $tableName ($columnFileID, $columnModel, $columnEmbedding, $columnUpdationTime) values(?, ?, ?, ?)',
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

  Future<void> deleteAllForModel(Model model) async {
    final db = await _database;
    await db.execute(
      'DELETE FROM $tableName WHERE $columnModel = ?',
      [modelToInt(model)!],
    );
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
    final model = intToModel(row[columnModel])!;
    final bytes = row[columnEmbedding] as Uint8List;
    final list = Float32List.view(bytes.buffer);
    return Embedding(fileID: fileID, model: model, embedding: list);
  }

  List<Object?> _getRowFromEmbedding(Embedding embedding) {
    return [
      embedding.fileID,
      modelToInt(embedding.model)!,
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

  int? modelToInt(Model model) {
    switch (model) {
      case Model.onnxClip:
        return 1;
      case Model.ggmlClip:
        return 2;
      default:
        return null;
    }
  }

  Model? intToModel(int model) {
    switch (model) {
      case 1:
        return Model.onnxClip;
      case 2:
        return Model.ggmlClip;
      default:
        return null;
    }
  }
}
