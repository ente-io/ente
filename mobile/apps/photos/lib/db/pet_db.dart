import "package:logging/logging.dart";
import "package:path/path.dart" show join;
import "package:path_provider/path_provider.dart";
import "package:photos/db/common/base.dart";
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:sqlite_async/sqlite_async.dart";

/// Standalone database for [PetEntity] records.
///
/// Pet entities are user-level concepts (independent of online/offline mode),
/// so a single shared instance is used app-wide.
class PetDB with SqlDbBase {
  static final Logger _logger = Logger("PetDB");
  static const _databaseName = "ente.pets.db";

  PetDB._();
  static final PetDB instance = PetDB._();

  Future<SqliteDatabase>? _dbFuture;

  Future<SqliteDatabase> get _db async {
    _dbFuture ??= _init();
    return _dbFuture!;
  }

  static const _petsTable = "pets";

  static const _migrationScripts = [
    '''CREATE TABLE IF NOT EXISTS $_petsTable (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  species INTEGER NOT NULL DEFAULT -1
)''',
  ];

  Future<SqliteDatabase> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _databaseName);
    _logger.info("Opening PetDB at $path");
    final db = SqliteDatabase(path: path, maxReaders: 2);
    await migrate(db, _migrationScripts);
    return db;
  }

  Future<List<PetEntity>> getAll() async {
    final db = await _db;
    final rows = await db.getAll("SELECT * FROM $_petsTable");
    return rows.map(PetEntity.fromMap).toList();
  }

  Future<Map<String, PetEntity>> getAllAsMap() async {
    final pets = await getAll();
    return {for (final p in pets) p.id: p};
  }

  Future<PetEntity?> get(String id) async {
    final db = await _db;
    final rows =
        await db.getAll("SELECT * FROM $_petsTable WHERE id = ?", [id]);
    if (rows.isEmpty) return null;
    return PetEntity.fromMap(rows.first);
  }

  Future<void> upsert(PetEntity pet) async {
    final db = await _db;
    await db.execute(
      '''INSERT INTO $_petsTable (id, name, species) VALUES (?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           name = excluded.name,
           species = excluded.species''',
      [pet.id, pet.name, pet.species],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.execute("DELETE FROM $_petsTable WHERE id = ?", [id]);
  }
}
