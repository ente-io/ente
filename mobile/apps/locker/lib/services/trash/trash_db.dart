import "package:ente_base/models/database.dart";
import 'package:locker/services/trash/models/trash_file.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TrashDB extends EnteBaseDatabase {
  TrashDB._privateConstructor();

  static final TrashDB instance = TrashDB._privateConstructor();

  Database? _database;

  static const String _trashTable = 'trash_files';

  Future<void> init() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'trash.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_trashTable (
        uploaded_file_id INTEGER PRIMARY KEY,
        local_path TEXT,
        owner_id INTEGER,
        collection_id INTEGER,
        title TEXT,
        creation_time INTEGER,
        modification_time INTEGER,
        updation_time INTEGER,
        added_time INTEGER,
        hash TEXT,
        metadata_version INTEGER,
        encrypted_key TEXT,
        key_decryption_nonce TEXT,
        file_decryption_header TEXT,
        thumbnail_decryption_header TEXT,
        metadata_decryption_header TEXT,
        file_size INTEGER,
        m_md_encoded_json TEXT,
        m_md_version INTEGER,
        pub_mmd_encoded_json TEXT,
        pub_mmd_version INTEGER,
        created_at INTEGER NOT NULL,
        update_at INTEGER NOT NULL,
        delete_by INTEGER NOT NULL
      )
    ''');
  }

  Database get _db {
    if (_database == null) {
      throw Exception('TrashDB not initialized. Call init() first.');
    }
    return _database!;
  }

  Future<void> insertMultiple(List<TrashFile> trashFiles) async {
    final batch = _db.batch();

    for (final trashFile in trashFiles) {
      batch.insert(
        _trashTable,
        _trashFileToMap(trashFile),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<void> delete(List<int> uploadedFileIDs) async {
    final batch = _db.batch();

    for (final uploadedFileID in uploadedFileIDs) {
      batch.delete(
        _trashTable,
        where: 'uploaded_file_id = ?',
        whereArgs: [uploadedFileID],
      );
    }

    await batch.commit();
  }

  Future<List<TrashFile>> getAllTrashFiles() async {
    final result = await _db.query(_trashTable);
    return result.map((row) => _mapToTrashFile(row)).toList();
  }

  @override
  Future<void> clearTable() async {
    await _db.delete(_trashTable);
  }

  Map<String, dynamic> _trashFileToMap(TrashFile trashFile) {
    return {
      'uploaded_file_id': trashFile.uploadedFileID!,
      'local_path': trashFile.localPath,
      'owner_id': trashFile.ownerID,
      'collection_id': trashFile.collectionID,
      'title': trashFile.title,
      'creation_time': trashFile.creationTime,
      'modification_time': trashFile.modificationTime,
      'updation_time': trashFile.updationTime,
      'added_time': trashFile.addedTime,
      'hash': trashFile.hash,
      'metadata_version': trashFile.metadataVersion,
      'encrypted_key': trashFile.encryptedKey,
      'key_decryption_nonce': trashFile.keyDecryptionNonce,
      'file_decryption_header': trashFile.fileDecryptionHeader,
      'thumbnail_decryption_header': trashFile.thumbnailDecryptionHeader,
      'metadata_decryption_header': trashFile.metadataDecryptionHeader,
      'file_size': trashFile.fileSize,
      'm_md_encoded_json': trashFile.mMdEncodedJson,
      'm_md_version': trashFile.mMdVersion,
      'pub_mmd_encoded_json': trashFile.pubMmdEncodedJson,
      'pub_mmd_version': trashFile.pubMmdVersion,
      'created_at': trashFile.createdAt,
      'update_at': trashFile.updateAt,
      'delete_by': trashFile.deleteBy,
    };
  }

  TrashFile _mapToTrashFile(Map<String, dynamic> map) {
    final trashFile = TrashFile();

    trashFile.localPath = map['local_path'];
    trashFile.uploadedFileID = map['uploaded_file_id'];
    trashFile.ownerID = map['owner_id'];
    trashFile.collectionID = map['collection_id'];
    trashFile.title = map['title'];
    trashFile.creationTime = map['creation_time'];
    trashFile.modificationTime = map['modification_time'];
    trashFile.updationTime = map['updation_time'];
    trashFile.addedTime = map['added_time'];
    trashFile.hash = map['hash'];
    trashFile.metadataVersion = map['metadata_version'];
    trashFile.encryptedKey = map['encrypted_key'];
    trashFile.keyDecryptionNonce = map['key_decryption_nonce'];
    trashFile.fileDecryptionHeader = map['file_decryption_header'];
    trashFile.thumbnailDecryptionHeader = map['thumbnail_decryption_header'];
    trashFile.metadataDecryptionHeader = map['metadata_decryption_header'];
    trashFile.fileSize = map['file_size'];
    trashFile.mMdEncodedJson = map['m_md_encoded_json'];
    trashFile.mMdVersion = map['m_md_version'] ?? 0;
    trashFile.pubMmdEncodedJson = map['pub_mmd_encoded_json'];
    trashFile.pubMmdVersion = map['pub_mmd_version'] ?? 1;

    // TrashFile specific fields
    trashFile.createdAt = map['created_at'];
    trashFile.updateAt = map['update_at'];
    trashFile.deleteBy = map['delete_by'];

    return trashFile;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
