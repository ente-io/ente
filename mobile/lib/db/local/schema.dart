import "dart:io";

import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

const assetColumns =
    "id, type, sub_type, width, height, duration_in_sec, orientation, is_fav, title, relative_path, created_at, modified_at, mime_type, latitude, longitude, scan_state";

const androidAssetState = 1;
const androidHashState = 1 << 2;
const androidMediaType = 1 << 3;
const iOSAssetState = 1;
const iOSCloudIdState = 1 << 2;
const iOSAssetHashState = 1 << 3;

final finalState = Platform.isAndroid
    ? (androidAssetState ^ androidHashState ^ androidMediaType)
    : (iOSAssetState ^ iOSCloudIdState ^ iOSAssetHashState);
// Generate the update clause dynamically (excludes 'id')
final String updateAssetColumns = assetColumns
    .split(', ')
    .where((column) => column != 'id') // Exclude primary key from update
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const devicePathColumns =
    "path_id, name, album_type, ios_album_type, ios_album_subtype";

final String updateDevicePathColumns = devicePathColumns
    .split(', ')
    .where((column) => column != 'path_id') // Exclude primary key from update
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const String deviceCollectionWithOneAssetQuery = '''
WITH latest_per_path AS (
    SELECT 
        dpa.path_id,
        MAX(a.created_at) as max_created
    FROM 
        device_path_assets dpa
    JOIN 
        assets a ON dpa.asset_id = a.id
    GROUP BY 
        dpa.path_id
),
ranked_assets AS (
    SELECT 
        dpa.path_id,
        a.*,
        ROW_NUMBER() OVER (PARTITION BY dpa.path_id ORDER BY a.id) as rn
    FROM 
        device_path_assets dpa
    JOIN 
        assets a ON dpa.asset_id = a.id
    JOIN 
        latest_per_path lpp ON dpa.path_id = lpp.path_id AND a.created_at = lpp.max_created
)
SELECT 
    dp.*,
    ra.*
FROM 
    device_path dp
JOIN 
    ranked_assets ra ON dp.path_id = ra.path_id AND ra.rn = 1
    ''';

class LocalAssertsParam {
  int? limit;
  int? offset;
  String? orderByColumn;
  bool? isAsc;
  (int?, int?)? createAtRange;

  LocalAssertsParam({
    this.limit,
    this.offset,
    this.orderByColumn = "created_at",
    this.isAsc = false,
    this.createAtRange,
  });

  String get orderBy => orderByColumn == null
      ? ""
      : "ORDER BY $orderByColumn ${isAsc! ? "ASC" : "DESC"}";

  String get limitOffset => (limit != null && offset != null)
      ? "LIMIT $limit +  OFFSET $offset)"
      : (limit != null)
          ? "LIMIT $limit"
          : "";

  String get createAtRangeStr => (createAtRange == null ||
          createAtRange!.$1 == null)
      ? ""
      : "(created_at BETWEEN ${createAtRange!.$1} AND ${createAtRange!.$2})";

  String whereClause() {
    final where = <String>[];
    if (createAtRangeStr.isNotEmpty) {
      where.add(createAtRangeStr);
    }

    return (where.isEmpty ? "" : where.join(" AND ")) + " " + limitOffset;
  }
}

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
    ''',
    '''
        CREATE INDEX IF NOT EXISTS assets_created_at ON assets(created_at);
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
