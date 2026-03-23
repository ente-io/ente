import 'dart:io';

import 'package:photos/db/ml/schema.dart';
import 'package:photos/models/ml/pet/pet_entity.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

void main() {
  // ── PetData model tests ──

  group('PetData', () {
    test('toJson/fromJson roundtrip', () {
      final data = PetData(name: 'Buddy', species: 0);
      final restored = PetData.fromJson(data.toJson());

      expect(restored.name, 'Buddy');
      expect(restored.species, 0);
    });

    test('copyWith updates name only', () {
      final data = PetData(name: 'Buddy', species: 0);
      final renamed = data.copyWith(name: 'Max');

      expect(renamed.name, 'Max');
      expect(renamed.species, 0);
    });

    test('copyWith updates species only', () {
      final data = PetData(name: 'Buddy', species: 0);
      final changed = data.copyWith(species: 1);

      expect(changed.name, 'Buddy');
      expect(changed.species, 1);
    });

    test('toJson contains expected keys', () {
      final data = PetData(name: 'Luna', species: 1);
      final map = data.toJson();

      expect(map.keys, containsAll(['name', 'species']));
      expect(map.length, 10);
    });

    test('fromJson handles missing fields with defaults', () {
      final data = PetData.fromJson(<String, dynamic>{});

      expect(data.name, '');
      expect(data.species, -1);
    });
  });

  // ── PetEntity tests ──

  group('PetEntity', () {
    test('copyWith replaces data', () {
      final pet = PetEntity('pet-1', PetData(name: 'Buddy', species: 0));
      final updated = pet.copyWith(
        data: PetData(name: 'Max', species: 0),
      );

      expect(updated.remoteID, 'pet-1');
      expect(updated.data.name, 'Max');
    });

    test('remoteID is preserved on copyWith', () {
      final pet = PetEntity('pet-1', PetData(name: 'Buddy', species: 0));
      final copy = pet.copyWith();

      expect(copy.remoteID, 'pet-1');
      expect(copy.data.name, 'Buddy');
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
