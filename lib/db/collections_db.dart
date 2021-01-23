import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

class CollectionsDB {
  static final _databaseName = "ente.collections.db";
  static final collectionsTable = 'collections';
  static final collectionsTableCopy = 'collections_copy';

  static final columnID = 'collection_id';
  static final columnOwner = 'owner';
  static final columnEncryptedKey = 'encrypted_key';
  static final columnKeyDecryptionNonce = 'key_decryption_nonce';
  static final columnName = 'name';
  static final columnEncryptedName = 'encrypted_name';
  static final columnNameDecryptionNonce = 'name_decryption_nonce';
  static final columnType = 'type';
  static final columnEncryptedPath = 'encrypted_path';
  static final columnPathDecryptionNonce = 'path_decryption_nonce';
  static final columnSharees = 'sharees';
  static final columnUpdationTime = 'updation_time';

  static final intitialScript = [onCreate];
  static final migrationScripts = [alterNameToAllowNULL, addEncryptedName];

  final dbConfig = MigrationConfig(
      initializationScript: intitialScript, migrationScripts: migrationScripts);

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
    return await openDatabaseWithMigration(path, dbConfig);
  }

  static final onCreate = '''
				CREATE TABLE $collectionsTable (
					$columnID INTEGER PRIMARY KEY NOT NULL,
					$columnOwner TEXT NOT NULL,
					$columnEncryptedKey TEXT NOT NULL,
					$columnKeyDecryptionNonce TEXT,
					$columnName TEXT,
					$columnType TEXT NOT NULL,
					$columnEncryptedPath TEXT,
					$columnPathDecryptionNonce TEXT,
					$columnSharees TEXT,
					$columnUpdationTime TEXT NOT NULL
				);
		''';

  static final alterNameToAllowNULL = '''
				CREATE TABLE $collectionsTableCopy  (
					$columnID INTEGER PRIMARY KEY NOT NULL,
					$columnOwner TEXT NOT NULL,
					$columnEncryptedKey TEXT NOT NULL,
					$columnKeyDecryptionNonce TEXT,
					$columnName TEXT,
					$columnType TEXT NOT NULL,
					$columnEncryptedPath TEXT,
					$columnPathDecryptionNonce TEXT,
					$columnSharees TEXT,
					$columnUpdationTime TEXT NOT NULL
				);

				INSERT INTO $collectionsTableCopy
				SELECT *
				FROM $collectionsTable;
				DROP TABLE $collectionsTable;

				ALTER TABLE $collectionsTable-copy 
				RENAME TO $collectionsTable;
    ''';

  static String addEncryptedName = '''
				ALTER TABLE $collectionsTable
				ADD COLUMN $columnEncryptedName TEXT 
				ADD COLUMN $columnNameDecryptionNonce TEXT
			''';

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

  Future<int> getLastCollectionUpdationTime() async {
    final db = await instance.database;
    final rows = await db.query(
      collectionsTable,
      orderBy: '$columnUpdationTime DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return int.parse(rows[0][columnUpdationTime]);
    } else {
      return null;
    }
  }

  Future<int> deleteCollection(int collectionID) async {
    final db = await instance.database;
    return db.delete(
      collectionsTable,
      where: '$columnID = ?',
      whereArgs: [collectionID],
    );
  }

  Map<String, dynamic> _getRowForCollection(Collection collection) {
    var row = new Map<String, dynamic>();
    row[columnID] = collection.id;
    row[columnOwner] = collection.owner.toJson();
    row[columnEncryptedKey] = collection.encryptedKey;
    row[columnKeyDecryptionNonce] = collection.keyDecryptionNonce;
    row[columnName] = collection.name;
    row[columnType] = Collection.typeToString(collection.type);
    row[columnEncryptedPath] = collection.attributes.encryptedPath;
    row[columnPathDecryptionNonce] = collection.attributes.pathDecryptionNonce;
    row[columnSharees] =
        json.encode(collection.sharees?.map((x) => x?.toMap())?.toList());
    row[columnUpdationTime] = collection.updationTime;
    return row;
  }

  Collection _convertToCollection(Map<String, dynamic> row) {
    return Collection(
      row[columnID],
      User.fromJson(row[columnOwner]),
      row[columnEncryptedKey],
      row[columnKeyDecryptionNonce],
      row[columnName],
      row[columnEncryptedName],
      row[columnNameDecryptionNonce],
      Collection.typeFromString(row[columnType]),
      CollectionAttributes(
          encryptedPath: row[columnEncryptedPath],
          pathDecryptionNonce: row[columnPathDecryptionNonce]),
      List<User>.from((json.decode(row[columnSharees]) as List)
          .map((x) => User.fromMap(x))),
      int.parse(row[columnUpdationTime]),
    );
  }
}
