import 'dart:io';

import 'package:myapp/models/photo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "orma.db";
  static final _databaseVersion = 1;

  static final table = 'photos';

  static final columnGeneratedId = '_id';
  static final columnUploadedFileId = 'uploaded_file_id';
  static final columnLocalId = 'local_id';
  static final columnLocalPath = 'local_path';
  static final columnRelativePath = 'relative_path';
  static final columnThumbnailPath = 'thumbnail_path';
  static final columnPath = 'path';
  static final columnHash = 'hash';
  static final columnIsDeleted = 'is_deleted';
  static final columnCreateTimestamp = 'create_timestamp';
  static final columnSyncTimestamp = 'sync_timestamp';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

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
            $columnLocalPath TEXT NOT NULL,
            $columnRelativePath TEXT NOT NULL,
            $columnThumbnailPath TEXT NOT NULL,
            $columnPath TEXT,
            $columnHash TEXT NOT NULL,
            $columnIsDeleted INTEGER DEFAULT 0,
            $columnCreateTimestamp TEXT NOT NULL,
            $columnSyncTimestamp TEXT
          )
          ''');
  }

  Future<int> insertPhoto(Photo photo) async {
    Database db = await instance.database;
    return await db.insert(table, _getRowForPhoto(photo));
  }

  Future<List<dynamic>> insertPhotos(List<Photo> photos) async {
    Database db = await instance.database;
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
    Database db = await instance.database;
    var results = await db.query(table,
        where: '$columnIsDeleted = 0', orderBy: '$columnCreateTimestamp DESC');
    return _convertToPhotos(results);
  }

  Future<List<Photo>> getAllDeletedPhotos() async {
    Database db = await instance.database;
    var results = await db.query(table,
        where: '$columnIsDeleted = 1', orderBy: '$columnCreateTimestamp DESC');
    return _convertToPhotos(results);
  }

  Future<List<Photo>> getPhotosToBeUploaded() async {
    Database db = await instance.database;
    var results = await db.query(table, where: '$columnUploadedFileId = -1');
    return _convertToPhotos(results);
  }

  Future<int> updatePhoto(Photo photo) async {
    Database db = await instance.database;
    return await db.update(table, _getRowForPhoto(photo),
        where: '$columnGeneratedId = ?', whereArgs: [photo.generatedId]);
  }

  Future<Photo> getPhotoByPath(String path) async {
    Database db = await instance.database;
    var rows =
        await db.query(table, where: '$columnPath =?', whereArgs: [path]);
    if (rows.length > 0) {
      return _getPhotofromRow(rows[0]);
    } else {
      throw ("No cached photo");
    }
  }

  Future<int> markPhotoForDeletion(Photo photo) async {
    Database db = await instance.database;
    var values = new Map<String, dynamic>();
    values[columnIsDeleted] = 1;
    return db.update(table, values,
        where: '$columnGeneratedId =?', whereArgs: [photo.generatedId]);
  }

  Future<int> deletePhoto(Photo photo) async {
    Database db = await instance.database;
    return db.delete(table,
        where: '$columnGeneratedId =?', whereArgs: [photo.generatedId]);
  }

  List<Photo> _convertToPhotos(List<Map<String, dynamic>> results) {
    var photos = List<Photo>();
    for (var result in results) {
      photos.add(_getPhotofromRow(result));
    }
    return photos;
  }

  Map<String, dynamic> _getRowForPhoto(Photo photo) {
    var row = new Map<String, dynamic>();
    row[columnLocalId] = photo.localId;
    row[columnUploadedFileId] =
        photo.uploadedFileId == null ? -1 : photo.uploadedFileId;
    row[columnLocalPath] = photo.localPath;
    row[columnRelativePath] = photo.relativePath;
    row[columnThumbnailPath] = photo.thumbnailPath;
    row[columnPath] = photo.path;
    row[columnHash] = photo.hash;
    row[columnCreateTimestamp] = photo.createTimestamp;
    row[columnSyncTimestamp] = photo.syncTimestamp;
    return row;
  }

  Photo _getPhotofromRow(Map<String, dynamic> row) {
    Photo photo = Photo();
    photo.generatedId = row[columnGeneratedId];
    photo.localId = row[columnLocalId];
    photo.uploadedFileId = row[columnUploadedFileId];
    photo.localPath = row[columnLocalPath];
    photo.relativePath = row[columnRelativePath];
    photo.thumbnailPath = row[columnThumbnailPath];
    photo.path = row[columnPath];
    photo.hash = row[columnHash];
    photo.createTimestamp = int.parse(row[columnCreateTimestamp]);
    photo.syncTimestamp = row[columnSyncTimestamp] == null
        ? -1
        : int.parse(row[columnSyncTimestamp]);
    return photo;
  }
}
