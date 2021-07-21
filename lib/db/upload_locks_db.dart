import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class UploadLocksDB {
  static const _databaseName = "ente.upload_locks.db";
  static const _databaseVersion = 1;

  static const _table = "upload_locks";
  static const _columnID = "id";
  static const _columnOwner = "owner";
  static const _columnTime = "time";

  UploadLocksDB._privateConstructor();
  static final UploadLocksDB instance = UploadLocksDB._privateConstructor();

  static Future<Database> _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture;
  }

  Future<Database> _initDatabase() async {
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
                CREATE TABLE $_table (
                  $_columnID TEXT PRIMARY KEY NOT NULL,
                  $_columnOwner TEXT NOT NULL,
                  $_columnTime TEXT NOT NULL
                )
                ''');
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(_table);
  }

  Future<void> acquireLock(String id, String owner, int time) async {
    final db = await instance.database;
    final row = new Map<String, dynamic>();
    row[_columnID] = id;
    row[_columnOwner] = owner;
    row[_columnTime] = time;
    await db.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<bool> isLocked(String id, String owner) async {
    final db = await instance.database;
    final rows = await db.query(
      _table,
      where: '$_columnID = ? AND $_columnOwner = ?',
      whereArgs: [id, owner.toString()],
    );
    return rows.length == 1;
  }

  Future<int> releaseLock(String id, String owner) async {
    final db = await instance.database;
    return db.delete(
      _table,
      where: '$_columnID = ? AND $_columnOwner = ?',
      whereArgs: [id, owner],
    );
  }

  Future<int> releaseLocksAcquiredByOwnerBefore(String owner, int time) async {
    final db = await instance.database;
    return db.delete(
      _table,
      where: '$_columnOwner = ? AND $_columnTime < ?',
      whereArgs: [owner, time],
    );
  }

  Future<int> releaseAllLocksAcquiredBefore(int time) async {
    final db = await instance.database;
    return db.delete(
      _table,
      where: '$_columnTime < ?',
      whereArgs: [time],
    );
  }
}
