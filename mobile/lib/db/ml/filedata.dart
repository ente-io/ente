import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_fields.dart";
import "package:photos/services/filedata/model/file_data.dart";

extension FileDataTable on MLDataDB {
  Future<void> putFDStatus(List<FDStatus> fdStatusList) async {
    if (fdStatusList.isEmpty) return;
    final db = await MLDataDB.instance.asyncDB;
    final inputs = <List<Object?>>[];
    for (var status in fdStatusList) {
      inputs.add(
        [
          status.fileID,
          status.userID,
          status.type,
          status.size,
          status.objectID,
          status.objectNonce,
          status.updatedAt,
        ],
      );
    }
    await db.executeBatch(
      'INSERT OR REPLACE INTO $fileDataTable ($fileIDColumn, user_id, type, size, obj_id, obj_nonce, updated_at ) values(?, ?, ?, ?, ?, ?, ?)',
      inputs,
    );
  }

  Future<Set<int>> getFileIDsWithFDData() async {
    final db = await MLDataDB.instance.asyncDB;
    final res = await db.execute('SELECT $fileIDColumn FROM $fileDataTable');
    return res.map((e) => e[fileIDColumn] as int).toSet();
  }
}
