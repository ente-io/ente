import 'dart:async';
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/db/common/base.dart";
import "package:photos/db/ml/base.dart";
import "package:photos/db/ml/clip_vector_db.dart";
import "package:photos/db/ml/db_model_mappers.dart";
import 'package:photos/db/ml/schema.dart';
import "package:photos/events/embedding_updated_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_db_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/ml_util.dart";
import 'package:sqlite_async/sqlite_async.dart';

/// Stores all data for the ML related features. The database can be accessed by `MLDataDB.instance.database`.
///
/// This includes:
/// [facesTable] - Stores all the detected faces and its embeddings in the images.
/// [faceClustersTable] - Stores all the mappings from the faces (faceID) to the clusters (clusterID).
/// [clusterPersonTable] - Stores all the clusters that are mapped to a certain person.
/// [clusterSummaryTable] - Stores a summary of each cluster, containg the mean embedding and the number of faces in the cluster.
/// [notPersonFeedback] - Stores the clusters that are confirmed not to belong to a certain person by the user
///
/// [clipTable] - Stores the embeddings of the CLIP model
/// [fileDataTable] - Stores data about the files that are already processed by the ML models
///
/// [faceCacheTable] - Stores a all the mappings from personID or clusterID to the faceID that has been used as cover face.
class MLDataDB with SqlDbBase implements IMLDataDB<int> {
  static final Logger _logger = Logger("MLDataDB");

  static const _databaseName = "ente.ml.db";

  static Logger get logger => _logger;

  // static const _databaseVersion = 1;

  MLDataDB._privateConstructor();

  static final MLDataDB instance = MLDataDB._privateConstructor();

  static final _migrationScripts = [
    createFacesTable,
    createFaceClustersTable,
    createClusterPersonTable,
    createClusterSummaryTable,
    createNotPersonFeedbackTable,
    fcClusterIDIndex,
    createClipEmbeddingsTable,
    createFileDataTable,
    createFaceCacheTable,
  ];

  // only have a single app-wide reference to the database
  static Future<SqliteDatabase>? _sqliteAsyncDBFuture;

  Future<SqliteDatabase> get asyncDB async {
    _sqliteAsyncDBFuture ??= _initSqliteAsyncDatabase();
    return _sqliteAsyncDBFuture!;
  }

  Future<SqliteDatabase> _initSqliteAsyncDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String databaseDirectory =
        join(documentsDirectory.path, _databaseName);
    _logger.info("Opening sqlite_async access: DB path " + databaseDirectory);
    final asyncDBConnection =
        SqliteDatabase(path: databaseDirectory, maxReaders: 2);
    final stopwatch = Stopwatch()..start();
    _logger.info("MLDataDB: Starting migration");
    await migrate(asyncDBConnection, _migrationScripts);
    _logger.info(
      "MLDataDB Migration took ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();

    return asyncDBConnection;
  }

  // bulkInsertFaces inserts the faces in the database in batches of 1000.
  // This is done to avoid the error "too many SQL variables" when inserting
  // a large number of faces.
  @override
  Future<void> bulkInsertFaces(List<Face> faces) async {
    final db = await instance.asyncDB;
    const batchSize = 500;
    final numBatches = (faces.length / batchSize).ceil();
    for (int i = 0; i < numBatches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, faces.length);
      final batch = faces.sublist(start, end);

      const String sql = '''
        INSERT INTO $facesTable (
          $fileIDColumn, $faceIDColumn, $faceDetectionColumn, $embeddingColumn, $faceScore, $faceBlur, $isSideways, $imageHeight, $imageWidth, $mlVersionColumn
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT($fileIDColumn, $faceIDColumn) DO UPDATE SET $faceIDColumn = excluded.$faceIDColumn, $faceDetectionColumn = excluded.$faceDetectionColumn, $embeddingColumn = excluded.$embeddingColumn, $faceScore = excluded.$faceScore, $faceBlur = excluded.$faceBlur, $isSideways = excluded.$isSideways, $imageHeight = excluded.$imageHeight, $imageWidth = excluded.$imageWidth, $mlVersionColumn = excluded.$mlVersionColumn
      ''';
      final parameterSets = batch.map((face) {
        final map = mapRemoteToFaceDB(face);
        return [
          map[fileIDColumn],
          map[faceIDColumn],
          map[faceDetectionColumn],
          map[embeddingColumn],
          map[faceScore],
          map[faceBlur],
          map[isSideways],
          map[imageHeight],
          map[imageWidth],
          map[mlVersionColumn],
        ];
      }).toList();

      await db.executeBatch(sql, parameterSets);
    }
  }

  @override
  Future<void> updateFaceIdToClusterId(
    Map<String, String> faceIDToClusterID,
  ) async {
    final db = await instance.asyncDB;
    const batchSize = 500;
    final numBatches = (faceIDToClusterID.length / batchSize).ceil();
    for (int i = 0; i < numBatches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, faceIDToClusterID.length);
      final batch = faceIDToClusterID.entries.toList().sublist(start, end);

      const String sql = '''
        INSERT INTO $faceClustersTable ($faceIDColumn, $clusterIDColumn)
        VALUES (?, ?)
        ON CONFLICT($faceIDColumn) DO UPDATE SET $clusterIDColumn = excluded.$clusterIDColumn
      ''';
      final parameterSets = batch.map((e) => [e.key, e.value]).toList();

      await db.executeBatch(sql, parameterSets);
    }
  }

  /// Returns a map of fileID to the indexed ML version
  @override
  Future<Map<int, int>> faceIndexedFileIds({
    int minimumMlVersion = faceMlVersion,
  }) async {
    final db = await instance.asyncDB;
    final String query = '''
        SELECT $fileIDColumn, $mlVersionColumn
        FROM $facesTable
        WHERE $mlVersionColumn >= $minimumMlVersion
      ''';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fileIDColumn] as int] = map[mlVersionColumn] as int;
    }
    return result;
  }

  @override
  Future<int> getFaceIndexedFileCount({
    int minimumMlVersion = faceMlVersion,
  }) async {
    final db = await instance.asyncDB;
    final String query =
        'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $facesTable WHERE $mlVersionColumn >= $minimumMlVersion';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.first['count'] as int;
  }

  @override
  Future<Map<String, int>> clusterIdToFaceCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn, COUNT(*) as count FROM $faceClustersTable where $clusterIDColumn IS NOT NULL GROUP BY $clusterIDColumn ',
    );
    final Map<String, int> result = {};
    for (final map in maps) {
      result[map[clusterIDColumn] as String] = map['count'] as int;
    }
    return result;
  }

  @override
  Future<Set<String>> getPersonIgnoredClusters(String personID) async {
    final db = await instance.asyncDB;
    // find out clusterIds that are assigned to other persons using the clusters table
    final List<Map<String, dynamic>> otherPersonMaps = await db.getAll(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn != ? AND $personIdColumn IS NOT NULL',
      [personID],
    );
    final Set<String> ignoredClusterIDs =
        otherPersonMaps.map((e) => e[clusterIDColumn] as String).toSet();
    final List<Map<String, dynamic>> rejectMaps = await db.getAll(
      'SELECT $clusterIDColumn FROM $notPersonFeedback WHERE $personIdColumn = ?',
      [personID],
    );
    final Set<String> rejectClusterIDs =
        rejectMaps.map((e) => e[clusterIDColumn] as String).toSet();
    return ignoredClusterIDs.union(rejectClusterIDs);
  }

  @override
  Future<Map<String, Set<String>>> getPersonToRejectedSuggestions() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> rejectMaps = await db.getAll(
      'SELECT $personIdColumn, $clusterIDColumn FROM $notPersonFeedback',
    );
    final Map<String, Set<String>> result = {};
    for (final map in rejectMaps) {
      final personID = map[personIdColumn] as String;
      final clusterID = map[clusterIDColumn] as String;
      result.putIfAbsent(personID, () => {}).add(clusterID);
    }
    return result;
  }

  @override
  Future<Set<String>> getPersonClusterIDs(String personID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn = ?',
      [personID],
    );
    return maps.map((e) => e[clusterIDColumn] as String).toSet();
  }

  @override
  Future<Set<String>> getPersonsClusterIDs(List<String> personID) async {
    final db = await instance.asyncDB;
    final inParam = personID.map((e) => "'$e'").join(',');
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn IN ($inParam)',
    );
    return maps.map((e) => e[clusterIDColumn] as String).toSet();
  }

  @override
  Future<void> clearTable() async {
    final db = await instance.asyncDB;

    await db.execute(deleteFacesTable);
    await db.execute(deleteFaceClustersTable);
    await db.execute(deleteClusterPersonTable);
    await db.execute(deleteClusterSummaryTable);
    await db.execute(deleteNotPersonFeedbackTable);
    await db.execute(deleteClipEmbeddingsTable);
    await db.execute(deleteFileDataTable);
  }

  @override
  Future<Iterable<Uint8List>> getFaceEmbeddingsForCluster(
    String clusterID, {
    int? limit,
  }) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $embeddingColumn FROM $facesTable WHERE  $faceIDColumn in (SELECT $faceIDColumn from $faceClustersTable where $clusterIDColumn = ?) ${limit != null ? 'LIMIT $limit' : ''}',
      [clusterID],
    );
    return maps.map((e) => e[embeddingColumn] as Uint8List);
  }

  @override
  Future<Map<String, Iterable<Uint8List>>> getFaceEmbeddingsForClusters(
    Iterable<String> clusterIDs, {
    int? limit,
  }) async {
    final db = await instance.asyncDB;
    final Map<String, List<Uint8List>> result = {};

    final selectQuery = '''
  SELECT fc.$clusterIDColumn, fe.$embeddingColumn
  FROM $faceClustersTable fc
  INNER JOIN $facesTable fe ON fc.$faceIDColumn = fe.$faceIDColumn
  WHERE fc.$clusterIDColumn IN (${List.filled(clusterIDs.length, '?').join(',')})
  ${limit != null ? 'LIMIT ?' : ''}
''';

    final List<dynamic> selectQueryParams = [...clusterIDs];
    if (limit != null) {
      selectQueryParams.add(limit);
    }

    final List<Map<String, dynamic>> maps =
        await db.getAll(selectQuery, selectQueryParams);

    for (final map in maps) {
      final clusterID = map[clusterIDColumn] as String;
      final faceEmbedding = map[embeddingColumn] as Uint8List;
      result.putIfAbsent(clusterID, () => <Uint8List>[]).add(faceEmbedding);
    }

    return result;
  }

  @override
  Future<Face?> getCoverFaceForPerson({
    required int recentFileID,
    String? personID,
    String? avatarFaceId,
    String? clusterID,
  }) async {
    // read person from db
    final db = await instance.asyncDB;
    if (personID != null) {
      final List<int> fileId = [recentFileID];
      int? avatarFileId;
      if (avatarFaceId != null) {
        avatarFileId = tryGetFileIdFromFaceId(avatarFaceId);
        if (avatarFileId != null) {
          fileId.add(avatarFileId);
        }
      }
      const String queryClusterID = '''
        SELECT $clusterIDColumn
        FROM $clusterPersonTable
        WHERE $personIdColumn = ?
      ''';
      final clusterRows = await db.getAll(
        queryClusterID,
        [personID],
      );
      final clusterIDs =
          clusterRows.map((e) => e[clusterIDColumn] as String).toList();

      final List<Map<String, dynamic>> faceMaps = await db.getAll(
        '''
        SELECT * FROM $facesTable
        WHERE $faceIDColumn IN (
        SELECT $faceIDColumn
        FROM $faceClustersTable
        WHERE $clusterIDColumn IN (${List.filled(clusterIDs.length, '?').join(',')})
        )
        AND $fileIDColumn IN (${List.filled(fileId.length, '?').join(',')})
        ORDER BY $faceScore DESC
        ''',
        [...clusterIDs, ...fileId],
      );
      if (faceMaps.isNotEmpty) {
        if (avatarFileId != null) {
          final row = faceMaps.firstWhereOrNull(
            (element) => (element[fileIDColumn] as int) == avatarFileId,
          );
          if (row != null) {
            return mapRowToFace(row);
          }
        }
        return mapRowToFace(faceMaps.first);
      }
    }
    if (clusterID != null) {
      const String queryFaceID = '''
        SELECT $faceIDColumn
        FROM $faceClustersTable
        WHERE $clusterIDColumn = ?
      ''';
      final List<Map<String, dynamic>> faceMaps = await db.getAll(
        queryFaceID,
        [clusterID],
      );
      final List<Face>? faces = await getFacesForGivenFileID(recentFileID);
      if (faces != null) {
        for (final face in faces) {
          if (faceMaps.any(
            (element) => (element[faceIDColumn] as String) == face.faceID,
          )) {
            return face;
          }
        }
      }
    }
    if (personID == null && clusterID == null) {
      _logger.severe("personID and clusterID cannot be null both");
      throw Exception("personID and clusterID cannot be null");
    }
    _logger.severe(
      "Something went wrong finding a face from `getCoverFaceForPerson` (personID: $personID, clusterID: $clusterID)",
    );
    return null;
  }

  @override
  Future<List<Face>?> getFacesForGivenFileID(int fileUploadID) async {
    final db = await instance.asyncDB;
    const String query = '''
      SELECT * FROM $facesTable
      WHERE $fileIDColumn = ?
    ''';
    final List<Map<String, dynamic>> maps = await db.getAll(
      query,
      [fileUploadID],
    );
    if (maps.isEmpty) {
      return null;
    }
    return maps.map((e) => mapRowToFace(e)).toList();
  }

  @override
  Future<Map<int, List<FaceWithoutEmbedding>>>
      getFileIDsToFacesWithoutEmbedding() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      '''
      SELECT $faceIDColumn, $fileIDColumn, $faceScore, $faceDetectionColumn, $faceBlur FROM $facesTable
    ''',
    );
    if (maps.isEmpty) {
      return {};
    }
    final result = <int, List<FaceWithoutEmbedding>>{};
    for (final map in maps) {
      final face = mapRowToFaceWithoutEmbedding(map);
      final fileID = map[fileIDColumn] as int;
      result.putIfAbsent(fileID, () => <FaceWithoutEmbedding>[]).add(face);
    }
    return result;
  }

  @override
  Future<Map<String, Iterable<String>>> getClusterToFaceIDs(
    Set<String> clusterIDs,
  ) async {
    final db = await instance.asyncDB;
    final Map<String, List<String>> result = {};

    final List<Map<String, dynamic>> maps = await db.getAll(
      '''
  SELECT $clusterIDColumn, $faceIDColumn
  FROM $faceClustersTable
  WHERE $clusterIDColumn IN (${List.filled(clusterIDs.length, '?').join(',')})
  ''',
      [...clusterIDs],
    );

    for (final map in maps) {
      final clusterID = map[clusterIDColumn] as String;
      final faceID = map[faceIDColumn] as String;
      result.putIfAbsent(clusterID, () => <String>[]).add(faceID);
    }
    return result;
  }

  @override
  Future<String?> getClusterIDForFaceID(String faceID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn FROM $faceClustersTable WHERE $faceIDColumn = ?',
      [faceID],
    );
    if (maps.isEmpty) {
      return null;
    }
    return maps.first[clusterIDColumn] as String;
  }

  @override
  Future<Map<String, Iterable<String>>> getAllClusterIdToFaceIDs() async {
    final db = await instance.asyncDB;
    final Map<String, List<String>> result = {};
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn, $faceIDColumn FROM $faceClustersTable',
    );
    for (final map in maps) {
      final clusterID = map[clusterIDColumn] as String;
      final faceID = map[faceIDColumn] as String;
      result.putIfAbsent(clusterID, () => <String>[]).add(faceID);
    }
    return result;
  }

  @override
  Future<Iterable<String>> getFaceIDsForCluster(String clusterID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceIDColumn FROM $faceClustersTable '
      'WHERE $faceClustersTable.$clusterIDColumn = ?',
      [clusterID],
    );
    return maps.map((e) => e[faceIDColumn] as String).toSet();
  }

  Future<List<String>> getFaceIDsForClusterOrderedByScore(
    String clusterID, {
    int limit = 10,
  }) async {
    final db = await instance.asyncDB;
    final faceIdsResult = await db.getAll(
      'SELECT $facesTable.$faceIDColumn FROM $facesTable '
      'JOIN $faceClustersTable ON $facesTable.$faceIDColumn = $faceClustersTable.$faceIDColumn '
      'WHERE $faceClustersTable.$clusterIDColumn = ? '
      'ORDER BY $facesTable.$faceScore DESC '
      'LIMIT ?',
      [clusterID, limit],
    );
    return faceIdsResult.map((e) => e[faceIDColumn] as String).toList();
  }

  // Get Map of personID to Map of clusterID to faceIDs
  @override
  Future<Map<String, Map<String, Set<String>>>>
      getPersonToClusterIdToFaceIds() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $personIdColumn, $faceClustersTable.$clusterIDColumn, $faceIDColumn FROM $clusterPersonTable '
      'INNER JOIN $faceClustersTable ON $clusterPersonTable.$clusterIDColumn = $faceClustersTable.$clusterIDColumn',
    );
    final Map<String, Map<String, Set<String>>> result = {};
    for (final map in maps) {
      final personID = map[personIdColumn] as String;
      final clusterID = map[clusterIDColumn] as String;
      final faceID = map[faceIDColumn] as String;
      result
          .putIfAbsent(personID, () => {})
          .putIfAbsent(clusterID, () => {})
          .add(faceID);
    }
    return result;
  }

  @override
  Future<Map<String, Set<String>>> getPersonToClusterIDs() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $personIdColumn, $clusterIDColumn FROM $clusterPersonTable',
    );
    final Map<String, Set<String>> result = {};
    for (final map in maps) {
      final personID = map[personIdColumn] as String;
      final clusterID = map[clusterIDColumn] as String;
      result.putIfAbsent(personID, () => {}).add(clusterID);
    }
    return result;
  }

  Future<Map<String, String>> getFaceIdToPersonIdForFaces(
    Iterable<String> faceIDs,
  ) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceIDColumn, $personIdColumn FROM $clusterPersonTable '
      'INNER JOIN $faceClustersTable ON $clusterPersonTable.$clusterIDColumn = $faceClustersTable.$clusterIDColumn '
      'WHERE $faceIDColumn IN (${faceIDs.map((id) => "'$id'").join(",")})',
    );
    final Map<String, String> result = {};
    for (final map in maps) {
      result[map[faceIDColumn] as String] = map[personIdColumn] as String;
    }
    return result;
  }

  @override
  Future<Map<String, Set<String>>> getClusterIdToFaceIdsForPerson(
    String personID,
  ) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceClustersTable.$clusterIDColumn, $faceIDColumn FROM $clusterPersonTable '
      'INNER JOIN $faceClustersTable ON $clusterPersonTable.$clusterIDColumn = $faceClustersTable.$clusterIDColumn '
      'WHERE $personIdColumn = ?',
      [personID],
    );
    final Map<String, Set<String>> result = {};
    for (final map in maps) {
      final clusterID = map[clusterIDColumn] as String;
      final faceID = map[faceIDColumn] as String;
      result.putIfAbsent(clusterID, () => {}).add(faceID);
    }
    return result;
  }

  @override
  Future<Set<String>> getFaceIDsForPerson(String personID) async {
    final db = await instance.asyncDB;
    final faceIdsResult = await db.getAll(
      'SELECT $faceIDColumn FROM $faceClustersTable LEFT JOIN $clusterPersonTable '
      'ON $faceClustersTable.$clusterIDColumn = $clusterPersonTable.$clusterIDColumn '
      'WHERE $clusterPersonTable.$personIdColumn = ?',
      [personID],
    );
    return faceIdsResult.map((e) => e[faceIDColumn] as String).toSet();
  }

  Future<List<String>> getFaceIDsForPersonOrderedByScore(
    String personID, {
    int limit = 10,
  }) async {
    final db = await instance.asyncDB;
    final faceIdsResult = await db.getAll(
      'SELECT $facesTable.$faceIDColumn FROM $facesTable '
      'JOIN $faceClustersTable ON $facesTable.$faceIDColumn = $faceClustersTable.$faceIDColumn '
      'JOIN $clusterPersonTable ON $faceClustersTable.$clusterIDColumn = $clusterPersonTable.$clusterIDColumn '
      'WHERE $clusterPersonTable.$personIdColumn = ? '
      'ORDER BY $facesTable.$faceScore DESC '
      'LIMIT ?',
      [personID, limit],
    );
    return faceIdsResult.map((e) => e[faceIDColumn] as String).toList();
  }

  @override
  Future<Iterable<double>> getBlurValuesForCluster(String clusterID) async {
    final db = await instance.asyncDB;
    const String query = '''
        SELECT $facesTable.$faceBlur
        FROM $facesTable
        JOIN $faceClustersTable ON $facesTable.$faceIDColumn = $faceClustersTable.$faceIDColumn
        WHERE $faceClustersTable.$clusterIDColumn = ?
      ''';
    // const String query2 = '''
    //     SELECT $faceBlur
    //     FROM $facesTable
    //     WHERE $faceIDColumn IN (SELECT $faceIDColumn FROM $faceClustersTable WHERE $clusterIDColumn = ?)
    //   ''';
    final List<Map<String, dynamic>> maps = await db.getAll(
      query,
      [clusterID],
    );
    return maps.map((e) => e[faceBlur] as double).toSet();
  }

  @override
  Future<Map<String, String?>> getFaceIdsToClusterIds(
    Iterable<String> faceIds,
  ) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceIDColumn, $clusterIDColumn FROM $faceClustersTable where $faceIDColumn IN (${faceIds.map((id) => "'$id'").join(",")})',
    );
    final Map<String, String?> result = {};
    for (final map in maps) {
      result[map[faceIDColumn] as String] = map[clusterIDColumn] as String?;
    }
    return result;
  }

  @override
  Future<Map<int, Set<String>>> getFileIdToClusterIds() async {
    final Map<int, Set<String>> result = {};
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn, $faceIDColumn FROM $faceClustersTable',
    );

    for (final map in maps) {
      final clusterID = map[clusterIDColumn] as String;
      final faceID = map[faceIDColumn] as String;
      final fileID = getFileIdFromFaceId<int>(faceID);
      result[fileID] = (result[fileID] ?? {})..add(clusterID);
    }
    return result;
  }

  @override
  Future<void> forceUpdateClusterIds(
    Map<String, String> faceIDToClusterID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $faceClustersTable ($faceIDColumn, $clusterIDColumn)
      VALUES (?, ?)
      ON CONFLICT($faceIDColumn) DO UPDATE SET $clusterIDColumn = excluded.$clusterIDColumn
    ''';
    final parameterSets =
        faceIDToClusterID.entries.map((e) => [e.key, e.value]).toList();
    await db.executeBatch(sql, parameterSets);
  }

  @override
  Future<void> removeFaceIdToClusterId(
    Map<String, String> faceIDToClusterID,
  ) async {
    final db = await instance.asyncDB;
    const String sql = '''
      DELETE FROM $faceClustersTable
      WHERE $faceIDColumn = ? AND $clusterIDColumn = ?
    ''';
    final parameterSets =
        faceIDToClusterID.entries.map((e) => [e.key, e.value]).toList();
    await db.executeBatch(sql, parameterSets);
  }

  @override
  Future<void> removePerson(String personID) async {
    final db = await instance.asyncDB;

    await db.writeTransaction((tx) async {
      try {
        await tx.execute(
          'DELETE FROM $clusterPersonTable WHERE $personIdColumn = ?',
          [personID],
        );
      } catch (e) {
        _logger.severe('Error in the first write of removePerson', e);
        rethrow;
      }
      try {
        await tx.execute(
          'DELETE FROM $notPersonFeedback WHERE $personIdColumn = ?',
          [personID],
        );
      } catch (e) {
        _logger.severe('Error in the second write of removePerson', e);
        rethrow;
      }
    });
  }

  @override
  Future<List<FaceDbInfoForClustering>> getFaceInfoForClustering({
    int maxFaces = 20000,
    int offset = 0,
    int batchSize = 10000,
  }) async {
    try {
      final EnteWatch w = EnteWatch("getFaceEmbeddingMap")..start();
      w.logAndReset(
        'reading as float offset: $offset, maxFaces: $maxFaces, batchSize: $batchSize',
      );
      final db = await instance.asyncDB;

      final List<FaceDbInfoForClustering> result = <FaceDbInfoForClustering>[];
      while (true) {
        // Query a batch of rows
        final List<Map<String, dynamic>> maps = await db.getAll(
          'SELECT $faceIDColumn, $embeddingColumn, $faceScore, $faceBlur, $isSideways FROM $facesTable'
          ' WHERE $faceScore > $kMinimumQualityFaceScore AND $faceBlur > $kLaplacianHardThreshold'
          ' ORDER BY $faceIDColumn'
          ' DESC LIMIT $batchSize OFFSET $offset',
        );
        // Break the loop if no more rows
        if (maps.isEmpty) {
          break;
        }
        final List<String> faceIds = [];
        for (final map in maps) {
          faceIds.add(map[faceIDColumn] as String);
        }
        final faceIdToClusterId = await getFaceIdsToClusterIds(faceIds);
        for (final map in maps) {
          final faceID = map[faceIDColumn] as String;
          final faceInfo = FaceDbInfoForClustering(
            faceID: faceID,
            clusterId: faceIdToClusterId[faceID],
            embeddingBytes: map[embeddingColumn] as Uint8List,
            faceScore: map[faceScore] as double,
            blurValue: map[faceBlur] as double,
            isSideways: (map[isSideways] as int) == 1,
          );
          result.add(faceInfo);
        }
        if (result.length >= maxFaces) {
          break;
        }
        offset += batchSize;
      }
      w.stopWithLog('done reading face embeddings ${result.length}');
      return result;
    } catch (e) {
      _logger.severe('err in getFaceInfoForClustering', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, Uint8List>> getFaceEmbeddingMapForFaces(
    Iterable<String> faceIDs,
  ) async {
    _logger.info('reading face embeddings for ${faceIDs.length} faces');
    final db = await instance.asyncDB;

    // Define the batch size
    const batchSize = 10000;
    int offset = 0;

    final Map<String, Uint8List> result = {};
    while (true) {
      // Query a batch of rows
      final String query = '''
        SELECT $faceIDColumn, $embeddingColumn
        FROM $facesTable
        WHERE $faceIDColumn IN (${faceIDs.map((id) => "'$id'").join(",")})
        ORDER BY $faceIDColumn DESC
        LIMIT $batchSize OFFSET $offset
      ''';
      final List<Map<String, dynamic>> maps = await db.getAll(query);
      // Break the loop if no more rows
      if (maps.isEmpty) {
        break;
      }
      for (final map in maps) {
        final faceID = map[faceIDColumn] as String;
        result[faceID] = map[embeddingColumn] as Uint8List;
      }
      if (result.length > 10000) {
        break;
      }
      offset += batchSize;
    }
    _logger.info('done reading face embeddings for ${faceIDs.length} faces');
    return result;
  }

  @override
  Future<int> getTotalFaceCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceScore > $kMinimumQualityFaceScore AND $faceBlur > $kLaplacianHardThreshold',
    );
    return maps.first['count'] as int;
  }

  @override
  Future<int> getErroredFaceCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceScore < 0',
    );
    return maps.first['count'] as int;
  }

  @override
  Future<Set<int>> getErroredFileIDs() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT DISTINCT $fileIDColumn FROM $facesTable WHERE $faceScore < 0',
    );
    return maps.map((e) => e[fileIDColumn] as int).toSet();
  }

  @override
  Future<void> deleteFaceIndexForFiles(List<int> fileIDs) async {
    final db = await instance.asyncDB;
    final String sql = '''
      DELETE FROM $facesTable WHERE $fileIDColumn IN (${fileIDs.join(", ")})
    ''';
    await db.execute(sql);
  }

  @override
  Future<int> getClusteredOrFacelessFileCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> clustered = await db.getAll(
      'SELECT $faceIDColumn FROM $faceClustersTable',
    );
    final Set<int> clusteredFileIDs = {};
    for (final map in clustered) {
      final int fileID = getFileIdFromFaceId<int>(map[faceIDColumn] as String);
      clusteredFileIDs.add(fileID);
    }

    final List<Map<String, dynamic>> badFacesFiles = await db.getAll(
      'SELECT DISTINCT $fileIDColumn FROM $facesTable WHERE $faceScore <= $kMinimumQualityFaceScore OR $faceBlur <= $kLaplacianHardThreshold',
    );
    final Set<int> badFileIDs = {};
    for (final map in badFacesFiles) {
      badFileIDs.add(map[fileIDColumn] as int);
    }

    final List<Map<String, dynamic>> goodFacesFiles = await db.getAll(
      'SELECT DISTINCT $fileIDColumn FROM $facesTable WHERE $faceScore > $kMinimumQualityFaceScore AND $faceBlur > $kLaplacianHardThreshold',
    );
    final Set<int> goodFileIDs = {};
    for (final map in goodFacesFiles) {
      goodFileIDs.add(map[fileIDColumn] as int);
    }
    final trulyFacelessFiles = badFileIDs.difference(goodFileIDs);
    return clusteredFileIDs.length + trulyFacelessFiles.length;
  }

  @override
  Future<double> getClusteredToIndexableFilesRatio() async {
    final int indexableFiles = await getIndexableFileCount();
    final int clusteredFiles = await getClusteredOrFacelessFileCount();

    return clusteredFiles / indexableFiles;
  }

  @override
  Future<int> getUnclusteredFaceCount() async {
    final db = await instance.asyncDB;
    const String query = '''
      SELECT f.$faceIDColumn
      FROM $facesTable f
      LEFT JOIN $faceClustersTable fc ON f.$faceIDColumn = fc.$faceIDColumn
      WHERE f.$faceScore > $kMinimumQualityFaceScore
      AND f.$faceBlur > $kLaplacianHardThreshold
      AND fc.$faceIDColumn IS NULL
    ''';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.length;
  }

  /// WARNING: Only use this method if the person has just been created.
  /// Otherwise, use [ClusterFeedbackService.instance.addClusterToExistingPerson] instead.
  @override
  Future<void> assignClusterToPerson({
    required String personID,
    required String clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $clusterPersonTable ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT($personIdColumn, $clusterIDColumn) DO NOTHING
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  @override
  Future<void> bulkAssignClusterToPersonID(
    Map<String, String> clusterToPersonID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $clusterPersonTable ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT($personIdColumn, $clusterIDColumn) DO NOTHING
    ''';
    final parameterSets =
        clusterToPersonID.entries.map((e) => [e.value, e.key]).toList();
    await db.executeBatch(sql, parameterSets);
  }

  @override
  Future<void> captureNotPersonFeedback({
    required String personID,
    required String clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $notPersonFeedback ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT DO NOTHING
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  @override
  Future<void> bulkCaptureNotPersonFeedback(
    Map<String, String> clusterToPersonID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $notPersonFeedback ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT DO NOTHING
    ''';
    final parameterSets =
        clusterToPersonID.entries.map((e) => [e.value, e.key]).toList();

    await db.executeBatch(sql, parameterSets);
  }

  @override
  Future<void> removeNotPersonFeedback({
    required String personID,
    required String clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      DELETE FROM $notPersonFeedback WHERE $personIdColumn = ? AND $clusterIDColumn = ?
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  @override
  Future<void> removeClusterToPerson({
    required String personID,
    required String clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      DELETE FROM $clusterPersonTable WHERE $personIdColumn = ? AND $clusterIDColumn = ?
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  // for a given personID, return a map of clusterID to fileIDs using join query
  @override
  Future<Map<int, Set<String>>> getFileIdToClusterIDSet(String personID) {
    final db = instance.asyncDB;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.getAll(
        'SELECT $faceClustersTable.$clusterIDColumn, $faceIDColumn FROM $faceClustersTable '
        'INNER JOIN $clusterPersonTable '
        'ON $faceClustersTable.$clusterIDColumn = $clusterPersonTable.$clusterIDColumn '
        'WHERE $clusterPersonTable.$personIdColumn = ?',
        [personID],
      );
      final Map<int, Set<String>> result = {};
      for (final map in maps) {
        final clusterID = map[clusterIDColumn] as String;
        final String faceID = map[faceIDColumn] as String;
        final fileID = getFileIdFromFaceId<int>(faceID);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  @override
  Future<Map<int, Set<String>>> getFileIdToClusterIDSetForCluster(
    Set<String> clusterIDs,
  ) {
    final db = instance.asyncDB;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.getAll(
        '''
  SELECT $clusterIDColumn, $faceIDColumn
  FROM $faceClustersTable
  WHERE $clusterIDColumn IN (${List.filled(clusterIDs.length, '?').join(',')})
  ''',
        [...clusterIDs],
      );
      final Map<int, Set<String>> result = {};
      for (final map in maps) {
        final clusterID = map[clusterIDColumn] as String;
        final faceID = map[faceIDColumn] as String;
        final fileID = getFileIdFromFaceId<int>(faceID);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  @override
  Future<void> clusterSummaryUpdate(
    Map<String, (Uint8List, int)> summary,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $clusterSummaryTable ($clusterIDColumn, $avgColumn, $countColumn) VALUES (?, ?, ?) ON CONFLICT($clusterIDColumn) DO UPDATE SET $avgColumn = excluded.$avgColumn, $countColumn = excluded.$countColumn
    ''';
    final List<List<Object?>> parameterSets = [];
    int batchCounter = 0;
    for (final entry in summary.entries) {
      if (batchCounter == 400) {
        await db.executeBatch(sql, parameterSets);
        batchCounter = 0;
        parameterSets.clear();
      }
      final String clusterID = entry.key;
      final int count = entry.value.$2;
      final Uint8List avg = entry.value.$1;
      parameterSets.add([clusterID, avg, count]);
      batchCounter++;
    }
    await db.executeBatch(sql, parameterSets);
  }

  @override
  Future<void> deleteClusterSummary(String clusterID) async {
    final db = await instance.asyncDB;
    const String sqlDelete =
        'DELETE FROM $clusterSummaryTable WHERE $clusterIDColumn = ?';
    await db.execute(sqlDelete, [clusterID]);
  }

  /// Returns a map of clusterID to (avg embedding, count)
  @override
  Future<Map<String, (Uint8List, int)>> getAllClusterSummary([
    int? minClusterSize,
  ]) async {
    final db = await instance.asyncDB;
    final Map<String, (Uint8List, int)> result = {};
    final rows = await db.getAll(
      'SELECT * FROM $clusterSummaryTable${minClusterSize != null ? ' WHERE $countColumn >= $minClusterSize' : ''}',
    );
    for (final r in rows) {
      final id = r[clusterIDColumn] as String;
      final avg = r[avgColumn] as Uint8List;
      final count = r[countColumn] as int;
      result[id] = (avg, count);
    }
    return result;
  }

  @override
  Future<Map<String, (Uint8List, int)>> getClusterToClusterSummary(
    Iterable<String> clusterIDs,
  ) async {
    final db = await instance.asyncDB;
    final Map<String, (Uint8List, int)> result = {};

    final rows = await db.getAll(
      'SELECT * FROM $clusterSummaryTable WHERE $clusterIDColumn IN (${List.filled(clusterIDs.length, '?').join(',')})',
      [...clusterIDs],
    );

    for (final r in rows) {
      final id = r[clusterIDColumn] as String;
      final avg = r[avgColumn] as Uint8List;
      final count = r[countColumn] as int;
      result[id] = (avg, count);
    }
    return result;
  }

  @override
  Future<Map<String, String>> getClusterIDToPersonID() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $personIdColumn, $clusterIDColumn FROM $clusterPersonTable',
    );
    final Map<String, String> result = {};
    for (final map in maps) {
      result[map[clusterIDColumn] as String] = map[personIdColumn] as String;
    }
    return result;
  }

  /// WARNING: This will delete ALL data in the database! Only use this for debug/testing purposes!
  @override
  Future<void> dropClustersAndPersonTable({bool faces = false}) async {
    try {
      final db = await instance.asyncDB;
      if (faces) {
        await db.execute(deleteFacesTable);
        await db.execute(createFacesTable);
        await db.execute(deleteFaceClustersTable);
        await db.execute(createFaceClustersTable);
        await db.execute(fcClusterIDIndex);
      }

      await db.execute(deleteClusterPersonTable);
      await db.execute(deleteNotPersonFeedbackTable);
      await db.execute(deleteClusterSummaryTable);
      await db.execute(deleteFaceClustersTable);

      await db.execute(createClusterPersonTable);
      await db.execute(createNotPersonFeedbackTable);
      await db.execute(createClusterSummaryTable);
      await db.execute(createFaceClustersTable);
      await db.execute(fcClusterIDIndex);
    } catch (e, s) {
      _logger.severe('Error dropping clusters and person table', e, s);
    }
  }

  /// WARNING: This will delete ALL data in the tables! Only use this for debug/testing purposes!
  @override
  Future<void> dropFacesFeedbackTables() async {
    try {
      final db = await instance.asyncDB;

      // Drop the tables
      await db.execute(deleteClusterPersonTable);
      await db.execute(deleteNotPersonFeedbackTable);

      // Recreate the tables
      await db.execute(createClusterPersonTable);
      await db.execute(createNotPersonFeedbackTable);
    } catch (e) {
      _logger.severe('Error dropping feedback tables', e);
    }
  }

  @override
  Future<List<int>> getFileIDsOfPersonID(String personID) async {
    final db = await instance.asyncDB;
    final result = await db.getAll(
      '''
        SELECT DISTINCT $facesTable.$fileIDColumn
        FROM $clusterPersonTable
        JOIN $faceClustersTable ON $clusterPersonTable.$clusterIDColumn = $faceClustersTable.$clusterIDColumn
        JOIN $facesTable ON $faceClustersTable.$faceIDColumn = $facesTable.$faceIDColumn
        WHERE $clusterPersonTable.$personIdColumn = ?
    ''',
      [personID],
    );

    return [for (final row in result) row[fileIDColumn]];
  }

  @override
  Future<List<int>> getFileIDsOfClusterID(String clusterID) async {
    final db = await instance.asyncDB;
    final result = await db.getAll(
      '''
        SELECT DISTINCT $facesTable.$fileIDColumn
        FROM $faceClustersTable
        JOIN $facesTable ON $faceClustersTable.$faceIDColumn = $facesTable.$faceIDColumn
        WHERE $faceClustersTable.$clusterIDColumn = ?
    ''',
      [clusterID],
    );

    return [for (final row in result) row[fileIDColumn]];
  }

  @override
  Future<Set<int>> getAllFileIDsOfFaceIDsNotInAnyCluster() async {
    final db = await instance.asyncDB;
    final result = await db.getAll(
      '''
        SELECT DISTINCT file_id
        FROM faces
        LEFT JOIN face_clusters ON faces.face_id = face_clusters.face_id
        WHERE face_clusters.face_id IS NULL;
    ''',
    );
    return <int>{for (final row in result) row[fileIDColumn]};
  }

  @override
  Future<Set<int>> getAllFilesAssociatedWithAllClusters({
    List<String>? exceptClusters,
  }) async {
    final notInParam = exceptClusters?.map((e) => "'$e'").join(',') ?? '';
    final db = await instance.asyncDB;
    final result = await db.getAll('''
        SELECT DISTINCT $facesTable.$fileIDColumn
        FROM $facesTable
        JOIN $faceClustersTable on $faceClustersTable.$faceIDColumn = $facesTable.$faceIDColumn
        WHERE $faceClustersTable.$clusterIDColumn NOT IN ($notInParam);
    ''');

    return <int>{for (final row in result) row[fileIDColumn]};
  }

  @override
  Future<List<EmbeddingVector>> getAllClipVectors() async {
    Logger("ClipDB").info("reading all embeddings from DB");
    final db = await instance.asyncDB;
    final results = await db
        .getAll('SELECT $fileIDColumn, $embeddingColumn FROM $clipTable');

    // Convert rows to vectors
    final List<EmbeddingVector> embeddings = [];
    for (final result in results) {
      // Convert to EmbeddingVector
      final embedding = EmbeddingVector(
        fileID: result[fileIDColumn],
        embedding: Float32List.view(result[embeddingColumn].buffer),
      );
      if (embedding.isEmpty) continue;
      embeddings.add(embedding);
    }
    return embeddings;
  }

  Future<void> checkMigrateFillClipVectorDB({bool force = false}) async {
    final migrationDone = await ClipVectorDB.instance.checkIfMigrationDone();
    if (migrationDone && !force) {
      _logger.info("ClipVectorDB migration not needed, already done");
      return;
    }
    _logger.info("Starting ClipVectorDB migration");

    // Get total count first to track progress
    _logger.info("Getting total count of clip embeddings");
    final db = await instance.asyncDB;
    final countResult =
        await db.getAll('SELECT COUNT($fileIDColumn) as total FROM $clipTable');
    final totalCount = countResult.first['total'] as int;
    if (totalCount == 0) {
      _logger.info("No clip embeddings to migrate");
      await ClipVectorDB.instance.setMigrationDone();
      return;
    }
    _logger.info("Total count of clip embeddings: $totalCount");

    _logger.info("First time referencing ClipVectorDB rust index in migration");
    final clipVectorDB = ClipVectorDB.instance;
    await clipVectorDB.deleteAllEmbeddings();
    _logger.info("ClipVectorDB rust index referenced");
    _logger.info("ClipVectorDB all embeddings cleared");

    _logger
        .info("Starting migration of $totalCount clip embeddings to vector DB");
    const batchSize = 5000;
    int offset = 0;
    int processedCount = 0;
    int weirdCount = 0;
    int whileCount = 0;
    final stopwatch = Stopwatch()..start();
    try {
      while (true) {
        whileCount++;
        _logger.info("$whileCount st round of while loop");
        // Allow some time for any GC to finish
        await Future.delayed(const Duration(milliseconds: 100));

        _logger.info("Reading $batchSize rows from DB");
        final List<Map<String, dynamic>> results = await db.getAll('''
        SELECT $fileIDColumn, $embeddingColumn
        FROM $clipTable
        ORDER BY $fileIDColumn DESC
        LIMIT $batchSize OFFSET $offset
      ''');
        _logger.info("Got ${results.length} results from DB");
        if (results.isEmpty) {
          _logger.info("No more results, breaking out of while loop");
          break;
        }
        _logger.info("Processing ${results.length} results");
        final List<int> fileIDs = [];
        final List<Float32List> embeddings = [];
        for (final result in results) {
          final embedding =
              Float32List.view((result[embeddingColumn] as Uint8List).buffer);
          if (embedding.length == 512) {
            fileIDs.add(result[fileIDColumn] as int);
            embeddings.add(Float32List.view(result[embeddingColumn].buffer));
          } else {
            weirdCount++;
          }
        }
        _logger.info(
          "Got ${fileIDs.length} valid embeddings, $weirdCount weird embeddings",
        );

        await ClipVectorDB.instance
            .bulkInsertEmbeddings(fileIDs: fileIDs, embeddings: embeddings);
        _logger.info("Inserted ${fileIDs.length} embeddings to ClipVectorDB");
        processedCount += fileIDs.length;
        offset += batchSize;
        _logger.info(
          "migrated $processedCount/$totalCount embeddings to ClipVectorDB",
        );
        if (processedCount >= totalCount) {
          _logger.info("All embeddings migrated, breaking out of while loop");
          break;
        }
        // Allow some time for any GC to finish
        _logger.info("Waiting for 100ms out of precaution, for GC to finish");
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _logger.info(
        "migrated all $totalCount embeddings to ClipVectorDB in ${stopwatch.elapsed.inMilliseconds} ms, with $weirdCount weird embeddings not migrated",
      );
      await ClipVectorDB.instance.setMigrationDone();
      _logger.info("ClipVectorDB migration done, flag file created");
    } catch (e, s) {
      _logger.severe(
        "Error migrating ClipVectorDB after ${stopwatch.elapsed.inMilliseconds} ms, clearing out DB again",
        e,
        s,
      );
      await clipVectorDB.deleteAllEmbeddings();
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  // Get indexed FileIDs
  @override
  Future<Map<int, int>> clipIndexedFileWithVersion() async {
    final db = await instance.asyncDB;
    final maps = await db
        .getAll('SELECT $fileIDColumn , $mlVersionColumn FROM $clipTable');
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fileIDColumn] as int] = map[mlVersionColumn] as int;
    }
    return result;
  }

  @override
  Future<int> getClipIndexedFileCount({
    int minimumMlVersion = clipMlVersion,
  }) async {
    final db = await instance.asyncDB;
    final String query =
        'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $clipTable WHERE $mlVersionColumn >= $minimumMlVersion';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.first['count'] as int;
  }

  @override
  Future<void> putClip(List<ClipEmbedding> embeddings) async {
    if (embeddings.isEmpty) return;
    final db = await instance.asyncDB;
    if (embeddings.length == 1) {
      await db.execute(
        'INSERT OR REPLACE INTO $clipTable ($fileIDColumn, $embeddingColumn, $mlVersionColumn) VALUES (?, ?, ?)',
        _getRowFromEmbedding(embeddings.first),
      );
      if (flagService.enableVectorDb &&
          await ClipVectorDB.instance.checkIfMigrationDone()) {
        await ClipVectorDB.instance.insertEmbedding(
          fileID: embeddings.first.fileID,
          embedding: embeddings.first.embedding,
        );
      }
    } else {
      final inputs = embeddings.map((e) => _getRowFromEmbedding(e)).toList();
      await db.executeBatch(
        'INSERT OR REPLACE INTO $clipTable ($fileIDColumn, $embeddingColumn, $mlVersionColumn) values(?, ?, ?)',
        inputs,
      );
      if (flagService.enableVectorDb &&
          await ClipVectorDB.instance.checkIfMigrationDone()) {
        await ClipVectorDB.instance.bulkInsertEmbeddings(
          fileIDs: embeddings.map((e) => e.fileID).toList(),
          embeddings:
              embeddings.map((e) => Float32List.fromList(e.embedding)).toList(),
        );
      }
    }
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  @override
  Future<void> deleteClipEmbeddings(List<int> fileIDs) async {
    final db = await instance.asyncDB;
    await db.execute(
      'DELETE FROM $clipTable WHERE $fileIDColumn IN (${fileIDs.join(", ")})',
    );
    if (flagService.enableVectorDb &&
        await ClipVectorDB.instance.checkIfMigrationDone()) {
      await ClipVectorDB.instance.deleteEmbeddings(fileIDs);
    }
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  @override
  Future<void> deleteClipIndexes() async {
    final db = await instance.asyncDB;
    await db.execute('DELETE FROM $clipTable');
    if (flagService.enableVectorDb &&
        await ClipVectorDB.instance.checkIfMigrationDone()) {
      await ClipVectorDB.instance.deleteAllEmbeddings();
    }
    Bus.instance.fire(EmbeddingUpdatedEvent());
  }

  List<Object?> _getRowFromEmbedding(ClipEmbedding embedding) {
    return [
      embedding.fileID,
      Float32List.fromList(embedding.embedding).buffer.asUint8List(),
      embedding.version,
    ];
  }

  /// WARNING: Better to use the similarly named [putFaceIdCachedForPersonOrCluster]
  /// method from face_thumbnail_cache instead!
  Future<void> putFaceIdCachedForPersonOrCluster(
    String personOrClusterId,
    String faceID,
  ) async {
    final db = await instance.asyncDB;
    await db.execute(
      '''
      INSERT OR REPLACE INTO $faceCacheTable ($personOrClusterIdColumn, $faceIDColumn)
      VALUES (?, ?)
    ''',
      [personOrClusterId, faceID],
    );
  }

  Future<String?> getFaceIdUsedForPersonOrCluster(
    String personOrClusterId,
  ) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      '''
      SELECT $faceIDColumn FROM $faceCacheTable
      WHERE $personOrClusterIdColumn = ?
    ''',
      [personOrClusterId],
    );
    if (maps.isNotEmpty) {
      return maps.first[faceIDColumn] as String;
    }
    return null;
  }

  Future<void> removeFaceIdCachedForPersonOrCluster(
    String personOrClusterID,
  ) async {
    final db = await instance.asyncDB;
    const String sql = '''
      DELETE FROM $faceCacheTable
      WHERE $personOrClusterIdColumn = ?
    ''';
    final List<Object?> params = [personOrClusterID];
    await db.execute(sql, params);
  }
}
