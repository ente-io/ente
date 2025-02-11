import "dart:io";

import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqlite_async/sqlite_async.dart";

class RemoteDB {
  final Logger _logger = Logger("RemoteDB");
  static const _databaseName = "ente.remote.db";

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
    _logger.info("DB path " + path);
    final database = SqliteDatabase(path: path);
    return database;
  }
}
