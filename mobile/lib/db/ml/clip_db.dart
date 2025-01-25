import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_fields.dart";
import "package:photos/events/embedding_updated_event.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/models/ml/vector.dart";

extension ClipDB on MLDataDB {
  Future<List<EmbeddingVector>> getAllClipVectors() async {
    Logger("ClipDB").info("reading all embeddings from DB");
    final db = await MLDataDB.instance.asyncDB;
    final results = await db.getAll('SELECT * FROM $clipTable');
    return _convertToVectors(results);
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

  Future<void> deleteClipEmbeddings(List<int> fileIDs) async {
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

  List<EmbeddingVector> _convertToVectors(List<Map<String, dynamic>> results) {
    final List<EmbeddingVector> embeddings = [];
    for (final result in results) {
      final embedding = _getVectorFromRow(result);
      if (embedding.isEmpty) continue;
      embeddings.add(embedding);
    }
    return embeddings;
  }

  EmbeddingVector _getVectorFromRow(Map<String, dynamic> row) {
    final fileID = row[fileIDColumn] as int;
    final bytes = row[embeddingColumn] as Uint8List;
    final list = Float32List.view(bytes.buffer);
    return EmbeddingVector(fileID: fileID, embedding: list);
  }

  List<Object?> _getRowFromEmbedding(ClipEmbedding embedding) {
    return [
      embedding.fileID,
      Float32List.fromList(embedding.embedding).buffer.asUint8List(),
      embedding.version,
    ];
  }
}
