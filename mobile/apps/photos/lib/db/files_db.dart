import "dart:async";
import "dart:io";

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import "package:photos/db/common/base.dart";
import "package:photos/extensions/stop_watch.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/location/location.dart';
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/services/filter/db_filters.dart";
import 'package:sqlite_async/sqlite_async.dart';

class FilesDB with SqlDbBase {
  /*
  Note: columnUploadedFileID and columnCollectionID have to be compared against
  both NULL and -1 because older clients might have entries where the DEFAULT
  was unset, and a migration script to set the DEFAULT would break in case of
  duplicate entries for un-uploaded files that were created due to a collision
  in background and foreground syncs.
  */
  static const _databaseName = "ente.files.db";

  static final Logger _logger = Logger("FilesDB");

  static const filesTable = 'files';
  static const tempTable = 'temp_files';

  static const columnGeneratedID = '_id';
  static const columnUploadedFileID = 'uploaded_file_id';
  static const columnOwnerID = 'owner_id';
  static const columnCollectionID = 'collection_id';
  static const columnLocalID = 'local_id';
  static const columnTitle = 'title';
  static const columnDeviceFolder = 'device_folder';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnFileType = 'file_type';
  static const columnFileSubType = 'file_sub_type';
  static const columnDuration = 'duration';
  static const columnExif = 'exif';
  static const columnHash = 'hash';
  static const columnMetadataVersion = 'metadata_version';
  static const columnIsDeleted = 'is_deleted';
  static const columnCreationTime = 'creation_time';
  static const columnModificationTime = 'modification_time';
  static const columnUpdationTime = 'updation_time';
  static const columnAddedTime = 'added_time';
  static const columnEncryptedKey = 'encrypted_key';
  static const columnKeyDecryptionNonce = 'key_decryption_nonce';
  static const columnFileDecryptionHeader = 'file_decryption_header';
  static const columnThumbnailDecryptionHeader = 'thumbnail_decryption_header';
  static const columnMetadataDecryptionHeader = 'metadata_decryption_header';
  static const columnFileSize = 'file_size';

  // MMD -> Magic Metadata
  static const columnMMdEncodedJson = 'mmd_encoded_json';
  static const columnMMdVersion = 'mmd_ver';

  static const columnPubMMdEncodedJson = 'pub_mmd_encoded_json';
  static const columnPubMMdVersion = 'pub_mmd_ver';

  // part of magic metadata
  // Only parse & store selected fields from JSON in separate columns if
  // we need to write query based on that field
  static const columnMMdVisibility = 'mmd_visibility';

//If adding or removing a new column, make sure to update the `_columnNames` list
//and update `_generateColumnsAndPlaceholdersForInsert` and
//`_generateUpdateAssignmentsWithPlaceholders`
  static final _migrationScripts = [
    ...createTable(filesTable),
    ...alterDeviceFolderToAllowNULL(),
    ...alterTimestampColumnTypes(),
    ...addIndices(),
    ...addMetadataColumns(),
    ...addMagicMetadataColumns(),
    ...addUniqueConstraintOnCollectionFiles(),
    ...addPubMagicMetadataColumns(),
    ...createOnDeviceFilesAndPathCollection(),
    ...addFileSizeColumn(),
    ...updateIndexes(),
    ...createEntityDataTable(),
    ...addAddedTime(),
  ];

  static const List<String> _columnNames = [
    columnGeneratedID,
    columnLocalID,
    columnUploadedFileID,
    columnOwnerID,
    columnCollectionID,
    columnTitle,
    columnDeviceFolder,
    columnLatitude,
    columnLongitude,
    columnFileType,
    columnModificationTime,
    columnEncryptedKey,
    columnKeyDecryptionNonce,
    columnFileDecryptionHeader,
    columnThumbnailDecryptionHeader,
    columnMetadataDecryptionHeader,
    columnCreationTime,
    columnUpdationTime,
    columnFileSubType,
    columnDuration,
    columnExif,
    columnHash,
    columnMetadataVersion,
    columnMMdEncodedJson,
    columnMMdVersion,
    columnMMdVisibility,
    columnPubMMdEncodedJson,
    columnPubMMdVersion,
    columnFileSize,
    columnAddedTime,
  ];

  // make this a singleton class
  FilesDB._privateConstructor();

  static final FilesDB instance = FilesDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<SqliteDatabase>? _sqliteAsyncDBFuture;

  Future<SqliteDatabase> get sqliteAsyncDB async {
    // lazily instantiate the db the first time it is accessed
    _sqliteAsyncDBFuture ??= _initSqliteAsyncDatabase();
    return _sqliteAsyncDBFuture!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<SqliteDatabase> _initSqliteAsyncDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path " + path);
    final database = SqliteDatabase(path: path);
    await migrate(database, _migrationScripts);
    return database;
  }

  // SQL code to create the database table
  static List<String> createTable(String tableName) {
    return [
      '''
        CREATE TABLE $tableName (
          $columnGeneratedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          $columnLocalID TEXT,
          $columnUploadedFileID INTEGER DEFAULT -1,
          $columnOwnerID INTEGER,
          $columnCollectionID INTEGER DEFAULT -1,
          $columnTitle TEXT NOT NULL,
          $columnDeviceFolder TEXT,
          $columnLatitude REAL,
          $columnLongitude REAL,
          $columnFileType INTEGER,
          $columnModificationTime TEXT NOT NULL,
          $columnEncryptedKey TEXT,
          $columnKeyDecryptionNonce TEXT,
          $columnFileDecryptionHeader TEXT,
          $columnThumbnailDecryptionHeader TEXT,
          $columnMetadataDecryptionHeader TEXT,
          $columnIsDeleted INTEGER DEFAULT 0,
          $columnCreationTime TEXT NOT NULL,
          $columnUpdationTime TEXT,
          UNIQUE($columnLocalID, $columnUploadedFileID, $columnCollectionID)
        );
      ''',
    ];
  }

  static List<String> addIndices() {
    return [
      '''
        CREATE INDEX IF NOT EXISTS collection_id_index ON $filesTable($columnCollectionID);
      ''',
      '''
        CREATE INDEX IF NOT EXISTS device_folder_index ON $filesTable($columnDeviceFolder);
      ''',
      '''
        CREATE INDEX IF NOT EXISTS creation_time_index ON $filesTable($columnCreationTime);
      ''',
      '''
        CREATE INDEX IF NOT EXISTS updation_time_index ON $filesTable($columnUpdationTime);
      '''
    ];
  }

  static List<String> alterDeviceFolderToAllowNULL() {
    return [
      ...createTable(tempTable),
      '''
        INSERT INTO $tempTable
        SELECT *
        FROM $filesTable;

        DROP TABLE $filesTable;
        
        ALTER TABLE $tempTable 
        RENAME TO $filesTable;
    '''
    ];
  }

  static List<String> alterTimestampColumnTypes() {
    return [
      '''
        DROP TABLE IF EXISTS $tempTable;
      ''',
      '''
        CREATE TABLE $tempTable (
          $columnGeneratedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          $columnLocalID TEXT,
          $columnUploadedFileID INTEGER DEFAULT -1,
          $columnOwnerID INTEGER,
          $columnCollectionID INTEGER DEFAULT -1,
          $columnTitle TEXT NOT NULL,
          $columnDeviceFolder TEXT,
          $columnLatitude REAL,
          $columnLongitude REAL,
          $columnFileType INTEGER,
          $columnModificationTime INTEGER NOT NULL,
          $columnEncryptedKey TEXT,
          $columnKeyDecryptionNonce TEXT,
          $columnFileDecryptionHeader TEXT,
          $columnThumbnailDecryptionHeader TEXT,
          $columnMetadataDecryptionHeader TEXT,
          $columnCreationTime INTEGER NOT NULL,
          $columnUpdationTime INTEGER,
          UNIQUE($columnLocalID, $columnUploadedFileID, $columnCollectionID)
        );
      ''',
      '''
        INSERT INTO $tempTable
        SELECT 
          $columnGeneratedID,
          $columnLocalID,
          $columnUploadedFileID,
          $columnOwnerID,
          $columnCollectionID,
          $columnTitle,
          $columnDeviceFolder,
          $columnLatitude,
          $columnLongitude,
          $columnFileType,
          CAST($columnModificationTime AS INTEGER),
          $columnEncryptedKey,
          $columnKeyDecryptionNonce,
          $columnFileDecryptionHeader,
          $columnThumbnailDecryptionHeader,
          $columnMetadataDecryptionHeader,
          CAST($columnCreationTime AS INTEGER),
          CAST($columnUpdationTime AS INTEGER)
        FROM $filesTable;
      ''',
      '''
        DROP TABLE $filesTable;
      ''',
      '''
        ALTER TABLE $tempTable 
        RENAME TO $filesTable;
      ''',
    ];
  }

  static List<String> addMetadataColumns() {
    return [
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnFileSubType INTEGER;
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnDuration INTEGER;
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnExif TEXT;
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnHash TEXT;
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnMetadataVersion INTEGER;
      ''',
    ];
  }

  static List<String> addMagicMetadataColumns() {
    return [
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnMMdEncodedJson TEXT DEFAULT '{}';
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnMMdVersion INTEGER DEFAULT 0;
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnMMdVisibility INTEGER DEFAULT $visibleVisibility;
      '''
    ];
  }

  static List<String> addUniqueConstraintOnCollectionFiles() {
    return [
      '''
      DELETE from $filesTable where $columnCollectionID || '-' || $columnUploadedFileID IN 
      (SELECT $columnCollectionID || '-' || $columnUploadedFileID from $filesTable WHERE 
      $columnCollectionID is not NULL AND $columnUploadedFileID is NOT NULL 
      AND $columnCollectionID != -1 AND $columnUploadedFileID  != -1 
      GROUP BY ($columnCollectionID || '-' || $columnUploadedFileID) HAVING count(*) > 1) 
      AND  ($columnCollectionID || '-' ||  $columnUploadedFileID || '-' || $columnGeneratedID) NOT IN 
      (SELECT $columnCollectionID || '-' ||  $columnUploadedFileID || '-' || max($columnGeneratedID) 
      from $filesTable WHERE 
      $columnCollectionID is not NULL AND $columnUploadedFileID is NOT NULL 
      AND $columnCollectionID != -1 AND $columnUploadedFileID  != -1 GROUP BY 
      ($columnCollectionID || '-' || $columnUploadedFileID) HAVING count(*) > 1);
      ''',
      '''
      CREATE UNIQUE INDEX IF NOT EXISTS cid_uid ON $filesTable ($columnCollectionID, $columnUploadedFileID)
      WHERE $columnCollectionID is not NULL AND $columnUploadedFileID is not NULL
      AND $columnCollectionID != -1 AND $columnUploadedFileID  != -1;
      '''
    ];
  }

  static List<String> addPubMagicMetadataColumns() {
    return [
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnPubMMdEncodedJson TEXT DEFAULT '{}';
      ''',
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnPubMMdVersion INTEGER DEFAULT 0;
      '''
    ];
  }

  static List<String> createOnDeviceFilesAndPathCollection() {
    return [
      '''
        CREATE TABLE IF NOT EXISTS device_files (
          id TEXT NOT NULL,
          path_id TEXT NOT NULL,
          UNIQUE(id, path_id)
       );
       ''',
      '''
       CREATE TABLE IF NOT EXISTS device_collections (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT,
          modified_at INTEGER NOT NULL DEFAULT 0,
          should_backup INTEGER NOT NULL DEFAULT 0,
          count INTEGER NOT NULL DEFAULT 0,
          collection_id INTEGER DEFAULT -1,
          upload_strategy INTEGER DEFAULT 0,
          cover_id TEXT
      );
      ''',
      '''
      CREATE INDEX IF NOT EXISTS df_id_idx ON device_files (id);
      ''',
      '''
      CREATE INDEX IF NOT EXISTS df_path_id_idx ON device_files (path_id);
      ''',
    ];
  }

  static List<String> createEntityDataTable() {
    return [
      '''
       CREATE TABLE IF NOT EXISTS entities (
          id TEXT PRIMARY KEY NOT NULL,
          type TEXT NOT NULL,
          ownerID INTEGER NOT NULL,
          data TEXT NOT NULL DEFAULT '{}',
          updatedAt INTEGER NOT NULL
      );
      '''
    ];
  }

  static List<String> addFileSizeColumn() {
    return [
      '''
      ALTER TABLE $filesTable ADD COLUMN $columnFileSize INTEGER;
      ''',
    ];
  }

  static List<String> updateIndexes() {
    return [
      '''
      DROP INDEX IF EXISTS device_folder_index;
      ''',
      '''
      CREATE INDEX IF NOT EXISTS file_hash_index ON $filesTable($columnHash);
      ''',
    ];
  }

  static List<String> addAddedTime() {
    return [
      '''
        ALTER TABLE $filesTable ADD COLUMN $columnAddedTime INTEGER NOT NULL DEFAULT -1;
      ''',
      '''
        CREATE INDEX IF NOT EXISTS added_time_index ON $filesTable($columnAddedTime);
      '''
    ];
  }

  Future<void> clearTable() async {
    final db = await instance.sqliteAsyncDB;
    await db.execute('DELETE FROM $filesTable');
    await db.execute('DELETE FROM device_files');
    await db.execute('DELETE FROM device_collections');
    await db.execute('DELETE FROM entities');
  }

  Future<FileLoadResult> getAllPendingOrUploadedFiles(
    int startTime,
    int endTime,
    int ownerID, {
    int? limit,
    bool? asc,
    int visibility = visibleVisibility,
    DBFilterOptions? filterOptions,
    bool applyOwnerCheck = false,
  }) async {
    final stopWatch = EnteWatch('getAllPendingOrUploadedFiles')..start();
    final order = (asc ?? false ? 'ASC' : 'DESC');

    final subQueries = <String>[];
    late List<Object?>? args;
    if (applyOwnerCheck) {
      subQueries.add(
          'SELECT * FROM $filesTable WHERE $columnCreationTime >= ? AND $columnCreationTime <= ? '
          'AND ($columnOwnerID IS NULL OR $columnOwnerID = ?) '
          'AND ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)');
      args = [startTime, endTime, ownerID];
    } else {
      subQueries.add(
          'SELECT * FROM $filesTable WHERE $columnCreationTime >= ? AND $columnCreationTime <= ? '
          'AND ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)');
      args = [startTime, endTime];
    }

    subQueries.add(' AND $columnMMdVisibility = ?');
    args.add(visibility);

    if (filterOptions?.ignoreSharedItems ?? false) {
      subQueries.add(' AND $columnOwnerID = ?');
      args.add(ownerID);
    }

    subQueries.add(
      ' ORDER BY $columnCreationTime $order, $columnModificationTime $order',
    );

    if (limit != null) {
      subQueries.add(' LIMIT ?');
      args.add(limit);
    }

    final finalQuery = subQueries.join();

    final db = await instance.sqliteAsyncDB;
    final results = await db.getAll(finalQuery, args);
    stopWatch.log('queryDone');
    final files = convertToFiles(results);
    stopWatch.log('convertDone');
    final filteredFiles = await applyDBFilters(files, filterOptions);
    stopWatch.log('filteringDone');
    stopWatch.stop();
    return FileLoadResult(filteredFiles, files.length == limit);
  }

  Future<FileLoadResult> getAllLocalAndUploadedFiles(
    int startTime,
    int endTime,
    int ownerID, {
    int? limit,
    bool? asc,
    required DBFilterOptions filterOptions,
  }) async {
    final db = await instance.sqliteAsyncDB;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final args = [startTime, endTime, visibleVisibility];
    final subQueries = <String>[];

    subQueries.add(
        'SELECT * FROM $filesTable WHERE $columnCreationTime >= ? AND $columnCreationTime <= ?  AND ($columnMMdVisibility IS NULL OR $columnMMdVisibility = ?)'
        ' AND ($columnLocalID IS NOT NULL OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))');

    if (filterOptions.ignoreSharedItems) {
      subQueries.add(' AND $columnOwnerID = ?');
      args.add(ownerID);
    }

    subQueries.add(
      ' ORDER BY $columnCreationTime $order, $columnModificationTime $order',
    );

    if (limit != null) {
      subQueries.add(' LIMIT ?');
      args.add(limit);
    }

    final finalQuery = subQueries.join();

    final results = await db.getAll(
      finalQuery,
      args,
    );
    final files = convertToFiles(results);
    final List<EnteFile> filteredFiles =
        await applyDBFilters(files, filterOptions);
    return FileLoadResult(filteredFiles, files.length == limit);
  }

  // todo:rewrite (upload related)
  Future<void> markFilesForReUpload(
    int ownerID,
    String localID,
    String? title,
    Location? location,
    int creationTime,
    int modificationTime,
    FileType fileType,
  ) async {
    final db = await instance.sqliteAsyncDB;

    await db.execute(
      '''
      UPDATE $filesTable
      SET  $columnTitle = ?,
            $columnLatitude = ?,
            $columnLongitude = ?,
            $columnCreationTime = ?,
            $columnModificationTime = ?,
            $columnUpdationTime = NULL,
            $columnFileType = ?
      WHERE $columnLocalID = ? AND ($columnOwnerID = ? OR $columnOwnerID IS NULL);
    ''',
      [
        title,
        location?.latitude,
        location?.longitude,
        creationTime,
        modificationTime,
        getInt(fileType),
        localID,
        ownerID,
      ],
    );
  }

  Future<void> deleteLocalFile(EnteFile file) async {
    final db = await instance.sqliteAsyncDB;
    if (file.localID != null) {
      // delete all files with same local ID
      unawaited(
        db.execute(
          'DELETE FROM $filesTable WHERE $columnLocalID = ? AND ($columnUploadedFileID IS NULL OR $columnUploadedFileID = -1)',
          [file.localID],
        ),
      );
    } else {
      unawaited(
        db.execute(
          'DELETE FROM $filesTable WHERE $columnGeneratedID = ? AND ($columnUploadedFileID IS NULL OR $columnUploadedFileID = -1)',
          [file.generatedID],
        ),
      );
    }
  }

  List<EnteFile> convertToFiles(List<Map<String, dynamic>> results) {
    final List<EnteFile> files = [];
    for (final result in results) {
      files.add(_getFileFromRow(result));
    }
    return files;
  }

  EnteFile _getFileFromRow(Map<String, dynamic> row) {
    final file = EnteFile();
    file.generatedID = row[columnGeneratedID];
    file.localID = row[columnLocalID];
    // file.uploadedFileID =
    //     row[columnUploadedFileID] == -1 ? null : row[columnUploadedFileID];
    file.ownerID = row[columnOwnerID];
    file.collectionID =
        row[columnCollectionID] == -1 ? null : row[columnCollectionID];
    // file.title = row[columnTitle];
    file.deviceFolder = row[columnDeviceFolder];
    if (row[columnLatitude] != null && row[columnLongitude] != null) {
      file.location = Location(
        latitude: row[columnLatitude],
        longitude: row[columnLongitude],
      );
    }
    file.fileType = getFileType(row[columnFileType]);
    file.creationTime = row[columnCreationTime];
    file.modificationTime = row[columnModificationTime];
    file.updationTime = row[columnUpdationTime] ?? -1;
    // file.encryptedKey = row[columnEncryptedKey];
    // file.keyDecryptionNonce = row[columnKeyDecryptionNonce];
    // file.fileDecryptionHeader = row[columnFileDecryptionHeader];
    // file.thumbnailDecryptionHeader = row[columnThumbnailDecryptionHeader];
    file.fileSubType = row[columnFileSubType] ?? -1;
    file.duration = row[columnDuration] ?? 0;
    file.exif = row[columnExif];
    file.hash = row[columnHash];
    file.metadataVersion = row[columnMetadataVersion] ?? 0;
    // file.fileSize = row[columnFileSize];

    // file.mMdVersion = row[columnMMdVersion] ?? 0;
    // file.mMdEncodedJson = row[columnMMdEncodedJson] ?? '{}';

    //
    return file;
  }
}
