import "dart:io";
import "dart:typed_data";

import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_fields.dart";
import "package:photos/events/embedding_updated_event.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/ml_versions.dart";

extension ClipDB on MLDataDB {
  static const databaseName = "ente.embeddings.db";

  Future<List<ClipEmbedding>> getAll() async {
    final db = await MLDataDB.instance.asyncDB;
    final results = await db.getAll('SELECT * FROM $clipTable');
    return _convertToEmbeddings(results);
  }

  // Get indexed FileIDs
  Future<Map<int, int>> clipIndexedFileWithVersion() async {
    final db = await MLDataDB.instance.asyncDB;
    final maps = await db
        .getAll('SELECT $fileIDColumn , $mlVersionColumn FROM $clipTable');
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fileIDColumn] as int] = map[mlVersionColumn] as int;
    }
    return result;
  }

  Future<int> getClipIndexedFileCount({
    int minimumMlVersion = clipMlVersion,
  }) async {
    final db = await MLDataDB.instance.asyncDB;
    final String query =
        'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $clipTable WHERE $mlVersionColumn >= $minimumMlVersion';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.first['count'] as int;
  }

  Future<void> put(ClipEmbedding embedding) async {
    final db = await MLDataDB.instance.asyncDB;
    await db.execute(
      'INSERT OR REPLACE INTO $clipTable ($fileIDColumn, $embeddingColumn, $mlVersionColumn) VALUES (?, ?, ?)',
      _getRowFromEmbedding(embedding),
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> putMany(List<ClipEmbedding> embeddings) async {
    if (embeddings.isEmpty) return;
    final db = await MLDataDB.instance.asyncDB;
    final inputs = embeddings.map((e) => _getRowFromEmbedding(e)).toList();
    await db.executeBatch(
      'INSERT OR REPLACE INTO $clipTable ($fileIDColumn, $embeddingColumn, $mlVersionColumn) values(?, ?, ?)',
      inputs,
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> deleteEmbeddings(List<int> fileIDs) async {
    final db = await MLDataDB.instance.asyncDB;
    await db.execute(
      'DELETE FROM $clipTable WHERE $fileIDColumn IN (${fileIDs.join(", ")})',
    );
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  Future<void> deleteClipIndexes() async {
    final db = await MLDataDB.instance.asyncDB;
    await db.execute('DELETE FROM $clipTable');
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
    final fileID = row[fileIDColumn] as int;
    final bytes = row[embeddingColumn] as Uint8List;
    final version = row[mlVersionColumn] as int;
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
