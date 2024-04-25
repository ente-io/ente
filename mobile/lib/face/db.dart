import 'dart:async';
import "dart:io" show Directory;
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
import "package:photos/models/file/file.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_info_for_clustering.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

/// Stores all data for the ML-related features. The database can be accessed by `MlDataDB.instance.database`.
///
/// This includes:
/// [facesTable] - Stores all the detected faces and its embeddings in the images.
/// [personTable] - Stores all the clusters of faces which are considered to be the same person.
class FaceMLDataDB {
  static final Logger _logger = Logger("FaceMLDataDB");

  static const _databaseName = "ente.face_ml_db.db";
  static const _databaseVersion = 1;

  FaceMLDataDB._privateConstructor();

  static final FaceMLDataDB instance = FaceMLDataDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Future<Database>? _dbFuture;
  static Future<sqlite_async.SqliteDatabase>? _sqliteAsyncDBFuture;

  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<sqlite_async.SqliteDatabase> get sqliteAsyncDB async {
    _sqliteAsyncDBFuture ??= _initSqliteAsyncDatabase();
    return _sqliteAsyncDBFuture!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final String databaseDirectory =
        join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      databaseDirectory,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<sqlite_async.SqliteDatabase> _initSqliteAsyncDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String databaseDirectory =
        join(documentsDirectory.path, _databaseName);
    _logger.info("Opening sqlite_async access: DB path " + databaseDirectory);
    return sqlite_async.SqliteDatabase(path: databaseDirectory, maxReaders: 1);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(createFacesTable);
    await db.execute(createFaceClustersTable);
    await db.execute(createClusterPersonTable);
    await db.execute(createClusterSummaryTable);
    await db.execute(createNotPersonFeedbackTable);
    await db.execute(fcClusterIDIndex);
  }

  // bulkInsertFaces inserts the faces in the database in batches of 1000.
  // This is done to avoid the error "too many SQL variables" when inserting
  // a large number of faces.
  Future<void> bulkInsertFaces(List<Face> faces) async {
    final db = await instance.database;
    const batchSize = 500;
    final numBatches = (faces.length / batchSize).ceil();
    for (int i = 0; i < numBatches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, faces.length);
      final batch = faces.sublist(start, end);
      final batchInsert = db.batch();
      for (final face in batch) {
        batchInsert.insert(
          facesTable,
          mapRemoteToFaceDB(face),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batchInsert.commit(noResult: true);
    }
  }

  Future<void> updateClusterIdToFaceId(
    Map<String, int> faceIDToClusterID,
  ) async {
    final db = await instance.database;
    const batchSize = 500;
    final numBatches = (faceIDToClusterID.length / batchSize).ceil();
    for (int i = 0; i < numBatches; i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, faceIDToClusterID.length);
      final batch = faceIDToClusterID.entries.toList().sublist(start, end);

      final batchUpdate = db.batch();

      for (final entry in batch) {
        final faceID = entry.key;
        final clusterID = entry.value;
        batchUpdate.insert(
          faceClustersTable,
          {fcClusterID: clusterID, fcFaceId: faceID},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batchUpdate.commit(noResult: true);
    }
  }

  /// Returns a map of fileID to the indexed ML version
  Future<Map<int, int>> getIndexedFileIds() async {
    final db = await instance.sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fileIDColumn, $mlVersionColumn FROM $facesTable',
    );
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fileIDColumn] as int] = map[mlVersionColumn] as int;
    }
    return result;
  }

  Future<int> getIndexedFileCount() async {
    final db = await instance.sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT COUNT(DISTINCT $fileIDColumn) as count FROM $facesTable',
    );
    return maps.first['count'] as int;
  }

  Future<Map<int, int>> clusterIdToFaceCount() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT $fcClusterID, COUNT(*) as count FROM $faceClustersTable where $fcClusterID IS NOT NULL GROUP BY $fcClusterID ',
    );
    final Map<int, int> result = {};
    for (final map in maps) {
      result[map[fcClusterID] as int] = map['count'] as int;
    }
    return result;
  }

  Future<Set<int>> getPersonIgnoredClusters(String personID) async {
    final db = await instance.database;
    // find out clusterIds that are assigned to other persons using the clusters table
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn != ? AND $personIdColumn IS NOT NULL',
      [personID],
    );
    final Set<int> ignoredClusterIDs =
        maps.map((e) => e[clusterIDColumn] as int).toSet();
    final List<Map<String, dynamic>> rejectMaps = await db.rawQuery(
      'SELECT $clusterIDColumn FROM $notPersonFeedback WHERE $personIdColumn = ?',
      [personID],
    );
    final Set<int> rejectClusterIDs =
        rejectMaps.map((e) => e[clusterIDColumn] as int).toSet();
    return ignoredClusterIDs.union(rejectClusterIDs);
  }

  Future<Set<int>> getPersonClusterIDs(String personID) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT $clusterIDColumn FROM $clusterPersonTable WHERE $personIdColumn = ?',
      [personID],
    );
    return maps.map((e) => e[clusterIDColumn] as int).toSet();
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(facesTable);
    await db.delete(clusterPersonTable);
    await db.delete(clusterSummaryTable);
    await db.delete(personTable);
    await db.delete(notPersonFeedback);
  }

  Future<Iterable<Uint8List>> getFaceEmbeddingsForCluster(
    int clusterID, {
    int? limit,
  }) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT $faceEmbeddingBlob FROM $facesTable WHERE  $faceIDColumn in (SELECT $fcFaceId from $faceClustersTable where $fcClusterID = ?) ${limit != null ? 'LIMIT $limit' : ''}',
      [clusterID],
    );
    return maps.map((e) => e[faceEmbeddingBlob] as Uint8List);
  }

  Future<Map<int, Iterable<Uint8List>>> getFaceEmbeddingsForClusters(
    Iterable<int> clusterIDs, {
    int? limit,
  }) async {
    final db = await instance.database;
    final Map<int, List<Uint8List>> result = {};

    final selectQuery = '''
    SELECT fc.$fcClusterID, fe.$faceEmbeddingBlob
    FROM $faceClustersTable fc
    INNER JOIN $facesTable fe ON fc.$fcFaceId = fe.$faceIDColumn
    WHERE fc.$fcClusterID IN (${clusterIDs.join(',')})
    ${limit != null ? 'LIMIT $limit' : ''}
  ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(selectQuery);

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
    final db = await instance.database;
    if (personID != null) {
      final List<int> fileId = [recentFileID];
      int? avatarFileId;
      if (avatarFaceId != null) {
        avatarFileId = int.tryParse(avatarFaceId.split('_')[0]);
        if (avatarFileId != null) {
          fileId.add(avatarFileId);
        }
      }
      final cluterRows = await db.query(
        clusterPersonTable,
        columns: [clusterIDColumn],
        where: '$personIdColumn = ?',
        whereArgs: [personID],
      );
      final clusterIDs =
          cluterRows.map((e) => e[clusterIDColumn] as int).toList();
      final List<Map<String, dynamic>> faceMaps = await db.rawQuery(
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
      final List<Map<String, dynamic>> faceMaps = await db.query(
        faceClustersTable,
        columns: [fcFaceId],
        where: '$fcClusterID = ?',
        whereArgs: [clusterID],
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
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      facesTable,
      columns: [
        faceIDColumn,
        fileIDColumn,
        faceEmbeddingBlob,
        faceScore,
        faceDetectionColumn,
        faceBlur,
        imageHeight,
        imageWidth,
        mlVersionColumn,
      ],
      where: '$fileIDColumn = ?',
      whereArgs: [fileUploadID],
    );
    if (maps.isEmpty) {
      return null;
    }
    return maps.map((e) => mapRowToFace(e)).toList();
  }

  Future<Face?> getFaceForFaceID(String faceID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT * FROM $facesTable where $faceIDColumn = ?',
      [faceID],
    );
    if (result.isEmpty) {
      return null;
    }
    return mapRowToFace(result.first);
  }

  Future<Map<int, Iterable<String>>> getClusterToFaceIDs(
    Set<int> clusterIDs,
  ) async {
    final db = await instance.sqliteAsyncDB;
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

  Future<Iterable<String>> getFaceIDsForCluster(int clusterID) async {
    final db = await instance.sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $fcFaceId FROM $faceClustersTable '
      'WHERE $faceClustersTable.$fcClusterID = ?',
      [clusterID],
    );
    return maps.map((e) => e[fcFaceId] as String).toSet();
  }

  Future<Iterable<String>> getFaceIDsForPerson(String personID) async {
    final db = await instance.sqliteAsyncDB;
    final faceIdsResult = await db.getAll(
      'SELECT $fcFaceId FROM $faceClustersTable LEFT JOIN $clusterPersonTable '
      'ON $faceClustersTable.$fcClusterID = $clusterPersonTable.$clusterIDColumn '
      'WHERE $clusterPersonTable.$personIdColumn = ?',
      [personID],
    );
    return faceIdsResult.map((e) => e[fcFaceId] as String).toSet();
  }

  Future<Iterable<double>> getBlurValuesForCluster(int clusterID) async {
    final db = await instance.sqliteAsyncDB;
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

  Future<Map<String, double>> getFaceIDsToBlurValues(
    int maxBlurValue,
  ) async {
    final db = await instance.sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT $faceIDColumn, $faceBlur FROM $facesTable WHERE $faceBlur < $maxBlurValue AND $faceBlur > 1 ORDER BY $faceBlur ASC',
    );
    final Map<String, double> result = {};
    for (final map in maps) {
      result[map[faceIDColumn] as String] = map[faceBlur] as double;
    }
    return result;
  }

  Future<Map<String, int?>> getFaceIdsToClusterIds(
    Iterable<String> faceIds,
  ) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
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
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable',
    );

    for (final map in maps) {
      final clusterID = map[fcClusterID] as int;
      final faceID = map[fcFaceId] as String;
      final x = faceID.split('_').first;
      final fileID = int.parse(x);
      result[fileID] = (result[fileID] ?? {})..add(clusterID);
    }
    return result;
  }

  Future<void> forceUpdateClusterIds(
    Map<String, int> faceIDToClusterID,
  ) async {
    final db = await instance.database;

    // Start a batch
    final batch = db.batch();

    for (final map in faceIDToClusterID.entries) {
      final faceID = map.key;
      final clusterID = map.value;
      batch.insert(
        faceClustersTable,
        {fcFaceId: faceID, fcClusterID: clusterID},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    // Commit the batch
    await batch.commit(noResult: true);
  }

  Future<void> removePerson(String personID) async {
    final db = await instance.database;
    await db.delete(
      clusterPersonTable,
      where: '$personIdColumn = ?',
      whereArgs: [personID],
    );
    await db.delete(
      notPersonFeedback,
      where: '$personIdColumn = ?',
      whereArgs: [personID],
    );
  }

  Future<Set<FaceInfoForClustering>> getFaceInfoForClustering({
    double minScore = kMinimumQualityFaceScore,
    int minClarity = kLaplacianHardThreshold,
    int maxFaces = 20000,
    int offset = 0,
    int batchSize = 10000,
  }) async {
    final EnteWatch w = EnteWatch("getFaceEmbeddingMap")..start();
    w.logAndReset(
      'reading as float offset: $offset, maxFaces: $maxFaces, batchSize: $batchSize',
    );
    final db = await instance.sqliteAsyncDB;

    final Set<FaceInfoForClustering> result = {};
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
        final faceInfo = FaceInfoForClustering(
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
  }

  /// Returns a map of faceID to record of clusterId and faceEmbeddingBlob
  ///
  /// Only selects faces with score greater than [minScore] and blur score greater than [minClarity]
  Future<Map<String, (int?, Uint8List)>> getFaceEmbeddingMap({
    double minScore = kMinimumQualityFaceScore,
    int minClarity = kLaplacianHardThreshold,
    int maxFaces = 20000,
    int offset = 0,
    int batchSize = 10000,
  }) async {
    final EnteWatch w = EnteWatch("getFaceEmbeddingMap")..start();
    w.logAndReset(
      'reading as float offset: $offset, maxFaces: $maxFaces, batchSize: $batchSize',
    );
    final db = await instance.sqliteAsyncDB;

    final Map<String, (int?, Uint8List)> result = {};
    while (true) {
      // Query a batch of rows
      final List<Map<String, dynamic>> maps = await db.getAll(
        'SELECT $faceIDColumn, $faceEmbeddingBlob FROM $facesTable'
        ' WHERE $faceScore > $minScore AND $faceBlur > $minClarity'
        ' ORDER BY $faceIDColumn'
        ' DESC LIMIT $batchSize OFFSET $offset',
        // facesTable,
        // columns: [faceIDColumn, faceEmbeddingBlob],
        // where: '$faceScore > $minScore and $faceBlur > $minClarity',
        // limit: batchSize,
        // offset: offset,
        // orderBy: '$faceIDColumn DESC',
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
        result[faceID] =
            (faceIdToClusterId[faceID], map[faceEmbeddingBlob] as Uint8List);
      }
      if (result.length >= maxFaces) {
        break;
      }
      offset += batchSize;
    }
    w.stopWithLog('done reading face embeddings ${result.length}');
    return result;
  }

  Future<Map<String, Uint8List>> getFaceEmbeddingMapForFile(
    List<int> fileIDs,
  ) async {
    _logger.info('reading face embeddings for ${fileIDs.length} files');
    final db = await instance.database;

    // Define the batch size
    const batchSize = 10000;
    int offset = 0;

    final Map<String, Uint8List> result = {};
    while (true) {
      // Query a batch of rows
      final List<Map<String, dynamic>> maps = await db.query(
        facesTable,
        columns: [faceIDColumn, faceEmbeddingBlob],
        where:
            '$faceScore > $kMinimumQualityFaceScore AND $faceBlur > $kLaplacianHardThreshold AND $fileIDColumn IN (${fileIDs.join(",")})',
        limit: batchSize,
        offset: offset,
        orderBy: '$faceIDColumn DESC',
      );
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
    _logger.info('done reading face embeddings for ${fileIDs.length} files');
    return result;
  }

  Future<Map<String, Uint8List>> getFaceEmbeddingMapForFaces(
    Iterable<String> faceIDs,
  ) async {
    _logger.info('reading face embeddings for ${faceIDs.length} faces');
    final db = await instance.sqliteAsyncDB;

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
    final db = await instance.sqliteAsyncDB;
    final List<Map<String, dynamic>> maps = await db.getAll(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceScore > $minFaceScore AND $faceBlur > $kLaplacianHardThreshold',
    );
    return maps.first['count'] as int;
  }

  Future<double> getClusteredToTotalFacesRatio() async {
    final db = await instance.sqliteAsyncDB;

    final List<Map<String, dynamic>> totalFacesMaps = await db.getAll(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceScore > $kMinimumQualityFaceScore AND $faceBlur > $kLaplacianHardThreshold',
    );
    final int totalFaces = totalFacesMaps.first['count'] as int;

    final List<Map<String, dynamic>> clusteredFacesMaps = await db.getAll(
      'SELECT COUNT(DISTINCT $fcFaceId) as count FROM $faceClustersTable',
    );
    final int clusteredFaces = clusteredFacesMaps.first['count'] as int;

    return clusteredFaces / totalFaces;
  }

  Future<int> getBlurryFaceCount([
    int blurThreshold = kLaplacianHardThreshold,
  ]) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $facesTable WHERE $faceBlur <= $blurThreshold AND $faceScore > $kMinimumQualityFaceScore',
    );
    return maps.first['count'] as int;
  }

  Future<void> resetClusterIDs() async {
    final db = await instance.database;
    await db.execute(dropFaceClustersTable);
    await db.execute(createFaceClustersTable);
    await db.execute(fcClusterIDIndex);
  }

  Future<void> assignClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.database;
    await db.insert(
      clusterPersonTable,
      {
        personIdColumn: personID,
        clusterIDColumn: clusterID,
      },
    );
  }

  Future<void> bulkAssignClusterToPersonID(
    Map<int, String> clusterToPersonID,
  ) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final entry in clusterToPersonID.entries) {
      final clusterID = entry.key;
      final personID = entry.value;
      batch.insert(
        clusterPersonTable,
        {
          personIdColumn: personID,
          clusterIDColumn: clusterID,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> captureNotPersonFeedback({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.database;
    await db.insert(
      notPersonFeedback,
      {
        personIdColumn: personID,
        clusterIDColumn: clusterID,
      },
    );
  }

  Future<void> bulkCaptureNotPersonFeedback(
    Map<int, String> clusterToPersonID,
  ) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final entry in clusterToPersonID.entries) {
      final clusterID = entry.key;
      final personID = entry.value;
      batch.insert(
        notPersonFeedback,
        {
          personIdColumn: personID,
          clusterIDColumn: clusterID,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> removeClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final db = await instance.database;
    return db.delete(
      clusterPersonTable,
      where: '$personIdColumn = ? AND $clusterIDColumn = ?',
      whereArgs: [personID, clusterID],
    );
  }

  // for a given personID, return a map of clusterID to fileIDs using join query
  Future<Map<int, Set<int>>> getFileIdToClusterIDSet(String personID) {
    final db = instance.database;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
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
        final fileID = int.parse(faceID.split('_').first);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  Future<Map<int, Set<int>>> getFileIdToClusterIDSetForCluster(
    Set<int> clusterIDs,
  ) {
    final db = instance.database;
    return db.then((db) async {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT $fcClusterID, $fcFaceId FROM $faceClustersTable '
        'WHERE $fcClusterID IN (${clusterIDs.join(",")})',
      );
      final Map<int, Set<int>> result = {};
      for (final map in maps) {
        final clusterID = map[fcClusterID] as int;
        final faceId = map[fcFaceId] as String;
        final fileID = int.parse(faceId.split("_").first);
        result[fileID] = (result[fileID] ?? {})..add(clusterID);
      }
      return result;
    });
  }

  Future<void> clusterSummaryUpdate(Map<int, (Uint8List, int)> summary) async {
    final db = await instance.database;
    var batch = db.batch();
    int batchCounter = 0;
    for (final entry in summary.entries) {
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      final int cluserID = entry.key;
      final int count = entry.value.$2;
      final Uint8List avg = entry.value.$1;
      batch.insert(
        clusterSummaryTable,
        {
          clusterIDColumn: cluserID,
          avgColumn: avg,
          countColumn: count,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
  }

  /// Returns a map of clusterID to (avg embedding, count)
  Future<Map<int, (Uint8List, int)>> getAllClusterSummary([
    int? minClusterSize,
  ]) async {
    final db = await instance.sqliteAsyncDB;
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
    final db = await instance.sqliteAsyncDB;
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
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
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
    final db = await instance.database;
    if (faces) {
      await db.execute(deleteFacesTable);
      await db.execute(createFacesTable);
      await db.execute(dropFaceClustersTable);
      await db.execute(createFaceClustersTable);
      await db.execute(fcClusterIDIndex);
    }
    await db.execute(deletePersonTable);
    await db.execute(dropClusterPersonTable);
    await db.execute(dropClusterSummaryTable);
    await db.execute(dropNotPersonFeedbackTable);

    await db.execute(createClusterPersonTable);
    await db.execute(createNotPersonFeedbackTable);
    await db.execute(createClusterSummaryTable);
  }

  /// WARNING: This will delete ALL data in the database! Only use this for debug/testing purposes!
  Future<void> dropFeedbackTables() async {
    final db = await instance.database;

    await db.execute(deletePersonTable);
    await db.execute(dropClusterPersonTable);
    await db.execute(dropNotPersonFeedbackTable);
    await db.execute(dropClusterSummaryTable);
    await db.execute(createClusterPersonTable);
    await db.execute(createNotPersonFeedbackTable);
    await db.execute(createClusterSummaryTable);
  }

  Future<void> removeFilesFromPerson(
    List<EnteFile> files,
    String personID,
  ) async {
    final db = await instance.database;
    final faceIdsResult = await db.rawQuery(
      'SELECT $fcFaceId FROM $faceClustersTable LEFT JOIN $clusterPersonTable '
      'ON $faceClustersTable.$fcClusterID = $clusterPersonTable.$clusterIDColumn '
      'WHERE $clusterPersonTable.$personIdColumn = ?',
      [personID],
    );
    final Set<String> fileIds = {};
    for (final enteFile in files) {
      fileIds.add(enteFile.uploadedFileID.toString());
    }
    int maxClusterID = DateTime.now().microsecondsSinceEpoch;
    final Map<String, int> faceIDToClusterID = {};
    for (final row in faceIdsResult) {
      final faceID = row[fcFaceId] as String;
      if (fileIds.contains(faceID.split('_').first)) {
        maxClusterID += 1;
        faceIDToClusterID[faceID] = maxClusterID;
      }
    }
    await forceUpdateClusterIds(faceIDToClusterID);
  }

  Future<void> removeFilesFromCluster(
    List<EnteFile> files,
    int clusterID,
  ) async {
    final db = await instance.database;
    final faceIdsResult = await db.rawQuery(
      'SELECT $fcFaceId FROM $faceClustersTable '
      'WHERE $faceClustersTable.$fcClusterID = ?',
      [clusterID],
    );
    final Set<String> fileIds = {};
    for (final enteFile in files) {
      fileIds.add(enteFile.uploadedFileID.toString());
    }
    int maxClusterID = DateTime.now().microsecondsSinceEpoch;
    final Map<String, int> faceIDToClusterID = {};
    for (final row in faceIdsResult) {
      final faceID = row[fcFaceId] as String;
      if (fileIds.contains(faceID.split('_').first)) {
        maxClusterID += 1;
        faceIDToClusterID[faceID] = maxClusterID;
      }
    }
    await forceUpdateClusterIds(faceIDToClusterID);
  }

  Future<void> addFacesToCluster(
    List<String> faceIDs,
    int clusterID,
  ) async {
    final faceIDToClusterID = <String, int>{};
    for (final faceID in faceIDs) {
      faceIDToClusterID[faceID] = clusterID;
    }

    await forceUpdateClusterIds(faceIDToClusterID);
  }
}
