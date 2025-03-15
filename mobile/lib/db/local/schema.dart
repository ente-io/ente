import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

const assetColumns =
    "id, type, sub_type, width, height, duration_in_sec, orientation, is_fav, title, relative_path, created_at, modified_at, mime_type, latitude, longitude";

const devicePathColumns =
    "path_id, name, album_type, ios_album_type, ios_album_subtype";
const placeHolderMap = {
  1: "?",
  2: "?,?",
  3: "?,?,?",
  4: "?,?,?,?",
  5: "?,?,?,?,?",
  6: "?,?,?,?,?,?",
  7: "?,?,?,?,?,?,?",
  8: "?,?,?,?,?,?,?,?",
  9: "?,?,?,?,?,?,?,?,?",
  10: "?,?,?,?,?,?,?,?,,?,?",
  11: "?,?,?,?,?,?,?,?,?,?,?,?",
  12: "?,?,?,?,?,?,?,?,?,?,?,?,?",
  13: "?,?,?,?,?,?,?,?,?,?,?,?,?,?",
  14: "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?",
  15: "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?",
};

class LocalDBMigration {
  static const migrationScripts = [
    '''
    CREATE TABLE assets (
      id TEXT PRIMARY KEY,
      type INTEGER NOT NULL,
      sub_type INTEGER NOT NULL,
      width INTEGER NOT NULL,
      height INTEGER NOT NULL,
      duration_in_sec INTEGER NOT NULL,
      orientation INTEGER NOT NULL,
      is_fav INTEGER NOT NULL,
      title TEXT NOT NULL,
      relative_path TEXT,
      created_at INTEGER NOT NULL,
      modified_at INTEGER NOT NULL,
      mime_type TEXT,
      latitude REAL,
      longitude REAL
    );
    ''',
    '''
    CREATE TABLE metadata (
      id TEXT PRIMARY_KEY,
      hash TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      modified_at INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      PRIMARY KEY (id),
      FOREIGN KEY (id) REFERENCES assets (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE old_hash (
     id TEXT NOT NULL,
     hash TEXT NOT NULL,
     created_at INTEGER NOT NULL,
     PRIMARY KEY (id, hash),
     FOREIGN KEY (id) REFERENCES assets (id) ON DELETE CASCADE
    ); 
  ''',
    '''
    CREATE TRIGGER update_old_hash
    AFTER UPDATE OF hash ON metadata
    FOR EACH ROW
        WHEN OLD.hash != NEW.hash AND NEW.hash IS NOT NULL
          BEGIN
            INSERT OR REPLACE INTO old_hash (id, hash, created_at) 
            VALUES (OLD.id, OLD.hash, strftime('%s', 'now'));
           END;
    ''',
    '''
    CREATE TABLE device_path (
      path_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      album_type INTEGER NOT NULL,
      ios_album_type INTEGER,
      ios_album_subtype INTEGER
    );
    ''',
    '''
    CREATE TABLE device_path_assets (
      path_id TEXT NOT NULL,
      asset_id TEXT NOT NULL,
      PRIMARY KEY (path_id, asset_id),
      FOREIGN KEY (path_id) REFERENCES device_path (path_id) ON DELETE CASCADE,
      FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE queue (
      id TEXT NOT NULL,
      name TEXT NOT NULL,
      PRIMARY KEY (id, name),
      FOREIGN KEY (id) REFERENCES assets (id) ON DELETE CASCADE
    )
    ''',
  ];

  static Future<void> migrate(
    SqliteDatabase database,
  ) async {
    final result = await database.execute('PRAGMA user_version');
    await database.execute("PRAGMA foreign_keys = ON");
    final currentVersion = result[0]['user_version'] as int;
    final toVersion = migrationScripts.length;

    if (currentVersion < toVersion) {
      debugPrint("Migrating Local DB from $currentVersion to $toVersion");
      await database.writeTransaction((tx) async {
        for (int i = currentVersion + 1; i <= toVersion; i++) {
          await tx.execute(migrationScripts[i - 1]);
        }
        await tx.execute('PRAGMA user_version = $toVersion');
      });
    } else if (currentVersion > toVersion) {
      throw AssertionError(
        "currentVersion($currentVersion) cannot be greater than toVersion($toVersion)",
      );
    }
  }
}
