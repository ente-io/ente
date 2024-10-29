import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_fields.dart";
import "package:photos/services/filedata/model/file_data.dart";

extension FileDataTable on MLDataDB {
  Future<void> putIndexStatus(List<IndexInfo> embeddings) async {
    if (embeddings.isEmpty) return;
    final db = await MLDataDB.instance.asyncDB;
    final inputs = <List<Object?>>[];
    for (var embedding in embeddings) {
      inputs.add(
        [
          embedding.fileID,
          embedding.userID,
          embedding.type,
          embedding.size,
          embedding.updatedAt,
        ],
      );
    }
    await db.executeBatch(
      'INSERT OR REPLACE INTO $fileDataTable ($fileIDColumn, user_id, type, size, updated_at) values(?, ?, ?, ?, ?)',
      inputs,
    );
  }
}
