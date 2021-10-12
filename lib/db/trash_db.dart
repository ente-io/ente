import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/trash_file.dart';
import 'package:sqflite/sqflite.dart';

class TrashDB {
  static final _databaseName = "ente.trash.db";
  static final _databaseVersion = 1;
  static final Logger _logger = Logger("TrashDB");
  static final tableName = 'trash';

  static final columnUploadedFileID = 'uploaded_file_id';
  static final columnCollectionID = 'collection_id';
  static final columnOwnerID = 'owner_id';
  static final columnTrashUpdatedAt = 't_updated_at';
  static final columnTrashDeleteBy = 't_delete_by';
  static final columnEncryptedKey = 'encrypted_key';
  static final columnKeyDecryptionNonce = 'key_decryption_nonce';
  static final columnFileDecryptionHeader = 'file_decryption_header';
  static final columnThumbnailDecryptionHeader = 'thumbnail_decryption_header';

  static final columnLocalID = 'local_id';
  static final columnTitle = 'title';
  static final columnDeviceFolder = 'device_folder';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';
  static final columnFileType = 'file_type';
  static final columnFileSubType = 'file_sub_type';
  static final columnDuration = 'duration';
  static final columnHash = 'hash';
  static final columnMetadataVersion = 'metadata_version';
  static final columnModificationTime = 'modification_time';
  static final columnCreationTime = 'creation_time';
  static final columnMMdEncodedJson = 'mmd_encoded_json';
  static final columnMMdVersion = 'mmd_ver';
  static final columnMMdVisibility = 'mmd_visibility';

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableName (
          $columnUploadedFileID INTEGER PRIMARY KEY NOT NULL,
          $columnCollectionID INTEGER NOT NULL,
          $columnOwnerID INTEGER,
          $columnTrashUpdatedAt INTEGER NOT NULL,
          $columnTrashDeleteBy INTEGER NOT NULL,
          $columnEncryptedKey TEXT,
          $columnKeyDecryptionNonce TEXT,
          $columnFileDecryptionHeader TEXT,
          $columnThumbnailDecryptionHeader TEXT,
          $columnLocalID TEXT,
          $columnTitle TEXT NOT NULL,
          $columnDeviceFolder TEXT,
          $columnLatitude REAL,
          $columnLongitude REAL,
          $columnFileType INTEGER,
          $columnCreationTime INTEGER NOT NULL,
          $columnModificationTime INTEGER NOT NULL,
          $columnFileSubType INTEGER,
          $columnDuration INTEGER,
          $columnHash TEXT,
          $columnMetadataVersion INTEGER,
          $columnMMdEncodedJson TEXT DEFAULT '{}',
          $columnMMdVersion INTEGER DEFAULT 0,
          $columnMMdVisibility INTEGER DEFAULT $kVisibilityVisible
        );
      CREATE INDEX IF NOT EXISTS creation_time_index ON $tableName($columnCreationTime); 
      CREATE INDEX IF NOT EXISTS creation_time_index ON $tableName($columnTrashDeleteBy);
      CREATE INDEX IF NOT EXISTS creation_time_index ON $tableName($columnTrashUpdatedAt);
      ''');
  }

  TrashDB._privateConstructor();

  static final TrashDB instance = TrashDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<Database> _dbFuture;

  Future<Database> get database async {
    // lazily instantiate the db the first time it is accessed
    _dbFuture ??= _initDatabase();
    return _dbFuture;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    _logger.info("DB path " + path);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(tableName);
  }

  Future<void> insertMultiple(List<Trash> trashFiles) async {
    final startTime = DateTime.now();
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (Trash trash in trashFiles) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        tableName,
        _getRowForTrash(trash),
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
        trashFiles.length.toString() +
        " took " +
        duration.inMilliseconds.toString() +
        "ms.");
  }

  Future<int> insert(Trash trash) async {
    final db = await instance.database;
    return db.insert(
      tableName,
      _getRowForTrash(trash),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(List<int> uploadedFileIDs) async {
    final db = await instance.database;
    return db.delete(
      tableName,
      where: '$columnUploadedFileID IN (${uploadedFileIDs.join(', ')})',
    );
  }

  Map<String, dynamic> _getRowForTrash(Trash trash) {
    final file = trash.file;
    final row = <String, dynamic>{};
    row[columnTrashUpdatedAt] = trash.updateAt;
    row[columnTrashDeleteBy] = trash.deleteBy;
    row[columnUploadedFileID] = file.uploadedFileID;
    row[columnCollectionID] = file.collectionID;
    row[columnOwnerID] = file.ownerID;
    row[columnLocalID] = file.localID;
    row[columnTitle] = file.title;
    row[columnDeviceFolder] = file.deviceFolder;
    if (file.location != null) {
      row[columnLatitude] = file.location.latitude;
      row[columnLongitude] = file.location.longitude;
    }
    row[columnFileType] = getInt(file.fileType);
    row[columnCreationTime] = file.creationTime;
    row[columnModificationTime] = file.modificationTime;
    row[columnEncryptedKey] = file.encryptedKey;
    row[columnKeyDecryptionNonce] = file.keyDecryptionNonce;
    row[columnFileDecryptionHeader] = file.fileDecryptionHeader;
    row[columnThumbnailDecryptionHeader] = file.thumbnailDecryptionHeader;
    row[columnFileSubType] = file.fileSubType ?? -1;
    row[columnDuration] = file.duration ?? 0;
    row[columnHash] = file.hash;
    row[columnMetadataVersion] = file.metadataVersion;
    row[columnMMdVersion] = file.mMdVersion ?? 0;
    row[columnMMdEncodedJson] = file.mMdEncodedJson ?? '{}';
    row[columnMMdVisibility] =
        file.magicMetadata?.visibility ?? kVisibilityVisible;
    return row;
  }
}
