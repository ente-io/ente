import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';

class CollectionsDB {
  static final _databaseName = "ente.collections.db";
  static final table = 'collections';
  static final tempTable = 'temp_collections';

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
  static final columnVersion = 'version';
  static final columnSharees = 'sharees';
  static final columnUpdationTime = 'updation_time';

  static final intitialScript = [...createTable(table)];
  static final migrationScripts = [
    ...alterNameToAllowNULL(),
    ...addEncryptedName(),
    ...addVersion(),
  ];

  final dbConfig = MigrationConfig(
      initializationScript: intitialScript, migrationScripts: migrationScripts);

  CollectionsDB._privateConstructor();
  static final CollectionsDB instance = CollectionsDB._privateConstructor();

  static Future<Database> _dbFuture;

  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabaseWithMigration(path, dbConfig);
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(table);
  }

  static List<String> createTable(String tableName) {
    return [
      '''
        CREATE TABLE $tableName (
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
    '''
    ];
  }

  static List<String> alterNameToAllowNULL() {
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

  static List<String> addEncryptedName() {
    return [
      '''
        ALTER TABLE $table
        ADD COLUMN $columnEncryptedName TEXT;
      ''',
      '''ALTER TABLE $table
        ADD COLUMN $columnNameDecryptionNonce TEXT;
      '''
    ];
  }

  static List<String> addVersion() {
    return [
      '''
        ALTER TABLE $table
        ADD COLUMN $columnVersion INTEGER DEFAULT 0;
      '''
    ];
  }

  Future<List<dynamic>> insert(List<Collection> collections) async {
    final db = await instance.database;
    var batch = db.batch();
    for (final collection in collections) {
      batch.insert(table, _getRowForCollection(collection),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return await batch.commit();
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await instance.database;
    final rows = await db.query(table);
    final collections = <Collection>[];
    for (final row in rows) {
      collections.add(_convertToCollection(row));
    }
    return collections;
  }

  Future<int> getLastCollectionUpdationTime() async {
    final db = await instance.database;
    final rows = await db.query(
      table,
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
      table,
      where: '$columnID = ?',
      whereArgs: [collectionID],
    );
  }

  Map<String, dynamic> _getRowForCollection(Collection collection) {
    var row = <String, dynamic>{};
    row[columnID] = collection.id;
    row[columnOwner] = collection.owner.toJson();
    row[columnEncryptedKey] = collection.encryptedKey;
    row[columnKeyDecryptionNonce] = collection.keyDecryptionNonce;
    row[columnName] = collection.name;
    row[columnEncryptedName] = collection.encryptedName;
    row[columnNameDecryptionNonce] = collection.nameDecryptionNonce;
    row[columnType] = Collection.typeToString(collection.type);
    row[columnEncryptedPath] = collection.attributes.encryptedPath;
    row[columnPathDecryptionNonce] = collection.attributes.pathDecryptionNonce;
    row[columnVersion] = collection.attributes.version;
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
        pathDecryptionNonce: row[columnPathDecryptionNonce],
        version: row[columnVersion],
      ),
      List<User>.from((json.decode(row[columnSharees]) as List)
          .map((x) => User.fromMap(x))),
      int.parse(row[columnUpdationTime]),
    );
  }
}
