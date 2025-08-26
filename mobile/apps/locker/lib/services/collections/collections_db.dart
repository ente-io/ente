import 'dart:convert';

import "package:ente_base/models/database.dart";
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/collections/models/public_url.dart';
import 'package:locker/services/collections/models/user.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class CollectionDB extends EnteBaseDatabase {
  CollectionDB._privateConstructor();

  static final CollectionDB instance = CollectionDB._privateConstructor();

  Database? _database;
  int _collectionSyncTime = 0;
  final Map<int, int> _collectionSyncTimesCache = {};

  static const String _collectionsTable = 'collections';
  static const String _filesTable = 'files';
  static const String _collectionFilesTable = 'collection_files';
  static const String _syncTimesTable = 'sync_times';

  Future<void> init() async {
    _database = await _initDatabase();
    await _loadCaches();
  }

  Future<void> _loadCaches() async {
    final syncTimes = await _db.query(
      _syncTimesTable,
      where: 'key LIKE ?',
      whereArgs: ['collection_sync_time_%'],
    );

    for (final row in syncTimes) {
      final key = row['key'] as String;
      final collectionId =
          int.tryParse(key.replaceFirst('collection_sync_time_', ''));
      if (collectionId != null) {
        _collectionSyncTimesCache[collectionId] = row['value'] as int;
      }
    }

    final globalSyncTime = await getSyncTimeAsync();
    _collectionSyncTime = globalSyncTime;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'collection_store.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_collectionsTable (
        id INTEGER PRIMARY KEY,
        owner_id INTEGER,
        owner_email TEXT,
        owner_name TEXT,
        encrypted_key TEXT,
        key_decryption_nonce TEXT,
        name TEXT,
        type TEXT,
        attributes_version INTEGER,
        attributes_encrypted_path TEXT,
        attributes_path_decryption_nonce TEXT,
        sharees TEXT,
        public_urls TEXT,
        updation_time INTEGER,
        is_deleted INTEGER DEFAULT 0,
        decrypted_path TEXT,
        m_md_encoded_json TEXT,
        m_md_pub_encoded_json TEXT,
        shared_mmd_json TEXT,
        m_md_version INTEGER DEFAULT 0,
        m_mb_pub_version INTEGER DEFAULT 0,
        shared_mmd_version INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $_filesTable (
        uploaded_file_id INTEGER,
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
        m_md_version INTEGER DEFAULT 0,
        pub_mmd_encoded_json TEXT,
        pub_mmd_version INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $_collectionFilesTable (
        collection_id INTEGER,
        uploaded_file_id INTEGER,
        PRIMARY KEY (collection_id, uploaded_file_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_syncTimesTable (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_files_collection_id ON $_filesTable (collection_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_files_uploaded_file_id ON $_filesTable (uploaded_file_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_collection_files_uploaded_file_id ON $_collectionFilesTable (uploaded_file_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_collections_updation_time ON $_collectionsTable (updation_time)
    ''');
  }

  Database get _db {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  Future<void> setSyncTime(int lastSyncTime) async {
    _collectionSyncTime = lastSyncTime;
    await _db.insert(
      _syncTimesTable,
      {'key': 'collection_sync_time', 'value': lastSyncTime},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  int getSyncTime() {
    return _collectionSyncTime;
  }

  Future<int> getSyncTimeAsync() async {
    final result = await _db.query(
      _syncTimesTable,
      where: 'key = ?',
      whereArgs: ['collection_sync_time'],
    );

    if (result.isNotEmpty) {
      _collectionSyncTime = result.first['value'] as int;
      return _collectionSyncTime;
    }
    return 0;
  }

  int getCollectionSyncTime(int collectionId) {
    return _collectionSyncTimesCache[collectionId] ?? 0;
  }

  Future<int> getCollectionSyncTimeAsync(int collectionId) async {
    final result = await _db.query(
      _syncTimesTable,
      where: 'key = ?',
      whereArgs: ['collection_sync_time_$collectionId'],
    );

    int syncTime = 0;
    if (result.isNotEmpty) {
      syncTime = result.first['value'] as int;
    }

    _collectionSyncTimesCache[collectionId] = syncTime;
    return syncTime;
  }

  Future<void> setCollectionSyncTime(int collectionId, int lastSyncTime) async {
    await _db.insert(
      _syncTimesTable,
      {'key': 'collection_sync_time_$collectionId', 'value': lastSyncTime},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _collectionSyncTimesCache[collectionId] = lastSyncTime;
  }

  Future<Collection> getCollection(int id) async {
    final result = await _db.query(
      _collectionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      throw Exception('Collection with id $id not found');
    }

    return _mapToCollection(result.first);
  }

  Future<void> updateCollections(List<Collection> collections) async {
    final batch = _db.batch();

    for (final collection in collections) {
      batch.delete(
        _collectionsTable,
        where: 'id = ?',
        whereArgs: [collection.id],
      );

      batch.insert(
        _collectionsTable,
        _collectionToMap(collection),
      );
    }

    await batch.commit();
  }

  Future<void> deleteCollection(Collection collection) async {
    final batch = _db.batch();

    batch.delete(
      _collectionsTable,
      where: 'id = ?',
      whereArgs: [collection.id],
    );

    batch.delete(
      _collectionFilesTable,
      where: 'collection_id = ?',
      whereArgs: [collection.id],
    );

    final filesInCollection = await _db.query(
      _collectionFilesTable,
      where: 'collection_id = ?',
      whereArgs: [collection.id],
    );

    for (final fileMap in filesInCollection) {
      final uploadedFileId = fileMap['uploaded_file_id'] as int;
      final otherCollections = await _db.query(
        _collectionFilesTable,
        where: 'uploaded_file_id = ? AND collection_id != ?',
        whereArgs: [uploadedFileId, collection.id],
      );

      if (otherCollections.isEmpty) {
        batch.delete(
          _filesTable,
          where: 'uploaded_file_id = ?',
          whereArgs: [uploadedFileId],
        );
      }
    }

    await batch.commit();
  }

  Future<List<Collection>> getCollections() async {
    final result = await _db.query(_collectionsTable);
    return result.map((row) => _mapToCollection(row)).toList();
  }

  Future<void> addFilesToCollection(
    Collection collection,
    List<EnteFile> files,
  ) async {
    final batch = _db.batch();

    for (final file in files) {
      batch.insert(
        _filesTable,
        _fileToMap(file),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      batch.insert(
        _collectionFilesTable,
        {
          'collection_id': collection.id,
          'uploaded_file_id': file.uploadedFileID!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit();
  }

  Future<void> deleteFilesFromCollection(
    Collection collection,
    List<EnteFile> files,
  ) async {
    final batch = _db.batch();

    for (final file in files) {
      batch.delete(
        _collectionFilesTable,
        where: 'collection_id = ? AND uploaded_file_id = ?',
        whereArgs: [collection.id, file.uploadedFileID!],
      );

      final otherCollections = await _db.query(
        _collectionFilesTable,
        where: 'uploaded_file_id = ? AND collection_id != ?',
        whereArgs: [file.uploadedFileID!, collection.id],
      );

      if (otherCollections.isEmpty) {
        batch.delete(
          _filesTable,
          where: 'uploaded_file_id = ?',
          whereArgs: [file.uploadedFileID!],
        );
      }
    }

    await batch.commit();
  }

  Future<List<EnteFile>> getFilesInCollection(Collection collection) async {
    final result = await _db.rawQuery(
      '''
      SELECT f.*
      FROM $_filesTable f
      INNER JOIN $_collectionFilesTable cf ON f.uploaded_file_id = cf.uploaded_file_id
      WHERE cf.collection_id = ?
    ''',
      [collection.id],
    );

    return result.map((row) => _mapToFile(row)).toList();
  }

  Future<List<Collection>> getCollectionsForFile(EnteFile file) async {
    final result = await _db.rawQuery(
      '''
      SELECT c.*
      FROM $_collectionsTable c
      INNER JOIN $_collectionFilesTable cf ON c.id = cf.collection_id
      WHERE cf.uploaded_file_id = ?
    ''',
      [file.uploadedFileID!],
    );

    return result.map((row) => _mapToCollection(row)).toList();
  }

  Future<List<EnteFile>> getAllFiles() async {
    final result = await _db.query(_filesTable);
    return result.map((row) => _mapToFile(row)).toList();
  }

  Map<String, dynamic> _collectionToMap(Collection collection) {
    return {
      'id': collection.id,
      'owner_id': collection.owner.id,
      'owner_email': collection.owner.email,
      'owner_name': collection.owner.name,
      'encrypted_key': collection.encryptedKey,
      'key_decryption_nonce': collection.keyDecryptionNonce,
      'name': collection.name,
      'type': typeToString(collection.type),
      'attributes_version': collection.attributes.version,
      'attributes_encrypted_path': collection.attributes.encryptedPath,
      'attributes_path_decryption_nonce':
          collection.attributes.pathDecryptionNonce,
      'sharees':
          jsonEncode(collection.sharees.map((user) => user.toMap()).toList()),
      'public_urls':
          jsonEncode(collection.publicURLs.map((url) => url.toMap()).toList()),
      'updation_time': collection.updationTime,
      'is_deleted': collection.isDeleted ? 1 : 0,
      'decrypted_path': collection.decryptedPath,
      'm_md_encoded_json': collection.mMdEncodedJson,
      'm_md_pub_encoded_json': collection.mMdPubEncodedJson,
      'shared_mmd_json': collection.sharedMmdJson,
      'm_md_version': collection.mMdVersion,
      'm_mb_pub_version': collection.mMbPubVersion,
      'shared_mmd_version': collection.sharedMmdVersion,
    };
  }

  Collection _mapToCollection(Map<String, dynamic> map) {
    final owner = User(
      id: map['owner_id'] as int?,
      email: map['owner_email'] as String,
      name: map['owner_name'] as String?,
    );

    final attributes = CollectionAttributes(
      version: map['attributes_version'] as int? ?? 0,
      encryptedPath: map['attributes_encrypted_path'] as String?,
      pathDecryptionNonce: map['attributes_path_decryption_nonce'] as String?,
    );

    final shareesJson = map['sharees'] as String? ?? '[]';
    final shareesData = jsonDecode(shareesJson) as List<dynamic>;
    final sharees = shareesData
        .map((shareeeMap) => User.fromMap(shareeeMap as Map<String, dynamic>))
        .where((user) => user != null)
        .cast<User>()
        .toList();

    final publicUrlsJson = map['public_urls'] as String? ?? '[]';
    final publicURLsData = jsonDecode(publicUrlsJson) as List<dynamic>;
    final publicURLs = publicURLsData
        .map((urlMap) => PublicURL.fromMap(urlMap as Map<String, dynamic>))
        .where((url) => url != null)
        .cast<PublicURL>()
        .toList();

    final collection = Collection(
      map['id'] as int,
      owner,
      map['encrypted_key'] as String,
      map['key_decryption_nonce'] as String?,
      map['name'] as String?,
      null,
      null,
      typeFromString(map['type'] as String),
      attributes,
      sharees,
      publicURLs,
      map['updation_time'] as int,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );

    collection.decryptedPath = map['decrypted_path'] as String?;
    collection.mMdEncodedJson = map['m_md_encoded_json'] as String?;
    collection.mMdPubEncodedJson = map['m_md_pub_encoded_json'] as String?;
    collection.sharedMmdJson = map['shared_mmd_json'] as String?;
    collection.mMdVersion = map['m_md_version'] as int? ?? 0;
    collection.mMbPubVersion = map['m_mb_pub_version'] as int? ?? 0;
    collection.sharedMmdVersion = map['shared_mmd_version'] as int? ?? 0;

    return collection;
  }

  Map<String, dynamic> _fileToMap(EnteFile file) {
    return {
      'uploaded_file_id': file.uploadedFileID,
      'local_path': file.localPath,
      'owner_id': file.ownerID,
      'collection_id': file.collectionID,
      'title': file.title,
      'creation_time': file.creationTime,
      'modification_time': file.modificationTime,
      'updation_time': file.updationTime,
      'added_time': file.addedTime,
      'hash': file.hash,
      'metadata_version': file.metadataVersion,
      'encrypted_key': file.encryptedKey,
      'key_decryption_nonce': file.keyDecryptionNonce,
      'file_decryption_header': file.fileDecryptionHeader,
      'thumbnail_decryption_header': file.thumbnailDecryptionHeader,
      'metadata_decryption_header': file.metadataDecryptionHeader,
      'file_size': file.fileSize,
      'm_md_encoded_json': file.mMdEncodedJson,
      'm_md_version': file.mMdVersion,
      'pub_mmd_encoded_json': file.pubMmdEncodedJson,
      'pub_mmd_version': file.pubMmdVersion,
    };
  }

  EnteFile _mapToFile(Map<String, dynamic> map) {
    final file = EnteFile();

    file.localPath = map['local_path'];
    file.uploadedFileID = map['uploaded_file_id'];
    file.ownerID = map['owner_id'];
    file.collectionID = map['collection_id'];
    file.title = map['title'];
    file.creationTime = map['creation_time'];
    file.modificationTime = map['modification_time'];
    file.updationTime = map['updation_time'];
    file.addedTime = map['added_time'];
    file.hash = map['hash'];
    file.metadataVersion = map['metadata_version'];
    file.encryptedKey = map['encrypted_key'];
    file.keyDecryptionNonce = map['key_decryption_nonce'];
    file.fileDecryptionHeader = map['file_decryption_header'];
    file.thumbnailDecryptionHeader = map['thumbnail_decryption_header'];
    file.metadataDecryptionHeader = map['metadata_decryption_header'];
    file.fileSize = map['file_size'];
    file.mMdEncodedJson = map['m_md_encoded_json'];
    file.mMdVersion = map['m_md_version'] ?? 0;
    file.pubMmdEncodedJson = map['pub_mmd_encoded_json'];
    file.pubMmdVersion = map['pub_mmd_version'] ?? 1;

    return file;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<void> clearTable() async {
    await _database?.delete(_collectionsTable);
    await _database?.delete(_filesTable);
    await _database?.delete(_collectionFilesTable);
    await _database?.delete(_syncTimesTable);
    _collectionSyncTimesCache.clear();
    _collectionSyncTime = 0;
  }
}
