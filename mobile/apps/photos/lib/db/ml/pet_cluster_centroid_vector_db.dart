import "dart:io" show File;
import "dart:math" show min;
import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge.dart" show Uint64List;
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/src/rust/api/usearch_api.dart";
import "package:sqlite_async/sqlite_async.dart";
import "package:synchronized/synchronized.dart";

/// Vector database for pet cluster centroids.
///
/// Stores L2-normalized mean centroids for each pet cluster, keyed by
/// auto-incrementing integer IDs mapped from string cluster IDs via
/// [petClusterCentroidVectorIdMappingTable].
///
/// One instance per species (dog/cat) × online/offline.
class PetClusterCentroidVectorDB {
  static final Logger _logger = Logger("PetClusterCentroidVectorDB");

  static const int centroidDimension = 128;

  final String _databaseName;

  PetClusterCentroidVectorDB._named(this._databaseName);

  // ── Online instances ──
  static final dog = PetClusterCentroidVectorDB._named(
    "ente.ml.vectordb.pet.cluster_centroid.dog.usearch",
  );
  static final cat = PetClusterCentroidVectorDB._named(
    "ente.ml.vectordb.pet.cluster_centroid.cat.usearch",
  );

  // ── Offline instances ──
  static final offlineDog = PetClusterCentroidVectorDB._named(
    "ente.ml.offline.vectordb.pet.cluster_centroid.dog.usearch",
  );
  static final offlineCat = PetClusterCentroidVectorDB._named(
    "ente.ml.offline.vectordb.pet.cluster_centroid.cat.usearch",
  );

  static PetClusterCentroidVectorDB forSpecies({
    required int species,
    bool offline = false,
  }) {
    assert(species == 0 || species == 1);
    if (offline) {
      return species == 0 ? offlineDog : offlineCat;
    }
    return species == 0 ? dog : cat;
  }

  Future<VectorDb>? _vectorDbFuture;
  final Lock _writeLock = Lock();

  /// Get the on-disk file path for this vector index without opening it.
  Future<String> getIndexPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  Future<VectorDb> get _vectorDB async {
    _vectorDbFuture ??= _initVectorDB();
    return _vectorDbFuture!;
  }

  Future<VectorDb> _initVectorDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String dbPath = join(documentsDirectory.path, _databaseName);
    _logger.info("Opening pet cluster centroid vectorDB: $dbPath");
    late VectorDb vectorDB;
    try {
      vectorDB = VectorDb(
        filePath: dbPath,
        dimensions: BigInt.from(centroidDimension),
      );
    } catch (e, s) {
      _logger.severe("Could not open pet centroid VectorDB at $dbPath", e, s);
      await _deleteIndexFile(dbPath);
      vectorDB = VectorDb(
        filePath: dbPath,
        dimensions: BigInt.from(centroidDimension),
      );
    }
    return vectorDB;
  }

  Future<void> _deleteIndexFile(String dbPath) async {
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete the on-disk index file and reset the lazy handle.
  Future<void> deleteIndexFile() async {
    final path = await getIndexPath();
    await _deleteIndexFile(path);
    _vectorDbFuture = null;
  }

  // ── ID Mapping (cluster_id string → integer for usearch) ──

  Future<Map<String, int>> getClusterCentroidVectorIdMap(
    Iterable<String> clusterIds, {
    required SqliteDatabase db,
    bool createIfMissing = false,
  }) async {
    final uniqueIds = clusterIds.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return {};

    if (createIfMissing) {
      const insertSql = '''
        INSERT OR IGNORE INTO $petClusterCentroidVectorIdMappingTable
          ($clusterIDColumn)
        VALUES (?)
      ''';
      final insertParams = uniqueIds.map((id) => [id]).toList();
      await db.executeBatch(insertSql, insertParams);
    }

    final result = <String, int>{};
    const chunkSize = 800;
    for (int i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.sublist(i, min(i + chunkSize, uniqueIds.length));
      final rows = await db.getAll(
        'SELECT $clusterIDColumn, $petClusterCentroidVectorIdColumn '
        'FROM $petClusterCentroidVectorIdMappingTable '
        'WHERE $clusterIDColumn IN (${List.filled(chunk.length, '?').join(',')})',
        chunk,
      );
      for (final row in rows) {
        result[row[clusterIDColumn] as String] =
            row[petClusterCentroidVectorIdColumn] as int;
      }
    }
    return result;
  }

  Future<void> deleteClusterCentroidMapping(
    String clusterId, {
    required SqliteDatabase db,
  }) async {
    await db.execute(
      'DELETE FROM $petClusterCentroidVectorIdMappingTable '
      'WHERE $clusterIDColumn = ?',
      [clusterId],
    );
  }

  // ── Vector Operations ──

  Future<void> _runWriteOperation(
    Future<void> Function(VectorDb db) operation,
  ) async {
    final db = await _vectorDB;
    await _writeLock.synchronized(() async {
      await operation(db);
    });
  }

  Future<void> bulkInsertCentroids({
    required List<int> vectorIds,
    required List<Float32List> centroids,
  }) async {
    if (vectorIds.isEmpty || centroids.isEmpty) return;
    try {
      await _runWriteOperation((db) async {
        await db.bulkAddVectors(
          keys: Uint64List.fromList(vectorIds),
          vectors: centroids,
        );
      });
    } catch (e, s) {
      _logger.severe("Error bulk inserting pet cluster centroids", e, s);
      rethrow;
    }
  }

  Future<List<Float32List>> getCentroids(List<int> vectorIds) async {
    if (vectorIds.isEmpty) return [];
    final db = await _vectorDB;
    try {
      return await db.bulkGetVectors(keys: Uint64List.fromList(vectorIds));
    } catch (e, s) {
      _logger.severe("Error getting pet cluster centroids", e, s);
      rethrow;
    }
  }

  Future<void> deleteCentroids(List<int> vectorIds) async {
    if (vectorIds.isEmpty) return;
    try {
      await _runWriteOperation((db) async {
        await db.bulkRemoveVectors(keys: Uint64List.fromList(vectorIds));
      });
    } catch (e, s) {
      _logger.severe("Error deleting pet cluster centroids", e, s);
      rethrow;
    }
  }
}
