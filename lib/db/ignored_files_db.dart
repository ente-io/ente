import 'dart:io';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/ignored_file.dart';
import 'package:sqflite/sqflite.dart';

// Keeps track of localIDs which should be not uploaded to ente without
// user's intervention.
// Common use case:
// when a user deletes a file just from ente on current or different device.
class IgnoreFilesDB {
  static final _databaseName = "ente.ignored_files.db";
  static final _databaseVersion = 1;
  static final Logger _logger = Logger("IgnoredFilesDB");
  static final tableName = 'ignored_files';

  static final columnLocalID = 'local_id';
  static final columnTitle = 'title';
  static final columnReason = 'reason';

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableName (
          $columnLocalID TEXT NOT NULL,
          $columnTitle TEXT NOT NULL,
          $columnReason TEXT DEFAULT $kIgnoreReasonTrash,
          UNIQUE($columnLocalID, $columnTitle)
        );
      CREATE INDEX IF NOT EXISTS local_id_index ON $tableName($columnLocalID);
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

  // return map of localID to set of titles associated with the given localIDs
  // Note: localIDs can easily clash across devices for Android, so we should
  // always compare both localID & title in Android before ignoring the file for upload.
  // iOS: localID is usually UUID and the title in localDB may be missing (before upload) as the
  // photo manager library doesn't always fetch the title by default.
  Future<Map<String, Set<String>>> getIgnoredFiles() async {
    final db = await instance.database;
    final rows = await db.query(tableName);
    final result = <String, Set<String>>{};
    for (final row in rows) {
      final ignoredFile = _getIgnoredFileFromRow(row);
      result
          .putIfAbsent(ignoredFile.localID, () => <String>{})
          .add(ignoredFile.title);
    }
    return result;
  }

  IgnoredFile _getIgnoredFileFromRow(Map<String, dynamic> row) {
    return IgnoredFile(row[columnLocalID], row[columnTitle], row[columnReason]);
  }

  Map<String, dynamic> _getRowForIgnoredFile(IgnoredFile ignoredFile) {
    assert(ignoredFile.title != null);
    assert(ignoredFile.localID != null);
    final row = <String, dynamic>{};
    row[columnLocalID] = ignoredFile.localID;
    row[columnTitle] = ignoredFile.title;
    row[columnReason] = ignoredFile.reason;
    return row;
  }
}
