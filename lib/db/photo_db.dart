import 'dart:io';

import 'package:photos/models/photo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class PhotoDB {
  // TODO: Use different tables within the same database
  static final _databaseName = "ente.photos.db";
  static final _databaseVersion = 1;

  static final table = 'photos';

  static final columnGeneratedId = '_id';
  static final columnUploadedFileId = 'uploaded_file_id';
  static final columnLocalId = 'local_id';
  static final columnTitle = 'title';
  static final columnDeviceFolder = 'device_folder';
  static final columnRemoteFolderId = 'remote_folder_id';
  static final columnRemotePath = 'remote_path';
  static final columnIsDeleted = 'is_deleted';
  static final columnCreateTimestamp = 'create_timestamp';
  static final columnSyncTimestamp = 'sync_timestamp';

  // make this a singleton class
  PhotoDB._privateConstructor();
  static final PhotoDB instance = PhotoDB._privateConstructor();

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
            $columnUploadedFileId INTEGER NOT NULL,
            $columnTitle TEXT NOT NULL,
            $columnDeviceFolder TEXT NOT NULL,
            $columnRemoteFolderId INTEGER DEFAULT -1,
            $columnRemotePath TEXT,
            $columnIsDeleted INTEGER DEFAULT 0,
            $columnCreateTimestamp TEXT NOT NULL,
            $columnSyncTimestamp TEXT
          )
          ''');
  }

  Future<int> insertPhoto(Photo photo) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForPhoto(photo));
  }

  Future<List<dynamic>> insertPhotos(List<Photo> photos) async {
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (Photo photo in photos) {
      if (batchCounter == 400) {
        await batch.commit();
        batch = db.batch();
      }
      batch.insert(table, _getRowForPhoto(photo));
      batchCounter++;
    }
    return await batch.commit();
  }

  Future<List<Photo>> getAllPhotos() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnLocalId IS NOT NULL AND $columnIsDeleted = 0',
      orderBy: '$columnCreateTimestamp DESC',
    );
    return _convertToPhotos(results);
  }

  Future<List<Photo>> getAllPhotosInFolder(int folderId) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnRemoteFolderId = ? AND $columnIsDeleted = 0',
      whereArgs: [folderId],
      orderBy: '$columnCreateTimestamp DESC',
    );
    return _convertToPhotos(results);
  }

  Future<List<Photo>> getAllDeletedPhotos() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnIsDeleted = 1',
      orderBy: '$columnCreateTimestamp DESC',
    );
    return _convertToPhotos(results);
  }

  Future<List<Photo>> getPhotosToBeUploaded() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnUploadedFileId = -1',
    );
    return _convertToPhotos(results);
  }

  Future<Photo> getMatchingPhoto(String localId, String title,
      String deviceFolder, int createTimestamp) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where:
          '$columnLocalId=? AND $columnTitle=? AND $columnDeviceFolder=? AND $columnCreateTimestamp=?',
      whereArgs: [localId, title, deviceFolder, createTimestamp],
    );
    if (rows.isNotEmpty) {
      return _getPhotoFromRow(rows[0]);
    } else {
      throw ("No matching photo found");
    }
  }

  Future<int> updatePhoto(int generatedId, int uploadedId, String remotePath,
      int syncTimestamp) async {
    final db = await instance.database;
    final values = new Map<String, dynamic>();
    values[columnUploadedFileId] = uploadedId;
    values[columnRemotePath] = remotePath;
    values[columnSyncTimestamp] = syncTimestamp;
    return await db.update(
      table,
      values,
      where: '$columnGeneratedId = ?',
      whereArgs: [generatedId],
    );
  }

  Future<Photo> getPhotoByPath(String path) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnRemotePath =?',
      whereArgs: [path],
    );
    if (rows.isNotEmpty) {
      return _getPhotoFromRow(rows[0]);
    } else {
      throw ("No cached photo");
    }
  }

  // TODO: Remove deleted photos on remote
  Future<int> markPhotoForDeletion(Photo photo) async {
    final db = await instance.database;
    var values = new Map<String, dynamic>();
    values[columnIsDeleted] = 1;
    return db.update(
      table,
      values,
      where: '$columnGeneratedId =?',
      whereArgs: [photo.generatedId],
    );
  }

  Future<int> deletePhoto(Photo photo) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnGeneratedId =?',
      whereArgs: [photo.generatedId],
    );
  }

  Future<int> deletePhotosInRemoteFolder(int folderId) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnRemoteFolderId =?',
      whereArgs: [folderId],
    );
  }

  Future<List<String>> getDistinctPaths() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnDeviceFolder],
      distinct: true,
    );
    List<String> result = List<String>();
    for (final row in rows) {
      result.add(row[columnDeviceFolder]);
    }
    return result;
  }

  Future<Photo> getLatestPhotoInPath(String path) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnDeviceFolder =?',
      whereArgs: [path],
      orderBy: '$columnCreateTimestamp DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getPhotoFromRow(rows[0]);
    } else {
      throw ("No photo found in path");
    }
  }

  Future<Photo> getLatestPhotoInRemoteFolder(int folderId) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnRemoteFolderId =?',
      whereArgs: [folderId],
      orderBy: '$columnCreateTimestamp DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getPhotoFromRow(rows[0]);
    } else {
      throw ("No photo found in remote folder");
    }
  }

  Future<Photo> getLatestPhotoAmongGeneratedIds(
      List<String> generatedIds) async {
    final db = await instance.database;
    var rows = await db.query(
      table,
      where: '$columnGeneratedId IN (${generatedIds.join(",")})',
      orderBy: '$columnCreateTimestamp DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getPhotoFromRow(rows[0]);
    } else {
      throw ("No photo found with ids " + generatedIds.join(", ").toString());
    }
  }

  List<Photo> _convertToPhotos(List<Map<String, dynamic>> results) {
    var photos = List<Photo>();
    for (var result in results) {
      photos.add(_getPhotoFromRow(result));
    }
    return photos;
  }

  Map<String, dynamic> _getRowForPhoto(Photo photo) {
    var row = new Map<String, dynamic>();
    row[columnLocalId] = photo.localId;
    row[columnUploadedFileId] =
        photo.uploadedFileId == null ? -1 : photo.uploadedFileId;
    row[columnTitle] = photo.title;
    row[columnDeviceFolder] = photo.deviceFolder;
    row[columnRemoteFolderId] = photo.remoteFolderId;
    row[columnRemotePath] = photo.remotePath;
    row[columnCreateTimestamp] = photo.createTimestamp;
    row[columnSyncTimestamp] = photo.syncTimestamp;
    return row;
  }

  Photo _getPhotoFromRow(Map<String, dynamic> row) {
    Photo photo = Photo();
    photo.generatedId = row[columnGeneratedId];
    photo.localId = row[columnLocalId];
    photo.uploadedFileId = row[columnUploadedFileId];
    photo.title = row[columnTitle];
    photo.deviceFolder = row[columnDeviceFolder];
    photo.remoteFolderId = row[columnRemoteFolderId];
    photo.remotePath = row[columnRemotePath];
    photo.createTimestamp = int.parse(row[columnCreateTimestamp]);
    photo.syncTimestamp = row[columnSyncTimestamp] == null
        ? -1
        : int.parse(row[columnSyncTimestamp]);
    return photo;
  }
}
