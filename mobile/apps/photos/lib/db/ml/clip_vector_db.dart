import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/services/machine_learning/semantic_search/query_result.dart";
import "package:photos/src/rust/api/usearch_api.dart";
import "package:shared_preferences/shared_preferences.dart";

class ClipVectorDB {
  static final Logger _logger = Logger("ClipVectorDB");

  static const _databaseName = "ente.ml.vectordb.clip";
  static const _kMigrationKey = "clip_vector_migration";

  static final BigInt _embeddingDimension = BigInt.from(512);

  static Logger get logger => _logger;

  // Singleton pattern
  ClipVectorDB._privateConstructor();
  static final instance = ClipVectorDB._privateConstructor();
  factory ClipVectorDB() => instance;

  // only have a single app-wide reference to the database
  static Future<VectorDb>? _vectorDbFuture;

  Future<VectorDb> get _vectorDB async {
    _vectorDbFuture ??= _initVectorDB();
    return _vectorDbFuture!;
  }

  bool? _migrationDone;

  Future<VectorDb> _initVectorDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String databaseDirectory =
        join(documentsDirectory.path, _databaseName);
    _logger.info("Opening vectorDB access: DB path " + databaseDirectory);
    final vectorDB = VectorDb(
      filePath: databaseDirectory,
      dimensions: _embeddingDimension,
    );
    final stats = await getIndexStats(vectorDB);
    _logger.info("VectorDB connection opened with stats: ${stats.toString()}");

    return vectorDB;
  }

  Future<bool> checkIfMigrationDone() async {
    if (_migrationDone != null) return _migrationDone!;
    _logger.info("Checking if ClipVectorDB migration has run");
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool(_kMigrationKey) ?? false;
    if (migrationDone) {
      _logger.info("ClipVectorDB migration already done");
      _migrationDone = true;
      return _migrationDone!;
    } else {
      _logger.info("ClipVectorDB migration not done");
      _migrationDone = false;
      return _migrationDone!;
    }
  }

  Future<void> setMigrationDone() async {
    _logger.info("Setting ClipVectorDB migration done");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMigrationKey, true);
    _migrationDone = true;
  }

  Future<void> insertEmbedding({
    required int fileID,
    required List<double> embedding,
  }) async {
    final db = await _vectorDB;
    try {
      await db.addVector(key: BigInt.from(fileID), vector: embedding);
    } catch (e, s) {
      _logger.severe("Error inserting embedding", e, s);
      rethrow;
    }
  }

  Future<void> bulkInsertEmbeddings({
    required List<int> fileIDs,
    required List<Float32List> embeddings,
  }) async {
    final db = await _vectorDB;
    final bigKeys = Uint64List.fromList(fileIDs);
    try {
      await db.bulkAddVectors(keys: bigKeys, vectors: embeddings);
    } catch (e, s) {
      _logger.severe("Error bulk inserting embeddings", e, s);
      rethrow;
    }
  }

  Future<List<EmbeddingVector>> getEmbeddings(List<int> fileIDs) async {
    final db = await _vectorDB;
    try {
      final keys = Uint64List.fromList(fileIDs);
      final vectors = await db.bulkGetVectors(keys: keys);
      return List.generate(
        vectors.length,
        (index) => EmbeddingVector(
          fileID: fileIDs[index],
          embedding: vectors[index],
        ),
      );
    } catch (e, s) {
      _logger.severe("Error getting embeddings", e, s);
      rethrow;
    }
  }

  Future<void> deleteEmbeddings(List<int> fileIDs) async {
    final db = await _vectorDB;
    try {
      final deletedCount =
          await db.bulkRemoveVectors(keys: Uint64List.fromList(fileIDs));
      _logger.info(
        "Deleted $deletedCount embeddings, from ${fileIDs.length} keys",
      );
    } catch (e, s) {
      _logger.severe("Error bulk deleting specific embeddings", e, s);
      rethrow;
    }
  }

  Future<void> deleteAllEmbeddings() async {
    final db = await _vectorDB;
    try {
      await db.resetIndex();
    } catch (e, s) {
      _logger.severe("Error deleting all embeddings", e, s);
      rethrow;
    }
  }

  Future<void> deleteIndex() async {
    final db = await _vectorDB;
    try {
      await db.deleteIndex();
      _vectorDbFuture = null;
    } catch (e, s) {
      _logger.severe("Error deleting index", e, s);
      rethrow;
    }
  }

  Future<VectorDbStats> getIndexStats([VectorDb? db]) async {
    db ??= await _vectorDB;
    try {
      final stats = await db.getIndexStats();
      return VectorDbStats(
        size: stats.$1.toInt(),
        capacity: stats.$2.toInt(),
        dimensions: stats.$3.toInt(),
        fileSize: stats.$4.toInt(),
        memoryUsage: stats.$5.toInt(),
        expansionAdd: stats.$6.toInt(),
        expansionSearch: stats.$7.toInt(),
      );
    } catch (e, s) {
      _logger.severe("Error getting index stats", e, s);
      rethrow;
    }
  }

  Future<(Uint64List, Float32List)> searchClosestVectors(
    List<double> query,
    int count, {
    bool exact = false,
  }) async {
    final db = await _vectorDB;
    try {
      final result = await db.searchVectors(
        query: query,
        count: BigInt.from(count),
        exact: exact,
      );
      return result;
    } catch (e, s) {
      _logger.severe("Error searching closest vectors", e, s);
      rethrow;
    }
  }

  Future<(BigInt, double)> searchClosestVector(
    List<double> query, {
    bool exact = false,
  }) async {
    final db = await _vectorDB;
    try {
      final result =
          await db.searchVectors(query: query, count: BigInt.one, exact: exact);
      return (result.$1[0], result.$2[0]);
    } catch (e, s) {
      _logger.severe("Error searching closest vector", e, s);
      rethrow;
    }
  }

  Future<(List<Uint64List>, List<Float32List>)> bulkSearchVectors(
    List<Float32List> queries,
    BigInt count, {
    bool exact = false,
  }) async {
    final db = await _vectorDB;
    try {
      final result = await db.bulkSearchVectors(
        queries: queries,
        count: count,
        exact: exact,
      );
      return result;
    } catch (e, s) {
      _logger.severe("Error bulk searching vectors", e, s);
      rethrow;
    }
  }

  Future<(Uint64List, List<Uint64List>, List<Float32List>)> bulkSearchWithKeys(
    Uint64List potentialKeys,
    BigInt count, {
    bool exact = false,
  }) async {
    final db = await _vectorDB;
    try {
      final result = await db.bulkSearchKeys(
        potentialKeys: potentialKeys,
        count: count,
        exact: exact,
      );
      return result;
    } catch (e, s) {
      _logger.severe("Error bulk searching vectors with potential keys", e, s);
      rethrow;
    }
  }

  Future<Map<String, List<QueryResult>>> computeBulkSimilarities(
    Map<String, List<double>> textQueryToEmbeddingMap,
    Map<String, double> minimumSimilarityMap,
  ) async {
    try {
      final queryToResults = <String, List<QueryResult>>{};
      for (final MapEntry<String, List<double>> entry
          in textQueryToEmbeddingMap.entries) {
        final query = entry.key;
        final minimumSimilarity = minimumSimilarityMap[query]!;
        final textEmbedding = entry.value;
        final (potentialFileIDs, distances) =
            await searchClosestVectors(textEmbedding, 1000);
        final queryResults = <QueryResult>[];
        for (var i = 0; i < potentialFileIDs.length; i++) {
          final similarity = 1 - distances[i];
          if (similarity >= minimumSimilarity) {
            queryResults
                .add(QueryResult(potentialFileIDs[i].toInt(), similarity));
          } else {
            break;
          }
        }
        queryToResults[query] = queryResults;
      }
      return queryToResults;
    } catch (e, s) {
      _logger.severe(
        "Could not bulk find embeddings similarities using vector DB",
        e,
        s,
      );
      rethrow;
    }
  }
}

class VectorDbStats {
  final int size;
  final int capacity;
  final int dimensions;

  // in bytes
  final int fileSize;
  final int memoryUsage;

  final int expansionAdd;
  final int expansionSearch;

  VectorDbStats({
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
    return "VectorDbStats(size: $size, capacity: $capacity, dimensions: $dimensions, file size on disk (bytes): $fileSize, memory usage (bytes): $memoryUsage, expansionAdd: $expansionAdd, expansionSearch: $expansionSearch)";
  }
}
