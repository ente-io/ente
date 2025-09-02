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
  List<EnteFile> deduplicateByLocalID(List<EnteFile> files) {
    final localIDs = <String>{};
    final List<EnteFile> deduplicatedFiles = [];
    for (final file in files) {
      final id = file.localID;
      if (id == null) {
        continue;
      }
      if (localIDs.contains(id)) {
        continue;
      }
      localIDs.add(id);
      deduplicatedFiles.add(file);
    }
    return deduplicatedFiles;
  }

  Future<FileLoadResult> getFilesInCollection(
    int collectionID,
    int startTime,
    int endTime, {
    int? limit,
    bool? asc,
    int visibility = visibleVisibility,
  }) async {
    final db = await instance.sqliteAsyncDB;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    String query =
        'SELECT * FROM $filesTable WHERE $columnCollectionID = ? AND $columnCreationTime >= ? AND $columnCreationTime <= ? ORDER BY $columnCreationTime $order, $columnModificationTime $order';
    final List<Object> args = [collectionID, startTime, endTime];
    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }
    final results = await db.getAll(
      query,
      args,
    );
    final files = convertToFiles(results);
    return FileLoadResult(files, files.length == limit);
  }

  Future<List<EnteFile>> getAllFilesCollection(int collectionID) async {
    final db = await instance.sqliteAsyncDB;
    const String whereClause = '$columnCollectionID = ?';
    final List<Object> whereArgs = [collectionID];
    final results = await db.getAll(
      'SELECT * FROM $filesTable WHERE $whereClause',
      whereArgs,
    );
    final files = convertToFiles(results);
    return files;
  }

  Future<List<EnteFile>> getAllFilesFromCollections(
    Iterable<int> collectionID,
  ) async {
    final db = await instance.sqliteAsyncDB;
    final String sql =
        'SELECT * FROM $filesTable WHERE $columnCollectionID IN (${collectionID.join(',')})';
    final results = await db.getAll(sql);
    final files = convertToFiles(results);
    return files;
  }

  Future<List<EnteFile>> getNewFilesInCollection(
    int collectionID,
    int addedTime,
  ) async {
    final db = await instance.sqliteAsyncDB;
    const String whereClause =
        '$columnCollectionID = ? AND $columnAddedTime > ?';
    final List<Object> whereArgs = [collectionID, addedTime];
    final results = await db.getAll(
      'SELECT * FROM $filesTable WHERE $whereClause',
      whereArgs,
    );
    final files = convertToFiles(results);
    return files;
  }

  Future<FileLoadResult> getFilesInCollections(
    List<int> collectionIDs,
    int startTime,
    int endTime,
    int userID, {
    int? limit,
    bool? asc,
  }) async {
    if (collectionIDs.isEmpty) {
      return FileLoadResult(<EnteFile>[], false);
    }
    final inParam = collectionIDs.map((id) => "'$id'").join(',');

    final db = await instance.sqliteAsyncDB;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final String whereClause =
        '$columnCollectionID  IN ($inParam) AND $columnCreationTime >= ? AND '
        '$columnCreationTime <= ? AND $columnOwnerID = ?';
    final List<Object> whereArgs = [startTime, endTime, userID];

    String query = 'SELECT * FROM $filesTable WHERE $whereClause ORDER BY '
        '$columnCreationTime $order, $columnModificationTime $order';
    if (limit != null) {
      query += ' LIMIT ?';
      whereArgs.add(limit);
    }
    final results = await db.getAll(
      query,
      whereArgs,
    );
    final files = convertToFiles(results);
    final dedupeResult =
        await applyDBFilters(files, DBFilterOptions.dedupeOption);
    _logger.info("Fetched " + dedupeResult.length.toString() + " files");
    return FileLoadResult(files, files.length == limit);
  }

  Future<List<EnteFile>> getFilesCreatedWithinDurations(
    List<List<int>> durations,
    Set<int> ignoredCollectionIDs, {
    int? visibility,
    String order = 'ASC',
  }) async {
    if (durations.isEmpty) {
      return <EnteFile>[];
    }
    final db = await instance.sqliteAsyncDB;
    String whereClause = durations
        .map(
          (duration) =>
              "($columnCreationTime >= ${duration[0]} AND $columnCreationTime < ${duration[1]})",
        )
        .join(" OR ");

    whereClause = "( $whereClause )";
    if (visibility != null) {
      whereClause += ' AND $columnMMdVisibility = $visibility';
    }
    final query =
        'SELECT * FROM $filesTable WHERE $whereClause ORDER BY $columnCreationTime $order';
    final results = await db.getAll(
      query,
    );
    final files = convertToFiles(results);
    return applyDBFilters(
      files,
      DBFilterOptions(ignoredCollectionIDs: ignoredCollectionIDs),
    );
  }

  // Files which user added to a collection manually but they are not
  // uploaded yet or files belonging to a collection which is marked for backup
  Future<List<EnteFile>> getFilesPendingForUpload() async {
    final db = await instance.sqliteAsyncDB;
    final results = await db.getAll(
      'SELECT * FROM $filesTable WHERE ($columnUploadedFileID IS NULL OR '
      '$columnUploadedFileID IS -1) AND $columnCollectionID IS NOT NULL AND '
      '$columnCollectionID IS NOT -1 AND $columnLocalID IS NOT NULL AND '
      '$columnLocalID IS NOT -1 GROUP BY $columnLocalID '
      'ORDER BY $columnCreationTime DESC',
    );
    final files = convertToFiles(results);
    // future-safe filter just to ensure that the query doesn't end up  returning files
    // which should not be backed up
    files.removeWhere(
      (e) =>
          e.collectionID == null ||
          e.localID == null ||
          e.uploadedFileID != null,
    );
    return files;
  }

  Future<List<EnteFile>> getUnUploadedLocalFiles() async {
    final db = await instance.sqliteAsyncDB;
    final results = await db.getAll(
      'SELECT * FROM $filesTable WHERE ($columnUploadedFileID IS NULL OR '
      '$columnUploadedFileID IS -1) AND $columnLocalID IS NOT NULL '
      'GROUP BY $columnLocalID ORDER BY $columnCreationTime DESC',
    );
    return convertToFiles(results);
  }

  Future<List<int>> getUploadedFileIDsToBeUpdated(int ownerID) async {
    final db = await instance.sqliteAsyncDB;
    final rows = await db.getAll(
      'SELECT DISTINCT $columnUploadedFileID FROM $filesTable WHERE '
      '($columnLocalID IS NOT NULL AND $columnOwnerID = ? AND '
      '($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1) '
      'AND $columnUpdationTime IS NULL) ORDER BY $columnCreationTime DESC ',
      [ownerID],
    );
    final uploadedFileIDs = <int>[];
    for (final row in rows) {
      uploadedFileIDs.add(row[columnUploadedFileID] as int);
    }
    return uploadedFileIDs;
  }

  Future<List<EnteFile>> getFilesInAllCollection(
    int uploadedFileID,
    int userID,
  ) async {
    final db = await instance.sqliteAsyncDB;
    final results = await db.getAll(
      'SELECT * FROM $filesTable WHERE $columnLocalID IS NOT NULL AND '
      '$columnOwnerID = ? AND $columnUploadedFileID = ?',
      [userID, uploadedFileID],
    );
    if (results.isEmpty) {
      return <EnteFile>[];
    }
    return convertToFiles(results);
  }

  Future<Set<String>> getExistingLocalFileIDs(int ownerID) async {
    final db = await instance.sqliteAsyncDB;
    final rows = await db.getAll(
      'SELECT DISTINCT $columnLocalID FROM $filesTable '
      'WHERE $columnLocalID IS NOT NULL AND ($columnOwnerID IS NULL OR '
      '$columnOwnerID = ?)',
      [ownerID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  Future<Set<String>> getLocalIDsMarkedForOrAlreadyUploaded(int ownerID) async {
    final db = await instance.sqliteAsyncDB;
    final rows = await db.getAll(
      'SELECT DISTINCT $columnLocalID FROM $filesTable '
      'WHERE $columnLocalID IS NOT NULL AND ($columnCollectionID IS NOT NULL '
      'AND $columnCollectionID != -1) AND ($columnOwnerID = ? OR '
      '$columnOwnerID IS NULL)',
      [ownerID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  // remove references for local files which are either already uploaded
  // or queued for upload but not yet uploaded
// Remove queued local files that have duplicate uploaded entries with same localID
  Future<int> removeQueuedLocalFiles(Set<String> localIDs, int ownerID) async {
    if (localIDs.isEmpty) {
      _logger.finest("No local IDs provided for removal");
      return 0;
    }

    final db = await instance.sqliteAsyncDB;
    const batchSize = 10000;
    int totalRemoved = 0;
    final localIDsList = localIDs.toList();

    for (int i = 0; i < localIDsList.length; i += batchSize) {
      final endIndex = (i + batchSize > localIDsList.length)
          ? localIDsList.length
          : i + batchSize;
      final batch = localIDsList.sublist(i, endIndex);
      final placeholders = List.filled(batch.length, '?').join(',');

      // Find localIDs that already have uploaded entries
      final result = await db.execute(
        '''
      SELECT DISTINCT $columnLocalID
      FROM $filesTable
      WHERE 
      $columnOwnerID = $ownerID
      AND $columnLocalID IN ($placeholders)
      AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID != -1)
    ''',
        batch,
      );

      if (result.isNotEmpty) {
        final alreadyUploadedLocalIDs =
            result.map((row) => row[columnLocalID] as String).toList();
        final localIdPlaceholder =
            List.filled(alreadyUploadedLocalIDs.length, '?').join(',');

        // Delete queued entries for localIDs that already have uploaded versions
        final deleteResult = await db.execute(
          '''
        DELETE FROM $filesTable
        WHERE $columnLocalID IN ($localIdPlaceholder)
        AND ($columnUploadedFileID IS NULL OR $columnUploadedFileID = -1)
      ''',
          alreadyUploadedLocalIDs,
        );

        final removedCount =
            deleteResult.length; // or however your DB returns affected rows
        if (removedCount > 0) {
          _logger.warning(
            "Batch ${(i ~/ batchSize) + 1}: Removed $removedCount queued duplicates",
          );
          totalRemoved += removedCount;
        }
      }
    }

    if (totalRemoved > 0) {
      _logger.warning(
        "Removed $totalRemoved queued files that had uploaded duplicates",
      );
    } else {
      _logger.finest("No queued duplicates found for uploaded files");
    }

    return totalRemoved;
  }

  Future<Set<String>> getLocalFileIDsForCollection(int collectionID) async {
    final db = await instance.sqliteAsyncDB;
    final rows = await db.getAll(
      'SELECT $columnLocalID FROM $filesTable '
      'WHERE $columnLocalID IS NOT NULL AND $columnCollectionID = ?',
      [collectionID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  // Sets the collectionID for the files with given LocalIDs if the
  // corresponding file entries are not already mapped to some other collection
  Future<void> setCollectionIDForUnMappedLocalFiles(
    int collectionID,
    Set<String> localIDs,
  ) async {
    final db = await instance.sqliteAsyncDB;
    final inParam = localIDs.map((id) => "'$id'").join(',');
    await db.execute(
      '''
      UPDATE $filesTable
      SET $columnCollectionID = $collectionID
      WHERE $columnLocalID IN ($inParam) AND ($columnCollectionID IS NULL OR 
      $columnCollectionID = -1);
    ''',
    );
  }

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
    // file.uploadedFileID =
    //     row[columnUploadedFileID] == -1 ? null : row[columnUploadedFileID];
    file.ownerID = row[columnOwnerID];
    // file.collectionID =
    //     row[columnCollectionID] == -1 ? null : row[columnCollectionID];
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
    // file.updationTime = row[columnUpdationTime] ?? -1;
    // file.encryptedKey = row[columnEncryptedKey];
    // file.keyDecryptionNonce = row[columnKeyDecryptionNonce];
    // file.fileDecryptionHeader = row[columnFileDecryptionHeader];
    // file.thumbnailDecryptionHeader = row[columnThumbnailDecryptionHeader];
    // file.fileSubType = row[columnFileSubType] ?? -1;
    // file.exif = row[columnExif];
    // file.hash = row[columnHash];
    // file.metadataVersion = row[columnMetadataVersion] ?? 0;
    // file.fileSize = row[columnFileSize];

    // file.mMdVersion = row[columnMMdVersion] ?? 0;
    // file.mMdEncodedJson = row[columnMMdEncodedJson] ?? '{}';

    //
    return file;
  }
}
