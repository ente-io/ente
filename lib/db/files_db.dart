import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class FilesDB {
  static final _databaseName = "ente.files.db";
  static final _databaseVersion = 1;

  static final Logger _logger = Logger("FilesDB");

  static final table = 'files';

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
  static final columnRemoteFolderID = 'remote_folder_id';
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
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnGeneratedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            $columnLocalID TEXT,
            $columnUploadedFileID INTEGER,
            $columnOwnerID INTEGER,
            $columnCollectionID INTEGER,
            $columnTitle TEXT NOT NULL,
            $columnDeviceFolder TEXT NOT NULL,
            $columnLatitude REAL,
            $columnLongitude REAL,
            $columnFileType INTEGER,
            $columnRemoteFolderID INTEGER,
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
          )
          ''');
  }

  Future<int> insert(File file) async {
    final db = await instance.database;
    return await db.insert(table, _getRowForFile(file));
  }

  Future<List<dynamic>> insertMultiple(List<File> files) async {
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
    return await batch.commit();
  }

  Future<File> getFile(int generatedID) async {
    final db = await instance.database;
    final results = await db.query(table,
        where: '$columnGeneratedID = ?', whereArgs: [generatedID]);
    return _convertToFiles(results)[0];
  }

  Future<List<File>> getOwnedFiles(int ownerID) async {
    final db = await instance.database;
    final whereArgs = List<dynamic>();
    if (ownerID != null) {
      whereArgs.add(ownerID);
    }
    final results = await db.query(
      table,
      where: '$columnIsDeleted = 0' +
          (ownerID == null
              ? ''
              : ' AND ($columnOwnerID IS NULL OR $columnOwnerID = ?)'),
      whereArgs: whereArgs,
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

  Future<List<File>> getAllInFolder(
      int folderID, int beforeCreationTime, int limit) async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where:
          '$columnRemoteFolderID = ? AND $columnIsDeleted = 0 AND $columnCreationTime < ?',
      whereArgs: [folderID, beforeCreationTime],
      orderBy: '$columnCreationTime DESC',
      limit: limit,
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

  Future<List<File>> getAllDeleted() async {
    final db = await instance.database;
    final results = await db.query(
      table,
      where: '$columnIsDeleted = 1',
      orderBy: '$columnCreationTime DESC',
    );
    return _convertToFiles(results);
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

  Future<File> getMatchingFile(String localID, String title,
      String deviceFolder, int creationTime, int modificationTime,
      {String alternateTitle}) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '''$columnLocalID=? AND ($columnTitle=? OR $columnTitle=?) AND 
          $columnDeviceFolder=? AND $columnCreationTime=? AND 
          $columnModificationTime=?''',
      whereArgs: [
        localID,
        title,
        alternateTitle,
        deviceFolder,
        creationTime,
        modificationTime,
      ],
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No matching file found");
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

  // TODO: Remove deleted files on remote
  Future<int> markForDeletion(File file) async {
    final db = await instance.database;
    final values = new Map<String, dynamic>();
    values[columnIsDeleted] = 1;
    return db.update(
      table,
      values,
      where: '$columnGeneratedID =?',
      whereArgs: [file.generatedID],
    );
  }

  Future<int> delete(File file) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnGeneratedID =?',
      whereArgs: [file.generatedID],
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

  Future<int> deleteFilesInRemoteFolder(int folderID) async {
    final db = await instance.database;
    return db.delete(
      table,
      where: '$columnRemoteFolderID =?',
      whereArgs: [folderID],
    );
  }

  Future<List<String>> getLocalPaths() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      columns: [columnDeviceFolder],
      distinct: true,
      where: '$columnRemoteFolderID IS NULL',
    );
    List<String> result = List<String>();
    for (final row in rows) {
      result.add(row[columnDeviceFolder]);
    }
    return result;
  }

  Future<File> getLatestFileInPath(String path) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnDeviceFolder =?',
      whereArgs: [path],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in path");
    }
  }

  Future<File> getLatestFileInRemoteFolder(int folderID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnRemoteFolderID =?',
      whereArgs: [folderID],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in remote folder " + folderID.toString());
    }
  }

  Future<File> getLatestFileInCollection(int collectionID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnCollectionID =?',
      whereArgs: [collectionID],
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in collection " + collectionID.toString());
    }
  }

  Future<File> getLastSyncedFileInRemoteFolder(int folderID) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnRemoteFolderID =?',
      whereArgs: [folderID],
      orderBy: '$columnUpdationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found in remote folder " + folderID.toString());
    }
  }

  Future<File> getLatestFileAmongGeneratedIDs(List<String> generatedIDs) async {
    final db = await instance.database;
    final rows = await db.query(
      table,
      where: '$columnGeneratedID IN (${generatedIDs.join(",")})',
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _getFileFromRow(rows[0]);
    } else {
      throw ("No file found with ids " + generatedIDs.join(", ").toString());
    }
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
    row[columnRemoteFolderID] = file.remoteFolderID;
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
    file.remoteFolderID = row[columnRemoteFolderID];
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
