import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/collection.dart';
import 'package:sqflite/sqflite.dart';

class CollectionsDB {
  static final _databaseName = "ente.collections.db";
  static final _databaseVersion = 1;

  static final collectionsTable = 'collections';

  static final columnID = 'collection_id';
  static final columnOwnerID = 'owner_id';
  static final columnOwnerEmail = 'owner_email';
  static final columnEncryptedKey = 'encrypted_key';
  static final columnKeyDecryptionNonce = 'key_decryption_nonce';
  static final columnName = 'name';
  static final columnType = 'type';
  static final columnEncryptedPath = 'encrypted_path';
  static final columnPathDecryptionNonce = 'path_decryption_nonce';
  static final columnCreationTime = 'creation_time';

  CollectionsDB._privateConstructor();
  static final CollectionsDB instance = CollectionsDB._privateConstructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
                CREATE TABLE $collectionsTable (
                  $columnID INTEGER PRIMARY KEY NOT NULL,
                  $columnOwnerID INTEGER NOT NULL,
                  $columnOwnerEmail TEXT,
                  $columnEncryptedKey TEXT NOT NULL,
                  $columnKeyDecryptionNonce TEXT,
                  $columnName TEXT NOT NULL,
                  $columnType TEXT NOT NULL,
                  $columnEncryptedPath TEXT,
                  $columnPathDecryptionNonce TEXT,
                  $columnCreationTime TEXT NOT NULL
                )
                ''');
  }

  Future<List<dynamic>> insert(List<Collection> collections) async {
    final db = await instance.database;
    var batch = db.batch();
    for (final collection in collections) {
      batch.insert(collectionsTable, _getRowForCollection(collection),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return await batch.commit();
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await instance.database;
    final rows = await db.query(collectionsTable);
    final collections = List<Collection>();
    for (final row in rows) {
      collections.add(_convertToCollection(row));
    }
    return collections;
  }

  Future<int> getLastCollectionCreationTime() async {
    final db = await instance.database;
    final rows = await db.query(
      collectionsTable,
      orderBy: '$columnCreationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return int.parse(rows[0][columnCreationTime]);
    } else {
      return null;
    }
  }

  Map<String, dynamic> _getRowForCollection(Collection collection) {
    var row = new Map<String, dynamic>();
    row[columnID] = collection.id;
    row[columnOwnerID] = collection.ownerID;
    row[columnOwnerEmail] = collection.ownerEmail;
    row[columnEncryptedKey] = collection.encryptedKey;
    row[columnKeyDecryptionNonce] = collection.keyDecryptionNonce;
    row[columnName] = collection.name;
    row[columnType] = Collection.typeToString(collection.type);
    row[columnEncryptedPath] = collection.attributes.encryptedPath;
    row[columnPathDecryptionNonce] = collection.attributes.pathDecryptionNonce;
    row[columnCreationTime] = collection.creationTime;
    return row;
  }

  Collection _convertToCollection(Map<String, dynamic> row) {
    return Collection(
      row[columnID],
      row[columnOwnerID],
      row[columnOwnerEmail],
      row[columnEncryptedKey],
      row[columnKeyDecryptionNonce],
      row[columnName],
      Collection.typeFromString(row[columnType]),
      CollectionAttributes(
          encryptedPath: row[columnEncryptedPath],
          pathDecryptionNonce: row[columnPathDecryptionNonce]),
      int.parse(row[columnCreationTime]),
    );
  }
}
