import 'dart:io';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/ignored_file.dart';
import 'package:sqflite/sqflite.dart';

// Keeps track of local fileIDs which should be not uploaded to ente without
// user's intervention, even if they marked the folder for backup.
// Common cases: when a user deletes a file just from ente on current device or
// when they delete a file from web/another device, we should not automatically
// upload the files.
class IgnoreFilesDB {
  static final _databaseName = "ente.ignore_files.db";
  static final _databaseVersion = 1;
  static final Logger _logger = Logger("IgnoreFilesDB");
  static final tableName = 'ignored_files';

  static final columnLocalID = 'local_id';
  static final columnDeviceFolder = 'device_folder';
  static final columnTitle = 'title';
  static final columnReason = 'reason';

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableName (
          $columnLocalID TEXT NOT NULL,
          $columnTitle TEXT NOT NULL,
          $columnDeviceFolder TEXT,
          $columnReason TEXT DEFAULT $kIgnoreReasonTrash,
          UNIQUE($columnLocalID, $columnDeviceFolder, $columnDeviceFolder)
        );
      CREATE INDEX IF NOT EXISTS local_id_index ON $tableName($columnLocalID);
      CREATE INDEX IF NOT EXISTS device_folder_index ON $tableName($columnDeviceFolder);
      ''');
  }

  IgnoreFilesDB._privateConstructor();

  static final IgnoreFilesDB instance = IgnoreFilesDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<Database> _dbFuture;

  Future<Database> get database async {
    // lazily instantiate the db the first time it is accessed
    _dbFuture ??= _initDatabase();
    return _dbFuture;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
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

  Future<void> insertMultiple(List<IgnoredFile> ignoredFiles) async {
    final startTime = DateTime.now();
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (IgnoredFile file in ignoredFiles) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        tableName,
        _getRowForIgnoredFile(file),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
    final endTime = DateTime.now();
    final duration = Duration(
        microseconds:
            endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch);
    _logger.info("Batch insert of " +
        ignoredFiles.length.toString() +
        " took " +
        duration.inMilliseconds.toString() +
        "ms.");
  }

  Future<int> insert(IgnoredFile ignoredFile) async {
    final db = await instance.database;
    return db.insert(
      tableName,
      _getRowForIgnoredFile(ignoredFile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _getRowForIgnoredFile(IgnoredFile ignoredFile) {
    final row = <String, dynamic>{};
    row[columnLocalID] = ignoredFile.localID;
    row[columnTitle] = ignoredFile.title;
    row[columnDeviceFolder] = ignoredFile.deviceFolder;
    if (ignoredFile.reason != null && ignoredFile.reason != "") {
      row[columnReason] = ignoredFile.reason;
    }
    return row;
  }
}
