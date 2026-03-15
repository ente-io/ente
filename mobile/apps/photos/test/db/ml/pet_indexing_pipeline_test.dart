import 'dart:io';

import 'package:photos/db/ml/db_pet_model_mappers.dart';
import 'package:photos/db/ml/schema.dart';
import 'package:photos/models/ml/ml_versions.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:test/test.dart';

/// Test the pet indexing pipeline after migrating from a separate
/// `pet_indexed_files` table to dummy [DBPetFace.empty] rows in
/// `pet_faces` (matching the human face detection pattern).
void main() {
  // ── DBPetFace.empty() factory tests ──

  group('DBPetFace.empty', () {
    test('creates a dummy entry with correct default values', () {
      final dummy = DBPetFace.empty(42);

      expect(dummy.fileId, 42);
      expect(dummy.petFaceId, '42_pet_0_0_0_0');
      expect(dummy.detection, '{}');
      expect(dummy.faceVectorId, -1);
      expect(dummy.species, -1);
      expect(dummy.faceScore, 0.0);
      expect(dummy.imageHeight, 0);
      expect(dummy.imageWidth, 0);
      expect(dummy.mlVersion, petMlVersion);
    });

    test('creates an error dummy with score -1.0', () {
      final dummy = DBPetFace.empty(7, error: true);

      expect(dummy.fileId, 7);
      expect(dummy.petFaceId, '7_pet_0_0_0_0');
      expect(dummy.faceScore, -1.0);
      expect(dummy.species, -1);
      expect(dummy.mlVersion, petMlVersion);
    });

    test('dummy petFaceId does not collide with real detection IDs', () {
      // Real IDs use detection coordinates like "42_pet_0.12_0.34_0.56_0.78"
      final dummy = DBPetFace.empty(42);
      final realId = '42_pet_0.12_0.34_0.56_0.78';

      expect(dummy.petFaceId, isNot(equals(realId)));
    });
  });

  // ── toMap / fromMap roundtrip tests ──

  group('DBPetFace serialisation roundtrip', () {
    test('empty entry survives toMap/fromMap roundtrip', () {
      final original = DBPetFace.empty(99);
      final map = original.toMap();
      final restored = DBPetFace.fromMap(map);

      expect(restored.fileId, original.fileId);
      expect(restored.petFaceId, original.petFaceId);
      expect(restored.detection, original.detection);
      expect(restored.faceVectorId, original.faceVectorId);
      expect(restored.species, original.species);
      expect(restored.faceScore, original.faceScore);
      expect(restored.imageHeight, original.imageHeight);
      expect(restored.imageWidth, original.imageWidth);
      expect(restored.mlVersion, original.mlVersion);
    });

    test('real entry survives toMap/fromMap roundtrip', () {
      final original = DBPetFace(
        fileId: 10,
        petFaceId: '10_pet_0.1_0.2_0.3_0.4',
        detection: '{"box":[0.1,0.2,0.3,0.4]}',
        faceVectorId: 5,
        species: 0,
        faceScore: 0.95,
        imageHeight: 1080,
        imageWidth: 1920,
        mlVersion: petMlVersion,
      );
      final restored = DBPetFace.fromMap(original.toMap());

      expect(restored.fileId, 10);
      expect(restored.species, 0);
      expect(restored.faceScore, closeTo(0.95, 0.001));
      expect(restored.faceVectorId, 5);
    });

    test('toMap does not contain embedding column', () {
      final face = DBPetFace.empty(1);
      final map = face.toMap();

      expect(map.containsKey('pet_face_embedding'), isFalse);
    });
  });

  // ── SQLite query tests (in-memory database) ──

  group('Pet faces DB queries', () {
    late SqliteDatabase db;

    setUp(() async {
      // Create a temp file for the database since sqlite_async needs a path
      final tempDir = Directory.systemTemp.createTempSync('pet_test_');
      final dbPath = '${tempDir.path}/test_pet.db';
      db = SqliteDatabase(path: dbPath);

      // Run pet-related schema migrations
      await db.writeTransaction((tx) async {
        await tx.execute(createPetFacesTable);
      });
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> insertPetFace(DBPetFace face) async {
      final map = face.toMap();
      await db.execute(
        '''INSERT INTO $petFacesTable (
          $fileIDColumn, $petFaceIDColumn, $faceDetectionColumn,
          $faceVectorIdColumn, $speciesColumn, $faceScore,
          $imageHeight, $imageWidth, $mlVersionColumn
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT($fileIDColumn, $petFaceIDColumn) DO UPDATE SET
          $faceDetectionColumn = excluded.$faceDetectionColumn,
          $faceVectorIdColumn = excluded.$faceVectorIdColumn,
          $speciesColumn = excluded.$speciesColumn,
          $faceScore = excluded.$faceScore,
          $imageHeight = excluded.$imageHeight,
          $imageWidth = excluded.$imageWidth,
          $mlVersionColumn = excluded.$mlVersionColumn
        ''',
        [
          map[fileIDColumn],
          map[petFaceIDColumn],
          map[faceDetectionColumn],
          map[faceVectorIdColumn],
          map[speciesColumn],
          map['score'],
          map['height'],
          map['width'],
          map[mlVersionColumn],
        ],
      );
    }

    // ── petIndexedFileIds (should include dummies) ──

    test('petIndexedFileIds includes dummy entries', () async {
      await insertPetFace(DBPetFace.empty(1));
      await insertPetFace(DBPetFace.empty(2, error: true));

      final rows = await db.getAll(
        'SELECT $fileIDColumn, $mlVersionColumn FROM $petFacesTable '
        'WHERE $mlVersionColumn >= $petMlVersion',
      );

      final indexed = {for (final r in rows) r[fileIDColumn] as int};
      expect(indexed, contains(1));
      expect(indexed, contains(2));
    });

    // ── getPetFacesForFileID (should exclude dummies) ──

    test('getPetFacesForFileID excludes dummy entries', () async {
      // Insert a dummy and a real face for the same file
      await insertPetFace(DBPetFace.empty(10));
      await insertPetFace(
        DBPetFace(
          fileId: 10,
          petFaceId: '10_pet_0.1_0.2_0.3_0.4',
          detection: '{"box":[0.1,0.2,0.3,0.4]}',
          faceVectorId: 5,
          species: 0,
          faceScore: 0.92,
          imageHeight: 1080,
          imageWidth: 1920,
          mlVersion: petMlVersion,
        ),
      );

      // Query with species filter (matches production query)
      final rows = await db.getAll(
        'SELECT * FROM $petFacesTable '
        'WHERE $fileIDColumn = ? AND $speciesColumn != -1',
        [10],
      );

      expect(rows.length, 1);
      final face = DBPetFace.fromMap(rows.first);
      expect(face.petFaceId, '10_pet_0.1_0.2_0.3_0.4');
      expect(face.species, 0);
    });

    test('getPetFacesForFileID returns null-equivalent for dummy-only files',
        () async {
      await insertPetFace(DBPetFace.empty(20));

      final rows = await db.getAll(
        'SELECT * FROM $petFacesTable '
        'WHERE $fileIDColumn = ? AND $speciesColumn != -1',
        [20],
      );

      expect(rows, isEmpty);
    });

    // ── getPetIndexedFileCount (DISTINCT, includes dummies) ──

    test('getPetIndexedFileCount counts distinct files including dummies',
        () async {
      // File 1: dummy only
      await insertPetFace(DBPetFace.empty(1));
      // File 2: two real faces
      await insertPetFace(
        DBPetFace(
          fileId: 2,
          petFaceId: '2_pet_a',
          detection: '{"box":[0.1,0.2,0.3,0.4]}',
          faceVectorId: 1,
          species: 0,
          faceScore: 0.9,
          imageHeight: 100,
          imageWidth: 100,
          mlVersion: petMlVersion,
        ),
      );
      await insertPetFace(
        DBPetFace(
          fileId: 2,
          petFaceId: '2_pet_b',
          detection: '{"box":[0.5,0.6,0.7,0.8]}',
          faceVectorId: 2,
          species: 1,
          faceScore: 0.85,
          imageHeight: 100,
          imageWidth: 100,
          mlVersion: petMlVersion,
        ),
      );

      final countRows = await db.getAll(
        'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $petFacesTable '
        'WHERE $mlVersionColumn >= $petMlVersion',
      );

      expect(countRows.first['count'], 2);
    });

    // ── ON CONFLICT: dummy replaced when same ID re-inserted ──

    test('re-indexing same file replaces dummy via ON CONFLICT', () async {
      // Initial: no pets found
      await insertPetFace(DBPetFace.empty(30));

      var rows = await db.getAll(
        'SELECT * FROM $petFacesTable WHERE $fileIDColumn = ?',
        [30],
      );
      expect(rows.length, 1);
      expect(DBPetFace.fromMap(rows.first).species, -1);

      // Re-index with same dummy ID (e.g. mlVersion bump, still no pets)
      await insertPetFace(DBPetFace.empty(30));

      rows = await db.getAll(
        'SELECT * FROM $petFacesTable WHERE $fileIDColumn = ?',
        [30],
      );
      // ON CONFLICT should update, not duplicate
      expect(rows.length, 1);
    });

    // ── Coexistence: dummy + real faces for same file ──

    test('dummy and real faces coexist for the same file', () async {
      await insertPetFace(DBPetFace.empty(40));
      await insertPetFace(
        DBPetFace(
          fileId: 40,
          petFaceId: '40_pet_0.2_0.3_0.6_0.7',
          detection: '{"box":[0.2,0.3,0.6,0.7]}',
          faceVectorId: 3,
          species: 1,
          faceScore: 0.88,
          imageHeight: 720,
          imageWidth: 1280,
          mlVersion: petMlVersion,
        ),
      );

      // All rows (for indexing tracking)
      final allRows = await db.getAll(
        'SELECT * FROM $petFacesTable WHERE $fileIDColumn = ?',
        [40],
      );
      expect(allRows.length, 2);

      // Filtered rows (for UI display)
      final realRows = await db.getAll(
        'SELECT * FROM $petFacesTable '
        'WHERE $fileIDColumn = ? AND $speciesColumn != -1',
        [40],
      );
      expect(realRows.length, 1);
      expect(DBPetFace.fromMap(realRows.first).species, 1);
    });

    // ── Delete cleans up both dummy and real entries ──

    test('deletePetDataForFiles removes dummy and real entries', () async {
      await insertPetFace(DBPetFace.empty(50));
      await insertPetFace(
        DBPetFace(
          fileId: 50,
          petFaceId: '50_pet_real',
          detection: '{"box":[0.1,0.2,0.3,0.4]}',
          faceVectorId: 1,
          species: 0,
          faceScore: 0.9,
          imageHeight: 100,
          imageWidth: 100,
          mlVersion: petMlVersion,
        ),
      );

      await db.execute(
        'DELETE FROM $petFacesTable WHERE $fileIDColumn IN (50)',
      );

      final rows = await db.getAll(
        'SELECT * FROM $petFacesTable WHERE $fileIDColumn = ?',
        [50],
      );
      expect(rows, isEmpty);
    });

    // ── Error dummy (-1 score) is still tracked as indexed ──

    test('error dummy entries are tracked as indexed', () async {
      await insertPetFace(DBPetFace.empty(60, error: true));

      final rows = await db.getAll(
        'SELECT $fileIDColumn FROM $petFacesTable '
        'WHERE $mlVersionColumn >= $petMlVersion',
      );

      expect(rows.length, 1);
      expect(rows.first[fileIDColumn], 60);
    });

    // ── Error dummies are excluded from UI queries ──

    test('error dummy entries are excluded from UI queries', () async {
      await insertPetFace(DBPetFace.empty(60, error: true));

      final rows = await db.getAll(
        'SELECT * FROM $petFacesTable '
        'WHERE $fileIDColumn = ? AND $speciesColumn != -1',
        [60],
      );

      expect(rows, isEmpty);
    });

    // ── Vector ID mapping: faceVectorId tracks vector DB entry ──

    test('faceVectorId is stored and retrievable', () async {
      await insertPetFace(
        DBPetFace(
          fileId: 70,
          petFaceId: '70_pet_real',
          detection: '{"box":[0.1,0.2,0.3,0.4]}',
          faceVectorId: 42,
          species: 0,
          faceScore: 0.9,
          imageHeight: 100,
          imageWidth: 100,
          mlVersion: petMlVersion,
        ),
      );

      final rows = await db.getAll(
        'SELECT $faceVectorIdColumn FROM $petFacesTable '
        'WHERE $petFaceIDColumn = ?',
        ['70_pet_real'],
      );

      expect(rows.first[faceVectorIdColumn], 42);
    });

    test('faceVectorId can be updated after initial insert', () async {
      // Insert with placeholder vectorId = -1
      await insertPetFace(
        DBPetFace(
          fileId: 80,
          petFaceId: '80_pet_real',
          detection: '{"box":[0.1,0.2,0.3,0.4]}',
          faceVectorId: -1,
          species: 1,
          faceScore: 0.85,
          imageHeight: 100,
          imageWidth: 100,
          mlVersion: petMlVersion,
        ),
      );

      // Simulate updatePetFaceVectorIds
      await db.execute(
        'UPDATE $petFacesTable SET $faceVectorIdColumn = ? '
        'WHERE $petFaceIDColumn = ?',
        [99, '80_pet_real'],
      );

      final rows = await db.getAll(
        'SELECT $faceVectorIdColumn FROM $petFacesTable '
        'WHERE $petFaceIDColumn = ?',
        ['80_pet_real'],
      );

      expect(rows.first[faceVectorIdColumn], 99);
    });
  });
}
