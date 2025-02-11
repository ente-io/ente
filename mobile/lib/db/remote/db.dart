import "dart:developer";
import "dart:io";

import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/remote/migration.dart";
import "package:sqlite_async/sqlite_async.dart";

var devLog = log;

class RemoteDB {
  static const _databaseName = "remote.db";
  // only have a single app-wide reference to the database
  static Future<SqliteDatabase>? _sqliteAsyncDBFuture;

  Future<SqliteDatabase> get sqliteAsyncDB async {
    // lazily instantiate the db the first time it is accessed
    _sqliteAsyncDBFuture ??= _initSqliteAsyncDatabase();
    return _sqliteAsyncDBFuture!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<SqliteDatabase> _initSqliteAsyncDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    devLog("DB path " + path);
    final database = SqliteDatabase(path: path);
    await RemoteDBMigration.migrate(database);
    return database;
  }
}
