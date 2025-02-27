import "package:flutter/cupertino.dart";
import "package:sqlite_async/sqlite_async.dart";

const collectionColumns =
    'id, owner, enc_key, enc_key_nonce, name, type, local_path, '
    'is_deleted, updation_time, sharees, public_urls, mmd_encoded_json, '
    'mmd_ver, pub_mmd_encoded_json, pub_mmd_ver, shared_mmd_json, '
    'shared_mmd_ver';

const collectionFilesColumns =
    'collection_id, file_id, enc_key, enc_key_nonce, created_at, updated_at, is_deleted';

const filesColumns =
    'id, owner_id, file_header, thumb_header, metadata, pri_medata, pub_medata, info';
const trashedFilesColumns =
    'id, owner_id, file_header, thumb_header, metadata, pri_medata, pub_medata, info, trash_data';

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
      PRIMARY KEY (file_id, collection_id)
      enc_key BLOB NOT NULL,
      enc_key_nonce BLOB NOT NULL,
      is_deleted INTEGER NOT NULL
      updated_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT 0,
    )
    ''',
    '''
    CREATE TABLE files (
      id INTEGER PRIMARY KEY,
      owner_id INTEGER NOT NULL,
      file_header BLOB NOT NULL,
      thumb_header BLOB NOT NULL,
      metadata TEXT NOT NULL',
      pri_medata TEXT NOT NULL DEFAULT '{}',
      pub_medata TEXT NOT NULL DEFAULT '{}',
      info TEXT DEFAULT '{}',
      trash_data TEXT,
      FOREIGN KEY(id) REFERENCES collection_files(file_id)
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
      debugPrint("Migrating Remote DB from $currentVersion to $toVersion");
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
