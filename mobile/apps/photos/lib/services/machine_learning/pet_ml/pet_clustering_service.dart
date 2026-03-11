import "dart:math" show min;
import "dart:typed_data" show Float32List, Float64List, Uint8List;

import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/pet_vector_db.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/src/rust/api/ml_indexing_api.dart";

final _logger = Logger("PetClusteringService");

/// Orchestrates pet clustering by reading indexed pet data from the DB,
/// fetching embeddings from the vector DB, calling the Rust 3-phase
/// clustering engine, and storing the results.
class PetClusteringService {
  PetClusteringService._();
  static final instance = PetClusteringService._();

  bool _isRunning = false;

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

    // Build cluster inputs
    final List<RustPetClusterInput> clusterInputs = [];
    final List<String> petFaceIds = [];

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

      clusterInputs.add(
        RustPetClusterInput(
          petFaceId: face.petFaceId,
          faceEmbedding: faceEmb,
          bodyEmbedding: bodyEmb,
          species: species,
          fileId: face.fileId,
        ),
      );
      petFaceIds.add(face.petFaceId);
    }

    if (clusterInputs.length < 2) {
      _logger.info("Not enough $speciesName faces to cluster "
          "(${clusterInputs.length})");
      return;
    }

    // 5. Check for existing clusters (incremental mode)
    final existingSummaries =
        await mlDataDB.getAllPetClusterSummary(species: species);

    _logger.info(
      "Clustering ${clusterInputs.length} $speciesName faces "
      "(${existingSummaries.length} existing clusters)",
    );

    late RustPetClusterResult result;

    if (existingSummaries.isEmpty) {
      // Batch mode
      result = await runPetClusteringRust(
        inputs: clusterInputs,
        species: species,
      );
    } else {
      // Incremental mode — pass existing centroids
      final faceCentroids = existingSummaries.entries
          .map(
            (e) => RustPetClusterSummary(
              clusterId: e.key,
              centroid: _uint8ListToFloat64(e.value.$1),
              count: e.value.$2,
            ),
          )
          .toList();

      // For body centroids we'd need a separate table; for now pass empty.
      // The Rust side handles missing body centroids gracefully.
      result = await runPetClusteringIncrementalRust(
        newInputs: clusterInputs,
        existingFaceCentroids: faceCentroids,
        existingBodyCentroids: [],
        species: species,
      );
    }

    // 6. Store results
    final faceToCluster = <String, String>{};
    for (final assignment in result.assignments) {
      faceToCluster[assignment.petFaceId] = assignment.clusterId;
    }

    if (faceToCluster.isNotEmpty) {
      await mlDataDB.updatePetFaceIdToClusterId(faceToCluster);
    }

    final clusterSummaries = <String, (Uint8List, int, int)>{};
    for (final summary in result.summaries) {
      clusterSummaries[summary.clusterId] = (
        _doublesToUint8List(summary.centroid),
        summary.count,
        species,
      );
    }

    if (clusterSummaries.isNotEmpty) {
      await mlDataDB.petClusterSummaryUpdate(clusterSummaries);
    }

    _logger.info(
      "$speciesName clustering done: ${faceToCluster.length} assigned, "
      "${result.nUnclustered} unclustered, "
      "${result.summaries.length} clusters",
    );
  }

  static Float64List _uint8ListToFloat64(Uint8List bytes) {
    final f32 = Float32List.view(bytes.buffer);
    final f64 = Float64List(f32.length);
    for (int i = 0; i < f32.length; i++) {
      f64[i] = f32[i];
    }
    return f64;
  }

  static Float64List _float32ToFloat64(Float32List f32) {
    final f64 = Float64List(f32.length);
    for (int i = 0; i < f32.length; i++) {
      f64[i] = f32[i];
    }
    return f64;
  }

  static Uint8List _doublesToUint8List(List<double> values) {
    final floats = Float32List(values.length);
    for (int i = 0; i < values.length; i++) {
      floats[i] = values[i];
    }
    return floats.buffer.asUint8List();
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

  /// Update pet cluster summaries (centroid + count + species).
  Future<void> petClusterSummaryUpdate(
    Map<String, (Uint8List, int, int)> summaries,
  ) async {
    if (summaries.isEmpty) return;
    final db = await asyncDB;
    const String sql = '''
      INSERT INTO $petClusterSummaryTable ($clusterIDColumn, $avgColumn, $countColumn, $speciesColumn)
      VALUES (?, ?, ?, ?)
      ON CONFLICT($clusterIDColumn) DO UPDATE SET
        $avgColumn = excluded.$avgColumn,
        $countColumn = excluded.$countColumn,
        $speciesColumn = excluded.$speciesColumn
    ''';
    const batchSize = 400;
    final entries = summaries.entries.toList();
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(i, min(i + batchSize, entries.length));
      final params = batch
          .map((e) => [e.key, e.value.$1, e.value.$2, e.value.$3])
          .toList();
      await db.executeBatch(sql, params);
    }
  }

  /// Get all existing pet cluster summaries, optionally filtered by species.
  Future<Map<String, (Uint8List, int)>> getAllPetClusterSummary({
    int? species,
  }) async {
    final db = await asyncDB;
    final where =
        species != null ? ' WHERE $speciesColumn = $species' : '';
    final rows = await db.getAll(
      'SELECT * FROM $petClusterSummaryTable$where',
    );
    final result = <String, (Uint8List, int)>{};
    for (final r in rows) {
      result[r[clusterIDColumn] as String] = (
        r[avgColumn] as Uint8List,
        r[countColumn] as int,
      );
    }
    return result;
  }
}
