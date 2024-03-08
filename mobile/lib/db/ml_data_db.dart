import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/ml/ml_typedefs.dart';
import "package:photos/services/face_ml/face_feedback.dart/cluster_feedback.dart";
import "package:photos/services/face_ml/face_feedback.dart/feedback_types.dart";
import "package:photos/services/face_ml/face_ml_result.dart";
import 'package:sqflite/sqflite.dart';

/// Stores all data for the ML-related features. The database can be accessed by `MlDataDB.instance.database`.
///
/// This includes:
/// [facesTable] - Stores all the detected faces and its embeddings in the images.
/// [peopleTable] - Stores all the clusters of faces which are considered to be the same person.
class MlDataDB {
  static final Logger _logger = Logger("MlDataDB");

  // TODO: [BOB] put the db in files
  static const _databaseName = "ente.ml_data.db";
  static const _databaseVersion = 1;

  static const facesTable = 'faces';
  static const fileIDColumn = 'file_id';
  static const faceMlResultColumn = 'face_ml_result';
  static const mlVersionColumn = 'ml_version';

  static const peopleTable = 'people';
  static const personIDColumn = 'person_id';
  static const clusterResultColumn = 'cluster_result';
  static const centroidColumn = 'cluster_centroid';
  static const centroidDistanceThresholdColumn = 'centroid_distance_threshold';

  static const feedbackTable = 'feedback';
  static const feedbackIDColumn = 'feedback_id';
  static const feedbackTypeColumn = 'feedback_type';
  static const feedbackDataColumn = 'feedback_data';
  static const feedbackTimestampColumn = 'feedback_timestamp';
  static const feedbackFaceMlVersionColumn = 'feedback_face_ml_version';
  static const feedbackClusterMlVersionColumn = 'feedback_cluster_ml_version';

  static const createFacesTable = '''CREATE TABLE IF NOT EXISTS $facesTable (
  $fileIDColumn	INTEGER NOT NULL UNIQUE,
	$faceMlResultColumn	TEXT NOT NULL,
  $mlVersionColumn	INTEGER NOT NULL,
  PRIMARY KEY($fileIDColumn)
  );
  ''';
  static const createPeopleTable = '''CREATE TABLE IF NOT EXISTS $peopleTable (
  $personIDColumn	INTEGER NOT NULL UNIQUE,
	$clusterResultColumn	TEXT NOT NULL,
  $centroidColumn	TEXT NOT NULL,
  $centroidDistanceThresholdColumn	REAL NOT NULL,
	PRIMARY KEY($personIDColumn)
  );
  ''';
  static const createFeedbackTable =
      '''CREATE TABLE IF NOT EXISTS $feedbackTable (
  $feedbackIDColumn	TEXT NOT NULL UNIQUE,
  $feedbackTypeColumn	TEXT NOT NULL,
  $feedbackDataColumn	TEXT NOT NULL,
  $feedbackTimestampColumn	TEXT NOT NULL,
  $feedbackFaceMlVersionColumn	INTEGER NOT NULL,
  $feedbackClusterMlVersionColumn	INTEGER NOT NULL,
  PRIMARY KEY($feedbackIDColumn)
  );
  ''';
  static const _deleteFacesTable = 'DROP TABLE IF EXISTS $facesTable';
  static const _deletePeopleTable = 'DROP TABLE IF EXISTS $peopleTable';
  static const _deleteFeedbackTable = 'DROP TABLE IF EXISTS $feedbackTable';

  MlDataDB._privateConstructor();
  static final MlDataDB instance = MlDataDB._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
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

  Future _onCreate(Database db, int version) async {
    await db.execute(createFacesTable);
    await db.execute(createPeopleTable);
    await db.execute(createFeedbackTable);
  }

  /// WARNING: This will delete ALL data in the database! Only use this for debug/testing purposes!
  Future<void> cleanTables({
    bool cleanFaces = false,
    bool cleanPeople = false,
    bool cleanFeedback = false,
  }) async {
    _logger.fine('`cleanTables()` called');
    final db = await instance.database;

    if (cleanFaces) {
      _logger.fine('`cleanTables()`: Cleaning faces table');
      await db.execute(_deleteFacesTable);
    }

    if (cleanPeople) {
      _logger.fine('`cleanTables()`: Cleaning people table');
      await db.execute(_deletePeopleTable);
    }

    if (cleanFeedback) {
      _logger.fine('`cleanTables()`: Cleaning feedback table');
      await db.execute(_deleteFeedbackTable);
    }

    if (!cleanFaces && !cleanPeople && !cleanFeedback) {
      _logger.fine(
        '`cleanTables()`: No tables cleaned, since no table was specified. Please be careful with this function!',
      );
    }

    await db.execute(createFacesTable);
    await db.execute(createPeopleTable);
    await db.execute(createFeedbackTable);
  }

  Future<void> createFaceMlResult(FaceMlResult faceMlResult) async {
    _logger.fine('createFaceMlResult called');

    final existingResult = await getFaceMlResult(faceMlResult.fileId);
    if (existingResult != null) {
      if (faceMlResult.mlVersion <= existingResult.mlVersion) {
        _logger.fine(
          'FaceMlResult with file ID ${faceMlResult.fileId} already exists with equal or higher version. Skipping insert.',
        );
        return;
      }
    }

    final db = await instance.database;
    await db.insert(
      facesTable,
      {
        fileIDColumn: faceMlResult.fileId,
        faceMlResultColumn: faceMlResult.toJsonString(),
        mlVersionColumn: faceMlResult.mlVersion,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> doesFaceMlResultExist(int fileId, {int? mlVersion}) async {
    _logger.fine('doesFaceMlResultExist called');
    final db = await instance.database;

    String whereString = '$fileIDColumn = ?';
    final List<dynamic> whereArgs = [fileId];

    if (mlVersion != null) {
      whereString += ' AND $mlVersionColumn = ?';
      whereArgs.add(mlVersion);
    }

    final result = await db.query(
      facesTable,
      where: whereString,
      whereArgs: whereArgs,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<FaceMlResult?> getFaceMlResult(int fileId, {int? mlVersion}) async {
    _logger.fine('getFaceMlResult called');
    final db = await instance.database;

    String whereString = '$fileIDColumn = ?';
    final List<dynamic> whereArgs = [fileId];

    if (mlVersion != null) {
      whereString += ' AND $mlVersionColumn = ?';
      whereArgs.add(mlVersion);
    }

    final result = await db.query(
      facesTable,
      where: whereString,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (result.isNotEmpty) {
      return FaceMlResult.fromJsonString(
        result.first[faceMlResultColumn] as String,
      );
    }
    _logger.fine(
      'No faceMlResult found for fileID $fileId and mlVersion $mlVersion (null if not specified)',
    );
    return null;
  }

  /// Returns the faceMlResults for the given [fileIds].
  Future<List<FaceMlResult>> getSelectedFaceMlResults(
    List<int> fileIds,
  ) async {
    _logger.fine('getSelectedFaceMlResults called');
    final db = await instance.database;

    if (fileIds.isEmpty) {
      _logger.warning('getSelectedFaceMlResults called with empty fileIds');
      return <FaceMlResult>[];
    }

    final List<Map<String, Object?>> results = await db.query(
      facesTable,
      columns: [faceMlResultColumn],
      where: '$fileIDColumn IN (${fileIds.join(',')})',
      orderBy: fileIDColumn,
    );

    return results
        .map(
          (result) =>
              FaceMlResult.fromJsonString(result[faceMlResultColumn] as String),
        )
        .toList();
  }

  Future<List<FaceMlResult>> getAllFaceMlResults({int? mlVersion}) async {
    _logger.fine('getAllFaceMlResults called');
    final db = await instance.database;

    String? whereString;
    List<dynamic>? whereArgs;

    if (mlVersion != null) {
      whereString = '$mlVersionColumn = ?';
      whereArgs = [mlVersion];
    }

    final results = await db.query(
      facesTable,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: fileIDColumn,
    );

    return results
        .map(
          (result) =>
              FaceMlResult.fromJsonString(result[faceMlResultColumn] as String),
        )
        .toList();
  }

  /// getAllFileIDs returns a set of all fileIDs from the facesTable, meaning all the fileIDs for which a FaceMlResult exists, optionally filtered by mlVersion.
  Future<Set<int>> getAllFaceMlResultFileIDs({int? mlVersion}) async {
    _logger.fine('getAllFaceMlResultFileIDs called');
    final db = await instance.database;

    String? whereString;
    List<dynamic>? whereArgs;

    if (mlVersion != null) {
      whereString = '$mlVersionColumn = ?';
      whereArgs = [mlVersion];
    }

    final List<Map<String, Object?>> results = await db.query(
      facesTable,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: fileIDColumn,
    );

    return results.map((result) => result[fileIDColumn] as int).toSet();
  }

  Future<Set<int>> getAllFaceMlResultFileIDsProcessedWithThumbnailOnly({
    int? mlVersion,
  }) async {
    _logger.fine('getAllFaceMlResultFileIDsProcessedWithThumbnailOnly called');
    final db = await instance.database;

    String? whereString;
    List<dynamic>? whereArgs;

    if (mlVersion != null) {
      whereString = '$mlVersionColumn = ?';
      whereArgs = [mlVersion];
    }

    final List<Map<String, Object?>> results = await db.query(
      facesTable,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: fileIDColumn,
    );

    return results
        .map(
          (result) =>
              FaceMlResult.fromJsonString(result[faceMlResultColumn] as String),
        )
        .where((element) => element.onlyThumbnailUsed)
        .map((result) => result.fileId)
        .toSet();
  }

  /// Updates the faceMlResult for the given [faceMlResult.fileId]. Update is done regardless of the [faceMlResult.mlVersion].
  /// However, if [updateHigherVersionOnly] is set to true, the update is only done if the [faceMlResult.mlVersion] is higher than the existing one.
  Future<int> updateFaceMlResult(
    FaceMlResult faceMlResult, {
    bool updateHigherVersionOnly = false,
  }) async {
    _logger.fine('updateFaceMlResult called');

    if (updateHigherVersionOnly) {
      final existingResult = await getFaceMlResult(faceMlResult.fileId);
      if (existingResult != null) {
        if (faceMlResult.mlVersion <= existingResult.mlVersion) {
          _logger.fine(
            'FaceMlResult with file ID ${faceMlResult.fileId} already exists with equal or higher version. Skipping update.',
          );
          return 0;
        }
      }
    }

    final db = await instance.database;
    return await db.update(
      facesTable,
      {
        fileIDColumn: faceMlResult.fileId,
        faceMlResultColumn: faceMlResult.toJsonString(),
        mlVersionColumn: faceMlResult.mlVersion,
      },
      where: '$fileIDColumn = ?',
      whereArgs: [faceMlResult.fileId],
    );
  }

  Future<int> deleteFaceMlResult(int fileId) async {
    _logger.fine('deleteFaceMlResult called');
    final db = await instance.database;
    final deleteCount = await db.delete(
      facesTable,
      where: '$fileIDColumn = ?',
      whereArgs: [fileId],
    );
    _logger.fine('Deleted $deleteCount faceMlResults');
    return deleteCount;
  }

  Future<void> createAllClusterResults(
    List<ClusterResult> clusterResults, {
    bool cleanExistingClusters = true,
  }) async {
    _logger.fine('createClusterResults called');
    final db = await instance.database;

    if (clusterResults.isEmpty) {
      _logger.fine('No clusterResults given, skipping insert.');
      return;
    }

    // Completely clean the table and start fresh
    if (cleanExistingClusters) {
      await deleteAllClusterResults();
    }

    // Insert all the cluster results
    for (final clusterResult in clusterResults) {
      await db.insert(
        peopleTable,
        {
          personIDColumn: clusterResult.personId,
          clusterResultColumn: clusterResult.toJsonString(),
          centroidColumn: clusterResult.medoid.toString(),
          centroidDistanceThresholdColumn:
              clusterResult.medoidDistanceThreshold,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<ClusterResult?> getClusterResult(int personId) async {
    _logger.fine('getClusterResult called');
    final db = await instance.database;

    final result = await db.query(
      peopleTable,
      where: '$personIDColumn = ?',
      whereArgs: [personId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ClusterResult.fromJsonString(
        result.first[clusterResultColumn] as String,
      );
    }
    _logger.fine('No clusterResult found for personID $personId');
    return null;
  }

  /// Returns the ClusterResult objects for the given [personIDs].
  Future<List<ClusterResult>> getSelectedClusterResults(
    List<int> personIDs,
  ) async {
    _logger.fine('getSelectedClusterResults called');
    final db = await instance.database;

    if (personIDs.isEmpty) {
      _logger.warning('getSelectedClusterResults called with empty personIDs');
      return <ClusterResult>[];
    }

    final results = await db.query(
      peopleTable,
      where: '$personIDColumn IN (${personIDs.join(',')})',
      orderBy: personIDColumn,
    );

    return results
        .map(
          (result) => ClusterResult.fromJsonString(
            result[clusterResultColumn] as String,
          ),
        )
        .toList();
  }

  Future<List<ClusterResult>> getAllClusterResults() async {
    _logger.fine('getAllClusterResults called');
    final db = await instance.database;

    final results = await db.query(
      peopleTable,
    );

    return results
        .map(
          (result) => ClusterResult.fromJsonString(
            result[clusterResultColumn] as String,
          ),
        )
        .toList();
  }

  /// Returns the personIDs of all clustered people in the database.
  Future<List<int>> getAllClusterIds() async {
    _logger.fine('getAllClusterIds called');
    final db = await instance.database;

    final results = await db.query(
      peopleTable,
      columns: [personIDColumn],
    );

    return results.map((result) => result[personIDColumn] as int).toList();
  }

  /// Returns the fileIDs of all files associated with a given [personId].
  Future<List<int>> getClusterFileIds(int personId) async {
    _logger.fine('getClusterFileIds called');

    final ClusterResult? clusterResult = await getClusterResult(personId);
    if (clusterResult == null) {
      return <int>[];
    }
    return clusterResult.uniqueFileIds;
  }

  Future<List<String>> getClusterFaceIds(int personId) async {
    _logger.fine('getClusterFaceIds called');

    final ClusterResult? clusterResult = await getClusterResult(personId);
    if (clusterResult == null) {
      return <String>[];
    }
    return clusterResult.faceIDs;
  }

  Future<List<Embedding>> getClusterEmbeddings(
    int personId,
  ) async {
    _logger.fine('getClusterEmbeddings called');

    final ClusterResult? clusterResult = await getClusterResult(personId);
    if (clusterResult == null) return <Embedding>[];

    final fileIds = clusterResult.uniqueFileIds;
    final faceIds = clusterResult.faceIDs;
    if (fileIds.length != faceIds.length) {
      _logger.severe(
        'fileIds and faceIds have different lengths: ${fileIds.length} vs ${faceIds.length}. This should not happen!',
      );
      return <Embedding>[];
    }

    final faceMlResults = await getSelectedFaceMlResults(fileIds);
    if (faceMlResults.isEmpty) return <Embedding>[];

    final embeddings = <Embedding>[];
    for (var i = 0; i < faceMlResults.length; i++) {
      final faceMlResult = faceMlResults[i];
      final int faceIndex = faceMlResult.allFaceIds.indexOf(faceIds[i]);
      if (faceIndex == -1) {
        _logger.severe(
          'Could not find faceIndex for faceId ${faceIds[i]} in faceMlResult ${faceMlResult.fileId}',
        );
        return <Embedding>[];
      }
      embeddings.add(faceMlResult.faces[faceIndex].embedding);
    }

    return embeddings;
  }

  Future<void> updateClusterResult(ClusterResult clusterResult) async {
    _logger.fine('updateClusterResult called');
    final db = await instance.database;
    await db.update(
      peopleTable,
      {
        personIDColumn: clusterResult.personId,
        clusterResultColumn: clusterResult.toJsonString(),
        centroidColumn: clusterResult.medoid.toString(),
        centroidDistanceThresholdColumn: clusterResult.medoidDistanceThreshold,
      },
      where: '$personIDColumn = ?',
      whereArgs: [clusterResult.personId],
    );
  }

  Future<int> deleteClusterResult(int personId) async {
    _logger.fine('deleteClusterResult called');
    final db = await instance.database;
    final deleteCount = await db.delete(
      peopleTable,
      where: '$personIDColumn = ?',
      whereArgs: [personId],
    );
    _logger.fine('Deleted $deleteCount clusterResults');
    return deleteCount;
  }

  Future<void> deleteAllClusterResults() async {
    _logger.fine('deleteAllClusterResults called');
    final db = await instance.database;
    await db.execute(_deletePeopleTable);
    await db.execute(createPeopleTable);
  }

  // TODO: current function implementation will skip inserting for a similar feedback, which means I can't remove two photos from the same person in a row
  Future<void> createClusterFeedback<T extends ClusterFeedback>(
    T feedback, {
    bool skipIfSimilarFeedbackExists = false,
  }) async {
    _logger.fine('createClusterFeedback called');

    // TODO: this skipping might cause issues for adding photos to the same person in a row!!
    if (skipIfSimilarFeedbackExists &&
        await doesSimilarClusterFeedbackExist(feedback)) {
      _logger.fine(
        'ClusterFeedback with ID ${feedback.feedbackID} already has a similar feedback installed. Skipping insert.',
      );
      return;
    }

    final db = await instance.database;
    await db.insert(
      feedbackTable,
      {
        feedbackIDColumn: feedback.feedbackID,
        feedbackTypeColumn: feedback.typeString,
        feedbackDataColumn: feedback.toJsonString(),
        feedbackTimestampColumn: feedback.timestampString,
        feedbackFaceMlVersionColumn: feedback.madeOnFaceMlVersion,
        feedbackClusterMlVersionColumn: feedback.madeOnClusterMlVersion,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return;
  }

  Future<bool> doesSimilarClusterFeedbackExist<T extends ClusterFeedback>(
    T feedback,
  ) async {
    _logger.fine('doesClusterFeedbackExist called');

    final List<T> existingFeedback =
        await getAllClusterFeedback<T>(type: feedback.type);

    if (existingFeedback.isNotEmpty) {
      for (final existingFeedbackItem in existingFeedback) {
        assert(
          existingFeedbackItem.type == feedback.type,
          'Feedback types should be the same!',
        );
        if (feedback.looselyMatchesMedoid(existingFeedbackItem)) {
          _logger.fine(
            'ClusterFeedback of type ${feedback.typeString} with ID ${feedback.feedbackID} already has a similar feedback installed!',
          );
          return true;
        }
      }
    }
    return false;
  }

  /// Returns all the clusterFeedbacks of type [T] which match the given [feedback], sorted by timestamp (latest first).
  Future<List<T>> getAllMatchingClusterFeedback<T extends ClusterFeedback>(
    T feedback, {
    bool sortNewestFirst = true,
  }) async {
    _logger.fine('getAllMatchingClusterFeedback called');

    final List<T> existingFeedback =
        await getAllClusterFeedback<T>(type: feedback.type);
    final List<T> matchingFeedback = <T>[];
    if (existingFeedback.isNotEmpty) {
      for (final existingFeedbackItem in existingFeedback) {
        assert(
          existingFeedbackItem.type == feedback.type,
          'Feedback types should be the same!',
        );
        if (feedback.looselyMatchesMedoid(existingFeedbackItem)) {
          _logger.fine(
            'ClusterFeedback of type ${feedback.typeString} with ID ${feedback.feedbackID} already has a similar feedback installed!',
          );
          matchingFeedback.add(existingFeedbackItem);
        }
      }
    }
    if (sortNewestFirst) {
      matchingFeedback.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return matchingFeedback;
  }

  Future<List<T>> getAllClusterFeedback<T extends ClusterFeedback>({
    required FeedbackType type,
    int? mlVersion,
    int? clusterMlVersion,
  }) async {
    _logger.fine('getAllClusterFeedback called');
    final db = await instance.database;

    // TODO: implement the versions for FeedbackType.imageFeedback and FeedbackType.faceFeedback and rename this function to getAllFeedback?

    String whereString = '$feedbackTypeColumn = ?';
    final List<dynamic> whereArgs = [type.toValueString()];

    if (mlVersion != null) {
      whereString += ' AND $feedbackFaceMlVersionColumn = ?';
      whereArgs.add(mlVersion);
    }
    if (clusterMlVersion != null) {
      whereString += ' AND $feedbackClusterMlVersionColumn = ?';
      whereArgs.add(clusterMlVersion);
    }

    final results = await db.query(
      feedbackTable,
      where: whereString,
      whereArgs: whereArgs,
    );

    if (results.isNotEmpty) {
      if (ClusterFeedback.fromJsonStringRegistry.containsKey(type)) {
        final Function(String) fromJsonString =
            ClusterFeedback.fromJsonStringRegistry[type]!;
        return results
            .map((e) => fromJsonString(e[feedbackDataColumn] as String) as T)
            .toList();
      } else {
        _logger.severe(
          'No fromJsonString function found for type ${type.name}. This should not happen!',
        );
      }
    }
    _logger.fine(
      'No clusterFeedback results found of type $type' +
          (mlVersion != null ? ' and mlVersion $mlVersion' : '') +
          (clusterMlVersion != null
              ? ' and clusterMlVersion $clusterMlVersion'
              : ''),
    );
    return <T>[];
  }

  Future<int> deleteClusterFeedback<T extends ClusterFeedback>(
    T feedback,
  ) async {
    _logger.fine('deleteClusterFeedback called');
    final db = await instance.database;
    final deleteCount = await db.delete(
      feedbackTable,
      where: '$feedbackIDColumn = ?',
      whereArgs: [feedback.feedbackID],
    );
    _logger.fine('Deleted $deleteCount clusterFeedbacks');
    return deleteCount;
  }
}
