import "dart:io";

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import "package:photos/extensions/stop_watch.dart";
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/location/location.dart';
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/services/filter/db_filters.dart";
import 'package:photos/utils/file_uploader_util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class FilesDB {
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

  static final initializationScript = [
    ...createTable(filesTable),
  ];
  static final migrationScripts = [
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

  final dbConfig = MigrationConfig(
    initializationScript: initializationScript,
    migrationScripts: migrationScripts,
  );

  // make this a singleton class
  FilesDB._privateConstructor();

  static final FilesDB instance = FilesDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<Database>? _dbFuture;
  static Future<sqlite3.Database>? _ffiDBFuture;

  Future<Database> get database async {
    // lazily instantiate the db the first time it is accessed
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<sqlite3.Database> get ffiDB async {
    _ffiDBFuture ??= _initFFIDatabase();
    return _ffiDBFuture!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path " + path);
    return await openDatabaseWithMigration(path, dbConfig);
  }

  Future<sqlite3.Database> _initFFIDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path " + path);
    return sqlite3.sqlite3.open(path);
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
    final db = await instance.database;
    await db.delete(filesTable);
    await db.delete("device_files");
    await db.delete("device_collections");
    await db.delete("entities");
  }

  Future<void> deleteDB() async {
    if (kDebugMode) {
      debugPrint("Deleting files db");
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, _databaseName);
      File(path).deleteSync(recursive: true);
      _dbFuture = null;
    }
  }

  Future<void> insertMultiple(
    List<EnteFile> files, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final startTime = DateTime.now();
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (EnteFile file in files) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        filesTable,
        _getRowForFile(file),
        conflictAlgorithm: conflictAlgorithm,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
    final endTime = DateTime.now();
    final duration = Duration(
      microseconds:
          endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch,
    );
    _logger.info(
      "Batch insert of " +
          files.length.toString() +
          " took " +
          duration.inMilliseconds.toString() +
          "ms.",
    );
  }

  Future<int> insert(EnteFile file) async {
    final db = await instance.database;
    return db.insert(
      filesTable,
      _getRowForFile(file),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EnteFile?> getFile(int generatedID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnGeneratedID = ?',
      whereArgs: [generatedID],
    );
    if (results.isEmpty) {
      return null;
    }
    return convertToFiles(results)[0];
  }

  Future<EnteFile?> getUploadedFile(int uploadedID, int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [
        uploadedID,
        collectionID,
      ],
    );
    if (results.isEmpty) {
      return null;
    }
    return convertToFiles(results)[0];
  }

  Future<EnteFile?> getAnyUploadedFile(int uploadedID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID = ?',
      whereArgs: [
        uploadedID,
      ],
    );
    if (results.isEmpty) {
      return null;
    }
    return convertToFiles(results)[0];
  }

  Future<Set<int>> getUploadedFileIDs(int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      columns: [columnUploadedFileID],
      where:
          '$columnCollectionID = ? AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1)',
      whereArgs: [
        collectionID,
      ],
    );
    final ids = <int>{};
    for (final result in results) {
      ids.add(result[columnUploadedFileID] as int);
    }
    return ids;
  }

  Future<BackedUpFileIDs> getBackedUpIDs() async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      columns: [columnLocalID, columnUploadedFileID, columnFileSize],
      where:
          '$columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1)',
    );
    final Set<String> localIDs = <String>{};
    final Set<int> uploadedIDs = <int>{};
    int localSize = 0;
    for (final result in results) {
      final String localID = result[columnLocalID] as String;
      final int? fileSize = result[columnFileSize] as int?;
      if (!localIDs.contains(localID) && fileSize != null) {
        localSize += fileSize;
      }
      localIDs.add(result[columnLocalID] as String);
      uploadedIDs.add(result[columnUploadedFileID] as int);
    }
    return BackedUpFileIDs(localIDs.toList(), uploadedIDs.toList(), localSize);
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
    late String whereQuery;
    late List<Object?>? whereArgs;
    if (applyOwnerCheck) {
      whereQuery = '$columnCreationTime >= ? AND $columnCreationTime <= ? '
          'AND ($columnOwnerID IS NULL OR $columnOwnerID = ?) '
          'AND ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)'
          ' AND $columnMMdVisibility = ?';
      whereArgs = [startTime, endTime, ownerID, visibility];
    } else {
      whereQuery =
          '$columnCreationTime >= ? AND $columnCreationTime <= ? AND ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)'
          ' AND $columnMMdVisibility = ?';
      whereArgs = [startTime, endTime, visibility];
    }

    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      filesTable,
      where: whereQuery,
      whereArgs: whereArgs,
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
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
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      filesTable,
      where:
          '$columnCreationTime >= ? AND $columnCreationTime <= ?  AND ($columnMMdVisibility IS NULL OR $columnMMdVisibility = ?)'
          ' AND ($columnLocalID IS NOT NULL OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))',
      whereArgs: [startTime, endTime, visibleVisibility],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = convertToFiles(results);
    final List<EnteFile> filteredFiles =
        await applyDBFilters(files, filterOptions);
    return FileLoadResult(filteredFiles, files.length == limit);
  }

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
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    const String whereClause =
        '$columnCollectionID = ? AND $columnCreationTime >= ? AND $columnCreationTime <= ?';
    final List<Object> whereArgs = [collectionID, startTime, endTime];

    final results = await db.query(
      filesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = convertToFiles(results);
    return FileLoadResult(files, files.length == limit);
  }

  Future<List<EnteFile>> getAllFilesCollection(int collectionID) async {
    final db = await instance.database;
    const String whereClause = '$columnCollectionID = ?';
    final List<Object> whereArgs = [collectionID];
    final results = await db.query(
      filesTable,
      where: whereClause,
      whereArgs: whereArgs,
    );
    final files = convertToFiles(results);
    return files;
  }

  Future<List<EnteFile>> getNewFilesInCollection(
    int collectionID,
    int addedTime,
  ) async {
    final db = await instance.database;
    const String whereClause =
        '$columnCollectionID = ? AND $columnAddedTime > ?';
    final List<Object> whereArgs = [collectionID, addedTime];
    final results = await db.query(
      filesTable,
      where: whereClause,
      whereArgs: whereArgs,
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
    String inParam = "";
    for (final id in collectionIDs) {
      inParam += "'" + id.toString() + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final String whereClause =
        '$columnCollectionID  IN ($inParam) AND $columnCreationTime >= ? AND '
        '$columnCreationTime <= ? AND $columnOwnerID = ?';
    final List<Object> whereArgs = [startTime, endTime, userID];

    final results = await db.query(
      filesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
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
    final db = await instance.database;
    String whereClause = "( ";
    for (int index = 0; index < durations.length; index++) {
      whereClause += "($columnCreationTime >= " +
          durations[index][0].toString() +
          " AND $columnCreationTime < " +
          durations[index][1].toString() +
          ")";
      if (index != durations.length - 1) {
        whereClause += " OR ";
      } else if (visibility != null) {
        whereClause += ' AND $columnMMdVisibility = $visibility';
      }
    }
    whereClause += ")";
    final results = await db.query(
      filesTable,
      where: whereClause,
      orderBy: '$columnCreationTime ' + order,
    );
    final files = convertToFiles(results);
    return applyDBFilters(
      files,
      DBFilterOptions(ignoredCollectionIDs: ignoredCollectionIDs),
    );
  }

  Future<List<EnteFile>> getFilesCreatedWithinDurationsSync(
    List<List<int>> durations,
    Set<int> ignoredCollectionIDs, {
    int? visibility,
    String order = 'ASC',
  }) async {
    if (durations.isEmpty) {
      return <EnteFile>[];
    }
    final db = await instance.ffiDB;
    String whereClause = "( ";
    for (int index = 0; index < durations.length; index++) {
      whereClause += "($columnCreationTime >= " +
          durations[index][0].toString() +
          " AND $columnCreationTime < " +
          durations[index][1].toString() +
          ")";
      if (index != durations.length - 1) {
        whereClause += " OR ";
      } else if (visibility != null) {
        whereClause += ' AND $columnMMdVisibility = $visibility';
      }
    }
    whereClause += ")";
    final results = db.select(
      'select * from $filesTable where $whereClause order by $columnCreationTime $order',
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
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where:
          '($columnUploadedFileID IS NULL OR $columnUploadedFileID IS -1) AND '
          '$columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1 AND '
          '$columnLocalID IS NOT NULL AND $columnLocalID IS NOT -1',
      orderBy: '$columnCreationTime DESC',
      groupBy: columnLocalID,
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
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where:
          '($columnUploadedFileID IS NULL OR $columnUploadedFileID IS -1) AND $columnLocalID IS NOT NULL',
      orderBy: '$columnCreationTime DESC',
      groupBy: columnLocalID,
    );
    return convertToFiles(results);
  }

  Future<List<int>> getUploadedFileIDsToBeUpdated(int ownerID) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnUploadedFileID],
      where: '($columnLocalID IS NOT NULL AND $columnOwnerID = ? AND '
          '($columnUploadedFileID '
          'IS NOT '
          'NULL AND $columnUploadedFileID IS NOT -1) AND $columnUpdationTime IS NULL)',
      whereArgs: [ownerID],
      orderBy: '$columnCreationTime DESC',
      distinct: true,
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
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnLocalID IS NOT NULL AND $columnOwnerID = ? AND '
          '$columnUploadedFileID = ?',
      whereArgs: [
        userID,
        uploadedFileID,
      ],
    );
    if (results.isEmpty) {
      return <EnteFile>[];
    }
    return convertToFiles(results);
  }

  Future<Set<String>> getExistingLocalFileIDs(int ownerID) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      distinct: true,
      where: '$columnLocalID IS NOT NULL AND ($columnOwnerID IS NULL OR '
          '$columnOwnerID = ?)',
      whereArgs: [ownerID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  Future<Set<String>> getLocalIDsMarkedForOrAlreadyUploaded(int ownerID) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      distinct: true,
      where: '$columnLocalID IS NOT NULL AND ($columnCollectionID IS NOT NULL '
          'AND '
          '$columnCollectionID != -1) AND ($columnOwnerID = ? OR '
          '$columnOwnerID IS NULL)',
      whereArgs: [ownerID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  Future<Set<String>> getLocalFileIDsForCollection(int collectionID) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      where: '$columnLocalID IS NOT NULL AND $columnCollectionID = ?',
      whereArgs: [collectionID],
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  // Sets the collectionID for the files with given LocalIDs if the
  // corresponding file entries are not already mapped to some other collection
  Future<int> setCollectionIDForUnMappedLocalFiles(
    int collectionID,
    Set<String> localIDs,
  ) async {
    final db = await instance.database;
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    return await db.rawUpdate(
      '''
      UPDATE $filesTable
      SET $columnCollectionID = $collectionID
      WHERE $columnLocalID IN ($inParam) AND ($columnCollectionID IS NULL OR 
      $columnCollectionID = -1);
    ''',
    );
  }

  Future<int> markFilesForReUpload(
    int ownerID,
    String localID,
    String? title,
    Location? location,
    int creationTime,
    int modificationTime,
    FileType fileType,
  ) async {
    final db = await instance.database;
    return await db.update(
      filesTable,
      {
        columnTitle: title,
        columnLatitude: location?.latitude,
        columnLongitude: location?.longitude,
        columnCreationTime: creationTime,
        columnModificationTime: modificationTime,
        // #hack reset updation time to null for re-upload
        columnUpdationTime: null,
        columnFileType: getInt(fileType),
      },
      where:
          '$columnLocalID = ? AND ($columnOwnerID = ? OR $columnOwnerID IS NULL)',
      whereArgs: [localID, ownerID],
    );
  }

  /*
    This method should only return localIDs which are not uploaded yet
    and can be mapped to incoming remote entry
   */
  Future<List<EnteFile>> getUnlinkedLocalMatchesForRemoteFile(
    int ownerID,
    String localID,
    FileType fileType, {
    required String title,
    required String deviceFolder,
  }) async {
    final db = await instance.database;
    // on iOS, match using localID and fileType. title can either match or
    // might be null based on how the file was imported
    String whereClause = ''' ($columnOwnerID = ? OR $columnOwnerID IS NULL) AND 
        $columnLocalID = ? AND $columnFileType = ? AND
        ($columnTitle=? OR $columnTitle IS NULL) ''';
    List<Object> whereArgs = [
      ownerID,
      localID,
      getInt(fileType),
      title,
    ];
    if (Platform.isAndroid) {
      whereClause = ''' ($columnOwnerID = ? OR $columnOwnerID IS NULL) AND 
          $columnLocalID = ? AND $columnFileType = ? AND $columnTitle=? AND $columnDeviceFolder= ? 
           ''';
      whereArgs = [
        ownerID,
        localID,
        getInt(fileType),
        title,
        deviceFolder,
      ];
    }

    final rows = await db.query(
      filesTable,
      where: whereClause,
      whereArgs: whereArgs,
    );

    return convertToFiles(rows);
  }

  Future<List<EnteFile>> getUploadedFilesWithHashes(
    FileHashData hashData,
    FileType fileType,
    int ownerID,
  ) async {
    String inParam = "'${hashData.fileHash}'";
    if (fileType == FileType.livePhoto && hashData.zipHash != null) {
      inParam += ",'${hashData.zipHash}'";
    }
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      where: '($columnUploadedFileID != NULL OR $columnUploadedFileID != -1) '
          'AND $columnOwnerID = ? AND $columnFileType ='
          ' ? '
          'AND $columnHash IN ($inParam)',
      whereArgs: [
        ownerID,
        getInt(fileType),
      ],
    );
    return convertToFiles(rows);
  }

  Future<int> update(EnteFile file) async {
    final db = await instance.database;
    return await db.update(
      filesTable,
      _getRowForFile(file),
      where: '$columnGeneratedID = ?',
      whereArgs: [file.generatedID],
    );
  }

  Future<int> updateUploadedFileAcrossCollections(EnteFile file) async {
    final db = await instance.database;
    return await db.update(
      filesTable,
      _getRowForFileWithoutCollection(file),
      where: '$columnUploadedFileID = ?',
      whereArgs: [file.uploadedFileID],
    );
  }

  Future<int> updateLocalIDForUploaded(int uploadedID, String localID) async {
    final db = await instance.database;
    return await db.update(
      filesTable,
      {columnLocalID: localID},
      where: '$columnUploadedFileID = ? AND $columnLocalID IS NULL',
      whereArgs: [uploadedID],
    );
  }

  Future<int> delete(int uploadedFileID) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where: '$columnUploadedFileID =?',
      whereArgs: [uploadedFileID],
    );
  }

  Future<int> deleteByGeneratedID(int genID) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where: '$columnGeneratedID =?',
      whereArgs: [genID],
    );
  }

  Future<int> deleteMultipleUploadedFiles(List<int> uploadedFileIDs) async {
    final db = await instance.database;
    return await db.delete(
      filesTable,
      where: '$columnUploadedFileID IN (${uploadedFileIDs.join(', ')})',
    );
  }

  Future<int> deleteMultipleByGeneratedIDs(List<int> generatedIDs) async {
    if (generatedIDs.isEmpty) {
      return 0;
    }
    final db = await instance.database;
    return await db.delete(
      filesTable,
      where: '$columnGeneratedID IN (${generatedIDs.join(', ')})',
    );
  }

  Future<int> deleteLocalFile(EnteFile file) async {
    final db = await instance.database;
    if (file.localID != null) {
      // delete all files with same local ID
      return db.delete(
        filesTable,
        where: '$columnLocalID =?',
        whereArgs: [file.localID],
      );
    } else {
      return db.delete(
        filesTable,
        where: '$columnGeneratedID =?',
        whereArgs: [file.generatedID],
      );
    }
  }

  Future<void> deleteLocalFiles(List<String> localIDs) async {
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    await db.rawQuery(
      '''
      UPDATE $filesTable
      SET $columnLocalID = NULL
      WHERE $columnLocalID IN ($inParam);
    ''',
    );
  }

  Future<List<EnteFile>> getLocalFiles(List<String> localIDs) async {
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnLocalID IN ($inParam)',
    );
    return convertToFiles(results);
  }

  Future<int> deleteUnSyncedLocalFiles(List<String> localIDs) async {
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    return db.delete(
      filesTable,
      where:
          '($columnUploadedFileID is NULL OR $columnUploadedFileID = -1 ) AND $columnLocalID IN ($inParam)',
    );
  }

  Future<int> deleteFromCollection(int uploadedFileID, int collectionID) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [uploadedFileID, collectionID],
    );
  }

  Future<int> deleteFilesFromCollection(
    int collectionID,
    List<int> uploadedFileIDs,
  ) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where:
          '$columnCollectionID = ? AND $columnUploadedFileID IN (${uploadedFileIDs.join(', ')})',
      whereArgs: [collectionID],
    );
  }

  Future<int> collectionFileCount(int collectionID) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $filesTable where $columnCollectionID = '
        '$collectionID AND $columnUploadedFileID IS NOT -1',
      ),
    );
    return count ?? 0;
  }

  Future<int> archivedFilesCount(
    int visibility,
    int ownerID,
    Set<int> hiddenCollections,
  ) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(distinct($columnUploadedFileID)) FROM $filesTable where '
        '$columnMMdVisibility'
        ' = $visibility AND $columnOwnerID = $ownerID AND $columnCollectionID NOT IN (${hiddenCollections.join(', ')})',
      ),
    );
    return count ?? 0;
  }

  Future<int> deleteCollection(int collectionID) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where: '$columnCollectionID = ?',
      whereArgs: [collectionID],
    );
  }

  Future<int> removeFromCollection(int collectionID, List<int> fileIDs) async {
    final db = await instance.database;
    return db.delete(
      filesTable,
      where:
          '$columnCollectionID =? AND $columnUploadedFileID IN (${fileIDs.join(', ')})',
      whereArgs: [collectionID],
    );
  }

  Future<List<EnteFile>> getPendingUploadForCollection(int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnCollectionID = ? AND ($columnUploadedFileID IS NULL OR '
          '$columnUploadedFileID = -1)',
      whereArgs: [collectionID],
    );
    return convertToFiles(results);
  }

  Future<Set<String>> getLocalIDsPresentInEntries(
    List<EnteFile> existingFiles,
    int collectionID,
  ) async {
    String inParam = "";
    for (final existingFile in existingFiles) {
      if (existingFile.localID != null) {
        inParam += "'" + existingFile.localID! + "',";
      }
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT $columnLocalID
      FROM $filesTable
      WHERE $columnLocalID IN ($inParam) AND $columnCollectionID != 
      $collectionID AND $columnLocalID IS NOT NULL;
    ''',
    );
    final result = <String>{};
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  // getCollectionLatestFileTime returns map of collectionID to the max
  // creationTime of the files in the collection.
  Future<Map<int, int>> getCollectionIDToMaxCreationTime() async {
    final enteWatch = EnteWatch("getCollectionIDToMaxCreationTime")..start();
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT $columnCollectionID, MAX($columnCreationTime) AS max_creation_time
      FROM $filesTable
      WHERE 
      ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1
       AND $columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS 
       NOT -1)
      GROUP BY $columnCollectionID;
    ''',
    );
    final result = <int, int>{};
    for (final row in rows) {
      result[row[columnCollectionID] as int] = row['max_creation_time'] as int;
    }
    enteWatch.log("query done");
    return result;
  }

  // getCollectionFileFirstOrLast returns the first or last uploaded file in
  // the collection based on the given collectionID and the order.
  Future<EnteFile?> getCollectionFileFirstOrLast(
    int collectionID,
    bool sortAsc,
  ) async {
    final db = await instance.database;
    final order = sortAsc ? 'ASC' : 'DESC';
    final rows = await db.query(
      filesTable,
      where: '$columnCollectionID = ? AND ($columnUploadedFileID IS NOT NULL '
          'AND $columnUploadedFileID IS NOT -1)',
      whereArgs: [collectionID],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return convertToFiles(rows).first;
  }

  Future<void> markForReUploadIfLocationMissing(List<String> localIDs) async {
    if (localIDs.isEmpty) {
      return;
    }
    String inParam = "";
    for (final localID in localIDs) {
      inParam += "'" + localID + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    await db.rawUpdate(
      '''
      UPDATE $filesTable
      SET $columnUpdationTime = NULL
      WHERE $columnLocalID IN ($inParam)
      AND ($columnLatitude IS NULL OR $columnLongitude IS NULL OR $columnLongitude = 0.0 or $columnLongitude = 0.0);
    ''',
    );
  }

  Future<bool> doesFileExistInCollection(
    int uploadedFileID,
    int collectionID,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [uploadedFileID, collectionID],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Map<int, EnteFile>> getFilesFromIDs(List<int> ids) async {
    final result = <int, EnteFile>{};
    if (ids.isEmpty) {
      return result;
    }
    String inParam = "";
    for (final id in ids) {
      inParam += "'" + id.toString() + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID IN ($inParam)',
    );
    final files = convertToFiles(results);
    for (final file in files) {
      result[file.uploadedFileID!] = file;
    }
    return result;
  }

  Future<Map<int, EnteFile>> getFilesFromGeneratedIDs(List<int> ids) async {
    final result = <int, EnteFile>{};
    if (ids.isEmpty) {
      return result;
    }
    String inParam = "";
    for (final id in ids) {
      inParam += "'" + id.toString() + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnGeneratedID IN ($inParam)',
    );
    final files = convertToFiles(results);
    for (final file in files) {
      result[file.generatedID as int] = file;
    }
    return result;
  }

  Future<Map<int, List<EnteFile>>> getAllFilesGroupByCollectionID(
    List<int> ids,
  ) async {
    final result = <int, List<EnteFile>>{};
    if (ids.isEmpty) {
      return result;
    }
    String inParam = "";
    for (final id in ids) {
      inParam += "'" + id.toString() + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID IN ($inParam)',
    );
    final files = convertToFiles(results);
    for (EnteFile eachFile in files) {
      if (!result.containsKey(eachFile.collectionID)) {
        result[eachFile.collectionID as int] = <EnteFile>[];
      }
      result[eachFile.collectionID]!.add(eachFile);
    }
    return result;
  }

  Future<Set<int>> getAllCollectionIDsOfFile(
    int uploadedFileID,
  ) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID = ? AND $columnCollectionID != -1',
      columns: [columnCollectionID],
      whereArgs: [uploadedFileID],
      distinct: true,
    );
    final collectionIDsOfFile = <int>{};
    for (var result in results) {
      collectionIDsOfFile.add(result['collection_id'] as int);
    }
    return collectionIDsOfFile;
  }

  List<EnteFile> convertToFiles(List<Map<String, dynamic>> results) {
    final List<EnteFile> files = [];
    for (final result in results) {
      files.add(_getFileFromRow(result));
    }
    return files;
  }

  Future<List<String>> getGeneratedIDForFilesOlderThan(
    int cutOffTime,
    int ownerID,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnGeneratedID],
      distinct: true,
      where:
          '$columnCreationTime <= ? AND  ($columnOwnerID IS NULL OR $columnOwnerID = ?)',
      whereArgs: [cutOffTime, ownerID],
    );
    final result = <String>[];
    for (final row in rows) {
      result.add(row[columnGeneratedID].toString());
    }
    return result;
  }

  // For givenUserID, get List of unique LocalIDs for files which are
  // uploaded by the given user and location is missing
  Future<List<String>> getLocalIDsForFilesWithoutLocation(int ownerID) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      distinct: true,
      where: '$columnOwnerID = ? AND $columnLocalID IS NOT NULL AND '
          '($columnLatitude IS NULL OR '
          '$columnLongitude IS NULL OR $columnLongitude = 0.0 or $columnLongitude = 0.0)',
      whereArgs: [ownerID],
    );
    final result = <String>[];
    for (final row in rows) {
      result.add(row[columnLocalID].toString());
    }
    return result;
  }

  // For a given userID, return unique uploadedFileId for the given userID
  Future<List<int>> getUploadIDsWithMissingSize(int userId) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnUploadedFileID],
      distinct: true,
      where: '$columnOwnerID = ? AND $columnFileSize IS NULL',
      whereArgs: [userId],
    );
    final result = <int>[];
    for (final row in rows) {
      result.add(row[columnUploadedFileID] as int);
    }
    return result;
  }

  // For a given userID, return unique localID for all uploaded live photos
  Future<List<String>> getLivePhotosForUser(int userId) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      distinct: true,
      where: '$columnOwnerID = ? AND '
          '$columnFileType = ? AND $columnLocalID IS NOT NULL',
      whereArgs: [userId, getInt(FileType.livePhoto)],
    );
    final result = <String>[];
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  Future<List<String>> getLocalFilesBackedUpWithoutLocation(int userId) async {
    final db = await instance.database;
    final rows = await db.query(
      filesTable,
      columns: [columnLocalID],
      distinct: true,
      where:
          '$columnOwnerID = ? AND $columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1) '
          'AND ($columnLatitude IS NULL OR $columnLongitude IS NULL OR $columnLongitude = 0.0 or $columnLongitude = 0.0)',
      whereArgs: [userId],
    );
    final result = <String>[];
    for (final row in rows) {
      result.add(row[columnLocalID] as String);
    }
    return result;
  }

  // updateSizeForUploadIDs takes a map of upploadedFileID and fileSize and
  // update the fileSize for the given uploadedFileID
  Future<void> updateSizeForUploadIDs(
    Map<int, int> uploadedFileIDToSize,
  ) async {
    if (uploadedFileIDToSize.isEmpty) {
      return;
    }
    final db = await instance.database;
    final batch = db.batch();
    for (final uploadedFileID in uploadedFileIDToSize.keys) {
      batch.update(
        filesTable,
        {columnFileSize: uploadedFileIDToSize[uploadedFileID]},
        where: '$columnUploadedFileID = ?',
        whereArgs: [uploadedFileID],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<EnteFile>> getAllFilesFromDB(
    Set<int> collectionsToIgnore, {
    bool dedupeByUploadId = true,
  }) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result =
        await db.query(filesTable, orderBy: '$columnCreationTime DESC');
    final List<EnteFile> files = convertToFiles(result);
    final List<EnteFile> deduplicatedFiles = await applyDBFilters(
      files,
      DBFilterOptions(
        ignoredCollectionIDs: collectionsToIgnore,
        dedupeUploadID: dedupeByUploadId,
      ),
    );
    return deduplicatedFiles;
  }

  Future<Map<FileType, int>> fetchFilesCountbyType(int userID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT $columnFileType, COUNT(DISTINCT $columnUploadedFileID) FROM $filesTable WHERE $columnUploadedFileID != -1 AND $columnOwnerID == $userID GROUP BY $columnFileType",
    );

    final filesCount = <FileType, int>{};
    for (var e in result) {
      filesCount.addAll(
        {getFileType(e[columnFileType] as int): e.values.last as int},
      );
    }
    return filesCount;
  }

  Future<FileLoadResult> fetchAllUploadedAndSharedFilesWithLocation(
    int startTime,
    int endTime, {
    int? limit,
    bool? asc,
    required DBFilterOptions? filterOptions,
  }) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      filesTable,
      where:
          '$columnLatitude IS NOT NULL AND $columnLongitude IS NOT NULL AND ($columnLatitude IS NOT 0 OR $columnLongitude IS NOT 0)'
          ' AND $columnCreationTime >= ? AND $columnCreationTime <= ?'
          ' AND ($columnLocalID IS NOT NULL OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))',
      whereArgs: [startTime, endTime],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = convertToFiles(results);
    final List<EnteFile> filteredFiles =
        await applyDBFilters(files, filterOptions);
    return FileLoadResult(filteredFiles, files.length == limit);
  }

  Future<List<int>> getOwnedFileIDs(int ownerID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      columns: [columnUploadedFileID],
      where:
          '($columnOwnerID = $ownerID AND $columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1)',
      distinct: true,
    );
    final ids = <int>[];
    for (final result in results) {
      ids.add(result[columnUploadedFileID] as int);
    }
    return ids;
  }

  Future<List<EnteFile>> getUploadedFiles(List<int> uploadedIDs) async {
    final db = await instance.database;
    String inParam = "";
    for (final id in uploadedIDs) {
      inParam += "'" + id.toString() + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID IN ($inParam)',
      groupBy: columnUploadedFileID,
    );
    if (results.isEmpty) {
      return <EnteFile>[];
    }
    return convertToFiles(results);
  }

  Map<String, dynamic> _getRowForFile(EnteFile file) {
    final row = <String, dynamic>{};
    if (file.generatedID != null) {
      row[columnGeneratedID] = file.generatedID;
    }
    row[columnLocalID] = file.localID;
    row[columnUploadedFileID] = file.uploadedFileID ?? -1;
    row[columnOwnerID] = file.ownerID;
    row[columnCollectionID] = file.collectionID ?? -1;
    row[columnTitle] = file.title;
    row[columnDeviceFolder] = file.deviceFolder;
    // if (file.location == null ||
    //     (file.location!.latitude == null && file.location!.longitude == null)) {
    //   file.location = Location.randomLocation();
    // }
    if (file.location != null) {
      row[columnLatitude] = file.location!.latitude;
      row[columnLongitude] = file.location!.longitude;
    }
    row[columnFileType] = getInt(file.fileType);
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
    row[columnAddedTime] =
        file.addedTime ?? DateTime.now().microsecondsSinceEpoch;
    row[columnEncryptedKey] = file.encryptedKey;
    row[columnKeyDecryptionNonce] = file.keyDecryptionNonce;
    row[columnFileDecryptionHeader] = file.fileDecryptionHeader;
    row[columnThumbnailDecryptionHeader] = file.thumbnailDecryptionHeader;
    row[columnMetadataDecryptionHeader] = file.metadataDecryptionHeader;
    row[columnFileSubType] = file.fileSubType ?? -1;
    row[columnDuration] = file.duration ?? 0;
    row[columnExif] = file.exif;
    row[columnHash] = file.hash;
    row[columnMetadataVersion] = file.metadataVersion;
    row[columnFileSize] = file.fileSize;
    row[columnMMdVersion] = file.mMdVersion;
    row[columnMMdEncodedJson] = file.mMdEncodedJson ?? '{}';
    row[columnMMdVisibility] = file.magicMetadata.visibility;
    row[columnPubMMdVersion] = file.pubMmdVersion;
    row[columnPubMMdEncodedJson] = file.pubMmdEncodedJson ?? '{}';
    // override existing fields to avoid re-writing all queries and logic
    if (file.pubMagicMetadata != null) {
      if (file.pubMagicMetadata!.editedTime != null) {
        row[columnCreationTime] = file.pubMagicMetadata!.editedTime;
      }
      if (file.pubMagicMetadata!.lat != null &&
          file.pubMagicMetadata!.long != null) {
        row[columnLatitude] = file.pubMagicMetadata!.lat;
        row[columnLongitude] = file.pubMagicMetadata!.long;
      }
    }
    return row;
  }

  Map<String, dynamic> _getRowForFileWithoutCollection(EnteFile file) {
    final row = <String, dynamic>{};
    row[columnLocalID] = file.localID;
    row[columnUploadedFileID] = file.uploadedFileID ?? -1;
    row[columnOwnerID] = file.ownerID;
    row[columnTitle] = file.title;
    row[columnDeviceFolder] = file.deviceFolder;
    if (file.location != null) {
      row[columnLatitude] = file.location!.latitude;
      row[columnLongitude] = file.location!.longitude;
    }
    row[columnFileType] = getInt(file.fileType);
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
    row[columnAddedTime] =
        file.addedTime ?? DateTime.now().microsecondsSinceEpoch;
    row[columnFileDecryptionHeader] = file.fileDecryptionHeader;
    row[columnThumbnailDecryptionHeader] = file.thumbnailDecryptionHeader;
    row[columnMetadataDecryptionHeader] = file.metadataDecryptionHeader;
    row[columnFileSubType] = file.fileSubType ?? -1;
    row[columnDuration] = file.duration ?? 0;
    row[columnExif] = file.exif;
    row[columnHash] = file.hash;
    row[columnMetadataVersion] = file.metadataVersion;

    row[columnMMdVersion] = file.mMdVersion;
    row[columnMMdEncodedJson] = file.mMdEncodedJson ?? '{}';
    row[columnMMdVisibility] = file.magicMetadata.visibility;

    row[columnPubMMdVersion] = file.pubMmdVersion;
    row[columnPubMMdEncodedJson] = file.pubMmdEncodedJson ?? '{}';
    if (file.pubMagicMetadata != null &&
        file.pubMagicMetadata!.editedTime != null) {
      // override existing creationTime to avoid re-writing all queries related
      // to loading the gallery
      row[columnCreationTime] = file.pubMagicMetadata!.editedTime!;
    }
    return row;
  }

  EnteFile _getFileFromRow(Map<String, dynamic> row) {
    final file = EnteFile();
    file.generatedID = row[columnGeneratedID];
    file.localID = row[columnLocalID];
    file.uploadedFileID =
        row[columnUploadedFileID] == -1 ? null : row[columnUploadedFileID];
    file.ownerID = row[columnOwnerID];
    file.collectionID =
        row[columnCollectionID] == -1 ? null : row[columnCollectionID];
    file.title = row[columnTitle];
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
    file.addedTime = row[columnAddedTime];
    file.encryptedKey = row[columnEncryptedKey];
    file.keyDecryptionNonce = row[columnKeyDecryptionNonce];
    file.fileDecryptionHeader = row[columnFileDecryptionHeader];
    file.thumbnailDecryptionHeader = row[columnThumbnailDecryptionHeader];
    file.metadataDecryptionHeader = row[columnMetadataDecryptionHeader];
    file.fileSubType = row[columnFileSubType] ?? -1;
    file.duration = row[columnDuration] ?? 0;
    file.exif = row[columnExif];
    file.hash = row[columnHash];
    file.metadataVersion = row[columnMetadataVersion] ?? 0;
    file.fileSize = row[columnFileSize];

    file.mMdVersion = row[columnMMdVersion] ?? 0;
    file.mMdEncodedJson = row[columnMMdEncodedJson] ?? '{}';

    file.pubMmdVersion = row[columnPubMMdVersion] ?? 0;
    file.pubMmdEncodedJson = row[columnPubMMdEncodedJson] ?? '{}';
    return file;
  }
}
