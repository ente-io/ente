import 'package:flutter/foundation.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/local_entity_data.dart";
import 'package:sqflite/sqlite_api.dart';

extension EntitiesDB on FilesDB {
  Future<void> upsertEntities(
    List<LocalEntityData> data, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    debugPrint("entitiesDB: upsertEntities ${data.length} entities");
    final db = await sqliteAsyncDB;
    final parameterSets = <List<Object?>>[];
    int batchCounter = 0;
    for (LocalEntityData e in data) {
      parameterSets.add([
        e.id,
        e.type.name,
        e.ownerID,
        e.data,
        e.updatedAt,
      ]);
      batchCounter++;

      if (batchCounter == 400) {
        await db.executeBatch(
          '''
          INSERT OR ${conflictAlgorithm.name.toUpperCase()} 
          INTO entities (id, type, ownerID, data, updatedAt)
          VALUES (?, ?, ?, ?, ?)
''',
          parameterSets,
        );
        parameterSets.clear();
        batchCounter = 0;
      }
    }
    await db.executeBatch(
      '''
          INSERT OR ${conflictAlgorithm.name.toUpperCase()} 
          INTO entities (id, type, ownerID, data, updatedAt)
          VALUES (?, ?, ?, ?, ?)
''',
      parameterSets,
    );
  }

  Future<void> deleteEntities(
    List<String> ids,
  ) async {
    final db = await sqliteAsyncDB;
    final parameterSets = <List<Object?>>[];
    int batchCounter = 0;
    for (String id in ids) {
      parameterSets.add(
        [id],
      );
      batchCounter++;

      if (batchCounter == 400) {
        await db.executeBatch(
          '''
            DELETE FROM entities WHERE id = ?
          ''',
          parameterSets,
        );
        parameterSets.clear();
        batchCounter = 0;
      }
    }
    await db.executeBatch(
      '''
            DELETE FROM entities WHERE id = ?
          ''',
      parameterSets,
    );
  }

  Future<List<LocalEntityData>> getEntities(EntityType type) async {
    final db = await sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT * FROM entities WHERE type = ?',
      [type.name],
    );
    return List.generate(maps.length, (i) {
      return LocalEntityData.fromJson(maps[i]);
    });
  }

  Future<LocalEntityData?> getEntity(EntityType type, String id) async {
    final db = await sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT * FROM entities WHERE type = ? AND id = ?',
      [type.name, id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return LocalEntityData.fromJson(maps.first);
  }
}
