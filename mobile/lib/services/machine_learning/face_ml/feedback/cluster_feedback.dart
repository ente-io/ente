import 'dart:developer' as dev;
import "dart:math" show Random, min;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/linalg.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/file/file.dart";
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
  final _computer = Computer.shared();
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

      final List<ClusterSuggestion> finalSuggestions = [];
      for (final clusterSuggestion in foundSuggestions) {
        if (clusterIDToFiles.containsKey(clusterSuggestion.$1)) {
          finalSuggestions.add(
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
        try {
          await _sortSuggestionsOnDistanceToPerson(person, finalSuggestions);
        } catch (e, s) {
          _logger.severe("Error in sorting suggestions", e, s);
        }
      }
      _logger.info(
        'getSuggestionForPerson post-processing suggestions took ${DateTime.now().difference(findSuggestionsTime).inMilliseconds} ms, of which sorting took ${DateTime.now().difference(sortingStartTime).inMilliseconds} ms and getting files took ${getFilesTime.difference(findSuggestionsTime).inMilliseconds} ms',
      );

      return finalSuggestions;
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
      _logger.info('removeFilesFromPerson called');
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

      if (faceIDs.isEmpty || embeddings.isEmpty) {
        _logger.severe(
          'No faces or embeddings found for person ${p.remoteID} that match the given files',
        );
        return;
      }

      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();

      // Re-cluster within the deleted faces
      final clusterResult =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.20,
      );
      if (clusterResult.isEmpty) {
        _logger.severe('No clusters found or something went wrong');
        return;
      }
      final newFaceIdToClusterID = clusterResult.newFaceIdToCluster;

      // Update the deleted faces
      await FaceMLDataDB.instance.forceUpdateClusterIds(newFaceIdToClusterID);
      await FaceMLDataDB.instance
          .clusterSummaryUpdate(clusterResult.newClusterSummaries);

      // Make sure the deleted faces don't get suggested in the future
      final notClusterIdToPersonId = <int, String>{};
      for (final clusterId in newFaceIdToClusterID.values.toSet()) {
        notClusterIdToPersonId[clusterId] = p.remoteID;
      }
      await FaceMLDataDB.instance
          .bulkCaptureNotPersonFeedback(notClusterIdToPersonId);

      // Update remote so new sync does not undo this change
      await PersonService.instance
          .removeFilesFromPerson(person: p, faceIDs: faceIDs.toSet());

      Bus.instance.fire(PeopleChangedEvent());
      _logger.info('removeFilesFromPerson done');
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
    _logger.info('removeFilesFromCluster called');
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

      if (faceIDs.isEmpty || embeddings.isEmpty) {
        _logger.severe(
          'No faces or embeddings found for cluster $clusterID that match the given files',
        );
        return;
      }

      final fileIDToCreationTime =
          await FilesDB.instance.getFileIDToCreationTime();

      // Re-cluster within the deleted faces
      final clusterResult =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.20,
      );
      if (clusterResult.isEmpty) {
        _logger.severe('No clusters found or something went wrong');
        return;
      }
      final newFaceIdToClusterID = clusterResult.newFaceIdToCluster;

      // Update the deleted faces
      await FaceMLDataDB.instance.forceUpdateClusterIds(newFaceIdToClusterID);
      await FaceMLDataDB.instance
          .clusterSummaryUpdate(clusterResult.newClusterSummaries);

      Bus.instance.fire(
        PeopleChangedEvent(
          relevantFiles: files,
          type: PeopleEventType.removedFilesFromCluster,
          source: "$clusterID",
        ),
      );
      _logger.info('removeFilesFromCluster done');
      return;
    } catch (e, s) {
      _logger.severe("Error in removeFilesFromCluster", e, s);
      rethrow;
    }
  }

  Future<void> addFacesToCluster(List<String> faceIDs, int clusterID) async {
    final faceIDToClusterID = <String, int>{};
    for (final faceID in faceIDs) {
      faceIDToClusterID[faceID] = clusterID;
    }
    await FaceMLDataDB.instance.forceUpdateClusterIds(faceIDToClusterID);
    Bus.instance.fire(PeopleChangedEvent());
    return;
  }

  Future<bool> checkAndDoAutomaticMerges(
    PersonEntity p, {
    required int personClusterID,
  }) async {
    final faceMlDb = FaceMLDataDB.instance;
    final faceIDs = await faceMlDb.getFaceIDsForCluster(personClusterID);
    final ignoredClusters = await faceMlDb.getPersonIgnoredClusters(p.remoteID);
    if (faceIDs.length < 2 * kMinimumClusterSizeSearchResult) {
      final fileIDs = faceIDs.map(getFileIdFromFaceId).toSet();
      if (fileIDs.length < kMinimumClusterSizeSearchResult) {
        _logger.info(
          'Cluster $personClusterID has less than $kMinimumClusterSizeSearchResult faces, not doing automatic merges',
        );
        return false;
      }
    }
    final allClusterIdsToCountMap = (await faceMlDb.clusterIdToFaceCount());
    _logger.info(
      '${kDebugMode ? p.data.name : "private"} has existing clusterID $personClusterID, checking if we can automatically merge more',
    );

    // Get and update the cluster summary to get the avg (centroid) and count
    final EnteWatch watch = EnteWatch("ClusterFeedbackService")..start();
    final Map<int, Vector> clusterAvg = await _getUpdateClusterAvg(
      allClusterIdsToCountMap,
      ignoredClusters,
      minClusterSize: kMinimumClusterSizeSearchResult,
    );
    watch.log('computed avg for ${clusterAvg.length} clusters');

    // Find the actual closest clusters for the person
    final List<(int, double)> suggestions = await calcSuggestionsMeanInComputer(
      clusterAvg,
      {personClusterID},
      ignoredClusters,
      0.24,
    );

    if (suggestions.isEmpty) {
      _logger.info(
        'No automatic merge suggestions for ${kDebugMode ? p.data.name : "private"}',
      );
      return false;
    }

    // log suggestions
    _logger.info(
      'suggestions for ${kDebugMode ? p.data.name : "private"} for cluster ID ${p.remoteID} are  suggestions $suggestions}',
    );

    for (final suggestion in suggestions) {
      final clusterID = suggestion.$1;
      await FaceMLDataDB.instance.assignClusterToPerson(
        personID: p.remoteID,
        clusterID: clusterID,
      );
    }

    Bus.instance.fire(PeopleChangedEvent());

    return true;
  }

  Future<void> ignoreCluster(int clusterID) async {
    await PersonService.instance.addPerson('', clusterID);
    Bus.instance.fire(PeopleChangedEvent());
    return;
  }

  Future<List<(int, int)>> checkForMixedClusters() async {
    final faceMlDb = FaceMLDataDB.instance;
    final allClusterToFaceCount = await faceMlDb.clusterIdToFaceCount();
    final clustersToInspect = <int>[];
    for (final clusterID in allClusterToFaceCount.keys) {
      if (allClusterToFaceCount[clusterID]! > 20 &&
          allClusterToFaceCount[clusterID]! < 500) {
        clustersToInspect.add(clusterID);
      }
    }

    final fileIDToCreationTime =
        await FilesDB.instance.getFileIDToCreationTime();

    final susClusters = <(int, int)>[];

    final inspectionStart = DateTime.now();
    for (final clusterID in clustersToInspect) {
      final int originalClusterSize = allClusterToFaceCount[clusterID]!;
      final faceIDs = await faceMlDb.getFaceIDsForCluster(clusterID);

      final embeddings = await faceMlDb.getFaceEmbeddingMapForFaces(faceIDs);

      final clusterResult =
          await FaceClusteringService.instance.predictWithinClusterComputer(
        embeddings,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.22,
      );

      if (clusterResult.isEmpty) {
        _logger.warning(
          '[CheckMixedClusters] Clustering did not seem to work for cluster $clusterID of size ${allClusterToFaceCount[clusterID]}',
        );
        continue;
      }

      final newClusterIdToCount =
          clusterResult.newClusterIdToFaceIds.map((key, value) {
        return MapEntry(key, value.length);
      });
      final amountOfNewClusters = newClusterIdToCount.length;

      _logger.info(
        '[CheckMixedClusters] Broke up cluster $clusterID into $amountOfNewClusters clusters \n ${newClusterIdToCount.toString()}',
      );

      // Now find the sizes of the biggest and second biggest cluster
      final int biggestClusterID = newClusterIdToCount.keys.reduce((a, b) {
        return newClusterIdToCount[a]! > newClusterIdToCount[b]! ? a : b;
      });
      final int biggestSize = newClusterIdToCount[biggestClusterID]!;
      final biggestRatio = biggestSize / originalClusterSize;
      if (newClusterIdToCount.length > 1) {
        final List<int> clusterIDs = newClusterIdToCount.keys.toList();
        clusterIDs.remove(biggestClusterID);
        final int secondBiggestClusterID = clusterIDs.reduce((a, b) {
          return newClusterIdToCount[a]! > newClusterIdToCount[b]! ? a : b;
        });
        final int secondBiggestSize =
            newClusterIdToCount[secondBiggestClusterID]!;
        final secondBiggestRatio = secondBiggestSize / originalClusterSize;

        if (biggestRatio < 0.5 || secondBiggestRatio > 0.2) {
          final faceIdsOfCluster =
              await faceMlDb.getFaceIDsForCluster(clusterID);
          final uniqueFileIDs =
              faceIdsOfCluster.map(getFileIdFromFaceId).toSet();
          susClusters.add((clusterID, uniqueFileIDs.length));
          _logger.info(
            '[CheckMixedClusters] Detected that cluster $clusterID with size ${uniqueFileIDs.length} might be mixed',
          );
        }
      } else {
        _logger.info(
          '[CheckMixedClusters] For cluster $clusterID we only found one cluster after reclustering',
        );
      }
    }
    _logger.info(
      '[CheckMixedClusters] Inspection took ${DateTime.now().difference(inspectionStart).inSeconds} seconds',
    );
    if (susClusters.isNotEmpty) {
      _logger.info(
        '[CheckMixedClusters] Found ${susClusters.length} clusters that might be mixed: $susClusters',
      );
    } else {
      _logger.info('[CheckMixedClusters] No mixed clusters found');
    }
    return susClusters;
  }

  Future<ClusteringResult> breakUpCluster(
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

    if (embeddings.isEmpty) {
      _logger.warning('No embeddings found for cluster $clusterID');
      return ClusteringResult.empty();
    }

    final fileIDToCreationTime =
        await FilesDB.instance.getFileIDToCreationTime();

    final clusterResult =
        await FaceClusteringService.instance.predictWithinClusterComputer(
      embeddings,
      fileIDToCreationTime: fileIDToCreationTime,
      distanceThreshold: 0.22,
    );

    if (clusterResult.isEmpty) {
      _logger.warning('No clusters found or something went wrong');
      return ClusteringResult.empty();
    }

    final clusterIdToCount =
        clusterResult.newClusterIdToFaceIds.map((key, value) {
      return MapEntry(key, value.length);
    });
    final amountOfNewClusters = clusterIdToCount.length;

    _logger.info(
      'Broke up cluster $clusterID into $amountOfNewClusters clusters \n ${clusterIdToCount.toString()}',
    );

    if (kDebugMode) {
      final Set allClusteredFaceIDsSet = {};
      for (final List<String> value
          in clusterResult.newClusterIdToFaceIds.values) {
        allClusteredFaceIDsSet.addAll(value);
      }
      assert((originalFaceIDsSet.difference(allClusteredFaceIDsSet)).isEmpty);
    }

    return clusterResult;
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
    double goodMeanDistance = 0.45,
  }) async {
    final w = (kDebugMode ? EnteWatch('getSuggestions') : null)?..start();
    // Get all the cluster data
    final faceMlDb = FaceMLDataDB.instance;
    final allClusterIdsToCountMap = await faceMlDb.clusterIdToFaceCount();
    final ignoredClusters = await faceMlDb.getPersonIgnoredClusters(p.remoteID);
    final personClusters = await faceMlDb.getPersonClusterIDs(p.remoteID);
    final personFaceIDs =
        await FaceMLDataDB.instance.getFaceIDsForPerson(p.remoteID);
    final personFileIDs = personFaceIDs.map(getFileIdFromFaceId).toSet();
    w?.log(
      '${p.data.name} has ${personClusters.length} existing clusters, getting all database data done',
    );
    final allClusterIdToFaceIDs =
        await FaceMLDataDB.instance.getAllClusterIdToFaceIDs();
    w?.log('getAllClusterIdToFaceIDs done');

    // First only do a simple check on the big clusters, if the person does not have small clusters yet
    final smallestPersonClusterSize = personClusters
        .map((clusterID) => allClusterIdsToCountMap[clusterID] ?? 0)
        .reduce((value, element) => min(value, element));
    final checkSizes = [100, 20, kMinimumClusterSizeSearchResult, 10, 5, 1];
    Map<int, Vector> clusterAvgBigClusters = <int, Vector>{};
    final List<(int, double)> suggestionsMean = [];
    for (final minimumSize in checkSizes.toSet()) {
      if (smallestPersonClusterSize >=
          min(minimumSize, kMinimumClusterSizeSearchResult)) {
        clusterAvgBigClusters = await _getUpdateClusterAvg(
          allClusterIdsToCountMap,
          ignoredClusters,
          minClusterSize: minimumSize,
        );
        w?.log(
          'Calculate avg for ${clusterAvgBigClusters.length} clusters of min size $minimumSize',
        );
        final List<(int, double)> suggestionsMeanBigClusters =
            await calcSuggestionsMeanInComputer(
          clusterAvgBigClusters,
          personClusters,
          ignoredClusters,
          goodMeanDistance,
        );
        w?.log(
          'Calculate suggestions using mean for ${clusterAvgBigClusters.length} clusters of min size $minimumSize',
        );
        for (final suggestion in suggestionsMeanBigClusters) {
          // Skip suggestions that have a high overlap with the person's files
          final suggestionSet = allClusterIdToFaceIDs[suggestion.$1]!
              .map((faceID) => getFileIdFromFaceId(faceID))
              .toSet();
          final overlap = personFileIDs.intersection(suggestionSet);
          if (overlap.isNotEmpty &&
              ((overlap.length / suggestionSet.length) > 0.5)) {
            await FaceMLDataDB.instance.captureNotPersonFeedback(
              personID: p.remoteID,
              clusterID: suggestion.$1,
            );
            continue;
          }
          suggestionsMean.add(suggestion);
        }
        if (suggestionsMean.isNotEmpty) {
          return suggestionsMean
              .map((e) => (e.$1, e.$2, true))
              .toList(growable: false);
        }
      }
    }
    w?.reset();

    // Find the other cluster candidates based on the median
    final clusterAvg = clusterAvgBigClusters;
    final List<(int, double)> moreSuggestionsMean =
        await calcSuggestionsMeanInComputer(
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

    w?.logAndReset("Starting median test");
    // Take the embeddings from the person's clusters in one big list and sample from it
    final List<Uint8List> personEmbeddingsProto = [];
    for (final clusterID in personClusters) {
      final Iterable<Uint8List> embeddings =
          await FaceMLDataDB.instance.getFaceEmbeddingsForCluster(clusterID);
      personEmbeddingsProto.addAll(embeddings);
    }
    final List<Uint8List> sampledEmbeddingsProto =
        _randomSampleWithoutReplacement(
      personEmbeddingsProto,
      sampleSize,
    );
    final List<Vector> sampledEmbeddings = sampledEmbeddingsProto
        .map(
          (embedding) => Vector.fromList(
            EVector.fromBuffer(embedding).values,
            dtype: DType.float32,
          ),
        )
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
      final List<Vector> sampledOtherEmbeddings = sampledOtherEmbeddingsProto
          .map(
            (embedding) => Vector.fromList(
              EVector.fromBuffer(embedding).values,
              dtype: DType.float32,
            ),
          )
          .toList(growable: false);

      // Calculate distances and find the median
      final List<double> distances = [];
      for (final otherEmbedding in sampledOtherEmbeddings) {
        for (final embedding in sampledEmbeddings) {
          distances.add(1 - embedding.dot(otherEmbedding));
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
    w?.log("Finished median test");
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

  Future<Map<int, Vector>> _getUpdateClusterAvg(
    Map<int, int> allClusterIdsToCountMap,
    Set<int> ignoredClusters, {
    int minClusterSize = 1,
    int maxClusterInCurrentRun = 500,
    int maxEmbeddingToRead = 10000,
  }) async {
    final w = (kDebugMode ? EnteWatch('_getUpdateClusterAvg') : null)?..start();
    final startTime = DateTime.now();
    final faceMlDb = FaceMLDataDB.instance;
    _logger.info(
      'start getUpdateClusterAvg for ${allClusterIdsToCountMap.length} clusters, minClusterSize $minClusterSize, maxClusterInCurrentRun $maxClusterInCurrentRun',
    );

    final Map<int, (Uint8List, int)> clusterToSummary =
        await faceMlDb.getAllClusterSummary(minClusterSize);
    final Map<int, (Uint8List, int)> updatesForClusterSummary = {};

    w?.log(
      'getUpdateClusterAvg database call for getAllClusterSummary',
    );

    final serializationEmbeddings = await _computer.compute(
      checkAndSerializeCurrentClusterMeans,
      param: {
        'allClusterIdsToCountMap': allClusterIdsToCountMap,
        'minClusterSize': minClusterSize,
        'ignoredClusters': ignoredClusters,
        'clusterToSummary': clusterToSummary,
      },
    ) as (Map<int, Vector>, Set<int>, int, int, int);
    final clusterAvg = serializationEmbeddings.$1;
    final allClusterIds = serializationEmbeddings.$2;
    final ignoredClustersCnt = serializationEmbeddings.$3;
    final alreadyUpdatedClustersCnt = serializationEmbeddings.$4;
    final smallerClustersCnt = serializationEmbeddings.$5;

    // Assert that all existing clusterAvg are normalized
    for (final avg in clusterAvg.values) {
      assert((avg.norm() - 1.0).abs() < 1e-5);
    }

    w?.log(
      'serialization of embeddings',
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
    w?.reset();

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
      final Iterable<Uint8List> embeddings = clusterEmbeddings[clusterID]!;
      final Iterable<Vector> vectors = embeddings.map(
        (e) => Vector.fromList(
          EVector.fromBuffer(e).values,
          dtype: DType.float32,
        ),
      );
      final avg = vectors.reduce((a, b) => a + b) / vectors.length;
      final avgNormalized = avg / avg.norm();
      final avgEmbeddingBuffer = EVector(values: avgNormalized).writeToBuffer();
      updatesForClusterSummary[clusterID] =
          (avgEmbeddingBuffer, embeddings.length);
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
      clusterAvg[clusterID] = avgNormalized;
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

  Future<List<(int, double)>> calcSuggestionsMeanInComputer(
    Map<int, Vector> clusterAvg,
    Set<int> personClusters,
    Set<int> ignoredClusters,
    double maxClusterDistance,
  ) async {
    return await _computer.compute(
      _calcSuggestionsMean,
      param: {
        'clusterAvg': clusterAvg,
        'personClusters': personClusters,
        'ignoredClusters': ignoredClusters,
        'maxClusterDistance': maxClusterDistance,
      },
    );
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

    // remove personClusters that don't have any summary
    for (final clusterID in personClusters.toSet()) {
      if (!personClusterToSummary.containsKey(clusterID)) {
        _logger.warning('missing summary for $clusterID');
        personClusters.remove(clusterID);
      }
    }
    if (personClusters.isEmpty) {
      _logger.warning('No person clusters with summary found');
      return;
    }

    // Calculate the avg embedding of the person
    final w = (kDebugMode ? EnteWatch('sortSuggestions') : null)?..start();
    int personEmbeddingsCount = 0;
    for (final clusterID in personClusters) {
      personEmbeddingsCount += personClusterToSummary[clusterID]!.$2;
    }

    Vector personAvg = Vector.filled(192, 0);
    for (final personClusterID in personClusters) {
      final personClusterBlob = personClusterToSummary[personClusterID]!.$1;
      final personClusterAvg = Vector.fromList(
        EVector.fromBuffer(personClusterBlob).values,
        dtype: DType.float32,
      );
      final clusterWeight =
          personClusterToSummary[personClusterID]!.$2 / personEmbeddingsCount;
      personAvg += personClusterAvg * clusterWeight;
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
      final faceIdToVectorMap = faceIdToEmbeddingMap.map(
        (key, value) => MapEntry(
          key,
          Vector.fromList(
            EVector.fromBuffer(value).values,
            dtype: DType.float32,
          ),
        ),
      );
      w?.log(
        'got ${faceIdToEmbeddingMap.values.length} embeddings for ${suggestion.filesInCluster.length} files for cluster $clusterID',
      );
      final fileIdToDistanceMap = {};
      for (final entry in faceIdToVectorMap.entries) {
        fileIdToDistanceMap[getFileIdFromFaceId(entry.key)] =
            1 - personAvg.dot(entry.value);
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

  Future<void> debugLogClusterBlurValues(
    int clusterID, {
    int? clusterSize,
    bool logClusterSummary = false,
    bool logBlurValues = false,
  }) async {
    if (!kDebugMode) return;

    // Logging the clusterID
    _logger.info(
      "Debug logging for cluster $clusterID${clusterSize != null ? ' with $clusterSize photos' : ''}",
    );
    const int biggestClusterID = 1715061228725148;

    // Logging the cluster summary for the cluster
    if (logClusterSummary) {
      final summaryMap = await FaceMLDataDB.instance.getClusterToClusterSummary(
        [clusterID, biggestClusterID],
      );
      final summary = summaryMap[clusterID];
      if (summary != null) {
        _logger.info(
          "Cluster summary for cluster $clusterID says the amount of faces is: ${summary.$2}",
        );
      }

      final biggestClusterSummary = summaryMap[biggestClusterID];
      final clusterSummary = summaryMap[clusterID];
      if (biggestClusterSummary != null && clusterSummary != null) {
        _logger.info(
          "Cluster summary for biggest cluster $biggestClusterID says the size is: ${biggestClusterSummary.$2}",
        );
        _logger.info(
          "Cluster summary for current cluster $clusterID says the size is: ${clusterSummary.$2}",
        );

        // Mean distance
        final biggestMean = Vector.fromList(
          EVector.fromBuffer(biggestClusterSummary.$1).values,
          dtype: DType.float32,
        );
        final currentMean = Vector.fromList(
          EVector.fromBuffer(clusterSummary.$1).values,
          dtype: DType.float32,
        );
        final bigClustersMeanDistance = 1 - biggestMean.dot(currentMean);
        _logger.info(
          "Mean distance between biggest cluster and current cluster: $bigClustersMeanDistance",
        );
        _logger.info(
          'Element differences between the two means are ${biggestMean - currentMean}',
        );
        final currentL2Norm = currentMean.norm();
        _logger.info(
          'L2 norm of current mean: $currentL2Norm',
        );
        final trueDistance =
            biggestMean.distanceTo(currentMean, distance: Distance.cosine);
        _logger.info('True distance between the two means: $trueDistance');

        // Median distance
        const sampleSize = 100;
        final Iterable<Uint8List> biggestEmbeddings = await FaceMLDataDB
            .instance
            .getFaceEmbeddingsForCluster(biggestClusterID);
        final List<Uint8List> biggestSampledEmbeddingsProto =
            _randomSampleWithoutReplacement(
          biggestEmbeddings,
          sampleSize,
        );
        final List<Vector> biggestSampledEmbeddings =
            biggestSampledEmbeddingsProto
                .map(
                  (embedding) => Vector.fromList(
                    EVector.fromBuffer(embedding).values,
                    dtype: DType.float32,
                  ),
                )
                .toList(growable: false);

        final Iterable<Uint8List> currentEmbeddings =
            await FaceMLDataDB.instance.getFaceEmbeddingsForCluster(clusterID);
        final List<Uint8List> currentSampledEmbeddingsProto =
            _randomSampleWithoutReplacement(
          currentEmbeddings,
          sampleSize,
        );
        final List<Vector> currentSampledEmbeddings =
            currentSampledEmbeddingsProto
                .map(
                  (embedding) => Vector.fromList(
                    EVector.fromBuffer(embedding).values,
                    dtype: DType.float32,
                  ),
                )
                .toList(growable: false);

        // Calculate distances and find the median
        final List<double> distances = [];
        final List<double> trueDistances = [];
        for (final biggestEmbedding in biggestSampledEmbeddings) {
          for (final currentEmbedding in currentSampledEmbeddings) {
            distances.add(1 - biggestEmbedding.dot(currentEmbedding));
            trueDistances.add(
              biggestEmbedding.distanceTo(
                currentEmbedding,
                distance: Distance.cosine,
              ),
            );
          }
        }
        distances.sort();
        trueDistances.sort();
        final double medianDistance = distances[distances.length ~/ 2];
        final double trueMedianDistance =
            trueDistances[trueDistances.length ~/ 2];
        _logger.info(
          "Median distance between biggest cluster and current cluster: $medianDistance (using sample of $sampleSize)",
        );
        _logger.info(
          'True distance median between the two embeddings: $trueMedianDistance',
        );
      }
    }

    // Logging the blur values for the cluster
    if (logBlurValues) {
      final List<double> blurValues = await FaceMLDataDB.instance
          .getBlurValuesForCluster(clusterID)
          .then((value) => value.toList());
      final blurValuesIntegers =
          blurValues.map((value) => value.round()).toList();
      blurValuesIntegers.sort();
      _logger.info(
        "Blur values for cluster $clusterID${clusterSize != null ? ' with $clusterSize photos' : ''}: $blurValuesIntegers",
      );
    }

    return;
  }
}

/// Returns a map of person's clusterID to map of closest clusterID to with disstance
List<(int, double)> _calcSuggestionsMean(Map<String, dynamic> args) {
  // Fill in args
  final Map<int, Vector> clusterAvg = args['clusterAvg'];
  final Set<int> personClusters = args['personClusters'];
  final Set<int> ignoredClusters = args['ignoredClusters'];
  final double maxClusterDistance = args['maxClusterDistance'];

  final Map<int, List<(int, double)>> suggestions = {};
  const suggestionMax = 2000;
  int suggestionCount = 0;
  int comparisons = 0;
  final w = (kDebugMode ? EnteWatch('getSuggestions') : null)?..start();

  // ignore the clusters that belong to the person or is ignored
  Set<int> otherClusters = clusterAvg.keys.toSet().difference(personClusters);
  otherClusters = otherClusters.difference(ignoredClusters);

  for (final otherClusterID in otherClusters) {
    final Vector? otherAvg = clusterAvg[otherClusterID];
    if (otherAvg == null) {
      dev.log('[WARNING] no avg for othercluster $otherClusterID');
      continue;
    }
    int? nearestPersonCluster;
    double? minDistance;
    for (final personCluster in personClusters) {
      if (clusterAvg[personCluster] == null) {
        dev.log('[WARNING] no avg for personcluster $personCluster');
        continue;
      }
      final Vector avg = clusterAvg[personCluster]!;
      final distance = 1 - avg.dot(otherAvg);
      comparisons++;
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
      suggestionCount++;
    }
    if (suggestionCount >= suggestionMax) {
      break;
    }
  }
  w?.log(
    'calculation inside calcSuggestionsMean for ${personClusters.length} person clusters and ${otherClusters.length} other clusters (so ${personClusters.length * otherClusters.length} combinations, $comparisons comparisons made resulted in $suggestionCount suggestions)',
  );

  if (suggestions.isNotEmpty) {
    final List<(int, double)> suggestClusterIds = [];
    for (final List<(int, double)> suggestion in suggestions.values) {
      suggestClusterIds.addAll(suggestion);
    }
    suggestClusterIds.sort(
      (a, b) => a.$2.compareTo(b.$2),
    ); // sort by distance

    dev.log(
      "Already found ${suggestClusterIds.length} good suggestions using mean",
    );
    return suggestClusterIds.sublist(0, min(suggestClusterIds.length, 20));
  } else {
    dev.log("No suggestions found using mean");
    return <(int, double)>[];
  }
}

Future<(Map<int, Vector>, Set<int>, int, int, int)>
    checkAndSerializeCurrentClusterMeans(
  Map args,
) async {
  final Map<int, int> allClusterIdsToCountMap = args['allClusterIdsToCountMap'];
  final int minClusterSize = args['minClusterSize'] ?? 1;
  final Set<int> ignoredClusters = args['ignoredClusters'] ?? {};
  final Map<int, (Uint8List, int)> clusterToSummary = args['clusterToSummary'];

  final Map<int, Vector> clusterAvg = {};

  final allClusterIds = allClusterIdsToCountMap.keys.toSet();
  int ignoredClustersCnt = 0, alreadyUpdatedClustersCnt = 0;
  int smallerClustersCnt = 0;
  for (final id in allClusterIdsToCountMap.keys) {
    if (ignoredClusters.contains(id)) {
      allClusterIds.remove(id);
      ignoredClustersCnt++;
    }
    if (clusterToSummary[id]?.$2 == allClusterIdsToCountMap[id]) {
      allClusterIds.remove(id);
      clusterAvg[id] = Vector.fromList(
        EVector.fromBuffer(clusterToSummary[id]!.$1).values,
        dtype: DType.float32,
      );
      alreadyUpdatedClustersCnt++;
    }
    if (allClusterIdsToCountMap[id]! < minClusterSize) {
      allClusterIds.remove(id);
      smallerClustersCnt++;
    }
  }

  return (
    clusterAvg,
    allClusterIds,
    ignoredClustersCnt,
    alreadyUpdatedClustersCnt,
    smallerClustersCnt
  );
}
