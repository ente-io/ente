import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class FileDB {
  // TODO: Use different tables within the same database
  static final _databaseName = "ente.files.db";
  static final _databaseVersion = 1;

  static final Logger _logger = Logger("FileDB");

  static final table = 'files';

  static final columnGeneratedId = '_id';
  static final columnUploadedFileId = 'uploaded_file_id';
  static final columnLocalId = 'local_id';
  static final columnTitle = 'title';
  static final columnDeviceFolder = 'device_folder';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';
  static final columnFileType = 'file_type';
  static final columnRemoteFolderId = 'remote_folder_id';
  static final columnRemotePath = 'remote_path';
  static final columnThumbnailPath = 'thumbnail_path';
  static final columnIsDeleted = 'is_deleted';
  static final columnCreationTime = 'creation_time';
  static final columnModificationTime = 'modification_time';
  static final columnUpdationTime = 'updation_time';

  // make this a singleton class
  FileDB._privateConstructor();
  static final FileDB instance = FileDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnGeneratedId INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            $columnLocalId TEXT,
            $columnUploadedFileId INTEGER,
            $columnTitle TEXT NOT NULL,
            $columnDeviceFolder TEXT NOT NULL,
            $columnLatitude REAL,
            $columnLongitude REAL,
            $columnFileType INTEGER,
            $columnRemoteFolderId INTEGER,
            $columnRemotePath TEXT,
            $columnThumbnailPath TEXT,
            $columnIsDeleted INTEGER DEFAULT 0,
            $columnCreationTime TEXT NOT NULL,
            $columnModificationTime TEXT NOT NULL,
            $columnUpdationTime TEXT
          )
          ''');
  }

  Future<int> insert(File file) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForFile(file));
  }

  Future<List<dynamic>> insertMultiple(List<File> files) async {
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (File file in files) {
      if (batchCounter == 400) {
        await batch.commit();
        batch = db.batch();
      }
      batch.insert(table, _getRowForFile(file));
      batchCounter++;
    }
    return await batch.commit();
  }

  Future<List<File>> getAllLocalFiles() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnLocalId IS NOT NULL AND $columnIsDeleted = 0',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllVideos() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnLocalId IS NOT NULL AND $columnFileType = 1 AND $columnIsDeleted = 0',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllInFolder(int folderId) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnRemoteFolderId = ? AND $columnIsDeleted = 0',
      whereArgs: [folderId],
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllDeleted() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnIsDeleted = 1',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getFilesToBeUploaded() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnUploadedFileId IS NULL',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<File> getMatchingFile(String localId, String title,
      String deviceFolder, int creationTime, int modificationTime,
      {String alternateTitle}) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '''$columnLocalId=? AND ($columnTitle=? OR $columnTitle=?) AND 
          $columnDeviceFolder=? AND $columnCreationTime=? AND $columnModificationTime=?''',
      whereArgs: [
        localId,
        title,
        alternateTitle,
        deviceFolder,
        creationTime,
        modificationTime
      ],
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No matching file found");
    }
  }

  Future<File> getMatchingRemoteFile(int uploadedFileId) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnUploadedFileId=?',
      whereArgs: [uploadedFileId],
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No matching file found");
    }
  }

  Future<int> update(
      int generatedId, int uploadedId, String remotePath, int updateTimestamp,
      [String thumbnailPath]) async {
    final db = await instance.database;
    final values = new Map<String, dynamic>();
    values[columnUploadedFileId] = uploadedId;
    values[columnRemotePath] = remotePath;
    values[columnThumbnailPath] = thumbnailPath;
    values[columnUpdationTime] = updateTimestamp;
    return await db.update(
      table,
      values,
      where: '$columnGeneratedId = ?',
      whereArgs: [generatedId],
    );
  }

  // TODO: Remove deleted files on remote
  Future<int> markForDeletion(File file) async {
    final db = await instance.database;
    var values = new Map<String, dynamic>();
    values[columnIsDeleted] = 1;
    return db.update(
      table,
      values,
      where: '$columnGeneratedId =?',
      whereArgs: [file.generatedId],
    );
  }

  Future<int> delete(File file) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnGeneratedId =?',
      whereArgs: [file.generatedId],
    );
  }

  Future<int> deleteFilesInRemoteFolder(int folderId) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnRemoteFolderId =?',
      whereArgs: [folderId],
    );
  }

  Future<List<String>> getLocalPaths() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnDeviceFolder],
      distinct: true,
      where: '$columnRemoteFolderId IS NULL',
    );
    List<String> result = List<String>();
    for (final row in rows) {
      result.add(row[columnDeviceFolder]);
    }
    return result;
  }

  Future<File> getLatestFileInPath(String path) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnDeviceFolder =?',
      whereArgs: [path],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in path");
    }
  }

  Future<File> getLatestFileInRemoteFolder(int folderId) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnRemoteFolderId =?',
      whereArgs: [folderId],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in remote folder " + folderId.toString());
    }
  }

  Future<File> getLastSyncedFileInRemoteFolder(int folderId) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnRemoteFolderId =?',
      whereArgs: [folderId],
      orderBy: '$columnUpdationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in remote folder " + folderId.toString());
    }
  }

  Future<File> getLatestFileAmongGeneratedIds(List<String> generatedIds) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnGeneratedId IN (${generatedIds.join(",")})',
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found with ids " + generatedIds.join(", ").toString());
    }
  }

  List<File> _convertToFiles(List<Map<String, dynamic>> results) {
    var files = List<File>();
    for (var result in results) {
      files.add(_getFileFromRow(result));
    }
    return files;
  }

  Map<String, dynamic> _getRowForFile(File file) {
    var row = new Map<String, dynamic>();
    row[columnLocalId] = file.localId;
    row[columnUploadedFileId] = file.uploadedFileId;
    row[columnTitle] = file.title;
    row[columnDeviceFolder] = file.deviceFolder;
    if (file.location != null) {
      row[columnLatitude] = file.location.latitude;
      row[columnLongitude] = file.location.longitude;
    }
    switch (file.fileType) {
      case FileType.image:
        row[columnFileType] = 0;
        break;
      case FileType.video:
        row[columnFileType] = 1;
        break;
      default:
        row[columnFileType] = -1;
    }
    row[columnRemoteFolderId] = file.remoteFolderId;
    row[columnRemotePath] = file.remotePath;
    row[columnThumbnailPath] = file.previewURL;
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
    return row;
  }

  File _getFileFromRow(Map<String, dynamic> row) {
    File file = File();
    file.generatedId = row[columnGeneratedId];
    file.localId = row[columnLocalId];
    file.uploadedFileId = row[columnUploadedFileId];
    file.title = row[columnTitle];
    file.deviceFolder = row[columnDeviceFolder];
    if (row[columnLatitude] != null && row[columnLongitude] != null) {
      file.location = Location(row[columnLatitude], row[columnLongitude]);
    }
    file.fileType = getFileType(row[columnFileType]);
    file.remoteFolderId = row[columnRemoteFolderId];
    file.remotePath = row[columnRemotePath];
    file.previewURL = row[columnThumbnailPath];
    file.creationTime = int.parse(row[columnCreationTime]);
    file.modificationTime = int.parse(row[columnModificationTime]);
    file.updationTime = row[columnUpdationTime] == null
        ? -1
        : int.parse(row[columnUpdationTime]);
    return file;
  }
}
