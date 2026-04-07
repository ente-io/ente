import "dart:convert" show jsonDecode, jsonEncode;
import "dart:io" show File;
import "dart:math" show min;
import "dart:typed_data" show Float32List, Float64List;

import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/db_pet_model_mappers.dart";
import "package:photos/db/ml/pet_cluster_centroid_vector_db.dart";
import "package:photos/db/ml/pet_vector_db.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/src/rust/api/ml_indexing_api.dart";
import "package:photos/utils/ml_util.dart" show computeL2MeanCentroid;
import "package:synchronized/synchronized.dart";
import "package:uuid/uuid.dart";

final _logger = Logger("PetClusteringService");

/// Orchestrates pet clustering by reading indexed pet data from the DB,
/// fetching embeddings from the vector DB, calling the Rust 3-phase
/// clustering engine, and storing the results.
class PetClusteringService {
  PetClusteringService._();
  static final instance = PetClusteringService._();

  final Lock _clusterLock = Lock();

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

      final faceVdb = PetVectorDB.forModel(
        species: species,
        isFace: true,
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
        } catch (e) {
          _logger.warning("Failed to get embedding for ${face.petFaceId}: $e");
          continue;
        }

        inputs.add({
          "petFaceId": face.petFaceId,
          "faceEmbedding": faceEmb,
          "bodyEmbedding": <double>[],
          "fileId": face.fileId,
        });
      }

      // Read existing cluster assignments for this species only
      final clusters = <String, String>{};
      final sqlDb = await mlDataDB.asyncDB;
      final rows = await sqlDb.getAll(
        'SELECT fc.$petFaceIDColumn, fc.$clusterIDColumn '
        'FROM $petFaceClustersTable fc '
        'INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn '
        'WHERE f.$speciesColumn = ?',
        [species],
      );
      for (final row in rows) {
        clusters[row[petFaceIDColumn] as String] =
            row[clusterIDColumn] as String;
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
  /// Returns `true` if any assignments or summaries were changed.
  Future<bool> clusterPets({
    required MLDataDB mlDataDB,
    bool isOffline = false,
  }) async {
    return _clusterLock.synchronized(() async {
      try {
        final unclusteredCount =
            await mlDataDB.getUnclusteredPetFaceCount(isOffline: isOffline);
        if (unclusteredCount == 0) {
          _logger.info("No unclustered pet faces, skipping");
          return false;
        }
        _logger.info("Starting pet clustering: $unclusteredCount unclustered");

        bool changed = false;
        for (final species in [0, 1]) {
          final speciesChanged = await _clusterSpecies(
            species: species,
            mlDataDB: mlDataDB,
            isOffline: isOffline,
          );
          changed = changed || speciesChanged;
        }
        return changed;
      } catch (e, s) {
        _logger.severe("Pet clustering failed", e, s);
        return false;
      }
    });
  }

  Future<bool> _clusterSpecies({
    required int species,
    required MLDataDB mlDataDB,
    required bool isOffline,
  }) async {
    final speciesName = species == 0 ? "dog" : "cat";
    _logger.info("Clustering $speciesName faces...");

    // 1. Read all pet faces for this species (lightweight metadata only)
    final faces =
        await mlDataDB.getPetFacesForClustering(species, isOffline: isOffline);
    if (faces.isEmpty) {
      _logger.info("No $speciesName faces to cluster");
      return false;
    }

    // 2. Build lightweight metadata — no embeddings cross FFI
    final allMetas = <RustPetFaceMeta>[];
    final unclusteredMetas = <RustPetFaceMeta>[];
    for (final face in faces) {
      if (face.faceVectorId == null) continue;
      final meta = RustPetFaceMeta(
        petFaceId: face.petFaceId,
        vectorId: face.faceVectorId!,
        species: species,
        fileId: face.fileId,
        clusterId: face.clusterId ?? "",
      );
      allMetas.add(meta);
      if (face.clusterId == null) {
        unclusteredMetas.add(meta);
      }
    }

    // 3. Get usearch index path — Rust reads embeddings directly
    final faceVdb = PetVectorDB.forModel(
      species: species,
      isFace: true,
      offline: isOffline,
    );
    final faceIndexPath = await faceVdb.getIndexPath();

    // 4. Check for existing clusters (incremental mode)
    final existingSummaries =
        await mlDataDB.getAllPetClusterSummary(species: species);

    late RustPetClusterResult result;

    if (existingSummaries.isEmpty) {
      // Batch mode — first run, cluster all faces
      if (allMetas.length < 2) {
        _logger.info("Not enough $speciesName faces to cluster "
            "(${allMetas.length})");
        return false;
      }
      _logger.info(
        "Batch clustering ${allMetas.length} $speciesName faces",
      );
      result = await runPetClusteringFromIndex(
        faces: allMetas,
        faceIndexPath: faceIndexPath,
        species: species,
      );
    } else {
      // Incremental mode — use exemplar matching (F1=0.96)
      if (unclusteredMetas.isEmpty) {
        _logger.info("No unclustered $speciesName faces, skipping");
        return false;
      }
      _logger.info(
        "Exemplar-incremental clustering ${unclusteredMetas.length} new "
        "$speciesName faces (${existingSummaries.length} existing clusters)",
      );

      // Load stored exemplars
      final exemplarsJsonMap =
          await mlDataDB.getClusterExemplarsJson(species: species);

      final clusterExemplars = <RustClusterExemplars>[];
      for (final entry in exemplarsJsonMap.entries) {
        final List<dynamic> parsed = jsonDecode(entry.value) as List<dynamic>;
        final exemplars = parsed
            .map(
              (e) => Float64List.fromList(
                (e as List<dynamic>).map((v) => (v as num).toDouble()).toList(),
              ),
            )
            .toList();
        clusterExemplars.add(
          RustClusterExemplars(
            clusterId: entry.key,
            exemplars: exemplars,
          ),
        );
      }

      if (clusterExemplars.isEmpty) {
        // No exemplars stored yet — fall back to batch
        _logger.info("No exemplars found, falling back to batch");
        result = await runPetClusteringFromIndex(
          faces: allMetas,
          faceIndexPath: faceIndexPath,
          species: species,
        );
      } else {
        result = await runPetClusteringIncrementalExemplarsFromIndex(
          newFaces: unclusteredMetas,
          faceIndexPath: faceIndexPath,
          clusterExemplars: clusterExemplars,
          species: species,
        );
      }
    }

    // 5. Store results — respect user feedback
    final faceToCluster = <String, String>{};
    for (final assignment in result.assignments) {
      faceToCluster[assignment.petFaceId] = assignment.clusterId;
    }

    // Online mode preserves user corrections by honoring rejected assignments.
    // Offline mode is view-only raw clustering output.
    if (faceToCluster.isNotEmpty) {
      if (!isOffline) {
        final allRejected = await mlDataDB.getBulkRejectedPetFaceIds(
          faceToCluster.values.toSet(),
        );
        if (allRejected.isNotEmpty) {
          for (final entry in faceToCluster.entries.toList()) {
            final rejected = allRejected[entry.value];
            if (rejected != null && rejected.contains(entry.key)) {
              faceToCluster[entry.key] = const Uuid().v4();
            }
          }
        }
      }
      await mlDataDB.updatePetFaceIdToClusterId(faceToCluster);
    }

    // 6. Use Rust-returned centroids for clusters it created/modified.
    // For clusters Rust didn't touch (e.g. incremental mode existing clusters),
    // recompute from the VDB.
    final rustCentroids = <String, Float32List>{};
    for (final s in result.summaries) {
      if (s.centroid.isNotEmpty) {
        rustCentroids[s.clusterId] = _doublesToFloat32(s.centroid);
      }
    }

    final dbClusterToFaces = await mlDataDB.getPetClusterToFaceIds(species);
    final clusterSummaries = <String, (int, int)>{};
    final clusterCentroids = <String, Float32List>{};

    for (final entry in dbClusterToFaces.entries) {
      clusterSummaries[entry.key] = (entry.value.length, species);
      // Use Rust's centroid if available, otherwise recompute from VDB
      final rustCentroid = rustCentroids[entry.key];
      if (rustCentroid != null) {
        clusterCentroids[entry.key] = rustCentroid;
      } else {
        final centroid = await _computeCentroidFromVdb(
          entry.value,
          mlDataDB,
          faceVdb,
        );
        if (centroid != null) {
          clusterCentroids[entry.key] = centroid;
        }
      }
    }

    // Delete existing summaries for clusters that no longer have any face
    // assignments in the DB.
    final activeClusterIds = await mlDataDB.getActivePetClusterIds(species);
    final staleIds = existingSummaries.keys
        .where((id) => !activeClusterIds.contains(id))
        .toList();
    if (staleIds.isNotEmpty) {
      await mlDataDB.deletePetClusterSummaries(staleIds);
    }

    if (clusterSummaries.isNotEmpty) {
      // Build exemplars JSON from Rust result
      final exemplarsJson = <String, String>{};
      for (final es in result.exemplarSummaries) {
        if (es.exemplars.isNotEmpty) {
          exemplarsJson[es.clusterId] = jsonEncode(
            es.exemplars.map((e) => e.toList()).toList(),
          );
        }
      }

      await mlDataDB.petClusterSummaryUpdate(
        clusterSummaries,
        exemplarsJson: exemplarsJson.isNotEmpty ? exemplarsJson : null,
      );
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
    return faceToCluster.isNotEmpty || clusterSummaries.isNotEmpty;
  }

  /// Compute L2-normalized mean centroid for a cluster by reading embeddings
  /// from the vector DB. Used for clusters Rust didn't return centroids for.
  static Future<Float32List?> _computeCentroidFromVdb(
    List<String> faceIds,
    MLDataDB mlDataDB,
    PetVectorDB faceVdb,
  ) async {
    final details = await mlDataDB.getPetFaceDetails(faceIds);
    final vectorIds = <int>[];
    for (final d in details.values) {
      if (d.$2 != null) vectorIds.add(d.$2!);
    }
    if (vectorIds.isEmpty) return null;
    try {
      final embs = await faceVdb.getEmbeddings(vectorIds);
      if (embs.isEmpty) return null;
      return computeL2MeanCentroid(embs);
    } catch (e) {
      return null;
    }
  }

  static Float32List _doublesToFloat32(List<double> values) {
    final floats = Float32List(values.length);
    for (int i = 0; i < values.length; i++) {
      floats[i] = values[i];
    }
    return floats;
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

  /// Update pet cluster summaries (count + species + exemplars) in SQLite.
  Future<void> petClusterSummaryUpdate(
    Map<String, (int count, int species)> summaries, {
    Map<String, String>? exemplarsJson,
  }) async {
    if (summaries.isEmpty) return;
    final db = await asyncDB;
    const String sql = '''
      INSERT INTO $petClusterSummaryTable ($clusterIDColumn, $countColumn, $speciesColumn, $exemplarsColumn)
      VALUES (?, ?, ?, ?)
      ON CONFLICT($clusterIDColumn) DO UPDATE SET
        $countColumn = excluded.$countColumn,
        $speciesColumn = excluded.$speciesColumn,
        $exemplarsColumn = excluded.$exemplarsColumn
    ''';
    const batchSize = 400;
    final entries = summaries.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, min(i + batchSize, entries.length));
      final params = batch
          .map(
            (e) => [e.key, e.value.$1, e.value.$2, exemplarsJson?[e.key]],
          )
          .toList();
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

  /// Get stored exemplar embeddings for all clusters of a species.
  Future<Map<String, String>> getClusterExemplarsJson({
    required int species,
  }) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT $clusterIDColumn, $exemplarsColumn FROM $petClusterSummaryTable '
      'WHERE $speciesColumn = ? AND $exemplarsColumn IS NOT NULL',
      [species],
    );
    final result = <String, String>{};
    for (final r in rows) {
      result[r[clusterIDColumn] as String] = r[exemplarsColumn] as String;
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

  /// Remove a cluster's pet mapping (unmerge).
  Future<void> removeClusterPetId(String clusterId) async {
    final db = await asyncDB;
    await db.execute(
      'DELETE FROM $petClusterPetTable WHERE $clusterIDColumn = ?',
      [clusterId],
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

  /// Get petId to {clusterId to Set of faceIds} for reconciliation.
  Future<Map<String, Map<String, Set<String>>>>
      getPetToClusterIdToFaceIds() async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT pcp.$petIdColumn, fc.$clusterIDColumn, fc.$petFaceIDColumn '
      'FROM $petClusterPetTable pcp '
      'INNER JOIN $petFaceClustersTable fc '
      'ON pcp.$clusterIDColumn = fc.$clusterIDColumn',
    );
    final result = <String, Map<String, Set<String>>>{};
    for (final r in rows) {
      final petId = r[petIdColumn] as String;
      final clusterId = r[clusterIDColumn] as String;
      final faceId = r[petFaceIDColumn] as String;
      result
          .putIfAbsent(petId, () => {})
          .putIfAbsent(clusterId, () => {})
          .add(faceId);
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

  /// Remove "not this pet" feedback for faces being moved to a cluster.
  /// This clears prior rejections so re-clustering won't eject them.
  Future<void> clearNotPetFeedback(
    String clusterId,
    List<String> petFaceIds,
  ) async {
    if (petFaceIds.isEmpty) return;
    final db = await asyncDB;
    final placeholders = List.filled(petFaceIds.length, '?').join(',');
    await db.execute(
      'DELETE FROM $notPetFeedbackTable '
      'WHERE $clusterIDColumn = ? AND $petFaceIDColumn IN ($placeholders)',
      [clusterId, ...petFaceIds],
    );
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

  /// Get all rejected petFaceIds for multiple clusters in one query.
  Future<Map<String, Set<String>>> getBulkRejectedPetFaceIds(
    Set<String> clusterIds,
  ) async {
    if (clusterIds.isEmpty) return {};
    final db = await asyncDB;
    final result = <String, Set<String>>{};
    const chunkSize = 500;
    final idList = clusterIds.toList();
    for (int i = 0; i < idList.length; i += chunkSize) {
      final chunk = idList.sublist(i, min(i + chunkSize, idList.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.getAll(
        'SELECT $clusterIDColumn, $petFaceIDColumn FROM $notPetFeedbackTable '
        'WHERE $clusterIDColumn IN ($placeholders)',
        chunk,
      );
      for (final r in rows) {
        result
            .putIfAbsent(r[clusterIDColumn] as String, () => {})
            .add(r[petFaceIDColumn] as String);
      }
    }
    return result;
  }

  /// Delete a pet cluster summary row.
  Future<void> deletePetClusterSummary(String clusterId) async {
    final db = await asyncDB;
    await db.execute(
      'DELETE FROM $petClusterSummaryTable WHERE $clusterIDColumn = ?',
      [clusterId],
    );
  }

  /// Delete multiple pet cluster summary rows in one batch.
  Future<void> deletePetClusterSummaries(List<String> clusterIds) async {
    if (clusterIds.isEmpty) return;
    final db = await asyncDB;
    final placeholders = List.filled(clusterIds.length, '?').join(',');
    await db.execute(
      'DELETE FROM $petClusterSummaryTable '
      'WHERE $clusterIDColumn IN ($placeholders)',
      clusterIds,
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

  /// Get file IDs for a single pet cluster.
  Future<List<int>> getPetFileIdsForCluster(String clusterId) async {
    final db = await asyncDB;
    final rows = await db.getAll(
      'SELECT DISTINCT f.$fileIDColumn '
      'FROM $petFaceClustersTable fc '
      'INNER JOIN $petFacesTable f ON fc.$petFaceIDColumn = f.$petFaceIDColumn '
      'WHERE fc.$clusterIDColumn = ? AND f.$speciesColumn >= 0',
      [clusterId],
    );
    return rows.map((r) => r[fileIDColumn] as int).toList();
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
