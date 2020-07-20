import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:photos/models/folder.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class FoldersDB {
  static final _databaseName = "ente.folder.db";
  static final _databaseVersion = 1;

  static final table = 'folders';

  static final columnId = 'id';
  static final columnName = 'name';
  static final columnOwner = 'owner';
  static final columnDeviceFolder = 'device_folder';
  static final columnSharedWith = 'shared_with';
  static final columnUpdationTime = 'updation_time';

  FoldersDB._privateConstructor();
  static final FoldersDB instance = FoldersDB._privateConstructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY NOT NULL,
            $columnName TEXT NOT NULL,
            $columnOwner TEXT NOT NULL,
            $columnDeviceFolder TEXT NOT NULL,
            $columnSharedWith TEXT NOT NULL,
            $columnUpdationTime INTEGER NOT NULL,
            UNIQUE($columnOwner, $columnDeviceFolder)
          )
          ''');
  }

  Future<int> putFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForFolder(folder),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Folder>> getFolders() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      orderBy: '$columnUpdationTime DESC',
    );
    return _convertToFolders(results);
  }

  Future<int> deleteFolder(Folder folder) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnId =?',
      whereArgs: [folder.id],
    );
  }

  List<Folder> _convertToFolders(List<Map<String, dynamic>> results) {
    final folders = List<Folder>();
    for (final result in results) {
      folders.add(_getFolderFromRow(result));
    }
    return folders;
  }

  Map<String, dynamic> _getRowForFolder(Folder folder) {
    final row = new Map<String, dynamic>();
    row[columnId] = folder.id;
    row[columnName] = folder.name;
    row[columnOwner] = folder.owner;
    row[columnDeviceFolder] = folder.deviceFolder;
    row[columnSharedWith] = jsonEncode(folder.sharedWith.toList());
    row[columnUpdationTime] = folder.updationTime;
    return row;
  }

  Folder _getFolderFromRow(Map<String, dynamic> row) {
    return Folder(
      row[columnId],
      row[columnName],
      row[columnOwner],
      row[columnDeviceFolder],
      (jsonDecode(row[columnSharedWith]) as List<dynamic>)
          .cast<String>()
          .toSet(),
      row[columnUpdationTime],
    );
  }
}
