import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

class LocalDBMigration {
  static const migrationScripts = [
    '''
    CREATE TABLE assets (
      id TEXT PRIMARY KEY,
      type INTEGER NOT NULL,
      subType INTEGER NOT NULL,
      width INTEGER NOT NULL,
      height INTEGER NOT NULL,
      durationMicroSec INTEGER NOT NULL,
      orientation INTEGER NOT NULL,
      isFavorite INTEGER NOT NULL,
      title TEXT,
      relative_path TEXT,
      createdAtMicroSec INTEGER NOT NULL,
      modifiedAtMicroSec INTEGER NOT NULL,
      mime_type TEXT,
      latitude REAL,
      longitude REAL,
    );
    ''',
    '''
    CREATE TABLE metadata (
      id TEXT NOT NULL,
      hash TEXT NOT NULL,
      creation_time INTEGER NOT NULL,
      modification_time INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      PRIMARY KEY (id, hash),
      FOREIGN KEY (id) REFERENCES assets (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE device_path (
      path_id TEXT NOT NULL,
      hash TEXT NOT NULL,
      creation_time INTEGER NOT NULL,
      modification_time INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      PRIMARY KEY (id, hash)
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
