import "package:path/path.dart";
import "package:photos/module/download/task.dart";
import "package:sqflite/sqflite.dart";

class DatabaseHelper {
  static final _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'download_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            id INTEGER PRIMARY KEY,
            filename TEXT NOT NULL,
            totalBytes INTEGER NOT NULL,
            bytesDownloaded INTEGER DEFAULT 0,
            status TEXT NOT NULL,
            error TEXT,
            filePath TEXT
          )
        ''');
      },
    );
  }

  Future<void> save(DownloadTask task) async {
    final db = await database;
    await db.insert('downloads', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DownloadTask?> get(int id) async {
    final db = await database;
    final maps = await db.query('downloads', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? DownloadTask.fromMap(maps.first) : null;
  }

  Future<List<DownloadTask>> getAll() async {
    final db = await database;
    final maps = await db.query('downloads');
    return maps.map(DownloadTask.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }
}
