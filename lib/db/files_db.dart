import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

class FilesDB {
  /*
  Note: columnUploadedFileID and columnCollectionID have to be compared against
  both NULL and -1 because older clients might have entries where the DEFAULT
  was unset, and a migration script to set the DEFAULT would break in case of
  duplicate entries for un-uploaded files that were created due to a collision
  in background and foreground syncs.
  */
  static final _databaseName = "ente.files.db";

  static final Logger _logger = Logger("FilesDB");

  static final table = 'files';
  static final tempTable = 'temp_files';

  static final columnGeneratedID = '_id';
  static final columnUploadedFileID = 'uploaded_file_id';
  static final columnOwnerID = 'owner_id';
  static final columnCollectionID = 'collection_id';
  static final columnLocalID = 'local_id';
  static final columnTitle = 'title';
  static final columnDeviceFolder = 'device_folder';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';
  static final columnFileType = 'file_type';
  static final columnIsDeleted = 'is_deleted';
  static final columnCreationTime = 'creation_time';
  static final columnModificationTime = 'modification_time';
  static final columnUpdationTime = 'updation_time';
  static final columnEncryptedKey = 'encrypted_key';
  static final columnKeyDecryptionNonce = 'key_decryption_nonce';
  static final columnFileDecryptionHeader = 'file_decryption_header';
  static final columnThumbnailDecryptionHeader = 'thumbnail_decryption_header';
  static final columnMetadataDecryptionHeader = 'metadata_decryption_header';

  static final intitialScript = [...createTable(table), ...addIndex()];
  static final migrationScripts = [...alterDeviceFolderToAllowNULL()];

  final dbConfig = MigrationConfig(
      initializationScript: intitialScript, migrationScripts: migrationScripts);
  // make this a singleton class
  FilesDB._privateConstructor();
  static final FilesDB instance = FilesDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
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

  static List<String> addIndex() {
    return [
      '''
        CREATE INDEX collection_id_index ON $table($columnCollectionID);
        CREATE INDEX device_folder_index ON $table($columnDeviceFolder);
        CREATE INDEX creation_time_index ON $table($columnCreationTime);
        CREATE INDEX updation_time_index ON $table($columnUpdationTime);
      '''
    ];
  }

  static List<String> alterDeviceFolderToAllowNULL() {
    return [
      ...createTable(tempTable),
      '''
        INSERT INTO $tempTable
        SELECT *
        FROM $table;

        DROP TABLE $table;
        
        ALTER TABLE $tempTable 
        RENAME TO $table;
    '''
    ];
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(table);
  }

  Future<void> insertMultiple(List<File> files) async {
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
        table,
        _getRowForFile(file),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
    final endTime = DateTime.now();
    final duration = Duration(
        microseconds:
            endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch);
    _logger.info("Batch insert of " +
        files.length.toString() +
        " took " +
        duration.inMilliseconds.toString() +
        "ms.");
  }

  Future<int> insert(File file) async {
    final db = await instance.database;
    return db.insert(
      table,
      _getRowForFile(file),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<File> getFile(int generatedID) async {
    final db = await instance.database;
    final results = await db.query(table,
        where: '$columnGeneratedID = ?', whereArgs: [generatedID]);
    if (results.isEmpty) {
      return null;
    }
    return _convertToFiles(results)[0];
  }

  Future<File> getUploadedFile(int uploadedID, int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [
        uploadedID,
        collectionID,
      ],
    );
    if (results.isEmpty) {
      return null;
    }
    return _convertToFiles(results)[0];
  }

  Future<Set<int>> getUploadedFileIDs(int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      columns: [columnUploadedFileID],
      where: '$columnCollectionID = ?',
      whereArgs: [
        collectionID,
      ],
    );
    final ids = Set<int>();
    for (final result in results) {
      ids.add(result[columnUploadedFileID]);
    }
    return ids;
  }

  Future<BackedUpFileIDs> getBackedUpIDs() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      columns: [columnLocalID, columnUploadedFileID],
      where:
          '$columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1)',
    );
    final localIDs = Set<String>();
    final uploadedIDs = Set<int>();
    for (final result in results) {
      localIDs.add(result[columnLocalID]);
      uploadedIDs.add(result[columnUploadedFileID]);
    }
    return BackedUpFileIDs(localIDs.toList(), uploadedIDs.toList());
  }

  Future<List<File>> getAllFiles(int startTime, int endTime,
      {int limit, bool asc}) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      table,
      where:
          '$columnCreationTime >= ? AND $columnCreationTime <= ? AND $columnIsDeleted = 0 AND ($columnLocalID IS NOT NULL OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))',
      whereArgs: [startTime, endTime],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getFilesInPaths(
      int startTime, int endTime, List<String> paths,
      {int limit, bool asc}) async {
    final db = await instance.database;
    String inParam = "";
    for (final path in paths) {
      inParam += "'" + path.replaceAll("'", "''") + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      table,
      where:
          '$columnCreationTime >= ? AND $columnCreationTime <= ? AND $columnIsDeleted = 0 AND (($columnLocalID IS NOT NULL AND $columnDeviceFolder IN ($inParam)) OR ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1))',
      whereArgs: [startTime, endTime],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final uploadedFileIDs = Set<int>();
    final files = _convertToFiles(results);
    final List<File> deduplicatedFiles = [];
    for (final file in files) {
      final id = file.uploadedFileID;
      if (id != null && id != -1 && uploadedFileIDs.contains(id)) {
        continue;
      }
      uploadedFileIDs.add(id);
      deduplicatedFiles.add(file);
    }
    return deduplicatedFiles;
  }

  Future<List<File>> getFilesInCollection(
      int collectionID, int startTime, int endTime,
      {int limit, bool asc}) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      table,
      where:
          '$columnCollectionID = ? AND $columnCreationTime >= ? AND $columnCreationTime <= ? AND $columnIsDeleted = 0',
      whereArgs: [collectionID, startTime, endTime],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      limit: limit,
    );
    final files = _convertToFiles(results);
    _logger.info("Fetched " + files.length.toString() + " files");
    return files;
  }

  Future<List<File>> getFilesInPath(String path, int startTime, int endTime,
      {int limit, bool asc}) async {
    final db = await instance.database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final results = await db.query(
      table,
      where:
          '$columnDeviceFolder = ? AND $columnCreationTime >= ? AND $columnCreationTime <= ? AND $columnLocalID IS NOT NULL AND $columnIsDeleted = 0',
      whereArgs: [path, startTime, endTime],
      orderBy:
          '$columnCreationTime ' + order + ', $columnModificationTime ' + order,
      groupBy: '$columnLocalID',
      limit: limit,
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllVideos() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnLocalID IS NOT NULL AND $columnFileType = 1 AND $columnIsDeleted = 0',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllInPath(String path) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnLocalID IS NOT NULL AND $columnDeviceFolder = ? AND $columnIsDeleted = 0',
      whereArgs: [path],
      orderBy: '$columnCreationTime DESC',
      groupBy: '$columnLocalID',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getFilesCreatedWithinDurations(
      List<List<int>> durations) async {
    final db = await instance.database;
    String whereClause = "";
    for (int index = 0; index < durations.length; index++) {
      whereClause += "($columnCreationTime > " +
          durations[index][0].toString() +
          " AND $columnCreationTime < " +
          durations[index][1].toString() +
          ")";
      if (index != durations.length - 1) {
        whereClause += " OR ";
      }
    }
    final results = await db.query(
      table,
      where: whereClause + " AND $columnIsDeleted = 0",
      orderBy: '$columnCreationTime ASC',
    );
    return _convertToFiles(results);
  }

  Future<List<int>> getDeletedFileIDs() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnUploadedFileID],
      distinct: true,
      where: '$columnIsDeleted = 1',
      orderBy: '$columnCreationTime DESC',
    );
    final result = List<int>();
    for (final row in rows) {
      result.add(row[columnUploadedFileID]);
    }
    return result;
  }

  Future<List<File>> getFilesToBeUploadedWithinFolders(
      Set<String> folders) async {
    if (folders.isEmpty) {
      return [];
    }
    final db = await instance.database;
    String inParam = "";
    for (final folder in folders) {
      inParam += "'" + folder.replaceAll("'", "''") + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final results = await db.query(
      table,
      where:
          '($columnUploadedFileID IS NULL OR $columnUploadedFileID IS -1) AND $columnDeviceFolder IN ($inParam)',
      orderBy: '$columnCreationTime DESC',
      groupBy: '$columnLocalID',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getEditedRemoteFiles() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1) AND ($columnUploadedFileID IS NULL OR $columnUploadedFileID IS -1)',
      orderBy: '$columnCreationTime DESC',
      groupBy: '$columnLocalID',
    );
    return _convertToFiles(results);
  }

  Future<List<int>> getUploadedFileIDsToBeUpdated() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnUploadedFileID],
      where:
          '($columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1) AND $columnUpdationTime IS NULL AND $columnIsDeleted = 0)',
      orderBy: '$columnCreationTime DESC',
      distinct: true,
    );
    final uploadedFileIDs = List<int>();
    for (final row in rows) {
      uploadedFileIDs.add(row[columnUploadedFileID]);
    }
    return uploadedFileIDs;
  }

  Future<File> getUploadedFileInAnyCollection(int uploadedFileID) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnUploadedFileID = ?',
      whereArgs: [
        uploadedFileID,
      ],
      limit: 1,
    );
    if (results.isEmpty) {
      return null;
    }
    return _convertToFiles(results)[0];
  }

  Future<Set<String>> getExistingLocalFileIDs() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnLocalID],
      distinct: true,
      where: '$columnLocalID IS NOT NULL',
    );
    final result = Set<String>();
    for (final row in rows) {
      result.add(row[columnLocalID]);
    }
    return result;
  }

  Future<int> getNumberOfUploadedFiles() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnUploadedFileID],
      where:
          '($columnLocalID IS NOT NULL AND ($columnUploadedFileID IS NOT NULL AND $columnUploadedFileID IS NOT -1) AND $columnUpdationTime IS NOT NULL AND $columnIsDeleted = 0)',
      distinct: true,
    );
    return rows.length;
  }

  Future<int> updateUploadedFile(
    String localID,
    String title,
    Location location,
    int creationTime,
    int modificationTime,
    int updationTime,
  ) async {
    final db = await instance.database;
    return await db.update(
      table,
      {
        columnTitle: title,
        columnLatitude: location.latitude,
        columnLongitude: location.longitude,
        columnCreationTime: creationTime,
        columnModificationTime: modificationTime,
        columnUpdationTime: updationTime,
      },
      where: '$columnLocalID = ?',
      whereArgs: [localID],
    );
  }

  Future<List<File>> getMatchingFiles(
    String title,
    String deviceFolder,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '''$columnTitle=? AND $columnDeviceFolder=?''',
      whereArgs: [
        title,
        deviceFolder,
      ],
    );
    if (rows.isNotEmpty) {
      return _convertToFiles(rows);
    } else {
      return null;
    }
  }

  Future<int> update(File file) async {
    final db = await instance.database;
    return await db.update(
      table,
      _getRowForFile(file),
      where: '$columnGeneratedID = ?',
      whereArgs: [file.generatedID],
    );
  }

  Future<int> updateUploadedFileAcrossCollections(File file) async {
    final db = await instance.database;
    return await db.update(
      table,
      _getRowForFileWithoutCollection(file),
      where: '$columnUploadedFileID = ?',
      whereArgs: [file.uploadedFileID],
    );
  }

  Future<int> delete(int uploadedFileID) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnUploadedFileID =?',
      whereArgs: [uploadedFileID],
    );
  }

  Future<int> deleteMultipleUploadedFiles(List<int> uploadedFileIDs) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '$columnUploadedFileID IN (${uploadedFileIDs.join(', ')})',
    );
  }

  Future<int> deleteLocalFile(String localID) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnLocalID =?',
      whereArgs: [localID],
    );
  }

  Future<int> deleteFromCollection(int uploadedFileID, int collectionID) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [uploadedFileID, collectionID],
    );
  }

  Future<int> deleteCollection(int collectionID) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnCollectionID = ?',
      whereArgs: [collectionID],
    );
  }

  Future<int> removeFromCollection(int collectionID, List<int> fileIDs) async {
    final db = await instance.database;
    return db.delete(
      table,
      where:
          '$columnCollectionID =? AND $columnUploadedFileID IN (${fileIDs.join(', ')})',
      whereArgs: [collectionID],
    );
  }

  Future<List<File>> getLatestLocalFiles() async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
      SELECT $table.*
      FROM $table
      INNER JOIN
        (
          SELECT $columnDeviceFolder, MAX($columnCreationTime) AS max_creation_time
          FROM $table
          WHERE $table.$columnLocalID IS NOT NULL
          GROUP BY $columnDeviceFolder
        ) latest_files
        ON $table.$columnDeviceFolder = latest_files.$columnDeviceFolder
        AND $table.$columnCreationTime = latest_files.max_creation_time;
    ''');
    final files = _convertToFiles(rows);
    // TODO: Do this de-duplication within the SQL Query
    final folderMap = Map<String, File>();
    for (final file in files) {
      if (folderMap.containsKey(file.deviceFolder)) {
        if (folderMap[file.deviceFolder].updationTime < file.updationTime) {
          continue;
        }
      }
      folderMap[file.deviceFolder] = file;
    }
    return folderMap.values.toList();
  }

  Future<List<File>> getLatestCollectionFiles() async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
      SELECT $table.*
      FROM $table
      INNER JOIN
        (
          SELECT $columnCollectionID, MAX($columnCreationTime) AS max_creation_time
          FROM $table
          WHERE ($columnCollectionID IS NOT NULL AND $columnCollectionID IS NOT -1)
          GROUP BY $columnCollectionID
        ) latest_files
        ON $table.$columnCollectionID = latest_files.$columnCollectionID
        AND $table.$columnCreationTime = latest_files.max_creation_time;
    ''');
    final files = _convertToFiles(rows);
    // TODO: Do this de-duplication within the SQL Query
    final collectionMap = Map<int, File>();
    for (final file in files) {
      if (collectionMap.containsKey(file.collectionID)) {
        if (collectionMap[file.collectionID].updationTime < file.updationTime) {
          continue;
        }
      }
      collectionMap[file.collectionID] = file;
    }
    return collectionMap.values.toList();
  }

  Future<File> getLastModifiedFileInCollection(int collectionID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnCollectionID = ? AND $columnIsDeleted = 0',
      whereArgs: [collectionID],
      orderBy: '$columnUpdationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      return null;
    }
  }

  Future<bool> doesFileExistInCollection(
      int uploadedFileID, int collectionID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnUploadedFileID = ? AND $columnCollectionID = ?',
      whereArgs: [uploadedFileID, collectionID],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  List<File> _convertToFiles(List<Map<String, dynamic>> results) {
    final List<File> files = [];
    for (final result in results) {
      files.add(_getFileFromRow(result));
    }
    return files;
  }

  Map<String, dynamic> _getRowForFile(File file) {
    final row = new Map<String, dynamic>();
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
      row[columnLatitude] = file.location.latitude;
      row[columnLongitude] = file.location.longitude;
    }
    switch (file.fileType) {
      case FileType.image:
        row[columnFileType] = 0;
        break;
      case FileType.video:
        row[columnFileType] = 1;
        break;
      default:
        row[columnFileType] = -1;
    }
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
    row[columnEncryptedKey] = file.encryptedKey;
    row[columnKeyDecryptionNonce] = file.keyDecryptionNonce;
    row[columnFileDecryptionHeader] = file.fileDecryptionHeader;
    row[columnThumbnailDecryptionHeader] = file.thumbnailDecryptionHeader;
    row[columnMetadataDecryptionHeader] = file.metadataDecryptionHeader;
    return row;
  }

  Map<String, dynamic> _getRowForFileWithoutCollection(File file) {
    final row = new Map<String, dynamic>();
    row[columnLocalID] = file.localID;
    row[columnUploadedFileID] = file.uploadedFileID ?? -1;
    row[columnOwnerID] = file.ownerID;
    row[columnTitle] = file.title;
    row[columnDeviceFolder] = file.deviceFolder;
    if (file.location != null) {
      row[columnLatitude] = file.location.latitude;
      row[columnLongitude] = file.location.longitude;
    }
    switch (file.fileType) {
      case FileType.image:
        row[columnFileType] = 0;
        break;
      case FileType.video:
        row[columnFileType] = 1;
        break;
      default:
        row[columnFileType] = -1;
    }
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnUpdationTime] = file.updationTime;
    row[columnFileDecryptionHeader] = file.fileDecryptionHeader;
    row[columnThumbnailDecryptionHeader] = file.thumbnailDecryptionHeader;
    row[columnMetadataDecryptionHeader] = file.metadataDecryptionHeader;
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
    file.creationTime = int.parse(row[columnCreationTime]);
    file.modificationTime = int.parse(row[columnModificationTime]);
    file.updationTime = row[columnUpdationTime] == null
        ? -1
        : int.parse(row[columnUpdationTime]);
    file.encryptedKey = row[columnEncryptedKey];
    file.keyDecryptionNonce = row[columnKeyDecryptionNonce];
    file.fileDecryptionHeader = row[columnFileDecryptionHeader];
    file.thumbnailDecryptionHeader = row[columnThumbnailDecryptionHeader];
    file.metadataDecryptionHeader = row[columnMetadataDecryptionHeader];
    return file;
  }
}
