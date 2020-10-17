import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class PublicKeysDB {
  static final _databaseName = "ente.public_keys.db";
  static final _databaseVersion = 1;

  static final table = 'public_keys';

  static final columnEmail = 'email';
  static final columnPublicKey = 'public_key';

  PublicKeysDB._privateConstructor();
  static final PublicKeysDB instance = PublicKeysDB._privateConstructor();

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
                  $columnEmail TEXT PRIMARY KEY NOT NULL,
                  $columnPublicKey TEXT NOT NULL
                )
                ''');
  }

  Future<int> setKey(String email, String publicKey) async {
    final db = await instance.database;
    return db.insert(table, _getRow(email, publicKey),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> searchByEmail(String email) async {
    final db = await instance.database;
    return _convertRows(await db.query(
      table,
      where: '$columnEmail LIKE %?%',
      whereArgs: [email],
    ));
  }

  Map<String, dynamic> _getRow(String email, String publicKey) {
    var row = new Map<String, dynamic>();
    row[columnEmail] = email;
    row[columnPublicKey] = publicKey;
    return row;
  }

  Map<String, String> _convertRows(List<Map<String, dynamic>> rows) {
    final keys = Map<String, String>();
    for (final row in rows) {
      keys[row[columnEmail]] = row[columnPublicKey];
    }
    return keys;
  }
}
