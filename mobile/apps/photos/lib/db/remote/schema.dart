const collectionColumns =
    'id, owner, enc_key, enc_key_nonce, name, type, local_path, is_deleted, '
    'updation_time, sharees, public_urls, mmd_encoded_json, '
    'mmd_ver, pub_mmd_encoded_json, pub_mmd_ver, shared_mmd_json, '
    'shared_mmd_ver';

final String updateCollectionColumns = collectionColumns
    .split(', ')
    .where((column) => column != 'id') // Exclude primary key from update
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const collectionFilesColumns =
    'collection_id, file_id, enc_key, enc_key_nonce, created_at, updated_at';

final String collectionFilesUpdateColumns = collectionFilesColumns
    .split(', ')
    .where(
      (column) =>
          column != 'collection_id' ||
          column != 'file_id' ||
          column != 'created_at',
    )
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const filesColumns =
    'id, owner_id, file_header, thumb_header, creation_time, modification_time, '
    'type, subtype, title, size, hash, visibility, durationInSec, lat, lng, '
    'height, width, no_thumb, sv, media_type, motion_video_index, caption, uploader_name';

final String filesUpdateColumns = filesColumns
    .split(', ')
    .where((column) => (column != 'id'))
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const filesMetadataColumns = 'id, metadata, priv_metadata, pub_metadata, info';
final String filesMetadataUpdateColumns = filesMetadataColumns
    .split(', ')
    .where((column) => (column != 'id'))
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const trashedFilesColumns =
    'id, owner_id, collection_id, enc_key,enc_key_nonce, file_header, thumb_header, metadata, priv_metadata, pub_metadata, info, created_at, updated_at, delete_by';

final String trashedFilesUpdateColumns = trashedFilesColumns
    .split(', ')
    .where((column) => (column != 'id'))
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const uploadLocalMappingColumns =
    'file_id, local_id, local_cloud_id, local_mapping_src';
String collectionValuePlaceHolder =
    collectionColumns.split(',').map((_) => '?').join(',');

class RemoteDBMigration {
  static const migrationScripts = [
    '''
    CREATE TABLE collections (
      id INTEGER PRIMARY KEY,
      owner TEXT NOT NULL,
      enc_key TEXT NOT NULL,
      enc_key_nonce TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      local_path TEXT,
      is_deleted INTEGER NOT NULL,
      updation_time INTEGER NOT NULL,
      sharees TEXT NOT NULL DEFAULT '[]',
      public_urls TEXT NOT NULL DEFAULT '[]',
      mmd_encoded_json TEXT NOT NULL DEFAULT '{}',
      mmd_ver INTEGER NOT NULL DEFAULT 0,
      pub_mmd_encoded_json TEXT DEFAULT '{}',
      pub_mmd_ver INTEGER NOT NULL DEFAULT 0,
      shared_mmd_json TEXT NOT NULL DEFAULT '{}',
      shared_mmd_ver INTEGER NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE collection_files (
      file_id INTEGER NOT NULL,
      collection_id INTEGER NOT NULL,
      enc_key BLOB NOT NULL,
      enc_key_nonce BLOB NOT NULL,
      updated_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (file_id, collection_id)
    );
    ''',
    '''
    CREATE TABLE files (
      id INTEGER PRIMARY KEY,
      owner_id INTEGER NOT NULL,
      file_header BLOB NOT NULL,
      thumb_header BLOB NOT NULL,
      creation_time INTEGER NOT NULL,
      modification_time INTEGER NOT NULL,
      type INTEGER NOT NULL,
      subtype INTEGER NOT NULL,
      title TEXT NOT NULL,
      size INTEGER,
      hash TEXT,
      visibility integer,
      durationInSec INTEGER,
      lat REAL DEFAULT NULL,
      lng REAL DEFAULT NULL,
      height INTEGER,
      width INTEGER,
      no_thumb INTEGER,
      sv INTEGER,
      media_type INTEGER,
      motion_video_index INTEGER,
      caption TEXT,
      uploader_name TEXT
    )
    ''',
    '''
    CREATE TABLE files_metadata (
      id INTEGER PRIMARY KEY,
      metadata TEXT NOT NULL,
      priv_metadata TEXT,
      pub_metadata TEXT,
      info TEXT,
      FOREIGN KEY (id) REFERENCES files(id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE trash (
      id INTEGER PRIMARY KEY,
      owner_id INTEGER NOT NULL,
      collection_id INTEGER NOT NULL,
      enc_key BLOB NOT NULL,
      enc_key_nonce BLOB NOT NULL,
      metadata TEXT NOT NULL,
      priv_metadata TEXT,
      pub_metadata TEXT,
      info TEXT,
      file_header BLOB NOT NULL,
      thumb_header BLOB NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      delete_by INTEGER NOT NULL
    )
    ''',
    '''
      CREATE TRIGGER delete_orphaned_files
      AFTER DELETE ON collection_files
      FOR EACH ROW
      WHEN (
          -- Only proceed if this file_id actually existed before deletion
          OLD.file_id IS NOT NULL
          -- And only if this was the last reference to the file
          AND NOT EXISTS (
              SELECT 1 
              FROM collection_files 
              WHERE file_id = OLD.file_id
          )
      )
      BEGIN
          -- Only then delete from files table
          DELETE FROM files WHERE id = OLD.file_id;
      END;
''',
    '''
    CREATE TABLE upload_mapping (
      file_id INTEGER PRIMARY KEY,
      local_id TEXT NOT NULL,
      -- icloud identifier if available
      local_cloud_id TEXT,
      local_mapping_src TEXT DEFAULT NULL,
      FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
    )'''
  ];
}

class FilterQueryParam {
  int? collectionID;
  int? limit;
  int? offset;
  String? orderByColumn;
  bool isAsc;
  (int?, int?)? createAtRange;

  FilterQueryParam({
    this.limit,
    this.offset,
    this.collectionID,
    this.orderByColumn = "creation_time",
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

  String get collectionFilter =>
      (collectionID == null) ? "" : "collection_id = $collectionID";

  String get createAtRangeStr => (createAtRange == null ||
          createAtRange!.$1 == null)
      ? ""
      : "(creation_time BETWEEN ${createAtRange!.$1} AND ${createAtRange!.$2})";

  String whereClause() {
    final where = <String>[];
    if (collectionFilter.isNotEmpty) {
      where.add(collectionFilter);
    }
    if (createAtRangeStr.isNotEmpty) {
      where.add(createAtRangeStr);
    }

    return (where.isEmpty ? "" : where.join(" AND ")) +
        " " +
        orderBy +
        " " +
        limitOffset;
  }
}
