import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:photos/models/memory.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class MemoriesDB {
  static final _databaseName = "ente.memories.db";
  static final _databaseVersion = 1;

  static final table = 'memories';

  static final columnFileId = 'file_id';
  static final columnSeenTime = 'seen_time';

  MemoriesDB._privateConstructor();
  static final MemoriesDB instance = MemoriesDB._privateConstructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
                CREATE TABLE $table (
                  $columnFileId INTEGER PRIMARY KEY NOT NULL,
                  $columnSeenTime TEXT NOT NULL
                )
                ''');
  }

  Future<int> clearMemoriesSeenBeforeTime(int timestamp) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnSeenTime < ',
      whereArgs: [timestamp],
    );
  }

  Future<int> markMemoryAsSeen(Memory memory, int timestamp) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForSeenMemory(memory, timestamp),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<int>> getSeenFileIDs() async {
    final db = await instance.database;
    return _convertToFileIDs(await db.query(table));
  }

  Map<String, dynamic> _getRowForSeenMemory(Memory memory, int timestamp) {
    var row = new Map<String, dynamic>();
    row[columnFileId] = memory.file.generatedId;
    row[columnSeenTime] = timestamp;
    return row;
  }

  _convertToFileIDs(List<Map<String, dynamic>> rows) {
    final fileIDs = List<int>();
    for (final row in rows) {
      fileIDs.add(int.parse(row[columnFileId]));
    }
  }
}
