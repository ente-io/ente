import "dart:async";
import "dart:io";

import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqflite/sqflite.dart";
import "package:sqflite_migration/sqflite_migration.dart";

enum BackgroundUploadVerificationState { pending, inProgress, verified, failed }

class BackgroundUploadVerificationRecord {
  final int uploadedFileID;
  final String localID;
  final int collectionID;
  final String? expectedHash;
  final String? expectedZipHash;
  final BackgroundUploadVerificationState state;
  final String? errorMessage;

  const BackgroundUploadVerificationRecord({
    required this.uploadedFileID,
    required this.localID,
    required this.collectionID,
    required this.expectedHash,
    required this.expectedZipHash,
    required this.state,
    this.errorMessage,
  });
}

class BackgroundUploadVerificationDB {
  static const _databaseName = "ente.bg_verify.db";

  static const _verificationTable = (
    table: "background_upload_verification",
    uploadedFileID: "uploaded_file_id",
    localID: "local_id",
    collectionID: "collection_id",
    expectedHash: "expected_hash",
    expectedZipHash: "expected_zip_hash",
    state: "state",
    errorMessage: "error_message",
    createdAt: "created_at",
    updatedAt: "updated_at",
  );

  static final initializationScript = [_createVerificationTable()];

  final dbConfig = MigrationConfig(
    initializationScript: initializationScript,
    migrationScripts: const [],
  );

  BackgroundUploadVerificationDB._privateConstructor();
  static final BackgroundUploadVerificationDB instance =
      BackgroundUploadVerificationDB._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    return openDatabaseWithMigration(path, dbConfig);
  }

  static String _createVerificationTable() {
    return '''
      CREATE TABLE IF NOT EXISTS ${_verificationTable.table} (
        ${_verificationTable.uploadedFileID} INTEGER PRIMARY KEY NOT NULL,
        ${_verificationTable.localID} TEXT NOT NULL,
        ${_verificationTable.collectionID} INTEGER NOT NULL,
        ${_verificationTable.expectedHash} TEXT,
        ${_verificationTable.expectedZipHash} TEXT,
        ${_verificationTable.state} TEXT NOT NULL,
        ${_verificationTable.errorMessage} TEXT,
        ${_verificationTable.createdAt} INTEGER NOT NULL,
        ${_verificationTable.updatedAt} INTEGER NOT NULL
      )
    ''';
  }

  Future<void> clearTable() async {
    final db = await database;
    await db.delete(_verificationTable.table);
  }

  Future<void> upsertPending({
    required int uploadedFileID,
    required String localID,
    required int collectionID,
    String? expectedHash,
    String? expectedZipHash,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      _verificationTable.table,
      {
        _verificationTable.uploadedFileID: uploadedFileID,
        _verificationTable.localID: localID,
        _verificationTable.collectionID: collectionID,
        _verificationTable.expectedHash: expectedHash,
        _verificationTable.expectedZipHash: expectedZipHash,
        _verificationTable.state:
            BackgroundUploadVerificationState.pending.name,
        _verificationTable.errorMessage: null,
        _verificationTable.createdAt: now,
        _verificationTable.updatedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BackgroundUploadVerificationRecord>> getPending({
    int limit = 20,
  }) async {
    final db = await database;
    final rows = await db.query(
      _verificationTable.table,
      where: '${_verificationTable.state} IN (?, ?)',
      whereArgs: [
        BackgroundUploadVerificationState.pending.name,
        BackgroundUploadVerificationState.inProgress.name,
      ],
      orderBy: '${_verificationTable.createdAt} ASC',
      limit: limit,
    );
    return rows.map(_toRecord).toList();
  }

  Future<bool> hasPendingForUploadID(int uploadedFileID) async {
    final db = await database;
    final rows = await db.query(
      _verificationTable.table,
      columns: [_verificationTable.uploadedFileID],
      where:
          '${_verificationTable.uploadedFileID} = ? AND ${_verificationTable.state} IN (?, ?)',
      whereArgs: [
        uploadedFileID,
        BackgroundUploadVerificationState.pending.name,
        BackgroundUploadVerificationState.inProgress.name,
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasRecordForUploadID(int uploadedFileID) async {
    final db = await database;
    final rows = await db.query(
      _verificationTable.table,
      columns: [_verificationTable.uploadedFileID],
      where: '${_verificationTable.uploadedFileID} = ?',
      whereArgs: [uploadedFileID],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String?> getFailedErrorForUploadID(int uploadedFileID) async {
    final db = await database;
    final rows = await db.query(
      _verificationTable.table,
      columns: [_verificationTable.errorMessage],
      where:
          '${_verificationTable.uploadedFileID} = ? AND ${_verificationTable.state} = ?',
      whereArgs: [
        uploadedFileID,
        BackgroundUploadVerificationState.failed.name,
      ],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first[_verificationTable.errorMessage] as String?;
  }

  Future<void> markInProgress(int uploadedFileID) async {
    await _updateState(
      uploadedFileID,
      BackgroundUploadVerificationState.inProgress,
    );
  }

  Future<void> markVerified(int uploadedFileID) async {
    await _updateState(
      uploadedFileID,
      BackgroundUploadVerificationState.verified,
    );
  }

  Future<void> markFailed(int uploadedFileID, String errorMessage) async {
    final db = await database;
    await db.update(
      _verificationTable.table,
      {
        _verificationTable.state: BackgroundUploadVerificationState.failed.name,
        _verificationTable.errorMessage: errorMessage,
        _verificationTable.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${_verificationTable.uploadedFileID} = ?',
      whereArgs: [uploadedFileID],
    );
  }

  Future<void> delete(int uploadedFileID) async {
    final db = await database;
    await db.delete(
      _verificationTable.table,
      where: '${_verificationTable.uploadedFileID} = ?',
      whereArgs: [uploadedFileID],
    );
  }

  Future<void> _updateState(
    int uploadedFileID,
    BackgroundUploadVerificationState state,
  ) async {
    final db = await database;
    await db.update(
      _verificationTable.table,
      {
        _verificationTable.state: state.name,
        _verificationTable.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${_verificationTable.uploadedFileID} = ?',
      whereArgs: [uploadedFileID],
    );
  }

  BackgroundUploadVerificationRecord _toRecord(Map<String, Object?> row) {
    return BackgroundUploadVerificationRecord(
      uploadedFileID: row[_verificationTable.uploadedFileID] as int,
      localID: row[_verificationTable.localID] as String,
      collectionID: row[_verificationTable.collectionID] as int,
      expectedHash: row[_verificationTable.expectedHash] as String?,
      expectedZipHash: row[_verificationTable.expectedZipHash] as String?,
      state: BackgroundUploadVerificationState.values.firstWhere(
        (e) => e.name == row[_verificationTable.state],
      ),
      errorMessage: row[_verificationTable.errorMessage] as String?,
    );
  }
}
