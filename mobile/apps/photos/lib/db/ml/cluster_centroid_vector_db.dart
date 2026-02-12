import "dart:io" show File;
import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/src/rust/api/usearch_api.dart";
import "package:shared_preferences/shared_preferences.dart";

class ClusterCentroidVectorDB {
  static final Logger _logger = Logger("ClusterCentroidVectorDB");

  final String _databaseName;
  final String _migrationKey;

  static const int embeddingDimensions = 192;
  static final BigInt _embeddingDimension = BigInt.from(embeddingDimensions);

  static Logger get logger => _logger;

  ClusterCentroidVectorDB._privateConstructor(
    this._databaseName,
    this._migrationKey,
  );

  static final instance = ClusterCentroidVectorDB._privateConstructor(
    "ente.ml.vectordb.cluster_centroid.usearch",
    "cluster_centroid_vectordb_migration",
  );
  static final offlineInstance = ClusterCentroidVectorDB._privateConstructor(
    "ente.ml.offline.vectordb.cluster_centroid.usearch",
    "cluster_centroid_vectordb_migration_offline",
  );

  factory ClusterCentroidVectorDB() => instance;

  Future<VectorDb>? _vectorDbFuture;
  Future<void>? _warmupFuture;

  Future<VectorDb> get _vectorDB async {
    _vectorDbFuture ??= _initVectorDB();
    return _vectorDbFuture!;
  }

  bool? _migrationDone;

  Future<VectorDb> _initVectorDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String dbPath = join(documentsDirectory.path, _databaseName);
    _logger.info("Opening cluster centroid vector DB access: DB path $dbPath");
    final indexFile = File(dbPath);
    if (!await indexFile.exists() && await checkIfMigrationDone()) {
      _logger.severe(
        "Cluster centroid vector DB file is missing while migration is marked done. Invalidating migration state.",
      );
      await invalidateMigrationState();
    }

    late VectorDb vectorDB;
    try {
      vectorDB = VectorDb(
        filePath: dbPath,
        dimensions: _embeddingDimension,
      );
    } catch (e, s) {
      _logger.severe(
        "Could not open cluster centroid vector DB at path $dbPath",
        e,
        s,
      );
      _logger.severe("Deleting the index file and trying again");
      await deleteIndexFile();
      try {
        vectorDB = VectorDb(
          filePath: dbPath,
          dimensions: _embeddingDimension,
        );
      } catch (e, s) {
        _logger.severe(
          "Still can't open cluster centroid vector DB at path $dbPath",
          e,
          s,
        );
        rethrow;
      }
    }

    final stats = await getIndexStats(vectorDB);
    _logger.info(
      "Cluster centroid vector DB connection opened with stats: ${stats.toString()}",
    );

    return vectorDB;
  }

  Future<bool> checkIfMigrationDone() async {
    if (_migrationDone != null) return _migrationDone!;
    _logger.info("Checking if cluster centroid vector DB migration has run");
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool(_migrationKey) ?? false;
    if (migrationDone) {
      _logger.info("Cluster centroid vector DB migration already done");
      _migrationDone = true;
      return _migrationDone!;
    } else {
      _logger.info("Cluster centroid vector DB migration not done");
      _migrationDone = false;
      return _migrationDone!;
    }
  }

  Future<void> setMigrationDone() async {
    _logger.info("Setting cluster centroid vector DB migration done");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    _migrationDone = true;
  }

  Future<void> invalidateMigrationState() async {
    _logger.info("Invalidating cluster centroid vector DB migration state");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, false);
    _migrationDone = false;
  }

  Future<void> insertCentroid({
    required int clusterVectorID,
    required List<double> centroid,
  }) async {
    final db = await _vectorDB;
    try {
      await db.addVector(key: BigInt.from(clusterVectorID), vector: centroid);
    } catch (e, s) {
      _logger.severe("Error inserting cluster centroid", e, s);
      rethrow;
    }
  }

  Future<void> bulkInsertCentroids({
    required List<int> clusterVectorIDs,
    required List<Float32List> centroids,
  }) async {
    if (clusterVectorIDs.isEmpty || centroids.isEmpty) {
      return;
    }
    final db = await _vectorDB;
    try {
      await db.bulkAddVectors(
        keys: Uint64List.fromList(clusterVectorIDs),
        vectors: centroids,
      );
    } catch (e, s) {
      _logger.severe("Error bulk inserting cluster centroids", e, s);
      rethrow;
    }
  }

  Future<void> deleteCentroids(List<int> clusterVectorIDs) async {
    if (clusterVectorIDs.isEmpty) {
      return;
    }
    final db = await _vectorDB;
    try {
      final deletedCount = await db.bulkRemoveVectors(
        keys: Uint64List.fromList(clusterVectorIDs),
      );
      _logger.info(
        "Deleted $deletedCount centroids from ${clusterVectorIDs.length} keys",
      );
    } catch (e, s) {
      _logger.severe("Error bulk deleting specific centroids", e, s);
      rethrow;
    }
  }

  Future<void> deleteAllCentroids() async {
    await invalidateMigrationState();
    final db = await _vectorDB;
    try {
      await db.resetIndex();
    } catch (e, s) {
      _logger.severe("Error deleting all cluster centroids", e, s);
      rethrow;
    }
  }

  Future<ClusterCentroidVectorDbStats> getIndexStats([VectorDb? db]) async {
    db ??= await _vectorDB;
    try {
      final stats = await db.getIndexStats();
      return ClusterCentroidVectorDbStats(
        size: stats.$1.toInt(),
        capacity: stats.$2.toInt(),
        dimensions: stats.$3.toInt(),
        fileSize: stats.$4.toInt(),
        memoryUsage: stats.$5.toInt(),
        expansionAdd: stats.$6.toInt(),
        expansionSearch: stats.$7.toInt(),
      );
    } catch (e, s) {
      _logger.severe("Error getting cluster centroid index stats", e, s);
      rethrow;
    }
  }

  Future<List<(int, double)>> searchApproxClosestCentroidsWithinDistance(
    List<double> query,
    Set<int> allowedClusterVectorIDs, {
    required double maxDistance,
    int count = 10,
  }) async {
    if (!await checkIfMigrationDone()) {
      throw StateError(
        "Cluster centroid vector DB migration is not done, cannot run approximate search",
      );
    }
    if (count <= 0 || allowedClusterVectorIDs.isEmpty) {
      return const [];
    }
    final db = await _vectorDB;
    try {
      final allowedKeys = Uint64List.fromList(
        allowedClusterVectorIDs.toList(growable: false),
      );
      final result = await db.approxFilteredSearchVectorsWithinDistance(
        query: query,
        allowedKeys: allowedKeys,
        count: BigInt.from(count),
        maxDistance: maxDistance,
      );
      final keys = result.$1;
      final distances = result.$2;
      final output = <(int, double)>[];
      for (var i = 0; i < keys.length; i++) {
        output.add((keys[i].toInt(), distances[i]));
      }
      return output;
    } catch (e, s) {
      _logger.severe("Error searching filtered centroids", e, s);
      rethrow;
    }
  }

  Future<void> warmupApproxSearch() async {
    _warmupFuture ??= _warmupApproxSearchInternal();
    await _warmupFuture;
  }

  Future<void> _warmupApproxSearchInternal() async {
    final stopwatch = Stopwatch()..start();
    try {
      final db = await _vectorDB;
      final stats = await getIndexStats(db);
      if (stats.size == 0) {
        _logger
            .info("Skipping cluster centroid vector DB warmup: index is empty");
        return;
      }

      final warmupQuery = List<double>.filled(
        stats.dimensions,
        0.0,
        growable: false,
      );
      await db.searchVectors(
        query: warmupQuery,
        count: BigInt.one,
        exact: false,
      );
      _logger.info(
        "Cluster centroid vector DB warmup finished in ${stopwatch.elapsedMilliseconds} ms",
      );
    } catch (e, s) {
      _logger.warning("Cluster centroid vector DB warmup failed", e, s);
      _warmupFuture = null;
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> deleteIndex() async {
    await invalidateMigrationState();
    final db = await _vectorDB;
    try {
      await db.deleteIndex();
      _vectorDbFuture = null;
      _warmupFuture = null;
    } catch (e, s) {
      _logger.severe("Error deleting cluster centroid index", e, s);
      rethrow;
    }
  }

  Future<void> deleteIndexFile() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final String dbPath = join(documentsDirectory.path, _databaseName);
      _logger.info("Delete cluster centroid index file: DB path $dbPath");
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
      _logger.info("Deleted cluster centroid index file on disk");
      _vectorDbFuture = null;
      _warmupFuture = null;
      await invalidateMigrationState();
    } catch (e, s) {
      _logger.severe(
        "Error deleting cluster centroid index file on disk",
        e,
        s,
      );
      rethrow;
    }
  }
}

class ClusterCentroidVectorDbStats {
  final int size;
  final int capacity;
  final int dimensions;

  final int fileSize;
  final int memoryUsage;

  final int expansionAdd;
  final int expansionSearch;

  ClusterCentroidVectorDbStats({
    required this.size,
    required this.capacity,
    required this.dimensions,
    required this.fileSize,
    required this.memoryUsage,
    required this.expansionAdd,
    required this.expansionSearch,
  });

  @override
  String toString() {
    return "ClusterCentroidVectorDbStats(size: $size, capacity: $capacity, dimensions: $dimensions, file size on disk (bytes): $fileSize, memory usage (bytes): $memoryUsage, expansionAdd: $expansionAdd, expansionSearch: $expansionSearch)";
  }
}
