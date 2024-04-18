import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import "package:photos/models/encryption_result.dart";
import "package:photos/module/upload/model/multipart.dart";
import "package:photos/module/upload/service/multipart.dart";
import "package:photos/utils/crypto_util.dart";
import 'package:sqflite/sqflite.dart';
import "package:sqflite_migration/sqflite_migration.dart";

class UploadLocksDB {
  static const _databaseName = "ente.upload_locks.db";

  static const _uploadLocksTable = (
    table: "upload_locks",
    columnID: "id",
    columnOwner: "owner",
    columnTime: "time",
  );

  static const _trackUploadTable = (
    table: "track_uploads",
    columnID: "id",
    columnLocalID: "local_id",
    columnFileHash: "file_hash",
    columnEncryptedFilePath: "encrypted_file_path",
    columnEncryptedFileSize: "encrypted_file_size",
    columnFileKey: "file_key",
    columnFileNonce: "file_nonce",
    columnObjectKey: "object_key",
    columnCompleteUrl: "complete_url",
    columnStatus: "status",
    columnPartSize: "part_size",
  );

  static const _partsTable = (
    table: "upload_parts",
    columnObjectKey: "object_key",
    columnPartNumber: "part_number",
    columnPartUrl: "part_url",
    columnPartETag: "part_etag",
    columnPartStatus: "part_status",
  );

  static final initializationScript = [
    ..._createUploadLocksTable(),
  ];

  static final migrationScripts = [
    ..._createTrackUploadsTable(),
  ];

  final dbConfig = MigrationConfig(
    initializationScript: initializationScript,
    migrationScripts: migrationScripts,
  );

  UploadLocksDB._privateConstructor();
  static final UploadLocksDB instance = UploadLocksDB._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    return await openDatabaseWithMigration(path, dbConfig);
  }

  static List<String> _createUploadLocksTable() {
    return [
      '''
                CREATE TABLE ${_uploadLocksTable.table} (
                  ${_uploadLocksTable.columnID} TEXT PRIMARY KEY NOT NULL,
                  ${_uploadLocksTable.columnOwner} TEXT NOT NULL,
                 ${_uploadLocksTable.columnTime} TEXT NOT NULL
                )
                ''',
    ];
  }

  static List<String> _createTrackUploadsTable() {
    return [
      '''
                CREATE TABLE ${_trackUploadTable.table} (
                  ${_trackUploadTable.columnID} INTEGER PRIMARY KEY,
                  ${_trackUploadTable.columnLocalID} TEXT NOT NULL,
                  ${_trackUploadTable.columnFileHash} TEXT NOT NULL,
                  ${_trackUploadTable.columnEncryptedFilePath} TEXT NOT NULL,
                  ${_trackUploadTable.columnEncryptedFileSize} INTEGER NOT NULL,
                  ${_trackUploadTable.columnFileKey} TEXT NOT NULL,
                  ${_trackUploadTable.columnFileNonce} TEXT NOT NULL,
                  ${_trackUploadTable.columnObjectKey} TEXT NOT NULL,
                  ${_trackUploadTable.columnCompleteUrl} TEXT NOT NULL,
                  ${_trackUploadTable.columnStatus} TEXT DEFAULT '${MultipartStatus.pending.name}' NOT NULL,
                  ${_trackUploadTable.columnPartSize} INTEGER NOT NULL
                )
                ''',
      '''
                CREATE TABLE ${_partsTable.table} (
                  ${_partsTable.columnObjectKey} TEXT NOT NULL REFERENCES ${_trackUploadTable.table}(${_trackUploadTable.columnObjectKey}) ON DELETE CASCADE,
                  ${_partsTable.columnPartNumber} INTEGER NOT NULL,
                  ${_partsTable.columnPartUrl} TEXT NOT NULL,
                  ${_partsTable.columnPartETag} TEXT,
                  ${_partsTable.columnPartStatus} TEXT NOT NULL,
                  PRIMARY KEY (${_partsTable.columnObjectKey}, ${_partsTable.columnPartNumber})
                )
                ''',
    ];
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(_uploadLocksTable.table);
    await db.delete(_trackUploadTable.table);
    await db.delete(_partsTable.table);
  }

  Future<void> acquireLock(String id, String owner, int time) async {
    final db = await instance.database;
    final row = <String, dynamic>{};
    row[_uploadLocksTable.columnID] = id;
    row[_uploadLocksTable.columnOwner] = owner;
    row[_uploadLocksTable.columnTime] = time;
    await db.insert(
      _uploadLocksTable.table,
      row,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<bool> isLocked(String id, String owner) async {
    final db = await instance.database;
    final rows = await db.query(
      _uploadLocksTable.table,
      where:
          '${_uploadLocksTable.columnID} = ? AND ${_uploadLocksTable.columnOwner} = ?',
      whereArgs: [id, owner],
    );
    return rows.length == 1;
  }

  Future<int> releaseLock(String id, String owner) async {
    final db = await instance.database;
    return db.delete(
      _uploadLocksTable.table,
      where:
          '${_uploadLocksTable.columnID} = ? AND ${_uploadLocksTable.columnOwner} = ?',
      whereArgs: [id, owner],
    );
  }

  Future<int> releaseLocksAcquiredByOwnerBefore(String owner, int time) async {
    final db = await instance.database;
    return db.delete(
      _uploadLocksTable.table,
      where:
          '${_uploadLocksTable.columnOwner} = ? AND ${_uploadLocksTable.columnTime} < ?',
      whereArgs: [owner, time],
    );
  }

  Future<int> releaseAllLocksAcquiredBefore(int time) async {
    final db = await instance.database;
    return db.delete(
      _uploadLocksTable.table,
      where: '${_uploadLocksTable.columnTime} < ?',
      whereArgs: [time],
    );
  }

  // For multipart download tracking
  Future<bool> doesExists(String localId, String hash) async {
    final db = await instance.database;
    final rows = await db.query(
      _trackUploadTable.table,
      where:
          '${_trackUploadTable.columnLocalID} = ? AND ${_trackUploadTable.columnFileHash} = ?',
      whereArgs: [localId, hash],
    );

    return rows.isNotEmpty;
  }

  Future<EncryptionResult> getFileEncryptionData(
    String localId,
    String fileHash,
  ) async {
    final db = await instance.database;

    final rows = await db.query(
      _trackUploadTable.table,
      where:
          '${_trackUploadTable.columnLocalID} = ? AND ${_trackUploadTable.columnFileHash} = ?',
      whereArgs: [localId, fileHash],
    );

    if (rows.isEmpty) {
      throw Exception("No cached links found for $localId and $fileHash");
    }
    final row = rows.first;

    return EncryptionResult(
      key:
          CryptoUtil.base642bin(row[_trackUploadTable.columnFileKey] as String),
      header: CryptoUtil.base642bin(
        row[_trackUploadTable.columnFileNonce] as String,
      ),
    );
  }

  Future<MultipartInfo> getCachedLinks(
    String localId,
    String fileHash,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      _trackUploadTable.table,
      where:
          '${_trackUploadTable.columnLocalID} = ? AND ${_trackUploadTable.columnFileHash} = ?',
      whereArgs: [localId, fileHash],
    );
    if (rows.isEmpty) {
      throw Exception("No cached links found for $localId and $fileHash");
    }
    final row = rows.first;
    final objectKey = row[_trackUploadTable.columnObjectKey] as String;
    final partsStatus = await db.query(
      _partsTable.table,
      where: '${_partsTable.columnObjectKey} = ?',
      whereArgs: [objectKey],
    );

    final List<bool> partUploadStatus = [];
    final List<String> partsURLs = List.generate(
      partsStatus.length,
      (index) => "",
    );
    final Map<int, String> partETags = {};

    for (final part in partsStatus) {
      final partNumber = part[_partsTable.columnPartNumber] as int;
      final partUrl = part[_partsTable.columnPartUrl] as String;
      final partStatus = part[_partsTable.columnPartStatus] as String;
      partsURLs[partNumber] = partUrl;
      if (part[_partsTable.columnPartETag] != null) {
        partETags[partNumber] = part[_partsTable.columnPartETag] as String;
      }
      partUploadStatus.add(partStatus == "uploaded");
    }
    final urls = MultipartUploadURLs(
      objectKey: objectKey,
      completeURL: row[_trackUploadTable.columnCompleteUrl] as String,
      partsURLs: partsURLs,
    );

    return MultipartInfo(
      urls: urls,
      status: MultipartStatus.values
          .byName(row[_trackUploadTable.columnStatus] as String),
      partUploadStatus: partUploadStatus,
      partETags: partETags,
      partSize: row[_trackUploadTable.columnPartSize] as int,
    );
  }

  Future<void> createTrackUploadsEntry(
    String localId,
    String fileHash,
    MultipartUploadURLs urls,
    String encryptedFilePath,
    int fileSize,
    String fileKey,
    String fileNonce,
  ) async {
    final db = await UploadLocksDB.instance.database;
    final objectKey = urls.objectKey;

    await db.insert(
      _trackUploadTable.table,
      {
        _trackUploadTable.columnLocalID: localId,
        _trackUploadTable.columnFileHash: fileHash,
        _trackUploadTable.columnObjectKey: objectKey,
        _trackUploadTable.columnCompleteUrl: urls.completeURL,
        _trackUploadTable.columnEncryptedFilePath: encryptedFilePath,
        _trackUploadTable.columnEncryptedFileSize: fileSize,
        _trackUploadTable.columnFileKey: fileKey,
        _trackUploadTable.columnFileNonce: fileNonce,
        _trackUploadTable.columnPartSize: MultiPartUploader.multipartPartSizeForUpload,
      },
    );

    final partsURLs = urls.partsURLs;
    final partsLength = partsURLs.length;

    for (int i = 0; i < partsLength; i++) {
      await db.insert(
        _partsTable.table,
        {
          _partsTable.columnObjectKey: objectKey,
          _partsTable.columnPartNumber: i,
          _partsTable.columnPartUrl: partsURLs[i],
          _partsTable.columnPartStatus: PartStatus.pending.name,
        },
      );
    }
  }

  Future<void> updatePartStatus(
    String objectKey,
    int partNumber,
    String etag,
  ) async {
    final db = await instance.database;
    await db.update(
      _partsTable.table,
      {
        _partsTable.columnPartStatus: PartStatus.uploaded.name,
        _partsTable.columnPartETag: etag,
      },
      where:
          '${_partsTable.columnObjectKey} = ? AND ${_partsTable.columnPartNumber} = ?',
      whereArgs: [objectKey, partNumber],
    );
  }

  Future<void> updateTrackUploadStatus(
    String objectKey,
    MultipartStatus status,
  ) async {
    final db = await instance.database;
    await db.update(
      _trackUploadTable.table,
      {
        _trackUploadTable.columnStatus: status.name,
      },
      where: '${_trackUploadTable.columnObjectKey} = ?',
      whereArgs: [objectKey],
    );
  }

  Future<int> deleteMultipartTrack(
    String localId,
  ) async {
    final db = await instance.database;
    return await db.delete(
      _trackUploadTable.table,
      where: '${_trackUploadTable.columnLocalID} = ?',
      whereArgs: [localId],
    );
  }
}
