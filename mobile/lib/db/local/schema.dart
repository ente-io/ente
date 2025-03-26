import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

const assetColumns =
    "id, type, sub_type, width, height, duration_in_sec, orientation, is_fav, title, relative_path, created_at, modified_at, mime_type, latitude, longitude, scan_state";

// Generate the update clause dynamically (excludes 'id')
final updateAssetColumns = assetColumns
    .split(', ')
    .where((column) => column != 'id') // Exclude primary key from update
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const devicePathColumns =
    "path_id, name, album_type, ios_album_type, ios_album_subtype";

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
      longitude REAL,
      scan_state INTEGER DEFAULT 0,
      hash TEXT,
      size INTEGER,
      os_metadata TEXT DEFAULT '{}'
    );
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
      PRIMARY KEY (path_id, asset_id)
      FOREIGN KEY (path_id) REFERENCES device_path(path_id)
      FOREIGN KEY (asset_id) REFERENCES assets(id)
    );
    ''',
    '''
    CREATE TABLE queue (
      id TEXT NOT NULL,
      name TEXT NOT NULL,
      PRIMARY KEY (id, name)
    );
    '''
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
