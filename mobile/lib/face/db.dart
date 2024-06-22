import 'dart:async';
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import "package:photos/extensions/stop_watch.dart";
import 'package:photos/face/db_fields.dart';
import "package:photos/face/db_model_mappers.dart";
import "package:photos/face/model/face.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_db_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import "package:photos/services/machine_learning/face_ml/face_ml_result.dart";
import "package:photos/utils/ml_util.dart";
import 'package:sqlite_async/sqlite_async.dart';

/// Stores all data for the FacesML-related features. The database can be accessed by `FaceMLDataDB.instance.database`.
///
/// This includes:
/// [facesTable] - Stores all the detected faces and its embeddings in the images.
/// [createFaceClustersTable] - Stores all the mappings from the faces (faceID) to the clusters (clusterID).
/// [clusterPersonTable] - Stores all the clusters that are mapped to a certain person.
/// [clusterSummaryTable] - Stores a summary of each cluster, containg the mean embedding and the number of faces in the cluster.
/// [notPersonFeedback] - Stores the clusters that are confirmed not to belong to a certain person by the user
class FaceMLDataDB {
  static final Logger _logger = Logger("FaceMLDataDB");

  static const _databaseName = "ente.face_ml_db.db";
  // static const _databaseVersion = 1;

  FaceMLDataDB._privateConstructor();

  static final FaceMLDataDB instance = FaceMLDataDB._privateConstructor();

  static final _migrationScripts = [
    createFacesTable,
    createFaceClustersTable,
    createClusterPersonTable,
    createClusterSummaryTable,
    createNotPersonFeedbackTable,
    fcClusterIDIndex,
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
    _logger.info("FaceMLDataDB: Starting migration");
    await _migrate(asyncDBConnection);
    _logger.info(
      "FaceMLDataDB Migration took ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();

    return asyncDBConnection;
  }

  Future<void> _migrate(
    SqliteDatabase database,
  ) async {
    final result = await database.execute('PRAGMA user_version');
    final currentVersion = result[0]['user_version'] as int;
    final toVersion = _migrationScripts.length;

    if (currentVersion < toVersion) {
      _logger.info("Migrating database from $currentVersion to $toVersion");
      await database.writeTransaction((tx) async {
        for (int i = currentVersion + 1; i <= toVersion; i++) {
          try {
            await tx.execute(_migrationScripts[i - 1]);
          } catch (e) {
            _logger.severe("Error running migration script index ${i - 1}", e);
            rethrow;
          }
        }
        await tx.execute('PRAGMA user_version = $toVersion');
      });
    } else if (currentVersion > toVersion) {
      throw AssertionError(
        "currentVersion($currentVersion) cannot be greater than toVersion($toVersion)",
      );
    }
  }

  // bulkInsertFaces inserts the faces in the database in batches of 1000.
  // This is done to avoid the error "too many SQL variables" when inserting
  // a large number of faces.
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
          $fileIDColumn, $faceIDColumn, $faceDetectionColumn, $faceEmbeddingBlob, $faceScore, $faceBlur, $isSideways, $imageHeight, $imageWidth, $mlVersionColumn 
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT($fileIDColumn, $faceIDColumn) DO UPDATE SET $faceIDColumn = excluded.$faceIDColumn, $faceDetectionColumn = excluded.$faceDetectionColumn, $faceEmbeddingBlob = excluded.$faceEmbeddingBlob, $faceScore = excluded.$faceScore, $faceBlur = excluded.$faceBlur, $isSideways = excluded.$isSideways, $imageHeight = excluded.$imageHeight, $imageWidth = excluded.$imageWidth, $mlVersionColumn = excluded.$mlVersionColumn 
      ''';
      final parameterSets = batch.map((face) {
        final map = mapRemoteToFaceDB(face);
        return [
          map[fileIDColumn],
          map[faceIDColumn],
          map[faceDetectionColumn],
          map[faceEmbeddingBlob],
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

  Future<void> updateFaceIdToClusterId(
    Map<String, int> faceIDToClusterID,
  ) async {
    final db = await instance.asyncDB;
    const batchSize = 500;
    final numBatches = (faceIDToClusterID.length / batchSize).ceil();
    for (int i = 0; i < numBatches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, faceIDToClusterID.length);
      final batch = faceIDToClusterID.entries.toList().sublist(start, end);

      const String sql = '''
        INSERT INTO $faceClustersTable ($fcFaceId, $fcClusterID)
        VALUES (?, ?)
        ON CONFLICT($fcFaceId) DO UPDATE SET $fcClusterID = excluded.$fcClusterID
      ''';
      final parameterSets = batch.map((e) => [e.key, e.value]).toList();

      await db.executeBatch(sql, parameterSets);
    }
  }

  /// Returns a map of fileID to the indexed ML version
  Future<Map<int, int>> getIndexedFileIds({int? minimumMlVersion}) async {
    final db = await instance.asyncDB;
    String query = '''
        SELECT $fileIDColumn, $mlVersionColumn
        FROM $facesTable
      ''';
    if (minimumMlVersion != null) {
      query += ' WHERE $mlVersionColumn >= $minimumMlVersion';
    }
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fileIDColumn] as int] = map[mlVersionColumn] as int;
    }
    return result;
  }

  Future<int> getIndexedFileCount({int? minimumMlVersion}) async {
    final db = await instance.asyncDB;
    String query =
        'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $facesTable';
    if (minimumMlVersion != null) {
      query += ' WHERE $mlVersionColumn >= $minimumMlVersion';
    }
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.first['count'] as int;
  }

  Future<Map<int, int>> clusterIdToFaceCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcClusterID, COUNT(*) as count FROM $faceClustersTable where $fcClusterID IS NOT NULL GROUP BY $fcClusterID ',
    );
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fcClusterID] as int] = map['count'] as int;
    }
    return result;
  }

  Future<Set<int>> getPersonIgnoredClusters(String personID) async {
    final db = await instance.asyncDB;
    // find out clusterIds that are assigned to other persons using the clusters table
    final List<Map<String, dynamic>> otherPersonMaps = await db.getAll(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn != ? AND $personIdColumn IS NOT NULL',
      [personID],
    );
    final Set<int> ignoredClusterIDs =
        otherPersonMaps.map((e) => e[clusterIDColumn] as int).toSet();
    final List<Map<String, dynamic>> rejectMaps = await db.getAll(
      'SELECT $clusterIDColumn FROM $notPersonFeedback WHERE $personIdColumn = ?',
      [personID],
    );
    final Set<int> rejectClusterIDs =
        rejectMaps.map((e) => e[clusterIDColumn] as int).toSet();
    return ignoredClusterIDs.union(rejectClusterIDs);
  }

  Future<Set<int>> getPersonClusterIDs(String personID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn = ?',
      [personID],
    );
    return maps.map((e) => e[clusterIDColumn] as int).toSet();
  }

  Future<void> clearTable() async {
    final db = await instance.asyncDB;

    await db.execute(deleteFacesTable);
    await db.execute(deleteFaceClustersTable);
    await db.execute(deleteClusterPersonTable);
    await db.execute(deleteClusterSummaryTable);
    await db.execute(deleteNotPersonFeedbackTable);
  }

  Future<Iterable<Uint8List>> getFaceEmbeddingsForCluster(
    int clusterID, {
    int? limit,
  }) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceEmbeddingBlob FROM $facesTable WHERE  $faceIDColumn in (SELECT $fcFaceId from $faceClustersTable where $fcClusterID = ?) ${limit != null ? 'LIMIT $limit' : ''}',
      [clusterID],
    );
    return maps.map((e) => e[faceEmbeddingBlob] as Uint8List);
  }

  Future<Map<int, Iterable<Uint8List>>> getFaceEmbeddingsForClusters(
    Iterable<int> clusterIDs, {
    int? limit,
  }) async {
    final db = await instance.asyncDB;
    final Map<int, List<Uint8List>> result = {};

    final selectQuery = '''
    SELECT fc.$fcClusterID, fe.$faceEmbeddingBlob
    FROM $faceClustersTable fc
    INNER JOIN $facesTable fe ON fc.$fcFaceId = fe.$faceIDColumn
    WHERE fc.$fcClusterID IN (${clusterIDs.join(',')})
    ${limit != null ? 'LIMIT $limit' : ''}
  ''';

    final List<Map<String, dynamic>> maps = await db.getAll(selectQuery);

    for (final map in maps) {
      final clusterID = map[fcClusterID] as int;
      final faceEmbedding = map[faceEmbeddingBlob] as Uint8List;
      result.putIfAbsent(clusterID, () => <Uint8List>[]).add(faceEmbedding);
    }

    return result;
  }

  Future<Face?> getCoverFaceForPerson({
    required int recentFileID,
    String? personID,
    String? avatarFaceId,
    int? clusterID,
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
          clusterRows.map((e) => e[clusterIDColumn] as int).toList();
      final List<Map<String, dynamic>> faceMaps = await db.getAll(
        'SELECT * FROM $facesTable where '
        '$faceIDColumn in (SELECT $fcFaceId from $faceClustersTable where  $fcClusterID IN (${clusterIDs.join(",")}))'
        'AND $fileIDColumn in (${fileId.join(",")}) AND $faceScore > $kMinimumQualityFaceScore ORDER BY $faceScore DESC',
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
        SELECT $fcFaceId
        FROM $faceClustersTable
        WHERE $fcClusterID = ?
      ''';
      final List<Map<String, dynamic>> faceMaps = await db.getAll(
        queryFaceID,
        [clusterID],
      );
      final List<Face>? faces = await getFacesForGivenFileID(recentFileID);
      if (faces != null) {
        for (final face in faces) {
          if (faceMaps
              .any((element) => (element[fcFaceId] as String) == face.faceID)) {
            return face;
          }
        }
      }
    }
    if (personID == null && clusterID == null) {
      throw Exception("personID and clusterID cannot be null");
    }
    return null;
  }

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

  Future<Map<int, Iterable<String>>> getClusterToFaceIDs(
    Set<int> clusterIDs,
  ) async {
    final db = await instance.asyncDB;
    final Map<int, List<String>> result = {};
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable WHERE $fcClusterID IN (${clusterIDs.join(",")})',
    );
    for (final map in maps) {
      final clusterID = map[fcClusterID] as int;
      final faceID = map[fcFaceId] as String;
      result.putIfAbsent(clusterID, () => <String>[]).add(faceID);
    }
    return result;
  }

  Future<int?> getClusterIDForFaceID(String faceID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcClusterID FROM $faceClustersTable WHERE $fcFaceId = ?',
      [faceID],
    );
    if (maps.isEmpty) {
      return null;
    }
    return maps.first[fcClusterID] as int;
  }

  Future<Map<int, Iterable<String>>> getAllClusterIdToFaceIDs() async {
    final db = await instance.asyncDB;
    final Map<int, List<String>> result = {};
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable',
    );
    for (final map in maps) {
      final clusterID = map[fcClusterID] as int;
      final faceID = map[fcFaceId] as String;
      result.putIfAbsent(clusterID, () => <String>[]).add(faceID);
    }
    return result;
  }

  Future<Iterable<String>> getFaceIDsForCluster(int clusterID) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcFaceId FROM $faceClustersTable '
      'WHERE $faceClustersTable.$fcClusterID = ?',
      [clusterID],
    );
    return maps.map((e) => e[fcFaceId] as String).toSet();
  }

  // Get Map of personID to Map of clusterID to faceIDs
  Future<Map<String, Map<int, Set<String>>>>
      getPersonToClusterIdToFaceIds() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $personIdColumn, $faceClustersTable.$fcClusterID, $fcFaceId FROM $clusterPersonTable '
      'LEFT JOIN $faceClustersTable ON $clusterPersonTable.$clusterIDColumn = $faceClustersTable.$fcClusterID',
    );
    final Map<String, Map<int, Set<String>>> result = {};
    for (final map in maps) {
      final personID = map[personIdColumn] as String;
      final clusterID = map[fcClusterID] as int;
      final faceID = map[fcFaceId] as String;
      result
          .putIfAbsent(personID, () => {})
          .putIfAbsent(clusterID, () => {})
          .add(faceID);
    }
    return result;
  }

  Future<Set<String>> getFaceIDsForPerson(String personID) async {
    final db = await instance.asyncDB;
    final faceIdsResult = await db.getAll(
      'SELECT $fcFaceId FROM $faceClustersTable LEFT JOIN $clusterPersonTable '
      'ON $faceClustersTable.$fcClusterID = $clusterPersonTable.$clusterIDColumn '
      'WHERE $clusterPersonTable.$personIdColumn = ?',
      [personID],
    );
    return faceIdsResult.map((e) => e[fcFaceId] as String).toSet();
  }

  Future<Iterable<double>> getBlurValuesForCluster(int clusterID) async {
    final db = await instance.asyncDB;
    const String query = '''
        SELECT $facesTable.$faceBlur 
        FROM $facesTable 
        JOIN $faceClustersTable ON $facesTable.$faceIDColumn = $faceClustersTable.$fcFaceId 
        WHERE $faceClustersTable.$fcClusterID = ?
      ''';
    // const String query2 = '''
    //     SELECT $faceBlur
    //     FROM $facesTable
    //     WHERE $faceIDColumn IN (SELECT $fcFaceId FROM $faceClustersTable WHERE $fcClusterID = ?)
    //   ''';
    final List<Map<String, dynamic>> maps = await db.getAll(
      query,
      [clusterID],
    );
    return maps.map((e) => e[faceBlur] as double).toSet();
  }

  Future<Map<String, int?>> getFaceIdsToClusterIds(
    Iterable<String> faceIds,
  ) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcFaceId, $fcClusterID FROM $faceClustersTable where $fcFaceId IN (${faceIds.map((id) => "'$id'").join(",")})',
    );
    final Map<String, int?> result = {};
    for (final map in maps) {
      result[map[fcFaceId] as String] = map[fcClusterID] as int?;
    }
    return result;
  }

  Future<Map<int, Set<int>>> getFileIdToClusterIds() async {
    final Map<int, Set<int>> result = {};
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable',
    );

    for (final map in maps) {
      final clusterID = map[fcClusterID] as int;
      final faceID = map[fcFaceId] as String;
      final fileID = getFileIdFromFaceId(faceID);
      result[fileID] = (result[fileID] ?? {})..add(clusterID);
    }
    return result;
  }

  Future<void> forceUpdateClusterIds(
    Map<String, int> faceIDToClusterID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $faceClustersTable ($fcFaceId, $fcClusterID)
      VALUES (?, ?)
      ON CONFLICT($fcFaceId) DO UPDATE SET $fcClusterID = excluded.$fcClusterID
    ''';
    final parameterSets =
        faceIDToClusterID.entries.map((e) => [e.key, e.value]).toList();
    await db.executeBatch(sql, parameterSets);
  }

  Future<void> removePerson(String personID) async {
    final db = await instance.asyncDB;

    await db.writeTransaction((tx) async {
      await tx.execute(
        'DELETE FROM $clusterPersonTable WHERE $personIdColumn = ?',
        [personID],
      );
      await tx.execute(
        'DELETE FROM $notPersonFeedback WHERE $personIdColumn = ?',
        [personID],
      );
    });
  }

  Future<List<FaceDbInfoForClustering>> getFaceInfoForClustering({
    double minScore = kMinimumQualityFaceScore,
    int minClarity = kLaplacianHardThreshold,
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
          'SELECT $faceIDColumn, $faceEmbeddingBlob, $faceScore, $faceBlur, $isSideways FROM $facesTable'
          ' WHERE $faceScore > $minScore AND $faceBlur > $minClarity'
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
            embeddingBytes: map[faceEmbeddingBlob] as Uint8List,
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
        SELECT $faceIDColumn, $faceEmbeddingBlob 
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
        result[faceID] = map[faceEmbeddingBlob] as Uint8List;
      }
      if (result.length > 10000) {
        break;
      }
      offset += batchSize;
    }
    _logger.info('done reading face embeddings for ${faceIDs.length} faces');
    return result;
  }

  Future<int> getTotalFaceCount({
    double minFaceScore = kMinimumQualityFaceScore,
  }) async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceScore > $minFaceScore AND $faceBlur > $kLaplacianHardThreshold',
    );
    return maps.first['count'] as int;
  }

  Future<int> getClusteredOrFacelessFileCount() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> clustered = await db.getAll(
      'SELECT $fcFaceId FROM $faceClustersTable',
    );
    final Set<int> clusteredFileIDs = {};
    for (final map in clustered) {
      final int fileID = getFileIdFromFaceId(map[fcFaceId] as String);
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

  Future<double> getClusteredToIndexableFilesRatio() async {
    final int indexableFiles = (await getIndexableFileIDs()).length;
    final int clusteredFiles = await getClusteredOrFacelessFileCount();

    return clusteredFiles / indexableFiles;
  }

  Future<int> getUnclusteredFaceCount() async {
    final db = await instance.asyncDB;
    const String query = '''
      SELECT f.$faceIDColumn
      FROM $facesTable f
      LEFT JOIN $faceClustersTable fc ON f.$faceIDColumn = fc.$fcFaceId
      WHERE f.$faceScore > $kMinimumQualityFaceScore
      AND f.$faceBlur > $kLaplacianHardThreshold
      AND fc.$fcFaceId IS NULL
    ''';
    final List<Map<String, dynamic>> maps = await db.getAll(query);
    return maps.length;
  }

  Future<void> assignClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $clusterPersonTable ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT($personIdColumn, $clusterIDColumn) DO NOTHING
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  Future<void> bulkAssignClusterToPersonID(
    Map<int, String> clusterToPersonID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $clusterPersonTable ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT($personIdColumn, $clusterIDColumn) DO NOTHING
    ''';
    final parameterSets =
        clusterToPersonID.entries.map((e) => [e.value, e.key]).toList();
    await db.executeBatch(sql, parameterSets);
  }

  Future<void> captureNotPersonFeedback({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $notPersonFeedback ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT DO NOTHING
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  Future<void> bulkCaptureNotPersonFeedback(
    Map<int, String> clusterToPersonID,
  ) async {
    final db = await instance.asyncDB;

    const String sql = '''
      INSERT INTO $notPersonFeedback ($personIdColumn, $clusterIDColumn) VALUES (?, ?) ON CONFLICT DO NOTHING
    ''';
    final parameterSets =
        clusterToPersonID.entries.map((e) => [e.value, e.key]).toList();

    await db.executeBatch(sql, parameterSets);
  }

  Future<void> removeNotPersonFeedback({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      DELETE FROM $notPersonFeedback WHERE $personIdColumn = ? AND $clusterIDColumn = ?
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  Future<void> removeClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.asyncDB;

    const String sql = '''
      DELETE FROM $clusterPersonTable WHERE $personIdColumn = ? AND $clusterIDColumn = ?
    ''';
    await db.execute(sql, [personID, clusterID]);
  }

  // for a given personID, return a map of clusterID to fileIDs using join query
  Future<Map<int, Set<int>>> getFileIdToClusterIDSet(String personID) {
    final db = instance.asyncDB;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.getAll(
        'SELECT $faceClustersTable.$fcClusterID, $fcFaceId FROM $faceClustersTable '
        'INNER JOIN $clusterPersonTable '
        'ON $faceClustersTable.$fcClusterID = $clusterPersonTable.$clusterIDColumn '
        'WHERE $clusterPersonTable.$personIdColumn = ?',
        [personID],
      );
      final Map<int, Set<int>> result = {};
      for (final map in maps) {
        final clusterID = map[clusterIDColumn] as int;
        final String faceID = map[fcFaceId] as String;
        final fileID = getFileIdFromFaceId(faceID);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  Future<Map<int, Set<int>>> getFileIdToClusterIDSetForCluster(
    Set<int> clusterIDs,
  ) {
    final db = instance.asyncDB;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.getAll(
        'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable '
        'WHERE $fcClusterID IN (${clusterIDs.join(",")})',
      );
      final Map<int, Set<int>> result = {};
      for (final map in maps) {
        final clusterID = map[fcClusterID] as int;
        final faceID = map[fcFaceId] as String;
        final fileID = getFileIdFromFaceId(faceID);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  Future<void> clusterSummaryUpdate(Map<int, (Uint8List, int)> summary) async {
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
      final int clusterID = entry.key;
      final int count = entry.value.$2;
      final Uint8List avg = entry.value.$1;
      parameterSets.add([clusterID, avg, count]);
      batchCounter++;
    }
    await db.executeBatch(sql, parameterSets);
  }

  Future<void> deleteClusterSummary(int clusterID) async {
    final db = await instance.asyncDB;
    const String sqlDelete =
        'DELETE FROM $clusterSummaryTable WHERE $clusterIDColumn = ?';
    await db.execute(sqlDelete, [clusterID]);
  }

  /// Returns a map of clusterID to (avg embedding, count)
  Future<Map<int, (Uint8List, int)>> getAllClusterSummary([
    int? minClusterSize,
  ]) async {
    final db = await instance.asyncDB;
    final Map<int, (Uint8List, int)> result = {};
    final rows = await db.getAll(
      'SELECT * FROM $clusterSummaryTable${minClusterSize != null ? ' WHERE $countColumn >= $minClusterSize' : ''}',
    );
    for (final r in rows) {
      final id = r[clusterIDColumn] as int;
      final avg = r[avgColumn] as Uint8List;
      final count = r[countColumn] as int;
      result[id] = (avg, count);
    }
    return result;
  }

  Future<Map<int, (Uint8List, int)>> getClusterToClusterSummary(
    Iterable<int> clusterIDs,
  ) async {
    final db = await instance.asyncDB;
    final Map<int, (Uint8List, int)> result = {};
    final rows = await db.getAll(
      'SELECT * FROM $clusterSummaryTable WHERE $clusterIDColumn IN (${clusterIDs.join(",")})',
    );
    for (final r in rows) {
      final id = r[clusterIDColumn] as int;
      final avg = r[avgColumn] as Uint8List;
      final count = r[countColumn] as int;
      result[id] = (avg, count);
    }
    return result;
  }

  Future<Map<int, String>> getClusterIDToPersonID() async {
    final db = await instance.asyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $personIdColumn, $clusterIDColumn FROM $clusterPersonTable',
    );
    final Map<int, String> result = {};
    for (final map in maps) {
      result[map[clusterIDColumn] as int] = map[personIdColumn] as String;
    }
    return result;
  }

  /// WARNING: This will delete ALL data in the database! Only use this for debug/testing purposes!
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
  Future<void> dropFeedbackTables() async {
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
}
