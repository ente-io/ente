import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/utils/file_uploader_util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

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

  static final initializationScript = [...createTable(filesTable)];
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

  Future<Database> get database async {
    // lazily instantiate the db the first time it is accessed
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    final io.Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path " + path);
    return await openDatabaseWithMigration(path, dbConfig);
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
        ALTER TABLE $filesTable ADD COLUMN $columnMMdVisibility INTEGER DEFAULT $visibilityVisible;
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

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(filesTable);
    await db.delete("device_files");
    await db.delete("device_collections");
  }

  Future<void> deleteDB() async {
    if (kDebugMode) {
      debugPrint("Deleting files db");
      final io.Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, _databaseName);
      io.File(path).deleteSync(recursive: true);
      _dbFuture = null;
    }
  }

  Future<void> insertMultiple(
    List<File> files, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final startTime = DateTime.now();
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (File file in files) {
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

  Future<int> insert(File file) async {
    final db = await instance.database;
    return db.insert(
      filesTable,
      _getRowForFile(file),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<File?> getFile(int generatedID) async {
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

  Future<File?> getUploadedFile(int uploadedID, int collectionID) async {
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
      columns: [columnLocalID, columnUploadedFileID],
      where:
          '$columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1)',
    );
    final localIDs = <String>{};
    final uploadedIDs = <int>{};
    for (final result in results) {
      localIDs.add(result[columnLocalID] as String);
      uploadedIDs.add(result[columnUploadedFileID] as int);
    }
    return BackedUpFileIDs(localIDs.toList(), uploadedIDs.toList());
  }

  Future<FileLoadResult> getAllPendingOrUploadedFiles(
    int startTime,
    int endTime,
    int ownerID, {
    int? limit,
    bool? asc,
    int visibility = visibilityVisible,
    Set<int>? ignoredCollectionIDs,
  }) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      filesTable,
      where:
          '$columnCreationTime >= ? AND $columnCreationTime <= ? AND  ($columnOwnerID IS NULL OR $columnOwnerID = ?) AND ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)'
          ' AND $columnMMdVisibility = ?',
      whereArgs: [startTime, endTime, ownerID, visibility],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = convertToFiles(results);
    final List<File> deduplicatedFiles =
        _deduplicatedAndFilterIgnoredFiles(files, ignoredCollectionIDs);
    return FileLoadResult(deduplicatedFiles, files.length == limit);
  }

  Future<FileLoadResult> getAllLocalAndUploadedFiles(
    int startTime,
    int endTime,
    int ownerID, {
    int? limit,
    bool? asc,
    Set<int>? ignoredCollectionIDs,
  }) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      filesTable,
      where:
          '$columnCreationTime >= ? AND $columnCreationTime <= ? AND ($columnOwnerID IS NULL OR $columnOwnerID = ?)  AND ($columnMMdVisibility IS NULL OR $columnMMdVisibility = ?)'
          ' AND ($columnLocalID IS NOT NULL OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))',
      whereArgs: [startTime, endTime, ownerID, visibilityVisible],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = convertToFiles(results);
    final List<File> deduplicatedFiles =
        _deduplicatedAndFilterIgnoredFiles(files, ignoredCollectionIDs);
    return FileLoadResult(deduplicatedFiles, files.length == limit);
  }

  List<File> deduplicateByLocalID(List<File> files) {
    final localIDs = <String>{};
    final List<File> deduplicatedFiles = [];
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

  List<File> _deduplicatedAndFilterIgnoredFiles(
    List<File> files,
    Set<int>? ignoredCollectionIDs,
  ) {
    final Set<int> uploadedFileIDs = <int>{};
    // ignoredFileUploadIDs is to keep a track of files which are part of
    // archived collection
    final Set<int> ignoredFileUploadIDs = <int>{};
    final List<File> deduplicatedFiles = [];
    for (final file in files) {
      final id = file.uploadedFileID;
      final bool isFileUploaded = id != null && id != -1;
      final bool isCollectionIgnored = ignoredCollectionIDs != null &&
          ignoredCollectionIDs.contains(file.collectionID);
      if (isCollectionIgnored || ignoredFileUploadIDs.contains(id)) {
        if (isFileUploaded) {
          ignoredFileUploadIDs.add(id);
          // remove the file from the list of deduplicated files
          if (uploadedFileIDs.contains(id)) {
            deduplicatedFiles
                .removeWhere((element) => element.uploadedFileID == id);
            uploadedFileIDs.remove(id);
          }
        }
        continue;
      }
      if (isFileUploaded && uploadedFileIDs.contains(id)) {
        continue;
      }
      if (isFileUploaded) {
        uploadedFileIDs.add(id);
      }
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
    int visibility = visibilityVisible,
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

  Future<List<File>> getAllFilesCollection(int collectionID) async {
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

  Future<FileLoadResult> getFilesInCollections(
    List<int> collectionIDs,
    int startTime,
    int endTime,
    int userID, {
    int? limit,
    bool? asc,
  }) async {
    if (collectionIDs.isEmpty) {
      return FileLoadResult(<File>[], false);
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
    final dedupeResult = _deduplicatedAndFilterIgnoredFiles(files, {});
    _logger.info("Fetched " + dedupeResult.length.toString() + " files");
    return FileLoadResult(files, files.length == limit);
  }

  Future<List<File>> getFilesCreatedWithinDurations(
    List<List<int>> durations,
    Set<int> ignoredCollectionIDs, {
    String order = 'ASC',
  }) async {
    if (durations.isEmpty) {
      return <File>[];
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
      }
    }
    whereClause += ") AND $columnMMdVisibility = $visibilityVisible";
    final results = await db.query(
      filesTable,
      where: whereClause,
      orderBy: '$columnCreationTime ' + order,
    );
    final files = convertToFiles(results);
    return _deduplicatedAndFilterIgnoredFiles(files, ignoredCollectionIDs);
  }

  // Files which user added to a collection manually but they are not
  // uploaded yet or files belonging to a collection which is marked for backup
  Future<List<File>> getFilesPendingForUpload() async {
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

  Future<List<File>> getUnUploadedLocalFiles() async {
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

  Future<File?> getUploadedFileInAnyCollection(int uploadedFileID) async {
    final db = await instance.database;
    final results = await db.query(
      filesTable,
      where: '$columnUploadedFileID = ?',
      whereArgs: [
        uploadedFileID,
      ],
      limit: 1,
    );
    if (results.isEmpty) {
      return null;
    }
    return convertToFiles(results)[0];
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

  Future<int> updateUploadedFile(
    String localID,
    String? title,
    Location? location,
    int creationTime,
    int modificationTime,
    int? updationTime,
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
        columnUpdationTime: updationTime,
      },
      where: '$columnLocalID = ?',
      whereArgs: [localID],
    );
  }

  /*
    This method should only return localIDs which are not uploaded yet
    and can be mapped to incoming remote entry
   */
  Future<List<File>> getUnlinkedLocalMatchesForRemoteFile(
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
    if (io.Platform.isAndroid) {
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

  Future<List<File>> getUploadedFilesWithHashes(
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

  Future<int> update(File file) async {
    final db = await instance.database;
    return await db.update(
      filesTable,
      _getRowForFile(file),
      where: '$columnGeneratedID = ?',
      whereArgs: [file.generatedID],
    );
  }

  Future<int> updateUploadedFileAcrossCollections(File file) async {
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

  Future<int> deleteLocalFile(File file) async {
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

  Future<List<File>> getLocalFiles(List<String> localIDs) async {
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

  Future<int> fileCountWithVisibility(int visibility, int ownerID) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(distinct($columnUploadedFileID)) FROM $filesTable where '
        '$columnMMdVisibility'
        ' = $visibility AND $columnOwnerID = $ownerID',
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

  Future<List<File>> getPendingUploadForCollection(int collectionID) async {
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
    List<File> existingFiles,
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

  Future<List<File>> getLatestCollectionFiles() async {
    debugPrint("Fetching latestCollectionFiles from db");
    const String query = '''
      SELECT $filesTable.*
      FROM $filesTable
      INNER JOIN
        (
          SELECT $columnCollectionID, MAX($columnCreationTime) AS max_creation_time
          FROM $filesTable
          WHERE 
          ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1
           AND $columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS 
           NOT -1)
          GROUP BY $columnCollectionID
        ) latest_files
        ON $filesTable.$columnCollectionID = latest_files.$columnCollectionID
        AND $filesTable.$columnCreationTime = latest_files.max_creation_time;
  ''';
    final db = await instance.database;
    final rows = await db.rawQuery(
      query,
    );
    final files = convertToFiles(rows);
    // TODO: Do this de-duplication within the SQL Query
    final collectionMap = <int, File>{};
    for (final file in files) {
      if (collectionMap.containsKey(file.collectionID)) {
        if (collectionMap[file.collectionID]!.updationTime! <
            file.updationTime!) {
          continue;
        }
      }
      collectionMap[file.collectionID!] = file;
    }
    return collectionMap.values.toList();
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

  Future<Map<int, File>> getFilesFromIDs(List<int> ids) async {
    final result = <int, File>{};
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

  Future<Map<int, File>> getFilesFromGeneratedIDs(List<int> ids) async {
    final result = <int, File>{};
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

  Future<Map<int, List<File>>> getAllFilesGroupByCollectionID(
    List<int> ids,
  ) async {
    final result = <int, List<File>>{};
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
    for (File eachFile in files) {
      if (!result.containsKey(eachFile.collectionID)) {
        result[eachFile.collectionID as int] = <File>[];
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

  List<File> convertToFiles(List<Map<String, dynamic>> results) {
    final List<File> files = [];
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

  Future<List<File>> getAllFilesFromDB(Set<int> collectionsToIgnore) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(filesTable);
    final List<File> files = convertToFiles(result);
    final List<File> deduplicatedFiles =
        _deduplicatedAndFilterIgnoredFiles(files, collectionsToIgnore);
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

  Map<String, dynamic> _getRowForFile(File file) {
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
    if (file.location != null) {
      row[columnLatitude] = file.location!.latitude;
      row[columnLongitude] = file.location!.longitude;
    }
    row[columnFileType] = getInt(file.fileType);
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
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
    if (file.pubMagicMetadata != null &&
        file.pubMagicMetadata!.editedTime != null) {
      // override existing creationTime to avoid re-writing all queries related
      // to loading the gallery
      row[columnCreationTime] = file.pubMagicMetadata!.editedTime;
    }
    return row;
  }

  Map<String, dynamic> _getRowForFileWithoutCollection(File file) {
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

  File _getFileFromRow(Map<String, dynamic> row) {
    final file = File();
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
      file.location = Location(row[columnLatitude], row[columnLongitude]);
    }
    file.fileType = getFileType(row[columnFileType]);
    file.creationTime = row[columnCreationTime];
    file.modificationTime = row[columnModificationTime];
    file.updationTime = row[columnUpdationTime] ?? -1;
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
