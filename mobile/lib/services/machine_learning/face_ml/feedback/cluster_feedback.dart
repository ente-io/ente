import 'dart:developer' as dev;
import "dart:math" show Random, min;

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
// import "package:photos/events/files_updated_event.dart";
// import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/cosine_distance.dart';
import "package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/face_ml_result.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";

class ClusterSuggestion {
  final int clusterIDToMerge;
  final double distancePersonToCluster;
  final bool usedOnlyMeanForSuggestion;
  final List<EnteFile> filesInCluster;
  final List<String> faceIDsInCluster;

  ClusterSuggestion(
    this.clusterIDToMerge,
    this.distancePersonToCluster,
    this.usedOnlyMeanForSuggestion,
    this.filesInCluster,
    this.faceIDsInCluster,
  );
}

class ClusterFeedbackService {
  final Logger _logger = Logger("ClusterFeedbackService");
  ClusterFeedbackService._privateConstructor();

  static final ClusterFeedbackService instance =
      ClusterFeedbackService._privateConstructor();

  static int lastViewedClusterID = -1;
  static setLastViewedClusterID(int clusterID) {
    lastViewedClusterID = clusterID;
  }

  static resetLastViewedClusterID() {
    lastViewedClusterID = -1;
  }

  /// Returns a list of cluster suggestions for a person. Each suggestion is a tuple of the following elements:
  /// 1. clusterID: the ID of the cluster
  /// 2. distance: the distance between the person's cluster and the suggestion
  /// 3. bool: whether the suggestion was found using the mean (true) or the median (false)
  /// 4. List<EnteFile>: the files in the cluster
  Future<List<ClusterSuggestion>> getSuggestionForPerson(
    PersonEntity person, {
    bool extremeFilesFirst = true,
  }) async {
    _logger.info(
      'getSuggestionForPerson ${kDebugMode ? person.data.name : person.remoteID}',
    );

    try {
      // Get the suggestions for the person using centroids and median
      final startTime = DateTime.now();
      final List<(int, double, bool)> foundSuggestions =
          await _getSuggestions(person);
      final findSuggestionsTime = DateTime.now();
      _logger.info(
        'getSuggestionForPerson `_getSuggestions`: Found ${foundSuggestions.length} suggestions in ${findSuggestionsTime.difference(startTime).inMilliseconds} ms',
      );

      // Get the files for the suggestions
      final suggestionClusterIDs = foundSuggestions.map((e) => e.$1).toSet();
      final Map<int, Set<int>> fileIdToClusterID =
          await FaceMLDataDB.instance.getFileIdToClusterIDSetForCluster(
        suggestionClusterIDs,
      );
      final clusterIdToFaceIDs =
          await FaceMLDataDB.instance.getClusterToFaceIDs(suggestionClusterIDs);
      final Map<int, List<EnteFile>> clusterIDToFiles = {};
      final allFiles = await SearchService.instance.getAllFiles();
      for (final f in allFiles) {
        if (!fileIdToClusterID.containsKey(f.uploadedFileID ?? -1)) {
          continue;
        }
        final cluserIds = fileIdToClusterID[f.uploadedFileID ?? -1]!;
        for (final cluster in cluserIds) {
          if (clusterIDToFiles.containsKey(cluster)) {
            clusterIDToFiles[cluster]!.add(f);
          } else {
            clusterIDToFiles[cluster] = [f];
          }
        }
      }

      final List<ClusterSuggestion> clusterIdAndFiles = [];
      for (final clusterSuggestion in foundSuggestions) {
        if (clusterIDToFiles.containsKey(clusterSuggestion.$1)) {
          clusterIdAndFiles.add(
            ClusterSuggestion(
              clusterSuggestion.$1,
              clusterSuggestion.$2,
              clusterSuggestion.$3,
              clusterIDToFiles[clusterSuggestion.$1]!,
              clusterIdToFaceIDs[clusterSuggestion.$1]!.toList(),
            ),
          );
        }
      }
      final getFilesTime = DateTime.now();

      final sortingStartTime = DateTime.now();
      if (extremeFilesFirst) {
        await _sortSuggestionsOnDistanceToPerson(person, clusterIdAndFiles);
      }
      _logger.info(
        'getSuggestionForPerson post-processing suggestions took ${DateTime.now().difference(findSuggestionsTime).inMilliseconds} ms, of which sorting took ${DateTime.now().difference(sortingStartTime).inMilliseconds} ms and getting files took ${getFilesTime.difference(findSuggestionsTime).inMilliseconds} ms',
      );

      return clusterIdAndFiles;
    } catch (e, s) {
      _logger.severe("Error in getClusterFilesForPersonID", e, s);
      rethrow;
    }
  }

  Future<void> removeFilesFromPerson(
    List<EnteFile> files,
    PersonEntity p,
  ) async {
    try {
      // Get the relevant faces to be removed
      final faceIDs = await FaceMLDataDB.instance
          .getFaceIDsForPerson(p.remoteID)
          .then((iterable) => iterable.toList());
      faceIDs.retainWhere((faceID) {
        final fileID = getFileIdFromFaceId(faceID);
        return files.any((file) => file.uploadedFileID == fileID);
      });
      final embeddings =
          await FaceMLDataDB.instance.getFaceEmbeddingMapForFaces(faceIDs);

      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();

      // Re-cluster within the deleted faces
      final newFaceIdToClusterID =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.20,
      );
      if (newFaceIdToClusterID == null || newFaceIdToClusterID.isEmpty) {
        return;
      }

      // Update the deleted faces
      await FaceMLDataDB.instance.forceUpdateClusterIds(newFaceIdToClusterID);

      // Make sure the deleted faces don't get suggested in the future
      final notClusterIdToPersonId = <int, String>{};
      for (final clusterId in newFaceIdToClusterID.values.toSet()) {
        notClusterIdToPersonId[clusterId] = p.remoteID;
      }
      await FaceMLDataDB.instance
          .bulkCaptureNotPersonFeedback(notClusterIdToPersonId);

      Bus.instance.fire(PeopleChangedEvent());
      return;
    } catch (e, s) {
      _logger.severe("Error in removeFilesFromPerson", e, s);
      rethrow;
    }
  }

  Future<void> removeFilesFromCluster(
    List<EnteFile> files,
    int clusterID,
  ) async {
    try {
      // Get the relevant faces to be removed
      final faceIDs = await FaceMLDataDB.instance
          .getFaceIDsForCluster(clusterID)
          .then((iterable) => iterable.toList());
      faceIDs.retainWhere((faceID) {
        final fileID = getFileIdFromFaceId(faceID);
        return files.any((file) => file.uploadedFileID == fileID);
      });
      final embeddings =
          await FaceMLDataDB.instance.getFaceEmbeddingMapForFaces(faceIDs);

      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();

      // Re-cluster within the deleted faces
      final newFaceIdToClusterID =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.20,
      );
      if (newFaceIdToClusterID == null || newFaceIdToClusterID.isEmpty) {
        return;
      }

      // Update the deleted faces
      await FaceMLDataDB.instance.forceUpdateClusterIds(newFaceIdToClusterID);

      Bus.instance.fire(
        PeopleChangedEvent(
          relevantFiles: files,
          type: PeopleEventType.removedFilesFromCluster,
          source: "$clusterID",
        ),
      );
      // Bus.instance.fire(
      //   LocalPhotosUpdatedEvent(
      //     files,
      //     type: EventType.peopleClusterChanged,
      //     source: "$clusterID",
      //   ),
      // );
      return;
    } catch (e, s) {
      _logger.severe("Error in removeFilesFromCluster", e, s);
      rethrow;
    }
  }

  Future<void> addFilesToCluster(List<String> faceIDs, int clusterID) async {
    await FaceMLDataDB.instance.addFacesToCluster(faceIDs, clusterID);
    Bus.instance.fire(PeopleChangedEvent());
    return;
  }

  Future<bool> checkAndDoAutomaticMerges(PersonEntity p) async {
    final faceMlDb = FaceMLDataDB.instance;
    final allClusterIdsToCountMap = (await faceMlDb.clusterIdToFaceCount());
    final ignoredClusters = await faceMlDb.getPersonIgnoredClusters(p.remoteID);
    final personClusters = await faceMlDb.getPersonClusterIDs(p.remoteID);
    dev.log(
      'existing clusters for ${p.data.name} are $personClusters',
      name: "ClusterFeedbackService",
    );

    // Get and update the cluster summary to get the avg (centroid) and count
    final EnteWatch watch = EnteWatch("ClusterFeedbackService")..start();
    final Map<int, List<double>> clusterAvg = await _getUpdateClusterAvg(
      allClusterIdsToCountMap,
      ignoredClusters,
    );
    watch.log('computed avg for ${clusterAvg.length} clusters');

    // Find the actual closest clusters for the person
    final List<(int, double)> suggestions = _calcSuggestionsMean(
      clusterAvg,
      personClusters,
      ignoredClusters,
      0.3,
    );

    if (suggestions.isEmpty) {
      dev.log(
        'No automatic merge suggestions for ${p.data.name}',
        name: "ClusterFeedbackService",
      );
      return false;
    }

    // log suggestions
    dev.log(
      'suggestions for ${p.data.name} for cluster ID ${p.remoteID} are  suggestions $suggestions}',
      name: "ClusterFeedbackService",
    );

    for (final suggestion in suggestions) {
      final clusterID = suggestion.$1;
      await PersonService.instance.assignClusterToPerson(
        personID: p.remoteID,
        clusterID: clusterID,
      );
    }

    Bus.instance.fire(PeopleChangedEvent());

    return true;
  }

  // TODO: iterate over this method to find sweet spot
  Future<Map<int, List<String>>> breakUpCluster(
    int clusterID, {
    bool useDbscan = false,
  }) async {
    _logger.info(
      'breakUpCluster called for cluster $clusterID with dbscan $useDbscan',
    );
    final faceMlDb = FaceMLDataDB.instance;

    final faceIDs = await faceMlDb.getFaceIDsForCluster(clusterID);
    final originalFaceIDsSet = faceIDs.toSet();

    final embeddings = await faceMlDb.getFaceEmbeddingMapForFaces(faceIDs);

    final fileIDToCreationTime =
        await FilesDB.instance.getFileIDToCreationTime();

    final Map<int, List<String>> clusterIdToFaceIds = {};
    if (useDbscan) {
      final dbscanClusters = await FaceClusteringService.instance.predictDbscan(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        eps: 0.30,
        minPts: 8,
      );

      if (dbscanClusters.isEmpty) {
        return {};
      }

      int maxClusterID = DateTime.now().millisecondsSinceEpoch;

      for (final List<String> cluster in dbscanClusters) {
        final faceIds = cluster;
        clusterIdToFaceIds[maxClusterID] = faceIds;
        maxClusterID++;
      }
    } else {
      final faceIdToCluster =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.22,
      );

      if (faceIdToCluster == null || faceIdToCluster.isEmpty) {
        _logger.info('No clusters found');
        return {};
      } else {
        _logger.info(
          'Broke up cluster $clusterID into ${faceIdToCluster.values.toSet().length} clusters',
        );
      }

      for (final entry in faceIdToCluster.entries) {
        final clusterID = entry.value;
        if (clusterIdToFaceIds.containsKey(clusterID)) {
          clusterIdToFaceIds[clusterID]!.add(entry.key);
        } else {
          clusterIdToFaceIds[clusterID] = [entry.key];
        }
      }
    }

    final clusterIdToCount = clusterIdToFaceIds.map((key, value) {
      return MapEntry(key, value.length);
    });
    final amountOfNewClusters = clusterIdToCount.length;

    _logger.info(
      'Broke up cluster $clusterID into $amountOfNewClusters clusters \n ${clusterIdToCount.toString()}',
    );

    final clusterIdToDisplayNames = <int, List<String>>{};
    if (kDebugMode) {
      for (final entry in clusterIdToFaceIds.entries) {
        final faceIDs = entry.value;
        final fileIDs = faceIDs.map((e) => getFileIdFromFaceId(e)).toList();
        final files = await FilesDB.instance.getFilesFromIDs(fileIDs);
        final displayNames = files.values.map((e) => e.displayName).toList();
        clusterIdToDisplayNames[entry.key] = displayNames;
      }
    }

    final Set allClusteredFaceIDsSet = {};
    for (final List<String> value in clusterIdToFaceIds.values) {
      allClusteredFaceIDsSet.addAll(value);
    }
    final clusterIDToNoiseFaceID =
        originalFaceIDsSet.difference(allClusteredFaceIDsSet);
    if (clusterIDToNoiseFaceID.isNotEmpty) {
      clusterIdToFaceIds[-1] = clusterIDToNoiseFaceID.toList();
    }

    return clusterIdToFaceIds;
  }

  /// WARNING: this method is purely for debugging purposes, never use in production
  Future<void> createFakeClustersByBlurValue() async {
    try {
      // Delete old clusters
      await FaceMLDataDB.instance.resetClusterIDs();
      await FaceMLDataDB.instance.dropClustersAndPersonTable();
      final List<PersonEntity> persons =
          await PersonService.instance.getPersons();
      for (final PersonEntity p in persons) {
        await PersonService.instance.deletePerson(p.remoteID);
      }

      // Create new fake clusters based on blur value. One for values between 0 and 10, one for 10-20, etc till 200
      final int startClusterID = DateTime.now().microsecondsSinceEpoch;
      final faceIDsToBlurValues =
          await FaceMLDataDB.instance.getFaceIDsToBlurValues(200);
      final faceIdToCluster = <String, int>{};
      for (final entry in faceIDsToBlurValues.entries) {
        final faceID = entry.key;
        final blurValue = entry.value;
        final newClusterID = startClusterID + blurValue ~/ 10;
        faceIdToCluster[faceID] = newClusterID;
      }
      await FaceMLDataDB.instance.updateClusterIdToFaceId(faceIdToCluster);

      Bus.instance.fire(PeopleChangedEvent());
    } catch (e, s) {
      _logger.severe("Error in createFakeClustersByBlurValue", e, s);
      rethrow;
    }
  }

  Future<void> debugLogClusterBlurValues(
    int clusterID, {
    int? clusterSize,
  }) async {
    final List<double> blurValues = await FaceMLDataDB.instance
        .getBlurValuesForCluster(clusterID)
        .then((value) => value.toList());

    // Round the blur values to integers
    final blurValuesIntegers =
        blurValues.map((value) => value.round()).toList();

    // Sort the blur values in ascending order
    blurValuesIntegers.sort();

    // Log the sorted blur values

    _logger.info(
      "Blur values for cluster $clusterID${clusterSize != null ? ' with $clusterSize photos' : ''}: $blurValuesIntegers",
    );

    return;
  }

  /// Returns a list of suggestions. For each suggestion we return a record consisting of the following elements:
  /// 1. clusterID: the ID of the cluster
  /// 2. distance: the distance between the person's cluster and the suggestion
  /// 3. usedMean: whether the suggestion was found using the mean (true) or the median (false)
  Future<List<(int, double, bool)>> _getSuggestions(
    PersonEntity p, {
    int sampleSize = 50,
    double maxMedianDistance = 0.62,
    double goodMedianDistance = 0.55,
    double maxMeanDistance = 0.65,
    double goodMeanDistance = 0.54,
  }) async {
    // Get all the cluster data
    final startTime = DateTime.now();
    final faceMlDb = FaceMLDataDB.instance;
    // final Map<int, List<(int, double)>> suggestions = {};
    final allClusterIdsToCountMap = await faceMlDb.clusterIdToFaceCount();
    final ignoredClusters = await faceMlDb.getPersonIgnoredClusters(p.remoteID);
    final personClusters = await faceMlDb.getPersonClusterIDs(p.remoteID);
    dev.log(
      'existing clusters for ${p.data.name} are $personClusters, getting all database data took ${DateTime.now().difference(startTime).inMilliseconds} ms',
      name: "getSuggestionsUsingMedian",
    );

    // First only do a simple check on the big clusters, if the person does not have small clusters yet
    final EnteWatch watch = EnteWatch("ClusterFeedbackService")..start();
    final smallestPersonClusterSize = personClusters
        .map((clusterID) => allClusterIdsToCountMap[clusterID] ?? 0)
        .reduce((value, element) => min(value, element));
    final checkSizes = [kMinimumClusterSizeSearchResult, 20, 10, 5, 1];
    for (final minimumSize in checkSizes.toSet()) {
      if (smallestPersonClusterSize >= minimumSize) {
        final Map<int, List<double>> clusterAvgBigClusters =
            await _getUpdateClusterAvg(
          allClusterIdsToCountMap,
          ignoredClusters,
          minClusterSize: minimumSize,
        );
        dev.log(
          'computed avg for ${clusterAvgBigClusters.length} clusters, in ${DateTime.now().difference(startTime).inMilliseconds} ms',
        );
        final List<(int, double)> suggestionsMeanBigClusters =
            _calcSuggestionsMean(
          clusterAvgBigClusters,
          personClusters,
          ignoredClusters,
          goodMeanDistance,
        );
        if (suggestionsMeanBigClusters.isNotEmpty) {
          return suggestionsMeanBigClusters
              .map((e) => (e.$1, e.$2, true))
              .toList(growable: false);
        }
      }
    }

    // Get and update the cluster summary to get the avg (centroid) and count
    final Map<int, List<double>> clusterAvg = await _getUpdateClusterAvg(
      allClusterIdsToCountMap,
      ignoredClusters,
    );
    dev.log(
      'computed avg for ${clusterAvg.length} clusters, in ${DateTime.now().difference(startTime).inMilliseconds} ms',
    );

    // Find the other cluster candidates based on the mean
    final List<(int, double)> suggestionsMean = _calcSuggestionsMean(
      clusterAvg,
      personClusters,
      ignoredClusters,
      goodMeanDistance,
    );
    if (suggestionsMean.isNotEmpty) {
      return suggestionsMean
          .map((e) => (e.$1, e.$2, true))
          .toList(growable: false);
    }

    // Find the other cluster candidates based on the median
    final List<(int, double)> moreSuggestionsMean = _calcSuggestionsMean(
      clusterAvg,
      personClusters,
      ignoredClusters,
      maxMeanDistance,
    );
    if (moreSuggestionsMean.isEmpty) {
      _logger
          .info("No suggestions found using mean, even with higher threshold");
      return [];
    }

    moreSuggestionsMean.sort((a, b) => a.$2.compareTo(b.$2));
    final otherClusterIdsCandidates = moreSuggestionsMean
        .map(
          (e) => e.$1,
        )
        .toList(growable: false);
    _logger.info(
      "Found potential suggestions from loose mean for median test: $otherClusterIdsCandidates",
    );

    watch.logAndReset("Starting median test");
    // Take the embeddings from the person's clusters in one big list and sample from it
    final List<Uint8List> personEmbeddingsProto = [];
    for (final clusterID in personClusters) {
      final Iterable<Uint8List> embedings =
          await FaceMLDataDB.instance.getFaceEmbeddingsForCluster(clusterID);
      personEmbeddingsProto.addAll(embedings);
    }
    final List<Uint8List> sampledEmbeddingsProto =
        _randomSampleWithoutReplacement(
      personEmbeddingsProto,
      sampleSize,
    );
    final List<List<double>> sampledEmbeddings = sampledEmbeddingsProto
        .map((embedding) => EVector.fromBuffer(embedding).values)
        .toList(growable: false);

    // Find the actual closest clusters for the person using median
    final List<(int, double)> suggestionsMedian = [];
    final List<(int, double)> greatSuggestionsMedian = [];
    double minMedianDistance = maxMedianDistance;
    for (final otherClusterId in otherClusterIdsCandidates) {
      final Iterable<Uint8List> otherEmbeddingsProto =
          await FaceMLDataDB.instance.getFaceEmbeddingsForCluster(
        otherClusterId,
      );
      final sampledOtherEmbeddingsProto = _randomSampleWithoutReplacement(
        otherEmbeddingsProto,
        sampleSize,
      );
      final List<List<double>> sampledOtherEmbeddings =
          sampledOtherEmbeddingsProto
              .map((embedding) => EVector.fromBuffer(embedding).values)
              .toList(growable: false);

      // Calculate distances and find the median
      final List<double> distances = [];
      for (final otherEmbedding in sampledOtherEmbeddings) {
        for (final embedding in sampledEmbeddings) {
          distances.add(cosineDistForNormVectors(embedding, otherEmbedding));
        }
      }
      distances.sort();
      final double medianDistance = distances[distances.length ~/ 2];
      if (medianDistance < minMedianDistance) {
        suggestionsMedian.add((otherClusterId, medianDistance));
        minMedianDistance = medianDistance;
        if (medianDistance < goodMedianDistance) {
          greatSuggestionsMedian.add((otherClusterId, medianDistance));
          break;
        }
      }
    }
    watch.log("Finished median test");
    if (suggestionsMedian.isEmpty) {
      _logger.info("No suggestions found using median");
      return [];
    } else {
      _logger.info("Found suggestions using median: $suggestionsMedian");
    }

    final List<(int, double, bool)> finalSuggestionsMedian = suggestionsMedian
        .map(((e) => (e.$1, e.$2, false)))
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    if (greatSuggestionsMedian.isNotEmpty) {
      _logger.info(
        "Found great suggestion using median: $greatSuggestionsMedian",
      );
      // // Return the largest size cluster by using allClusterIdsToCountMap
      // final List<int> greatSuggestionsMedianClusterIds =
      //     greatSuggestionsMedian.map((e) => e.$1).toList(growable: false);
      // greatSuggestionsMedianClusterIds.sort(
      //   (a, b) =>
      //       allClusterIdsToCountMap[b]!.compareTo(allClusterIdsToCountMap[a]!),
      // );

      // return [greatSuggestionsMedian.last.$1, ...finalSuggestionsMedian];
    }

    return finalSuggestionsMedian;
  }

  Future<Map<int, List<double>>> _getUpdateClusterAvg(
    Map<int, int> allClusterIdsToCountMap,
    Set<int> ignoredClusters, {
    int minClusterSize = 1,
    int maxClusterInCurrentRun = 500,
    int maxEmbeddingToRead = 10000,
  }) async {
    final startTime = DateTime.now();
    final faceMlDb = FaceMLDataDB.instance;
    _logger.info(
      'start getUpdateClusterAvg for ${allClusterIdsToCountMap.length} clusters, minClusterSize $minClusterSize, maxClusterInCurrentRun $maxClusterInCurrentRun',
    );

    final Map<int, (Uint8List, int)> clusterToSummary =
        await faceMlDb.getAllClusterSummary(minClusterSize);
    final Map<int, (Uint8List, int)> updatesForClusterSummary = {};

    final Map<int, List<double>> clusterAvg = {};

    dev.log(
      'getUpdateClusterAvg database call for getAllClusterSummary took ${DateTime.now().difference(startTime).inMilliseconds} ms',
    );

    final allClusterIds = allClusterIdsToCountMap.keys.toSet();
    int ignoredClustersCnt = 0, alreadyUpdatedClustersCnt = 0;
    int smallerClustersCnt = 0;
    final serializationTime = DateTime.now();
    for (final id in allClusterIdsToCountMap.keys) {
      if (ignoredClusters.contains(id)) {
        allClusterIds.remove(id);
        ignoredClustersCnt++;
      }
      if (clusterToSummary[id]?.$2 == allClusterIdsToCountMap[id]) {
        allClusterIds.remove(id);
        clusterAvg[id] = EVector.fromBuffer(clusterToSummary[id]!.$1).values;
        alreadyUpdatedClustersCnt++;
      }
      if (allClusterIdsToCountMap[id]! < minClusterSize) {
        allClusterIds.remove(id);
        smallerClustersCnt++;
      }
    }
    dev.log(
      'serialization of embeddings took ${DateTime.now().difference(serializationTime).inMilliseconds} ms',
    );
    _logger.info(
      'Ignored $ignoredClustersCnt clusters, already updated $alreadyUpdatedClustersCnt clusters, $smallerClustersCnt clusters are smaller than $minClusterSize',
    );

    if (allClusterIds.isEmpty) {
      _logger.info(
        'No clusters to update, getUpdateClusterAvg done in ${DateTime.now().difference(startTime).inMilliseconds} ms',
      );
      return clusterAvg;
    }

    // get clusterIDs sorted by count in descending order
    final sortedClusterIDs = allClusterIds.toList();
    sortedClusterIDs.sort(
      (a, b) =>
          allClusterIdsToCountMap[b]!.compareTo(allClusterIdsToCountMap[a]!),
    );
    int indexedInCurrentRun = 0;
    final EnteWatch? w = kDebugMode ? EnteWatch("computeAvg") : null;
    w?.start();

    w?.log(
      'reading embeddings for $maxClusterInCurrentRun or ${sortedClusterIDs.length} clusters',
    );

    int currentPendingRead = 0;
    final List<int> clusterIdsToRead = [];
    for (final clusterID in sortedClusterIDs) {
      if (maxClusterInCurrentRun-- <= 0) {
        break;
      }
      if (currentPendingRead == 0) {
        currentPendingRead = allClusterIdsToCountMap[clusterID] ?? 0;
        clusterIdsToRead.add(clusterID);
      } else {
        if ((currentPendingRead + allClusterIdsToCountMap[clusterID]!) <
            maxEmbeddingToRead) {
          clusterIdsToRead.add(clusterID);
          currentPendingRead += allClusterIdsToCountMap[clusterID]!;
        } else {
          break;
        }
      }
    }

    final Map<int, Iterable<Uint8List>> clusterEmbeddings = await FaceMLDataDB
        .instance
        .getFaceEmbeddingsForClusters(clusterIdsToRead);

    w?.logAndReset(
      'read  $currentPendingRead embeddings for ${clusterEmbeddings.length} clusters',
    );

    for (final clusterID in clusterEmbeddings.keys) {
      late List<double> avg;
      final Iterable<Uint8List> embedings = clusterEmbeddings[clusterID]!;
      final List<double> sum = List.filled(192, 0);
      for (final embedding in embedings) {
        final data = EVector.fromBuffer(embedding).values;
        for (int i = 0; i < sum.length; i++) {
          sum[i] += data[i];
        }
      }
      avg = sum.map((e) => e / embedings.length).toList();
      final avgEmbeedingBuffer = EVector(values: avg).writeToBuffer();
      updatesForClusterSummary[clusterID] =
          (avgEmbeedingBuffer, embedings.length);
      // store the intermediate updates
      indexedInCurrentRun++;
      if (updatesForClusterSummary.length > 100) {
        await faceMlDb.clusterSummaryUpdate(updatesForClusterSummary);
        updatesForClusterSummary.clear();
        if (kDebugMode) {
          _logger.info(
            'getUpdateClusterAvg $indexedInCurrentRun clusters in current one',
          );
        }
      }
      clusterAvg[clusterID] = avg;
    }
    if (updatesForClusterSummary.isNotEmpty) {
      await faceMlDb.clusterSummaryUpdate(updatesForClusterSummary);
    }
    w?.logAndReset('done computing avg ');
    _logger.info(
      'end getUpdateClusterAvg for ${clusterAvg.length} clusters, done in ${DateTime.now().difference(startTime).inMilliseconds} ms',
    );

    return clusterAvg;
  }

  /// Returns a map of person's clusterID to map of closest clusterID to with disstance
  List<(int, double)> _calcSuggestionsMean(
    Map<int, List<double>> clusterAvg,
    Set<int> personClusters,
    Set<int> ignoredClusters,
    double maxClusterDistance, {
    Map<int, int>? allClusterIdsToCountMap,
  }) {
    final Map<int, List<(int, double)>> suggestions = {};
    for (final otherClusterID in clusterAvg.keys) {
      // ignore the cluster that belong to the person or is ignored
      if (personClusters.contains(otherClusterID) ||
          ignoredClusters.contains(otherClusterID)) {
        continue;
      }
      final otherAvg = clusterAvg[otherClusterID]!;
      int? nearestPersonCluster;
      double? minDistance;
      for (final personCluster in personClusters) {
        if (clusterAvg[personCluster] == null) {
          _logger.info('no avg for cluster $personCluster');
          continue;
        }
        final avg = clusterAvg[personCluster]!;
        final distance = cosineDistForNormVectors(avg, otherAvg);
        if (distance < maxClusterDistance) {
          if (minDistance == null || distance < minDistance) {
            minDistance = distance;
            nearestPersonCluster = personCluster;
          }
        }
      }
      if (nearestPersonCluster != null && minDistance != null) {
        suggestions
            .putIfAbsent(nearestPersonCluster, () => [])
            .add((otherClusterID, minDistance));
      }
    }

    if (suggestions.isNotEmpty) {
      final List<(int, double)> suggestClusterIds = [];
      for (final List<(int, double)> suggestion in suggestions.values) {
        suggestClusterIds.addAll(suggestion);
      }
      suggestClusterIds.sort(
        (a, b) => a.$2.compareTo(b.$2),
      ); // sort by distance

      List<int>? suggestClusterIdsSizes;
      if (allClusterIdsToCountMap != null) {
        suggestClusterIdsSizes = suggestClusterIds
            .map((e) => allClusterIdsToCountMap[e.$1]!)
            .toList(growable: false);
      }
      final suggestClusterIdsDistances =
          suggestClusterIds.map((e) => e.$2).toList(growable: false);
      _logger.info(
        "Already found good suggestions using mean: $suggestClusterIds, ${suggestClusterIdsSizes != null ? 'with sizes $suggestClusterIdsSizes' : ''} and distances $suggestClusterIdsDistances",
      );
      return suggestClusterIds;
    } else {
      _logger.info("No suggestions found using mean");
      return <(int, double)>[];
    }
  }

  List<T> _randomSampleWithoutReplacement<T>(
    Iterable<T> embeddings,
    int sampleSize,
  ) {
    final random = Random();

    if (sampleSize >= embeddings.length) {
      return embeddings.toList();
    }

    // If sampleSize is more than half the list size, shuffle and take first sampleSize elements
    if (sampleSize > embeddings.length / 2) {
      final List<T> shuffled = List<T>.from(embeddings)..shuffle(random);
      return shuffled.take(sampleSize).toList(growable: false);
    }

    // Otherwise, use the set-based method for efficiency
    final selectedIndices = <int>{};
    final sampledEmbeddings = <T>[];
    while (sampledEmbeddings.length < sampleSize) {
      final int index = random.nextInt(embeddings.length);
      if (!selectedIndices.contains(index)) {
        selectedIndices.add(index);
        sampledEmbeddings.add(embeddings.elementAt(index));
      }
    }

    return sampledEmbeddings;
  }

  Future<void> _sortSuggestionsOnDistanceToPerson(
    PersonEntity person,
    List<ClusterSuggestion> suggestions, {
    bool onlySortBigSuggestions = true,
  }) async {
    if (suggestions.isEmpty) {
      debugPrint('No suggestions to sort');
      return;
    }
    if (onlySortBigSuggestions) {
      final bigSuggestions = suggestions
          .where(
            (s) => s.filesInCluster.length > kMinimumClusterSizeSearchResult,
          )
          .toList();
      if (bigSuggestions.isEmpty) {
        debugPrint('No big suggestions to sort');
        return;
      }
    }
    final startTime = DateTime.now();
    final faceMlDb = FaceMLDataDB.instance;

    // Get the cluster averages for the person's clusters and the suggestions' clusters
    final personClusters = await faceMlDb.getPersonClusterIDs(person.remoteID);
    final Map<int, (Uint8List, int)> personClusterToSummary =
        await faceMlDb.getClusterToClusterSummary(personClusters);
    final clusterSummaryCallTime = DateTime.now();

    // Calculate the avg embedding of the person
    final w = (kDebugMode ? EnteWatch('sortSuggestions') : null)?..start();
    final personEmbeddingsCount = personClusters
        .map((e) => personClusterToSummary[e]!.$2)
        .reduce((a, b) => a + b);
    final List<double> personAvg = List.filled(192, 0);
    for (final personClusterID in personClusters) {
      final personClusterBlob = personClusterToSummary[personClusterID]!.$1;
      final personClusterAvg = EVector.fromBuffer(personClusterBlob).values;
      final clusterWeight =
          personClusterToSummary[personClusterID]!.$2 / personEmbeddingsCount;
      for (int i = 0; i < personClusterAvg.length; i++) {
        personAvg[i] += personClusterAvg[i] *
            clusterWeight; // Weighted sum of the cluster averages
      }
    }
    w?.log('calculated person avg');

    // Sort the suggestions based on the distance to the person
    for (final suggestion in suggestions) {
      if (onlySortBigSuggestions) {
        if (suggestion.filesInCluster.length <= 8) {
          continue;
        }
      }
      final clusterID = suggestion.clusterIDToMerge;
      final faceIDs = suggestion.faceIDsInCluster;
      final faceIdToEmbeddingMap = await faceMlDb.getFaceEmbeddingMapForFaces(
        faceIDs,
      );
      w?.log(
        'got ${faceIdToEmbeddingMap.values.length} embeddings for ${suggestion.filesInCluster.length} files for cluster $clusterID',
      );
      final fileIdToDistanceMap = {};
      for (final entry in faceIdToEmbeddingMap.entries) {
        fileIdToDistanceMap[getFileIdFromFaceId(entry.key)] =
            cosineDistForNormVectors(
          personAvg,
          EVector.fromBuffer(entry.value).values,
        );
      }
      w?.log('calculated distances for cluster $clusterID');
      suggestion.filesInCluster.sort((b, a) {
        //todo: review with @laurens, added this to avoid null safety issue
        final double distanceA = fileIdToDistanceMap[a.uploadedFileID!] ?? -1;
        final double distanceB = fileIdToDistanceMap[b.uploadedFileID!] ?? -1;
        return distanceA.compareTo(distanceB);
      });
      w?.log('sorted files for cluster $clusterID');

      debugPrint(
        "[${_logger.name}] Sorted suggestions for cluster $clusterID based on distance to person: ${suggestion.filesInCluster.map((e) => fileIdToDistanceMap[e.uploadedFileID]).toList()}",
      );
    }

    final endTime = DateTime.now();
    _logger.info(
      "Sorting suggestions based on distance to person took ${endTime.difference(startTime).inMilliseconds} ms for ${suggestions.length} suggestions, of which ${clusterSummaryCallTime.difference(startTime).inMilliseconds} ms was spent on the cluster summary call",
    );
  }
}
