import 'dart:io';

import 'package:photos/db/ml/schema.dart';
import 'package:photos/models/ml/pet/pet_entity.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

void main() {
  // ── PetEntity model tests ──

  group('PetEntity', () {
    test('toMap/fromMap roundtrip', () {
      const pet = PetEntity(id: 'pet-1', name: 'Buddy', species: 0);
      final restored = PetEntity.fromMap(pet.toMap());

      expect(restored.id, 'pet-1');
      expect(restored.name, 'Buddy');
      expect(restored.species, 0);
    });

    test('copyWith updates name only', () {
      const pet = PetEntity(id: 'pet-1', name: 'Buddy', species: 0);
      final renamed = pet.copyWith(name: 'Max');

      expect(renamed.id, 'pet-1');
      expect(renamed.name, 'Max');
      expect(renamed.species, 0);
    });

    test('copyWith updates species only', () {
      const pet = PetEntity(id: 'pet-1', name: 'Buddy', species: 0);
      final changed = pet.copyWith(species: 1);

      expect(changed.id, 'pet-1');
      expect(changed.name, 'Buddy');
      expect(changed.species, 1);
    });

    test('toMap contains expected keys', () {
      const pet = PetEntity(id: 'abc', name: 'Luna', species: 1);
      final map = pet.toMap();

      expect(map.keys, containsAll(['id', 'name', 'species']));
      expect(map.length, 3);
    });
  });

  // ── PetDB SQLite tests (using raw SqliteDatabase) ──

  group('PetDB queries', () {
    late SqliteDatabase db;
    late Directory tempDir;

    const petsTable = 'pets';

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('pet_db_test_');
      final dbPath = '${tempDir.path}/test_pets.db';
      db = SqliteDatabase(path: dbPath);
      await db.writeTransaction((tx) async {
        await tx.execute('''
          CREATE TABLE IF NOT EXISTS $petsTable (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL DEFAULT '',
            species INTEGER NOT NULL DEFAULT -1
          )
        ''');
      });
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> upsertPet(PetEntity pet) async {
      await db.execute(
        '''INSERT INTO $petsTable (id, name, species) VALUES (?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             name = excluded.name,
             species = excluded.species''',
        [pet.id, pet.name, pet.species],
      );
    }

    Future<PetEntity?> getPet(String id) async {
      final rows = await db.getAll(
        'SELECT * FROM $petsTable WHERE id = ?',
        [id],
      );
      if (rows.isEmpty) return null;
      return PetEntity.fromMap(rows.first);
    }

    Future<List<PetEntity>> getAllPets() async {
      final rows = await db.getAll('SELECT * FROM $petsTable');
      return rows.map(PetEntity.fromMap).toList();
    }

    test('insert and retrieve a pet', () async {
      const pet = PetEntity(id: 'p1', name: 'Buddy', species: 0);
      await upsertPet(pet);

      final result = await getPet('p1');
      expect(result, isNotNull);
      expect(result!.id, 'p1');
      expect(result.name, 'Buddy');
      expect(result.species, 0);
    });

    test('upsert updates existing pet', () async {
      const pet = PetEntity(id: 'p1', name: 'Buddy', species: 0);
      await upsertPet(pet);

      const updated = PetEntity(id: 'p1', name: 'Max', species: 0);
      await upsertPet(updated);

      final result = await getPet('p1');
      expect(result!.name, 'Max');

      final all = await getAllPets();
      expect(all.length, 1);
    });

    test('get returns null for missing pet', () async {
      final result = await getPet('nonexistent');
      expect(result, isNull);
    });

    test('getAll returns all pets', () async {
      await upsertPet(const PetEntity(id: 'p1', name: 'Buddy', species: 0));
      await upsertPet(const PetEntity(id: 'p2', name: 'Luna', species: 1));
      await upsertPet(const PetEntity(id: 'p3', name: 'Charlie', species: 0));

      final all = await getAllPets();
      expect(all.length, 3);

      final names = all.map((p) => p.name).toSet();
      expect(names, containsAll(['Buddy', 'Luna', 'Charlie']));
    });

    test('delete removes a pet', () async {
      await upsertPet(const PetEntity(id: 'p1', name: 'Buddy', species: 0));
      await db.execute('DELETE FROM $petsTable WHERE id = ?', ['p1']);

      final result = await getPet('p1');
      expect(result, isNull);
    });

    test('delete non-existent pet is a no-op', () async {
      await upsertPet(const PetEntity(id: 'p1', name: 'Buddy', species: 0));
      await db.execute('DELETE FROM $petsTable WHERE id = ?', ['p99']);

      final all = await getAllPets();
      expect(all.length, 1);
    });
  });

  // ── pet_cluster_pet mapping table tests ──

  group('pet_cluster_pet mapping', () {
    late SqliteDatabase db;
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('pet_mapping_test_');
      final dbPath = '${tempDir.path}/test_mapping.db';
      db = SqliteDatabase(path: dbPath);
      await db.writeTransaction((tx) async {
        await tx.execute(createPetClusterPetTable);
      });
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> setClusterPetId(String clusterId, String petId) async {
      await db.execute(
        '''INSERT INTO $petClusterPetTable ($clusterIDColumn, $petIdColumn)
           VALUES (?, ?)
           ON CONFLICT($clusterIDColumn) DO UPDATE SET
             $petIdColumn = excluded.$petIdColumn''',
        [clusterId, petId],
      );
    }

    Future<Map<String, String>> getClusterToPetId() async {
      final rows = await db.getAll(
        'SELECT $clusterIDColumn, $petIdColumn FROM $petClusterPetTable',
      );
      return {
        for (final r in rows)
          r[clusterIDColumn] as String: r[petIdColumn] as String,
      };
    }

    test('map a cluster to a pet', () async {
      await setClusterPetId('cluster-1', 'pet-1');

      final mappings = await getClusterToPetId();
      expect(mappings['cluster-1'], 'pet-1');
    });

    test('update mapping for existing cluster', () async {
      await setClusterPetId('cluster-1', 'pet-1');
      await setClusterPetId('cluster-1', 'pet-2');

      final mappings = await getClusterToPetId();
      expect(mappings['cluster-1'], 'pet-2');
      expect(mappings.length, 1);
    });

    test('multiple clusters map to same pet (merge)', () async {
      await setClusterPetId('cluster-1', 'pet-1');
      await setClusterPetId('cluster-2', 'pet-1');
      await setClusterPetId('cluster-3', 'pet-1');

      final mappings = await getClusterToPetId();
      expect(mappings.length, 3);
      expect(mappings.values.toSet(), {'pet-1'});
    });

    test('different clusters map to different pets', () async {
      await setClusterPetId('cluster-1', 'pet-1');
      await setClusterPetId('cluster-2', 'pet-2');

      final mappings = await getClusterToPetId();
      expect(mappings['cluster-1'], 'pet-1');
      expect(mappings['cluster-2'], 'pet-2');
    });

    test('unmerge by deleting a mapping', () async {
      await setClusterPetId('cluster-1', 'pet-1');
      await setClusterPetId('cluster-2', 'pet-1');

      await db.execute(
        'DELETE FROM $petClusterPetTable WHERE $clusterIDColumn = ?',
        ['cluster-2'],
      );

      final mappings = await getClusterToPetId();
      expect(mappings.length, 1);
      expect(mappings['cluster-1'], 'pet-1');
      expect(mappings.containsKey('cluster-2'), isFalse);
    });

    test('empty table returns empty map', () async {
      final mappings = await getClusterToPetId();
      expect(mappings, isEmpty);
    });
  });
}
