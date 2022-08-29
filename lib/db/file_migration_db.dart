import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class FilesMigrationDB {
  static const _databaseName = "ente.files_migration.db";
  static const _databaseVersion = 1;
  static final Logger _logger = Logger((FilesMigrationDB).toString());
  static const tableName = 're_upload_tracker';

  static const columnLocalID = 'local_id';

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
        CREATE TABLE $tableName (
        $columnLocalID TEXT NOT NULL,
          UNIQUE($columnLocalID)
        );
      ''',
    );
  }

  FilesMigrationDB._privateConstructor();

  static final FilesMigrationDB instance =
      FilesMigrationDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<Database> _dbFuture;

  Future<Database> get database async {
    // lazily instantiate the db the first time it is accessed
    _dbFuture ??= _initDatabase();
    return _dbFuture;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(tableName);
  }

  Future<void> insertMultiple(List<String> fileLocalIDs) async {
    final startTime = DateTime.now();
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (String localID in fileLocalIDs) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        tableName,
        _getRowForReUploadTable(localID),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
    final endTime = DateTime.now();
    final duration = Duration(
      microseconds:
          endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch,
    );
    _logger.info(
      "Batch insert of ${fileLocalIDs.length} "
      "took ${duration.inMilliseconds} ms.",
    );
  }

  Future<int> deleteByLocalIDs(List<String> localIDs) async {
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    return await db.delete(
      tableName,
      where: '$columnLocalID IN (${localIDs.join(', ')})',
    );
  }

  Future<List<String>> getLocalIDsForPotentialReUpload(int limit) async {
    final db = await instance.database;
    final rows = await db.query(tableName, limit: limit);
    final result = <String>[];
    for (final row in rows) {
      result.add(row[columnLocalID]);
    }
    return result;
  }

  Map<String, dynamic> _getRowForReUploadTable(String localID) {
    assert(localID != null);
    final row = <String, dynamic>{};
    row[columnLocalID] = localID;
    return row;
  }
}
