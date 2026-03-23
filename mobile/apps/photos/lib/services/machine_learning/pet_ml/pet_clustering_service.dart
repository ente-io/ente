import "dart:convert" show jsonEncode;
import "dart:io" show File;
import "dart:math" show min, sqrt;
import "dart:typed_data" show Float32List, Float64List;

import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_pet_model_mappers.dart";
import "package:photos/db/ml/pet_cluster_centroid_vector_db.dart";
import "package:photos/db/ml/pet_vector_db.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/src/rust/api/ml_indexing_api.dart";
import "package:uuid/uuid.dart";

final _logger = Logger("PetClusteringService");

/// Orchestrates pet clustering by reading indexed pet data from the DB,
/// fetching embeddings from the vector DB, calling the Rust 3-phase
/// clustering engine, and storing the results.
class PetClusteringService {
  PetClusteringService._();
  static final instance = PetClusteringService._();

  bool _isRunning = false;

  /// Export all pet face/body embeddings with cluster assignments to a JSON
  /// file for offline threshold tuning. Call from a debug menu or test.
  ///
  /// Output format: `{ "species": 0, "inputs": [...], "clusters": {...} }`
  /// where each input has petFaceId, faceEmbedding, bodyEmbedding, fileId,
  /// and clusters maps petFaceId -> clusterId.
  Future<String> dumpEmbeddingsJson({
    required MLDataDB mlDataDB,
    required String outputPath,
    bool isOffline = false,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (final species in [0, 1]) {
      final speciesName = species == 0 ? "dog" : "cat";
      final faces = await mlDataDB.getPetFacesForClustering(
        species,
        isOffline: isOffline,
      );
      if (faces.isEmpty) continue;

      final bodies = await mlDataDB.getPetBodiesForClustering(
        species,
        isOffline: isOffline,
      );
      final bodyByFileId = <int, PetBodyClusterInfo>{};
      for (final body in bodies) {
        bodyByFileId.putIfAbsent(body.fileId, () => body);
      }

      final faceVdb = PetVectorDB.forModel(
        species: species,
        isFace: true,
        offline: isOffline,
      );
      final bodyVdb = PetVectorDB.forModel(
        species: species,
        isFace: false,
        offline: isOffline,
      );

      final inputs = <Map<String, dynamic>>[];
      for (final face in faces) {
        if (face.faceVectorId == null) continue;
        List<double> faceEmb;
        try {
          final embs = await faceVdb.getEmbeddings([face.faceVectorId!]);
          if (embs.isEmpty) continue;
          faceEmb = embs.first.toList();
        } catch (_) {
          continue;
        }

        List<double> bodyEmb = [];
        final body = bodyByFileId[face.fileId];
        if (body != null && body.bodyVectorId != null) {
          try {
            final bodyEmbs = await bodyVdb.getEmbeddings([body.bodyVectorId!]);
            if (bodyEmbs.isNotEmpty) {
              bodyEmb = bodyEmbs.first.toList();
            }
          } catch (_) {}
        }

        inputs.add({
          "petFaceId": face.petFaceId,
          "faceEmbedding": faceEmb,
          "bodyEmbedding": bodyEmb,
          "fileId": face.fileId,
        });
      }

      // Read existing cluster assignments
      final clusters = <String, String>{};
      final sqlDb = await mlDataDB.asyncDB;
      final rows = await sqlDb.getAll(
        "SELECT pet_face_id, cluster_id FROM $petFaceClustersTable",
      );
      for (final row in rows) {
        clusters[row["pet_face_id"] as String] = row["cluster_id"] as String;
      }

      results.add({
        "species": species,
        "speciesName": speciesName,
        "count": inputs.length,
        "inputs": inputs,
        "clusters": clusters,
      });
    }

    final json = jsonEncode(results);
    await File(outputPath).writeAsString(json);
    _logger.info("Exported ${results.length} species groups to $outputPath");
    return outputPath;
  }

  /// Run pet clustering on all unclustered pet faces.
  ///
  /// Groups by species (dog=0, cat=1) and clusters each independently.
  /// Supports both batch (first run) and incremental (subsequent runs).
  Future<void> clusterPets({
    required MLDataDB mlDataDB,
    bool isOffline = false,
  }) async {
    if (_isRunning) {
      _logger.info("Pet clustering already running, skipping");
      return;
    }
    _isRunning = true;
    try {
      final unclusteredCount =
          await mlDataDB.getUnclusteredPetFaceCount(isOffline: isOffline);
      if (unclusteredCount == 0) {
        _logger.info("No unclustered pet faces, skipping");
        return;
      }
      _logger.info("Starting pet clustering: $unclusteredCount unclustered");

      // Get all pet faces grouped by species
      for (final species in [0, 1]) {
        await _clusterSpecies(
          species: species,
          mlDataDB: mlDataDB,
          isOffline: isOffline,
        );
      }
    } catch (e, s) {
      _logger.severe("Pet clustering failed", e, s);
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _clusterSpecies({
    required int species,
    required MLDataDB mlDataDB,
    required bool isOffline,
  }) async {
    final speciesName = species == 0 ? "dog" : "cat";
    _logger.info("Clustering $speciesName faces...");

    // 1. Read all pet faces for this species
    final faces =
        await mlDataDB.getPetFacesForClustering(species, isOffline: isOffline);
    if (faces.isEmpty) {
      _logger.info("No $speciesName faces to cluster");
      return;
    }

    // 2. Read all pet bodies for this species (for body rescue + merge)
    final bodies =
        await mlDataDB.getPetBodiesForClustering(species, isOffline: isOffline);

    // 3. Build a map from fileId to body info for pairing
    final bodyByFileId = <int, PetBodyClusterInfo>{};
    for (final body in bodies) {
      // Keep the first (highest-scoring) body per file
      bodyByFileId.putIfAbsent(body.fileId, () => body);
    }

    // 4. Fetch face embeddings from vector DB
    final faceVdb = PetVectorDB.forModel(
      species: species,
      isFace: true,
      offline: isOffline,
    );
    final bodyVdb = PetVectorDB.forModel(
      species: species,
      isFace: false,
      offline: isOffline,
    );

    // Build cluster inputs, tracking which are unclustered
    final List<RustPetClusterInput> allInputs = [];
    final List<RustPetClusterInput> unclusteredInputs = [];

    for (final face in faces) {
      if (face.faceVectorId == null) continue;

      Float64List faceEmb;
      try {
        final embs = await faceVdb.getEmbeddings([face.faceVectorId!]);
        if (embs.isEmpty) continue;
        faceEmb = _float32ToFloat64(embs.first);
      } catch (e) {
        _logger.warning("Failed to get face embedding for ${face.petFaceId}");
        continue;
      }

      // Try to get matching body embedding
      Float64List bodyEmb = Float64List(0);
      final body = bodyByFileId[face.fileId];
      if (body != null && body.bodyVectorId != null) {
        try {
          final bodyEmbs = await bodyVdb.getEmbeddings([body.bodyVectorId!]);
          if (bodyEmbs.isNotEmpty) {
            bodyEmb = _float32ToFloat64(bodyEmbs.first);
          }
        } catch (e) {
          _logger
              .warning("Failed to get body embedding for file ${face.fileId}");
        }
      }

      final input = RustPetClusterInput(
        petFaceId: face.petFaceId,
        faceEmbedding: faceEmb,
        bodyEmbedding: bodyEmb,
        species: species,
        fileId: face.fileId,
      );
      allInputs.add(input);
      if (face.clusterId == null) {
        unclusteredInputs.add(input);
      }
    }

    // 5. Check for existing clusters (incremental mode)
    final existingSummaries =
        await mlDataDB.getAllPetClusterSummary(species: species);

    late RustPetClusterResult result;

    if (existingSummaries.isEmpty) {
      // Batch mode — send all faces
      if (allInputs.length < 2) {
        _logger.info("Not enough $speciesName faces to cluster "
            "(${allInputs.length})");
        return;
      }
      _logger.info(
        "Batch clustering ${allInputs.length} $speciesName faces",
      );
      result = await runPetClusteringRust(
        inputs: allInputs,
        species: species,
      );
    } else {
      // Incremental mode — only send unclustered faces
      if (unclusteredInputs.isEmpty) {
        _logger.info("No unclustered $speciesName faces, skipping");
        return;
      }
      _logger.info(
        "Incremental clustering ${unclusteredInputs.length} new "
        "$speciesName faces (${existingSummaries.length} existing clusters)",
      );

      final centroidVdb = PetClusterCentroidVectorDB.forSpecies(
        species: species,
        offline: isOffline,
      );
      final sqlDb = await mlDataDB.asyncDB;
      final idMap = await centroidVdb.getClusterCentroidVectorIdMap(
        existingSummaries.keys,
        db: sqlDb,
      );

      final faceCentroids = <RustPetClusterSummary>[];
      if (idMap.isNotEmpty) {
        final vectorIds = <int>[];
        final clusterIds = <String>[];
        for (final entry in idMap.entries) {
          clusterIds.add(entry.key);
          vectorIds.add(entry.value);
        }
        final centroids = await centroidVdb.getCentroids(vectorIds);
        for (int i = 0; i < clusterIds.length && i < centroids.length; i++) {
          faceCentroids.add(
            RustPetClusterSummary(
              clusterId: clusterIds[i],
              centroid: _float32ToFloat64(centroids[i]),
              count: existingSummaries[clusterIds[i]]?.$1 ?? 0,
            ),
          );
        }
      }

      result = await runPetClusteringIncrementalRust(
        newInputs: unclusteredInputs,
        existingFaceCentroids: faceCentroids,
        existingBodyCentroids: [],
        species: species,
      );
    }

    // 6. Store results — respect user feedback
    final faceToCluster = <String, String>{};
    for (final assignment in result.assignments) {
      faceToCluster[assignment.petFaceId] = assignment.clusterId;
    }

    // Check not-pet feedback and override violating assignments
    if (faceToCluster.isNotEmpty) {
      final allRejected = <String, Set<String>>{};
      for (final clusterId in faceToCluster.values.toSet()) {
        final rejected = await mlDataDB.getRejectedPetFaceIds(clusterId);
        if (rejected.isNotEmpty) {
          allRejected[clusterId] = rejected;
        }
      }
      if (allRejected.isNotEmpty) {
        for (final entry in faceToCluster.entries.toList()) {
          final rejected = allRejected[entry.value];
          if (rejected != null && rejected.contains(entry.key)) {
            faceToCluster[entry.key] = const Uuid().v4();
          }
        }
      }
      await mlDataDB.updatePetFaceIdToClusterId(faceToCluster);
    }

    // Recompute summaries from the DB's actual cluster membership (after
    // the upsert), not just faceToCluster. Rust may leave some faces
    // unclustered (nUnclustered > 0), and those retain their previous DB
    // assignments which must be reflected in the summary.
    final embeddingByFaceId = <String, Float64List>{};
    for (final input in allInputs) {
      if (input.faceEmbedding.isNotEmpty) {
        embeddingByFaceId[input.petFaceId] = Float64List.fromList(
          input.faceEmbedding,
        );
      }
    }

    final dbClusterToFaces = await mlDataDB.getPetClusterToFaceIds(species);
    final clusterSummaries = <String, (int, int)>{};
    final clusterCentroids = <String, Float32List>{};
    for (final entry in dbClusterToFaces.entries) {
      final embs = <Float64List>[];
      for (final faceId in entry.value) {
        final emb = embeddingByFaceId[faceId];
        if (emb != null) embs.add(emb);
      }
      if (embs.isEmpty) continue;
      final centroid = _meanCentroid(embs);
      clusterCentroids[entry.key] = _doublesToFloat32(centroid);
      clusterSummaries[entry.key] = (entry.value.length, species);
    }

    // Delete existing summaries for clusters that no longer have any face
    // assignments in the DB.
    final activeClusterIds = await mlDataDB.getActivePetClusterIds(species);
    final staleIds = existingSummaries.keys
        .where((id) => !activeClusterIds.contains(id))
        .toList();
    for (final staleId in staleIds) {
      await mlDataDB.deletePetClusterSummary(staleId);
    }

    if (clusterSummaries.isNotEmpty) {
      await mlDataDB.petClusterSummaryUpdate(clusterSummaries);
    }

    // Write centroids to vector DB
    if (clusterCentroids.isNotEmpty) {
      final centroidVdb = PetClusterCentroidVectorDB.forSpecies(
        species: species,
        offline: isOffline,
      );
      final sqlDb = await mlDataDB.asyncDB;
      final idMap = await centroidVdb.getClusterCentroidVectorIdMap(
        clusterCentroids.keys,
        db: sqlDb,
        createIfMissing: true,
      );
      final vectorIds = <int>[];
      final centroids = <Float32List>[];
      for (final entry in clusterCentroids.entries) {
        final vectorId = idMap[entry.key];
        if (vectorId != null) {
          vectorIds.add(vectorId);
          centroids.add(entry.value);
        }
      }
      if (vectorIds.isNotEmpty) {
        await centroidVdb.bulkInsertCentroids(
          vectorIds: vectorIds,
          centroids: centroids,
        );
      }
    }

    _logger.info(
      "$speciesName clustering done: ${faceToCluster.length} assigned, "
      "${result.nUnclustered} unclustered, "
      "${result.summaries.length} clusters",
    );
  }

  static Float64List _float32ToFloat64(Float32List f32) {
    final f64 = Float64List(f32.length);
    for (int i = 0; i < f32.length; i++) {
      f64[i] = f32[i];
    }
    return f64;
  }

  static Float32List _doublesToFloat32(List<double> values) {
    final floats = Float32List(values.length);
    for (int i = 0; i < values.length; i++) {
      floats[i] = values[i];
    }
    return floats;
  }

  /// Compute the L2-normalized mean centroid of a list of embeddings.
  static List<double> _meanCentroid(List<Float64List> embeddings) {
    final dim = embeddings.first.length;
    final centroid = Float64List(dim);
    for (final emb in embeddings) {
      for (int i = 0; i < dim; i++) {
        centroid[i] += emb[i];
      }
    }
    final n = embeddings.length.toDouble();
    double norm = 0;
    for (int i = 0; i < dim; i++) {
      centroid[i] /= n;
      norm += centroid[i] * centroid[i];
    }
    norm = sqrt(norm);
    if (norm > 0) {
      for (int i = 0; i < dim; i++) {
        centroid[i] /= norm;
      }
    }
    return centroid;
  }
}

/// Lightweight holder for pet face data needed for clustering.
class PetFaceClusterInfo {
  final int fileId;
  final String petFaceId;
  final int? faceVectorId;
  final int species;
  final String? clusterId;

  PetFaceClusterInfo({
    required this.fileId,
    required this.petFaceId,
    required this.faceVectorId,
    required this.species,
    this.clusterId,
  });
}

/// Lightweight holder for pet body data needed for clustering.
class PetBodyClusterInfo {
  final int fileId;
  final String petBodyId;
  final int? bodyVectorId;
  final int species;

  PetBodyClusterInfo({
    required this.fileId,
    required this.petBodyId,
    required this.bodyVectorId,
    required this.species,
  });
}

// ── DB helper methods (extension on MLDataDB) ───────────────────────────

extension PetClusteringDB on MLDataDB {
  /// Count pet faces that don't have a cluster assignment yet.
  Future<int> getUnclusteredPetFaceCount({bool isOffline = false}) async {
    final db = await asyncDB;
    const String query = '''
      SELECT COUNT(*) as count
      FROM $petFacesTable f
      LEFT JOIN $petFaceClustersTable fc ON f.$petFaceIDColumn = fc.$petFaceIDColumn
      WHERE f.$speciesColumn >= 0
        AND f.$faceVectorIdColumn IS NOT NULL
        AND fc.$petFaceIDColumn IS NULL
    ''';
    final rows = await db.getAll(query);
    return rows.first['count'] as int;
  }

  /// Get all pet faces for a given species, with their existing cluster IDs.
  Future<List<PetFaceClusterInfo>> getPetFacesForClustering(
    int species, {
    bool isOffline = false,
  }) async {
    final db = await asyncDB;
    const String query = '''
      SELECT f.$fileIDColumn, f.$petFaceIDColumn, f.$faceVectorIdColumn,
             f.$speciesColumn, fc.$clusterIDColumn
      FROM $petFacesTable f
      LEFT JOIN $petFaceClustersTable fc ON f.$petFaceIDColumn = fc.$petFaceIDColumn
      WHERE f.$speciesColumn = ?
        AND f.$faceVectorIdColumn IS NOT NULL
      ORDER BY f.$fileIDColumn
    ''';
    final rows = await db.getAll(query, [species]);
    return rows
        .map(
          (r) => PetFaceClusterInfo(
            fileId: r[fileIDColumn] as int,
            petFaceId: r[petFaceIDColumn] as String,
            faceVectorId: r[faceVectorIdColumn] as int?,
            species: r[speciesColumn] as int,
            clusterId: r[clusterIDColumn] as String?,
          ),
        )
        .toList();
  }

  /// Get all pet bodies for a given species.
  Future<List<PetBodyClusterInfo>> getPetBodiesForClustering(
    int species, {
    bool isOffline = false,
  }) async {
    final db = await asyncDB;
    const String query = '''
      SELECT $fileIDColumn, $petBodyIDColumn, $bodyVectorIdColumn, $speciesColumn
      FROM $petBodiesTable
      WHERE $speciesColumn = ?
        AND $bodyVectorIdColumn IS NOT NULL
      ORDER BY score DESC
    ''';
    final rows = await db.getAll(query, [species]);
    return rows
        .map(
          (r) => PetBodyClusterInfo(
            fileId: r[fileIDColumn] as int,
            petBodyId: r[petBodyIDColumn] as String,
            bodyVectorId: r[bodyVectorIdColumn] as int?,
            species: r[speciesColumn] as int,
          ),
        )
        .toList();
  }

  /// Store pet face → cluster assignments.
  Future<void> updatePetFaceIdToClusterId(
    Map<String, String> faceIdToClusterId,
  ) async {
    if (faceIdToClusterId.isEmpty) return;
    final db = await asyncDB;
    const batchSize = 500;
    final entries = faceIdToClusterId.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, min(i + batchSize, entries.length));
      const String sql = '''
        INSERT INTO $petFaceClustersTable ($petFaceIDColumn, $clusterIDColumn)
        VALUES (?, ?)
        ON CONFLICT($petFaceIDColumn) DO UPDATE SET $clusterIDColumn = excluded.$clusterIDColumn
      ''';
      final params = batch.map((e) => [e.key, e.value]).toList();
      await db.executeBatch(sql, params);
    }
  }

  /// Update pet cluster summaries (count + species) in SQLite.
  Future<void> petClusterSummaryUpdate(
    Map<String, (int count, int species)> summaries,
  ) async {
    if (summaries.isEmpty) return;
    final db = await asyncDB;
    const String sql = '''
      INSERT INTO $petClusterSummaryTable ($clusterIDColumn, $countColumn, $speciesColumn)
      VALUES (?, ?, ?)
      ON CONFLICT($clusterIDColumn) DO UPDATE SET
        $countColumn = excluded.$countColumn,
        $speciesColumn = excluded.$speciesColumn
    ''';
    const batchSize = 400;
    final entries = summaries.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, min(i + batchSize, entries.length));
      final params = batch.map((e) => [e.key, e.value.$1, e.value.$2]).toList();
      await db.executeBatch(sql, params);
    }
  }

  /// Get all existing pet cluster summaries, optionally filtered by species.
  Future<Map<String, (int count, int species)>> getAllPetClusterSummary({
    int? species,
  }) async {
    final db = await asyncDB;
    final where = species != null ? ' WHERE $speciesColumn = ?' : '';
    final params = species != null ? [species] : <Object>[];
    final rows = await db.getAll(
      'SELECT * FROM $petClusterSummaryTable$where',
      params,
    );
    final result = <String, (int, int)>{};
    for (final r in rows) {
      result[r[clusterIDColumn] as String] = (
        r[countColumn] as int,
        r[speciesColumn] as int,
      );
    }
    return result;
  }

  // ── Cover face for cluster (face crops) ──

  /// Get the highest-scoring pet face in a cluster.
  Future<DBPetFace?> getCoverPetFaceForCluster(String clusterId) async {
    final db = await asyncDB;
    const String query = '''
      SELECT f.*
      FROM $petFaceClustersTable fc
      INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn
      WHERE fc.$clusterIDColumn = ?
        AND f.$speciesColumn >= 0
      ORDER BY f.$faceScore DESC
      LIMIT 1
    ''';
    final rows = await db.getAll(query, [clusterId]);
    if (rows.isEmpty) return null;
    return DBPetFace.fromMap(rows.first);
  }

  // ── Cluster → Pet mapping ──

  /// Get all cluster-to-pet-ID mappings.
  Future<Map<String, String>> getClusterToPetId() async {
    final db = await asyncDB;
    final rows = await db.getAll(
      "SELECT $clusterIDColumn, $petIdColumn FROM $petClusterPetTable",
    );
    final result = <String, String>{};
    for (final r in rows) {
      result[r[clusterIDColumn] as String] = r[petIdColumn] as String;
    }
    return result;
  }

  /// Map a cluster to a pet ID.
  Future<void> setClusterPetId(String clusterId, String petId) async {
    final db = await asyncDB;
    await db.execute(
      '''INSERT INTO $petClusterPetTable ($clusterIDColumn, $petIdColumn)
         VALUES (?, ?)
         ON CONFLICT($clusterIDColumn) DO UPDATE SET
           $petIdColumn = excluded.$petIdColumn''',
      [clusterId, petId],
    );
  }

  // ── Manual reassignment helpers ──

  /// Get petFaceIds for given fileIds within a specific cluster.
  Future<List<String>> getPetFaceIdsForFilesInCluster(
    List<int> fileIds,
    String clusterId,
  ) async {
    if (fileIds.isEmpty) return [];
    final db = await asyncDB;
    final placeholders = List.filled(fileIds.length, '?').join(',');
    final query = '''
      SELECT fc.$petFaceIDColumn
      FROM $petFaceClustersTable fc
      INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn
      WHERE fc.$clusterIDColumn = ?
        AND f.$fileIDColumn IN ($placeholders)
    ''';
    final rows = await db.getAll(query, [clusterId, ...fileIds]);
    return rows.map((r) => r[petFaceIDColumn] as String).toList();
  }

  /// Get cluster → list of petFaceIds for a given species.
  Future<Map<String, List<String>>> getPetClusterToFaceIds(
    int species,
  ) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT fc.$clusterIDColumn, fc.$petFaceIDColumn '
      'FROM $petFaceClustersTable fc '
      'INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn '
      'WHERE f.$speciesColumn = ?',
      [species],
    );
    final result = <String, List<String>>{};
    for (final r in rows) {
      result
          .putIfAbsent(r[clusterIDColumn] as String, () => [])
          .add(r[petFaceIDColumn] as String);
    }
    return result;
  }

  /// Get species and faceVectorId for given petFaceIds.
  Future<Map<String, (int species, int? vectorId)>> getPetFaceDetails(
    List<String> petFaceIds,
  ) async {
    if (petFaceIds.isEmpty) return {};
    final db = await asyncDB;
    final placeholders = List.filled(petFaceIds.length, '?').join(',');
    final rows = await db.getAll(
      'SELECT $petFaceIDColumn, $speciesColumn, $faceVectorIdColumn '
      'FROM $petFacesTable WHERE $petFaceIDColumn IN ($placeholders)',
      petFaceIds,
    );
    final result = <String, (int, int?)>{};
    for (final r in rows) {
      result[r[petFaceIDColumn] as String] = (
        r[speciesColumn] as int,
        r[faceVectorIdColumn] as int?,
      );
    }
    return result;
  }

  /// Get all distinct cluster IDs that have at least one face for a species.
  Future<Set<String>> getActivePetClusterIds(int species) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT DISTINCT fc.$clusterIDColumn '
      'FROM $petFaceClustersTable fc '
      'INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn '
      'WHERE f.$speciesColumn = ?',
      [species],
    );
    return rows.map((r) => r[clusterIDColumn] as String).toSet();
  }

  /// Get all petFaceIds assigned to a given cluster.
  Future<List<String>> getPetFaceIdsForCluster(String clusterId) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT $petFaceIDColumn FROM $petFaceClustersTable '
      'WHERE $clusterIDColumn = ?',
      [clusterId],
    );
    return rows.map((r) => r[petFaceIDColumn] as String).toList();
  }

  /// Force-update pet face cluster assignments.
  Future<void> forceUpdatePetFaceClusterIds(
    Map<String, String> petFaceIdToClusterId,
  ) async {
    if (petFaceIdToClusterId.isEmpty) return;
    final db = await asyncDB;
    const String sql = '''
      INSERT INTO $petFaceClustersTable ($petFaceIDColumn, $clusterIDColumn)
      VALUES (?, ?)
      ON CONFLICT($petFaceIDColumn) DO UPDATE SET
        $clusterIDColumn = excluded.$clusterIDColumn
    ''';
    const batchSize = 500;
    final entries = petFaceIdToClusterId.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, min(i + batchSize, entries.length));
      final params = batch.map((e) => [e.key, e.value]).toList();
      await db.executeBatch(sql, params);
    }
  }

  /// Record "not this pet" feedback.
  Future<void> bulkInsertNotPetFeedback(
    List<(String clusterId, String petFaceId)> feedback,
  ) async {
    if (feedback.isEmpty) return;
    final db = await asyncDB;
    const String sql = '''
      INSERT OR IGNORE INTO $notPetFeedbackTable
        ($clusterIDColumn, $petFaceIDColumn)
      VALUES (?, ?)
    ''';
    final params = feedback.map((e) => [e.$1, e.$2]).toList();
    await db.executeBatch(sql, params);
  }

  /// Get all rejected petFaceIds for a cluster.
  Future<Set<String>> getRejectedPetFaceIds(String clusterId) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT $petFaceIDColumn FROM $notPetFeedbackTable '
      'WHERE $clusterIDColumn = ?',
      [clusterId],
    );
    return rows.map((r) => r[petFaceIDColumn] as String).toSet();
  }

  /// Delete a pet cluster summary row.
  Future<void> deletePetClusterSummary(String clusterId) async {
    final db = await asyncDB;
    await db.execute(
      'DELETE FROM $petClusterSummaryTable WHERE $clusterIDColumn = ?',
      [clusterId],
    );
  }

  /// Reassign all pet faces in one cluster to another.
  Future<void> reassignAllPetFacesInCluster(
    String sourceClusterId,
    String targetClusterId,
  ) async {
    final db = await asyncDB;
    await db.execute(
      'UPDATE $petFaceClustersTable SET $clusterIDColumn = ? '
      'WHERE $clusterIDColumn = ?',
      [targetClusterId, sourceClusterId],
    );
  }

  /// Get a mapping from cluster ID to the list of file IDs in that cluster.
  Future<Map<String, List<int>>> getPetClusterFileIds() async {
    final db = await asyncDB;
    const String query = '''
      SELECT fc.$clusterIDColumn, f.$fileIDColumn
      FROM $petFaceClustersTable fc
      INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn
      WHERE f.$speciesColumn >= 0
      ORDER BY fc.$clusterIDColumn
    ''';
    final rows = await db.getAll(query);
    final result = <String, Set<int>>{};
    for (final r in rows) {
      final cid = r[clusterIDColumn] as String;
      final fid = r[fileIDColumn] as int;
      result.putIfAbsent(cid, () => {}).add(fid);
    }
    return result.map((k, v) => MapEntry(k, v.toList()));
  }

  /// Get all pet clusters with their file counts.
  /// Returns list of (clusterId, species, fileCount, name?).
  Future<List<(String, int, int, String?)>> getAllPetClustersWithInfo() async {
    final db = await asyncDB;
    const String query = '''
      SELECT fc.$clusterIDColumn,
             f.$speciesColumn,
             COUNT(DISTINCT f.$fileIDColumn) as file_count
      FROM $petFaceClustersTable fc
      INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn
      WHERE f.$speciesColumn >= 0
      GROUP BY fc.$clusterIDColumn
      ORDER BY file_count DESC
    ''';
    final rows = await db.getAll(query);

    // Resolve names via cluster → pet mapping + PetService
    final clusterToPetId = await getClusterToPetId();
    final petEntities = await PetService.instance.getPetsMap();
    final names = <String, String>{};
    for (final entry in clusterToPetId.entries) {
      final pet = petEntities[entry.value];
      if (pet != null && pet.data.name.isNotEmpty) {
        names[entry.key] = pet.data.name;
      }
    }

    return rows.map((r) {
      final cid = r[clusterIDColumn] as String;
      return (
        cid,
        r[speciesColumn] as int,
        r['file_count'] as int,
        names[cid],
      );
    }).toList();
  }
}
