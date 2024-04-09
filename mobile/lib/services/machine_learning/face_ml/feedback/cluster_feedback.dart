import 'dart:developer' as dev;
import "dart:math" show Random;

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/cosine_distance.dart';
import "package:photos/services/machine_learning/face_ml/face_clustering/linear_clustering_service.dart";
import "package:photos/services/machine_learning/face_ml/face_ml_result.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";

class ClusterSuggestion {
  final int clusterIDToMerge;
  final double distancePersonToCluster;
  final bool usedOnlyMeanForSuggestion;
  final List<EnteFile> filesInCluster;

  ClusterSuggestion(
    this.clusterIDToMerge,
    this.distancePersonToCluster,
    this.usedOnlyMeanForSuggestion,
    this.filesInCluster,
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

  /// Returns a map of person's clusterID to map of closest clusterID to with disstance
  Future<Map<int, List<(int, double)>>> getSuggestionsUsingMean(
    PersonEntity p, {
    double maxClusterDistance = 0.4,
  }) async {
    // Get all the cluster data
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
    final Map<int, List<(int, double)>> suggestions = _calcSuggestionsMean(
      clusterAvg,
      personClusters,
      ignoredClusters,
      maxClusterDistance,
    );

    // log suggestions
    for (final entry in suggestions.entries) {
      dev.log(
        ' ${entry.value.length} suggestion for ${p.data.name} for cluster ID ${entry.key} are  suggestions ${entry.value}}',
        name: "ClusterFeedbackService",
      );
    }
    return suggestions;
  }

  /// Returns a list of suggestions. For each suggestion we return a record consisting of the following elements:
  /// 1. clusterID: the ID of the cluster
  /// 2. distance: the distance between the person's cluster and the suggestion
  /// 3. usedMean: whether the suggestion was found using the mean (true) or the median (false)
  Future<List<(int, double, bool)>> getSuggestionsUsingMedian(
    PersonEntity p, {
    int sampleSize = 50,
    double maxMedianDistance = 0.65,
    double goodMedianDistance = 0.55,
    double maxMeanDistance = 0.65,
    double goodMeanDistance = 0.4,
  }) async {
    // Get all the cluster data
    final faceMlDb = FaceMLDataDB.instance;
    // final Map<int, List<(int, double)>> suggestions = {};
    final allClusterIdsToCountMap = (await faceMlDb.clusterIdToFaceCount());
    final ignoredClusters = await faceMlDb.getPersonIgnoredClusters(p.remoteID);
    final personClusters = await faceMlDb.getPersonClusterIDs(p.remoteID);
    dev.log(
      'existing clusters for ${p.data.name} are $personClusters',
      name: "getSuggestionsUsingMedian",
    );

    // Get and update the cluster summary to get the avg (centroid) and count
    final EnteWatch watch = EnteWatch("ClusterFeedbackService")..start();
    final Map<int, List<double>> clusterAvg = await _getUpdateClusterAvg(
      allClusterIdsToCountMap,
      ignoredClusters,
    );
    watch.log('computed avg for ${clusterAvg.length} clusters');

    // Find the other cluster candidates based on the mean
    final Map<int, List<(int, double)>> suggestionsMean = _calcSuggestionsMean(
      clusterAvg,
      personClusters,
      ignoredClusters,
      goodMeanDistance,
    );
    if (suggestionsMean.isNotEmpty) {
      final List<(int, double)> suggestClusterIds = [];
      for (final List<(int, double)> suggestion in suggestionsMean.values) {
        suggestClusterIds.addAll(suggestion);
      }
      suggestClusterIds.sort(
        (a, b) => allClusterIdsToCountMap[b.$1]!
            .compareTo(allClusterIdsToCountMap[a.$1]!),
      );
      final suggestClusterIdsSizes = suggestClusterIds
          .map((e) => allClusterIdsToCountMap[e.$1]!)
          .toList(growable: false);
      final suggestClusterIdsDistances =
          suggestClusterIds.map((e) => e.$2).toList(growable: false);
      _logger.info(
        "Already found good suggestions using mean: $suggestClusterIds, with sizes $suggestClusterIdsSizes and distances $suggestClusterIdsDistances",
      );
      return suggestClusterIds
          .map((e) => (e.$1, e.$2, true))
          .toList(growable: false);
    }

    // Find the other cluster candidates based on the median
    final Map<int, List<(int, double)>> moreSuggestionsMean =
        _calcSuggestionsMean(
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

    final List<(int, double)> temp = [];
    for (final List<(int, double)> suggestion in moreSuggestionsMean.values) {
      temp.addAll(suggestion);
    }
    temp.sort((a, b) => a.$2.compareTo(b.$2));
    final otherClusterIdsCandidates = temp
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
      'getClusterFilesForPersonID ${kDebugMode ? person.data.name : person.remoteID}',
    );

    try {
      // Get the suggestions for the person using centroids and median
      final List<(int, double, bool)> suggestClusterIds =
          await getSuggestionsUsingMedian(person);

      // Get the files for the suggestions
      final Map<int, Set<int>> fileIdToClusterID =
          await FaceMLDataDB.instance.getFileIdToClusterIDSetForCluster(
        suggestClusterIds.map((e) => e.$1).toSet(),
      );
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
      for (final clusterSuggestion in suggestClusterIds) {
        if (clusterIDToFiles.containsKey(clusterSuggestion.$1)) {
          clusterIdAndFiles.add(
            ClusterSuggestion(
              clusterSuggestion.$1,
              clusterSuggestion.$2,
              clusterSuggestion.$3,
              clusterIDToFiles[clusterSuggestion.$1]!,
            ),
          );
        }
      }

      if (extremeFilesFirst) {
        await _sortSuggestionsOnDistanceToPerson(person, clusterIdAndFiles);
      }

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
    await FaceMLDataDB.instance.removeFilesFromPerson(files, p.remoteID);
    Bus.instance.fire(PeopleChangedEvent());
  }

  Future<void> removeFilesFromCluster(
    List<EnteFile> files,
    int clusterID,
  ) async {
    await FaceMLDataDB.instance.removeFilesFromCluster(files, clusterID);
    Bus.instance.fire(PeopleChangedEvent());
    return;
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
    final Map<int, List<(int, double)>> suggestions = _calcSuggestionsMean(
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
    for (final entry in suggestions.entries) {
      dev.log(
        ' ${entry.value.length} suggestion for ${p.data.name} for cluster ID ${entry.key} are  suggestions ${entry.value}}',
        name: "ClusterFeedbackService",
      );
    }

    for (final suggestionsPerCluster in suggestions.values) {
      for (final suggestion in suggestionsPerCluster) {
        final clusterID = suggestion.$1;
        await PersonService.instance.assignClusterToPerson(
          personID: p.remoteID,
          clusterID: clusterID,
        );
      }
    }

    Bus.instance.fire(PeopleChangedEvent());

    return true;
  }

  // TODO: iterate over this method to find sweet spot
  Future<Map<int, List<String>>> breakUpCluster(
    int clusterID, {
    useDbscan = false,
  }) async {
    _logger.info(
      'breakUpCluster called for cluster $clusterID with dbscan $useDbscan',
    );
    final faceMlDb = FaceMLDataDB.instance;

    final faceIDs = await faceMlDb.getFaceIDsForCluster(clusterID);
    final originalFaceIDsSet = faceIDs.toSet();
    final fileIDs = faceIDs.map((e) => getFileIdFromFaceId(e)).toList();

    final embeddings = await faceMlDb.getFaceEmbeddingMapForFile(fileIDs);
    embeddings.removeWhere((key, value) => !faceIDs.contains(key));

    final fileIDToCreationTime =
        await FilesDB.instance.getFileIDToCreationTime();

    final Map<int, List<String>> clusterIdToFaceIds = {};
    if (useDbscan) {
      final dbscanClusters = await FaceClustering.instance.predictDbscan(
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
      final clusteringInput = embeddings.map((key, value) {
        return MapEntry(key, (null, value));
      });

      final faceIdToCluster = await FaceClustering.instance.predictLinear(
        clusteringInput,
        fileIDToCreationTime: fileIDToCreationTime,
        distanceThreshold: 0.23,
      );

      if (faceIdToCluster == null) {
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

  Future<Map<int, List<double>>> _getUpdateClusterAvg(
    Map<int, int> allClusterIdsToCountMap,
    Set<int> ignoredClusters, {
    int minClusterSize = 1,
    int maxClusterInCurrentRun = 500,
    int maxEmbeddingToRead = 10000,
  }) async {
    final faceMlDb = FaceMLDataDB.instance;
    _logger.info(
      'start getUpdateClusterAvg for ${allClusterIdsToCountMap.length} clusters, minClusterSize $minClusterSize, maxClusterInCurrentRun $maxClusterInCurrentRun',
    );

    final Map<int, (Uint8List, int)> clusterToSummary =
        await faceMlDb.clusterSummaryAll();
    final Map<int, (Uint8List, int)> updatesForClusterSummary = {};

    final Map<int, List<double>> clusterAvg = {};

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
        clusterAvg[id] = EVector.fromBuffer(clusterToSummary[id]!.$1).values;
        alreadyUpdatedClustersCnt++;
      }
      if (allClusterIdsToCountMap[id]! < minClusterSize) {
        allClusterIds.remove(id);
        smallerClustersCnt++;
      }
    }
    _logger.info(
      'Ignored $ignoredClustersCnt clusters, already updated $alreadyUpdatedClustersCnt clusters, $smallerClustersCnt clusters are smaller than $minClusterSize',
    );
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
    _logger.info('end getUpdateClusterAvg for ${clusterAvg.length} clusters');

    return clusterAvg;
  }

  /// Returns a map of person's clusterID to map of closest clusterID to with disstance
  Map<int, List<(int, double)>> _calcSuggestionsMean(
    Map<int, List<double>> clusterAvg,
    Set<int> personClusters,
    Set<int> ignoredClusters,
    double maxClusterDistance,
  ) {
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
    for (final entry in suggestions.entries) {
      entry.value.sort((a, b) => a.$1.compareTo(b.$1));
    }

    return suggestions;
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
    List<ClusterSuggestion> suggestions,
  ) async {
    if (suggestions.isEmpty) {
      debugPrint('No suggestions to sort');
      return;
    }
    final startTime = DateTime.now();
    final faceMlDb = FaceMLDataDB.instance;

    // Get the cluster averages for the person's clusters and the suggestions' clusters
    final Map<int, (Uint8List, int)> clusterToSummary =
        await faceMlDb.clusterSummaryAll();

    // Calculate the avg embedding of the person
    final personClusters = await faceMlDb.getPersonClusterIDs(person.remoteID);
    final personEmbeddingsCount = personClusters
        .map((e) => clusterToSummary[e]!.$2)
        .reduce((a, b) => a + b);
    final List<double> personAvg = List.filled(192, 0);
    for (final personClusterID in personClusters) {
      final personClusterBlob = clusterToSummary[personClusterID]!.$1;
      final personClusterAvg = EVector.fromBuffer(personClusterBlob).values;
      final clusterWeight =
          clusterToSummary[personClusterID]!.$2 / personEmbeddingsCount;
      for (int i = 0; i < personClusterAvg.length; i++) {
        personAvg[i] += personClusterAvg[i] *
            clusterWeight; // Weighted sum of the cluster averages
      }
    }

    // Sort the suggestions based on the distance to the person
    for (final suggestion in suggestions) {
      final clusterID = suggestion.clusterIDToMerge;
      final faceIdToEmbeddingMap = await faceMlDb.getFaceEmbeddingMapForFile(
        suggestion.filesInCluster.map((e) => e.uploadedFileID!).toList(),
      );
      final fileIdToDistanceMap = {};
      for (final entry in faceIdToEmbeddingMap.entries) {
        fileIdToDistanceMap[getFileIdFromFaceId(entry.key)] =
            cosineDistForNormVectors(
          personAvg,
          EVector.fromBuffer(entry.value).values,
        );
      }
      suggestion.filesInCluster.sort((b, a) {
        //todo: review with @laurens, added this to avoid null safety issue
        final double distanceA = fileIdToDistanceMap[a.uploadedFileID!] ?? -1;
        final double distanceB = fileIdToDistanceMap[b.uploadedFileID!] ?? -1;
        return distanceA.compareTo(distanceB);
      });

      debugPrint(
        "[${_logger.name}] Sorted suggestions for cluster $clusterID based on distance to person: ${suggestion.filesInCluster.map((e) => fileIdToDistanceMap[e.uploadedFileID]).toList()}",
      );
    }

    final endTime = DateTime.now();
    _logger.info(
      "Sorting suggestions based on distance to person took ${endTime.difference(startTime).inMilliseconds} ms for ${suggestions.length} suggestions",
    );
  }
}
