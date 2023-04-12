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
    debugPrint("Inserting missing PathIDToLocalIDMapping");
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (LocalEntityData e in data) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        "entities",
        e.toJson(),
        conflictAlgorithm: conflictAlgorithm,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteEntities(
    List<String> ids,
  ) async {
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (String id in ids) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.delete(
        "entities",
        where: "id = ?",
        whereArgs: [id],
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
  }

  Future<List<LocalEntityData>> getEntities(EntityType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      "entities",
      where: "type = ?",
      whereArgs: [type.typeToString()],
    );
    return List.generate(maps.length, (i) {
      return LocalEntityData.fromJson(maps[i]);
    });
  }
}
