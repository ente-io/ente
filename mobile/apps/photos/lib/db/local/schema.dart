import "dart:io";

import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

const assetColumns =
    "id, type, sub_type, width, height, duration_in_sec, orientation, is_fav, title, relative_path, created_at, modified_at, mime_type, latitude, longitude, scan_state";

const assetUploadQueueColumns =
    "dest_collection_id, asset_id, path_id, owner_id, manual";
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
        MAX(a.created_at) as max_created,
		count(*) as asset_count
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
        ROW_NUMBER() OVER (PARTITION BY dpa.path_id ORDER BY a.id) as rn,
		lpp.asset_count
    FROM 
        device_path_assets dpa
    JOIN 
        assets a ON dpa.asset_id = a.id
    JOIN 
        latest_per_path lpp ON dpa.path_id = lpp.path_id AND a.created_at = lpp.max_created
)
SELECT 
    dp.*,
    ra.*,
	pc.*
FROM 
    device_path dp
JOIN 
    ranked_assets ra ON dp.path_id = ra.path_id AND ra.rn = 1
LEFT JOIN path_backup_config pc
    on dp.path_id = pc.device_path_id
    ''';

class LocalAssertsParam {
  int? limit;
  int? offset;
  String? orderByColumn;
  bool isAsc;
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
      : "ORDER BY $orderByColumn ${isAsc ? "ASC" : "DESC"}";

  String get limitOffset => (limit != null && offset != null)
      ? "LIMIT $limit +  OFFSET $offset)"
      : (limit != null)
          ? "LIMIT $limit"
          : "";

  String get createAtRangeStr => (createAtRange == null ||
          createAtRange!.$1 == null)
      ? ""
      : "(created_at BETWEEN ${createAtRange!.$1} AND ${createAtRange!.$2})";

  String whereClause({bool addWhere = false}) {
    final where = <String>[];
    if (createAtRangeStr.isNotEmpty) {
      where.add(createAtRangeStr);
    }

    return (where.isEmpty
            ? ""
            : '${addWhere ? "Where" : ""} ${where.join(" AND ")}') +
        " " +
        orderBy +
        " " +
        limitOffset;
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
        CREATE INDEX IF NOT EXISTS assets_created_at ON assets(created_at);
    ''',
    '''
      CREATE TABLE shared_assets (
       dest_collection_id INTEGER NOT NULL,
       id TEXT NOT NULL,
       name TEXT NOT NULL,
       type INTEGER NOT NULL,
       created_at INTEGER NOT NULL,
       duration_in_sec INTEGER DEFAULT 0,
       owner_id INTEGER NOT NULL,
       latitude REAL,
       longitude REAL,
       PRIMARY KEY (dest_collection_id, id)
    );
  ''',
    '''
        CREATE INDEX IF NOT EXISTS sa_collection_owner ON shared_assets(dest_collection_id, owner_id);
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
      FOREIGN KEY (path_id) REFERENCES device_path(path_id)  ON DELETE CASCADE,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
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
    CREATE TABLE path_backup_config(
      device_path_id TEXT PRIMARY KEY,
      owner_id INTEGER NOT NULL,
      collection_id INTEGER,
      should_backup INTEGER NOT NULL DEFAULT 0,
      upload_strategy INTEGER NOT NULL DEFAULT 0
    );
  ''',
    '''
    CREATE TABLE asset_upload_queue (
      dest_collection_id INTEGER NOT NULL,
      asset_id TEXT NOT NULL,
      path_id TEXT,
      owner_id INTEGER NOT NULL,
      manual INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (dest_collection_id, asset_id),
      FOREIGN KEY(asset_id) REFERENCES assets(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_asset_upload_queue_owner_id 
      ON asset_upload_queue(owner_id) 
      WHERE owner_id IS NOT NULL;
  ''',
    '''
        CREATE INDEX IF NOT EXISTS assets_created_at_desc ON assets(created_at DESC);
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
