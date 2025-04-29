import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/memories/memory.dart';
import 'package:sqflite/sqflite.dart';

class MemoriesDB {
  static const _databaseName = "ente.memories.db";
  static const _databaseVersion = 1;

  static const table = 'memories';

  static const columnFileID = 'file_id';
  static const columnSeenTime = 'seen_time';

  MemoriesDB._privateConstructor();
  static final MemoriesDB instance = MemoriesDB._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
                CREATE TABLE $table (
                  $columnFileID INTEGER PRIMARY KEY NOT NULL,
                  $columnSeenTime TEXT NOT NULL
                )
                ''',
    );
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(table);
  }

  Future<int> clearMemoriesSeenBeforeTime(int timestamp) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnSeenTime < ?',
      whereArgs: [timestamp],
    );
  }

  Future<int> markMemoryAsSeen(Memory memory, int timestamp) async {
    final db = await instance.database;
    return await db.insert(
      table,
      _getRowForSeenMemory(memory, timestamp),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<int, int>> getSeenTimes() async {
    final db = await instance.database;
    return _convertToSeenTimes(await db.query(table));
  }

  Map<String, dynamic> _getRowForSeenMemory(Memory memory, int timestamp) {
    final row = <String, dynamic>{};
    row[columnFileID] = memory.file.generatedID;
    row[columnSeenTime] = timestamp;
    return row;
  }

  Map<int, int> _convertToSeenTimes(List<Map<String, dynamic>> rows) {
    final seenTimes = <int, int>{};
    for (final row in rows) {
      seenTimes[row[columnFileID]] = int.parse(row[columnSeenTime]);
    }
    return seenTimes;
  }
}
