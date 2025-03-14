import "dart:io";

import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/local/migration.dart";
import "package:photos/log/devlog.dart";
import "package:sqlite_async/sqlite_async.dart";

class LocalDB {
  static const _databaseName = "local_1.db";
  static const _batchInsertMaxCount = 1000;
  late final SqliteDatabase _sqliteDB;

  Future<void> init() async {
    devLog("LocalDB init");
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    final database = SqliteDatabase(path: path);
    await LocalDBMigration.migrate(database);
    _sqliteDB = database;
    devLog("LocalDB init complete $path");
  }

  Future<Set<String>> getAssetsIDs() async {
    final result = await _sqliteDB.execute("SELECT id FROM assets");
    final ids = <String>{};
    for (var row in result) {
      ids.add(row["id"] as String);
    }
    return ids;
  }
}
