const collectionColumns =
    'id, owner, enc_key, enc_key_nonce, name, type, local_path, '
    'is_deleted, updation_time, sharees, public_urls, mmd_encoded_json, '
    'mmd_ver, pub_mmd_encoded_json, pub_mmd_ver, shared_mmd_json, '
    'shared_mmd_ver';

final String updateCollectionColumns = collectionColumns
    .split(', ')
    .where((column) => column != 'id') // Exclude primary key from update
    .map((column) => '$column = excluded.$column') // Use excluded virtual table
    .join(', ');

const collectionFilesColumns =
    'collection_id, file_id, enc_key, enc_key_nonce, created_at, updated_at, is_deleted';

const filesColumns =
    'id, owner_id, file_header, thumb_header, metadata, priv_metadata, pub_metadata, info';
const trashedFilesColumns =
    'id, owner_id, file_header, thumb_header, metadata, priv_metadata, pub_metadata, info, trash_data';

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
      is_deleted INTEGER NOT NULL,
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
      metadata TEXT NOT NULL,
      priv_metadata TEXT NOT NULL DEFAULT '{}',
      pub_metadata TEXT NOT NULL DEFAULT '{}',
      info TEXT DEFAULT '{}',
      trash_data TEXT
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
  ];
}
