import 'dart:io';

import 'package:myapp/models/photo.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "orma.db";
  static final _databaseVersion = 1;

  static final table = 'photos';

  static final columnId = 'photo_id';
  static final columnLocalPath = 'local_path';
  static final columnUrl = 'url';
  static final columnHash = 'hash';
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
            $columnId VARCHAR(255) PRIMARY KEY,
            $columnLocalPath TEXT NOT NULL,
            $columnUrl TEXT NOT NULL,
            $columnHash TEXT NOT NULL,
            $columnSyncTimestamp TEXT NOT NULL
          )
          ''');
  }

  Future<int> insertPhoto(Photo photo) async {
    Database db = await instance.database;
    var row = new Map<String, dynamic>();
    row[columnId] = photo.photoID;
    row[columnLocalPath] = photo.localPath;
    row[columnUrl] = photo.url;
    row[columnHash] = photo.hash;
    row[columnSyncTimestamp] = photo.syncTimestamp;
    return await db.insert(table, row);
  }

  Future<List<Photo>> getAllPhotos() async {
    Database db = await instance.database;
    var results = await db.query(table);
    var photos = List<Photo>();
    for (var result in results) {
      photos.add(Photo.fromRow(result));
    }
    return photos;
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<bool> containsPath(String path) async {
    Database db = await instance.database;
    return (await db.query(table, where: '$columnLocalPath =?', whereArgs: [path]))
            .length >
        0;
  }
}
