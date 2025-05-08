import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/src/rust/api/usearch_api.dart";

class ClipVectorDB {
  static final Logger _logger = Logger("ClipVectorDB");

  static const _databaseName = "ente.ml.vectordb.clip";

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

  Future<VectorDb> _initVectorDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String databaseDirectory =
        join(documentsDirectory.path, _databaseName);
    _logger.info("Opening vectorDB access: DB path " + databaseDirectory);
    final vectorDB = VectorDb(
      filePath: databaseDirectory,
      dimensions: _embeddingDimension,
    );

    return vectorDB;
  }

  Future<void> bulkInsertEmbeddings({
    required Uint64List keys,
    required List<Float32List> embeddings,
  }) async {
    final db = await _vectorDB;
    try {
      await db.bulkAddVectors(keys: keys, vectors: embeddings);
    } catch (e, s) {
      _logger.severe("Error bulk inserting embeddings", e, s);
      rethrow;
    }
  }

  Future<void> insertEmbeddings({
    required BigInt key,
    required List<double> embedding,
  }) async {
    final db = await _vectorDB;
    try {
      await db.addVector(key: key, vector: embedding);
    } catch (e, s) {
      _logger.severe("Error inserting embedding", e, s);
      rethrow;
    }
  }

  Future<List<EmbeddingVector>> getVectors(List<int> fileIds) async {
    final db = await _vectorDB;
    try {
      final keys = Uint64List.fromList(fileIds);
      final vectors = await db.bulkGetVectors(keys: keys);
      return List.generate(
        vectors.length,
        (index) => EmbeddingVector(
          fileID: fileIds[index],
          embedding: vectors[index],
        ),
      );
    } catch (e, s) {
      _logger.severe("Error getting embeddings", e, s);
      rethrow;
    }
  }

  Future<void> deleteEmbeddings(List<int> keys) async {
    final db = await _vectorDB;
    try {
      final deletedCount =
          await db.bulkRemoveVectors(keys: Uint64List.fromList(keys));
      _logger
          .info("Deleted $deletedCount embeddings, from ${keys.length} keys");
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

  Future<(Uint64List, Float32List)> searchClosestVectors(
    List<double> query,
    int count,
  ) async {
    final db = await _vectorDB;
    try {
      final result =
          await db.searchVectors(query: query, count: BigInt.from(count));
      return result;
    } catch (e, s) {
      _logger.severe("Error searching closest vectors", e, s);
      rethrow;
    }
  }

  Future<(BigInt, double)> searchClosestVector(
    List<double> query,
  ) async {
    final db = await _vectorDB;
    try {
      final result = await db.searchVectors(query: query, count: BigInt.one);
      return (result.$1[0], result.$2[0]);
    } catch (e, s) {
      _logger.severe("Error searching closest vector", e, s);
      rethrow;
    }
  }
}
