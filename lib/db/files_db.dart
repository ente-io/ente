import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

class FilesDB {
  static final _databaseName = "ente.files.db";

  static final Logger _logger = Logger("FilesDB");

  static final table = 'files';
  static final tableCopy = 'files_copy';

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
  static final columnIsEncrypted = 'is_encrypted';
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
  static List<String> createTable(String tablename) {
    return [
      '''
          CREATE TABLE $tablename (
            $columnGeneratedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            $columnLocalID TEXT,
            $columnUploadedFileID INTEGER,
            $columnOwnerID INTEGER,
            $columnCollectionID INTEGER,
            $columnTitle TEXT NOT NULL,
            $columnDeviceFolder TEXT,
            $columnLatitude REAL,
            $columnLongitude REAL,
            $columnFileType INTEGER,
            $columnIsEncrypted INTEGER DEFAULT 1,
            $columnModificationTime TEXT NOT NULL,
            $columnEncryptedKey TEXT,
            $columnKeyDecryptionNonce TEXT,
            $columnFileDecryptionHeader TEXT,
            $columnThumbnailDecryptionHeader TEXT,
            $columnMetadataDecryptionHeader TEXT,
            $columnIsDeleted INTEGER DEFAULT 0,
            $columnCreationTime TEXT NOT NULL,
            $columnUpdationTime TEXT,
            UNIQUE($columnUploadedFileID, $columnCollectionID)
          );''',
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
      ...createTable(tableCopy),
      '''
        INSERT INTO $tableCopy
        SELECT *
        FROM $table;
      ''',
      '''
        DROP TABLE $table;
      ''',
      '''
        ALTER TABLE $tableCopy 
        RENAME TO $table;
    '''
    ];
  }

  Future<int> insert(File file) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForFile(file));
  }

  Future<void> insertMultiple(List<File> files) async {
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (File file in files) {
      if (batchCounter == 400) {
        await batch.commit();
        batch = db.batch();
      }
      batch.insert(
        table,
        _getRowForFile(file),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
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

  Future<List<File>> getDeduplicatedFiles() async {
    _logger.info("Getting files for collection");
    final db = await instance.database;
    final results = await db.query(table,
        where: '$columnIsDeleted = 0',
        orderBy: '$columnCreationTime DESC',
        groupBy:
            'IFNULL($columnUploadedFileID, $columnGeneratedID), IFNULL($columnLocalID, $columnGeneratedID)');
    return _convertToFiles(results);
  }

  Future<List<File>> getFiles() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnIsDeleted = 0',
      orderBy: '$columnCreationTime DESC',
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

  Future<List<File>> getAllInCollectionBeforeCreationTime(
      int collectionID, int beforeCreationTime, int limit) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnCollectionID = ? AND $columnIsDeleted = 0 AND $columnCreationTime < ?',
      whereArgs: [collectionID, beforeCreationTime],
      orderBy: '$columnCreationTime DESC',
      limit: limit,
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

  Future<List<File>> getAllInPathBeforeCreationTime(
      String path, int beforeCreationTime, int limit) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnLocalID IS NOT NULL AND $columnDeviceFolder = ? AND $columnIsDeleted = 0 AND $columnCreationTime < ?',
      whereArgs: [path, beforeCreationTime],
      orderBy: '$columnCreationTime DESC',
      groupBy: '$columnLocalID',
      limit: limit,
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getAllInCollection(int collectionID) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnCollectionID = ?',
      whereArgs: [collectionID],
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<File>> getFilesCreatedWithinDuration(
      int startCreationTime, int endCreationTime) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnCreationTime > ? AND $columnCreationTime < ? AND $columnIsDeleted = 0',
      whereArgs: [startCreationTime, endCreationTime],
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
    final db = await instance.database;
    String inParam = "";
    for (final folder in folders) {
      inParam += "'" + folder + "',";
    }
    inParam = inParam.substring(0, inParam.length - 1);
    final results = await db.query(
      table,
      where:
          '$columnUploadedFileID IS NULL AND $columnDeviceFolder IN ($inParam)',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
  }

  Future<List<int>> getUploadedFileIDsToBeUpdated() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnUploadedFileID],
      where:
          '($columnLocalID IS NOT NULL AND $columnUploadedFileID IS NOT NULL AND $columnUpdationTime IS NULL AND $columnIsDeleted = 0)',
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

  Future<Map<int, File>> getLastCreatedFilesInCollections(
      List<int> collectionIDs) async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
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
        $columnIsEncrypted,
        $columnModificationTime,
        $columnEncryptedKey,
        $columnKeyDecryptionNonce,
        $columnFileDecryptionHeader,
        $columnThumbnailDecryptionHeader,
        $columnMetadataDecryptionHeader,
        $columnIsDeleted,
        $columnUpdationTime,
        MAX($columnCreationTime) as $columnCreationTime
      FROM $table
      WHERE $columnCollectionID IN (${collectionIDs.join(', ')}) AND $columnIsDeleted = 0
      GROUP BY $columnCollectionID
      ORDER BY $columnCreationTime DESC;
    ''');
    final result = Map<int, File>();
    final files = _convertToFiles(rows);
    for (final file in files) {
      result[file.collectionID] = file;
    }
    return result;
  }

  Future<Map<int, File>> getLastUpdatedFilesInCollections(
      List<int> collectionIDs) async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
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
        $columnIsEncrypted,
        $columnModificationTime,
        $columnEncryptedKey,
        $columnKeyDecryptionNonce,
        $columnFileDecryptionHeader,
        $columnThumbnailDecryptionHeader,
        $columnMetadataDecryptionHeader,
        $columnIsDeleted,
        $columnCreationTime,
        MAX($columnUpdationTime) AS $columnUpdationTime
      FROM $table
      WHERE $columnCollectionID IN (${collectionIDs.join(', ')}) AND $columnIsDeleted = 0
      GROUP BY $columnCollectionID
      ORDER BY $columnUpdationTime DESC;
    ''');
    final result = Map<int, File>();
    final files = _convertToFiles(rows);
    for (final file in files) {
      result[file.collectionID] = file;
    }
    return result;
  }

  Future<List<File>> getMatchingFiles(
    String title,
    String deviceFolder,
    int creationTime,
  ) async {
    final db = await instance.database;
    final rows = await (deviceFolder != null
        ? db.query(
            table,
            where: '''$columnTitle=? AND $columnDeviceFolder=? AND 
          $columnCreationTime=?''',
            whereArgs: [
              title,
              deviceFolder,
              creationTime,
            ],
          )
        : db.query(
            table,
            where: '''$columnTitle=? AND 
          $columnCreationTime=?''',
            whereArgs: [
              title,
              creationTime,
            ],
          ));
    if (rows.isNotEmpty) {
      return _convertToFiles(rows);
    } else {
      return null;
    }
  }

  Future<File> getMatchingRemoteFile(int uploadedFileID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnUploadedFileID=?',
      whereArgs: [uploadedFileID],
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No matching file found");
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

  Future<int> markForDeletion(int uploadedFileID) async {
    final db = await instance.database;
    final values = new Map<String, dynamic>();
    values[columnIsDeleted] = 1;
    return db.update(
      table,
      values,
      where: '$columnUploadedFileID =?',
      whereArgs: [uploadedFileID],
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

  Future<List<String>> getLocalPaths() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnDeviceFolder],
      where: '$columnLocalID IS NOT NULL',
      distinct: true,
    );
    List<String> result = List<String>();
    for (final row in rows) {
      result.add(row[columnDeviceFolder]);
    }
    return result;
  }

  Future<File> getLatestFileInCollection(int collectionID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnCollectionID = ? AND $columnIsDeleted = 0',
      whereArgs: [collectionID],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      return null;
    }
  }

  Future<File> getLastCreatedFileInPath(String path) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where:
          '$columnDeviceFolder = ? AND $columnLocalID IS NOT NULL AND $columnIsDeleted = 0',
      whereArgs: [path],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      return null;
    }
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
    final files = List<File>();
    for (final result in results) {
      files.add(_getFileFromRow(result));
    }
    return files;
  }

  Map<String, dynamic> _getRowForFile(File file) {
    final row = new Map<String, dynamic>();
    row[columnLocalID] = file.localID;
    row[columnUploadedFileID] = file.uploadedFileID;
    row[columnOwnerID] = file.ownerID;
    row[columnCollectionID] = file.collectionID;
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
    row[columnIsEncrypted] = file.isEncrypted ? 1 : 0;
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
    row[columnUploadedFileID] = file.uploadedFileID;
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
    row[columnIsEncrypted] = file.isEncrypted ? 1 : 0;
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
    file.uploadedFileID = row[columnUploadedFileID];
    file.ownerID = row[columnOwnerID];
    file.collectionID = row[columnCollectionID];
    file.title = row[columnTitle];
    file.deviceFolder = row[columnDeviceFolder];
    if (row[columnLatitude] != null && row[columnLongitude] != null) {
      file.location = Location(row[columnLatitude], row[columnLongitude]);
    }
    file.fileType = getFileType(row[columnFileType]);
    file.isEncrypted = row[columnIsEncrypted] == 1;
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
