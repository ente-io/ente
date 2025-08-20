import 'dart:developer' as dev show log;
import "dart:math" show Random, min;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/linalg.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/face_clustering_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/search_service.dart";

class ClusterSuggestion {
  final PersonEntity person;
  final String clusterIDToMerge;
  final double distancePersonToCluster;
  final bool usedOnlyMeanForSuggestion;
  final List<EnteFile> filesInCluster;
  final List<String> faceIDsInCluster;

  ClusterSuggestion(
    this.person,
    this.clusterIDToMerge,
    this.distancePersonToCluster,
    this.usedOnlyMeanForSuggestion,
    this.filesInCluster,
    this.faceIDsInCluster,
  );
}

class ClusterFeedbackService<T> {
  final Logger _logger = Logger("ClusterFeedbackService");
  final _computer = Computer.shared();
  ClusterFeedbackService._privateConstructor();
  late final mlDataDB = MLDataDB.instance;

  static final ClusterFeedbackService instance =
      ClusterFeedbackService._privateConstructor();

  static String lastViewedClusterID = '';
  static setLastViewedClusterID(String clusterID) {
    lastViewedClusterID = clusterID;
  }

  static resetLastViewedClusterID() {
    lastViewedClusterID = '';
  }

  /// Returns a list of cluster suggestions for a person.
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
      final List<(String, double, bool)> foundSuggestions =
          await _getSuggestions(person);
      final findSuggestionsTime = DateTime.now();
      _logger.info(
        'getSuggestionForPerson `_getSuggestions`: Found ${foundSuggestions.length} suggestions in ${findSuggestionsTime.difference(startTime).inMilliseconds} ms',
      );

      // Get the files for the suggestions
      final suggestionClusterIDs = foundSuggestions.map((e) => e.$1).toSet();
      final Map<int, Set<String>> fileIdToClusterID =
          await mlDataDB.getFileIdToClusterIDSetForCluster(
        suggestionClusterIDs,
      );
      final clusterIdToFaceIDs =
          await mlDataDB.getClusterToFaceIDs(suggestionClusterIDs);
      final Map<String, List<EnteFile>> clusterIDToFiles = {};
      final allFiles = await SearchService.instance.getAllFilesForSearch();
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
              person,
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
      // Get the relevant faces to be removed
      final faceIDs = await mlDataDB
          .getFaceIDsForPerson(p.remoteID)
          .then((iterable) => iterable.toList());
      faceIDs.retainWhere((faceID) {
        final fileID = getFileIdFromFaceId<int>(faceID);
        return files.any((file) => file.uploadedFileID == fileID);
      });
      final embeddings = await mlDataDB.getFaceEmbeddingMapForFaces(faceIDs);

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
      await mlDataDB.forceUpdateClusterIds(newFaceIdToClusterID);
      await mlDataDB.clusterSummaryUpdate(clusterResult.newClusterSummaries);

      // Make sure the deleted faces don't get suggested in the future
      final notClusterIdToPersonId = <String, String>{};
      for (final clusterId in newFaceIdToClusterID.values.toSet()) {
        notClusterIdToPersonId[clusterId] = p.remoteID;
      }
      await mlDataDB.bulkCaptureNotPersonFeedback(notClusterIdToPersonId);

      // Update remote so new sync does not undo this change
      await PersonService.instance
          .removeFacesFromPerson(person: p, faceIDs: faceIDs.toSet());

      Bus.instance.fire(PeopleChangedEvent());
      return;
    } catch (e, s) {
      _logger.severe("Error in removeFilesFromPerson", e, s);
      rethrow;
    }
  }

  Future<String> removeFaceFromPerson(
    String faceID,
    PersonEntity person,
  ) async {
    try {
      final updatedClusterID = newClusterID();
      final newFaceIdToClusterID = {faceID: updatedClusterID};
      await mlDataDB.forceUpdateClusterIds(newFaceIdToClusterID);

      // Make sure the deleted faces don't get suggested in the future
      final notClusterIdToPersonId = {updatedClusterID: person.remoteID};
      await mlDataDB.bulkCaptureNotPersonFeedback(notClusterIdToPersonId);

      // Update remote so new sync does not undo this change
      await PersonService.instance
          .removeFacesFromPerson(person: person, faceIDs: {faceID});

      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.removedFaceFromCluster,
          relevantFaceIDs: [faceID],
          source: person.remoteID,
        ),
      );
      return updatedClusterID;
    } catch (e, s) {
      _logger.severe("Error in removeFaceFromPerson", e, s);
      rethrow;
    }
  }

  Future<void> removeFilesFromCluster(
    List<EnteFile> files,
    String clusterID,
  ) async {
    _logger.info('removeFilesFromCluster called');
    try {
      // Get the relevant faces to be removed
      final faceIDs = await mlDataDB
          .getFaceIDsForCluster(clusterID)
          .then((iterable) => iterable.toList());
      faceIDs.retainWhere((faceID) {
        final fileID = getFileIdFromFaceId<int>(faceID);
        return files.any((file) => file.uploadedFileID == fileID);
      });
      final embeddings = await mlDataDB.getFaceEmbeddingMapForFaces(faceIDs);

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
      await mlDataDB.forceUpdateClusterIds(newFaceIdToClusterID);
      await mlDataDB.clusterSummaryUpdate(clusterResult.newClusterSummaries);

      Bus.instance.fire(
        PeopleChangedEvent(
          relevantFiles: files,
          type: PeopleEventType.removedFilesFromCluster,
          source: clusterID,
        ),
      );
      _logger.info('removeFilesFromCluster done');
      return;
    } catch (e, s) {
      _logger.severe("Error in removeFilesFromCluster", e, s);
      rethrow;
    }
  }

  Future<String> removeFaceFromCluster({
    required String faceID,
    String? clusterID,
  }) async {
    try {
      final updatedClusterID = newClusterID();
      final newFaceIdToClusterID = {faceID: updatedClusterID};
      await mlDataDB.forceUpdateClusterIds(newFaceIdToClusterID);

      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.removedFaceFromCluster,
          relevantFaceIDs: [faceID],
          source: clusterID ?? "",
        ),
      );
      return updatedClusterID;
    } catch (e, s) {
      _logger.severe("Error in removeFaceFromCluster", e, s);
      rethrow;
    }
  }

  Future<void> addFacesToCluster(List<String> faceIDs, String clusterID) async {
    final faceIDToClusterID = <String, String>{};
    for (final faceID in faceIDs) {
      faceIDToClusterID[faceID] = clusterID;
    }
    await mlDataDB.forceUpdateClusterIds(faceIDToClusterID);
    Bus.instance.fire(PeopleChangedEvent());
    return;
  }

  Future<List<ClusterSuggestion>> getAllLargePersonSuggestions() async {
    final personsMap = await PersonService.instance.getPersonsMap();
    if (personsMap.isEmpty) return [];
    try {
      final allClusterIdsToCountMap = await mlDataDB.clusterIdToFaceCount();
      final personToClusterIDs = await mlDataDB.getPersonToClusterIDs();
      final personIdToBiggestCluster = <String, String>{};
      final biggestClusterToPersonID = <String, String>{};
      final personIdToOtherPersonClusterIDs = <String, Set<String>>{};
      for (final person in personsMap.values) {
        final personID = person.remoteID;
        final personClusters = personToClusterIDs[personID] ?? {};
        if (person.data.isIgnored) {
          personIdToOtherPersonClusterIDs[personID] = personClusters;
          continue;
        }
        int biggestClusterSize = 0;
        String biggestClusterID = '';
        final Set<String> otherPersonClusterIDs = {};
        for (final clusterID in personClusters) {
          final clusterSize = allClusterIdsToCountMap[clusterID] ?? 0;
          if (clusterSize > biggestClusterSize) {
            if (biggestClusterSize > 0) {
              otherPersonClusterIDs.add(biggestClusterID);
            }
            biggestClusterID = clusterID;
            biggestClusterSize = clusterSize;
          } else {
            otherPersonClusterIDs.add(clusterID);
          }
        }
        personIdToBiggestCluster[personID] = biggestClusterID;
        biggestClusterToPersonID[biggestClusterID] = personID;
        personIdToOtherPersonClusterIDs[personID] = otherPersonClusterIDs;
      }
      final allPersonClusters = biggestClusterToPersonID.keys.toSet();
      final allOtherPersonClustersToIgnore =
          personIdToOtherPersonClusterIDs.values.reduce((a, b) => a.union(b));
      final Map<String, Vector> clusterAvg = await _getUpdateClusterAvg(
        allClusterIdsToCountMap,
        allOtherPersonClustersToIgnore,
        minClusterSize: kMinimumClusterSizeSearchResult,
      );

      final Map<String, Set<String>> personClusterToIgnoredClusters = {};
      final personToRejectedSuggestions =
          await mlDataDB.getPersonToRejectedSuggestions();
      for (final personID in personToRejectedSuggestions.keys) {
        final personCluster = personIdToBiggestCluster[personID];
        if (personCluster == null) continue;
        final ignoredClusters = personToRejectedSuggestions[personID] ?? {};
        personClusterToIgnoredClusters[personCluster] = ignoredClusters;
      }

      final List<(String, double, String)> foundSuggestions =
          await calcSuggestionsMeanInComputer(
        clusterAvg,
        allPersonClusters,
        allOtherPersonClustersToIgnore,
        personClusterToIgnoredClusters: personClusterToIgnoredClusters,
        0.55,
      );

      // Get the files for the suggestions
      final suggestionClusterIDs = foundSuggestions.map((e) => e.$1).toSet();
      final Map<int, Set<String>> fileIdToClusterID =
          await mlDataDB.getFileIdToClusterIDSetForCluster(
        suggestionClusterIDs,
      );
      final clusterIdToFaceIDs =
          await mlDataDB.getClusterToFaceIDs(suggestionClusterIDs);
      final Map<String, List<EnteFile>> clusterIDToFiles = {};
      final allFiles = await SearchService.instance.getAllFilesForSearch();
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

      final List<ClusterSuggestion> finalSuggestions = <ClusterSuggestion>[];
      for (final clusterSuggestion in foundSuggestions) {
        if (clusterIDToFiles.containsKey(clusterSuggestion.$1)) {
          finalSuggestions.add(
            ClusterSuggestion(
              personsMap[biggestClusterToPersonID[clusterSuggestion.$3]]!,
              clusterSuggestion.$1,
              clusterSuggestion.$2,
              true,
              clusterIDToFiles[clusterSuggestion.$1]!,
              clusterIdToFaceIDs[clusterSuggestion.$1]!.toList(),
            ),
          );
        }
      }
      try {
        await _sortSuggestionsOnDistanceToPerson(null, finalSuggestions);
      } catch (e, s) {
        _logger.severe("Error in sorting suggestions", e, s);
      }
      return finalSuggestions;
    } catch (e, s) {
      _logger.severe("Error in getAllLargePersonSuggestions", e, s);
      rethrow;
    }
  }

  Future<bool> checkAndDoAutomaticMerges(
    PersonEntity p, {
    required String personClusterID,
  }) async {
    final faceIDs = await mlDataDB.getFaceIDsForCluster(personClusterID);

    if (faceIDs.length < 2 * kMinimumClusterSizeSearchResult) {
      final fileIDs = faceIDs.map(getFileIdFromFaceId<int>).toSet();
      if (fileIDs.length < kMinimumClusterSizeSearchResult) {
        _logger.info(
          'Cluster $personClusterID has less than $kMinimumClusterSizeSearchResult faces, not doing automatic merges',
        );
        return false;
      }
    }
    final List<(String, double, String)> suggestions =
        await _getFastSuggestions(
      p,
      personClusterID,
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
      await mlDataDB.assignClusterToPerson(
        personID: p.remoteID,
        clusterID: clusterID,
      );
    }

    Bus.instance.fire(PeopleChangedEvent());

    return true;
  }

  Future<void> addClusterToExistingPerson({
    required PersonEntity person,
    required String clusterID,
  }) async {
    if (person.data.rejectedFaceIDs.isNotEmpty) {
      final clusterFaceIDs = await mlDataDB.getFaceIDsForCluster(clusterID);
      final rejectedLengthBefore = person.data.rejectedFaceIDs.length;
      person.data.rejectedFaceIDs
          .removeWhere((faceID) => clusterFaceIDs.contains(faceID));
      final rejectedLengthAfter = person.data.rejectedFaceIDs.length;
      if (rejectedLengthBefore != rejectedLengthAfter) {
        _logger.info(
          'Removed ${rejectedLengthBefore - rejectedLengthAfter} rejected faces from person ${person.data.name} due to adding cluster $clusterID',
        );
        await PersonService.instance.updatePerson(person);
      }
    }
    await mlDataDB.assignClusterToPerson(
      personID: person.remoteID,
      clusterID: clusterID,
    );
    Bus.instance.fire(
      PeopleChangedEvent(
        type: PeopleEventType.addedClusterToPerson,
        source: clusterID,
      ),
    );
  }

  Future<void> ignoreCluster(String clusterID) async {
    final ignoredPerson = await PersonService.instance
        .addPerson(name: '', clusterID: clusterID, isHidden: true);
    final mergedAndFired = await checkAndDoAutomaticMerges(
      ignoredPerson,
      personClusterID: clusterID,
    );
    if (!mergedAndFired) Bus.instance.fire(PeopleChangedEvent());
  }

  Future<List<(String, int)>> checkForMixedClusters() async {
    final allClusterToFaceCount = await mlDataDB.clusterIdToFaceCount();
    final clustersToInspect = <String>[];
    for (final clusterID in allClusterToFaceCount.keys) {
      if (allClusterToFaceCount[clusterID]! > 20 &&
          allClusterToFaceCount[clusterID]! < 500) {
        clustersToInspect.add(clusterID);
      }
    }

    final fileIDToCreationTime =
        await FilesDB.instance.getFileIDToCreationTime();

    final susClusters = <(String, int)>[];

    final inspectionStart = DateTime.now();
    for (final clusterID in clustersToInspect) {
      final int originalClusterSize = allClusterToFaceCount[clusterID]!;
      final faceIDs = await mlDataDB.getFaceIDsForCluster(clusterID);

      final embeddings = await mlDataDB.getFaceEmbeddingMapForFaces(faceIDs);

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
      final String biggestClusterID = newClusterIdToCount.keys.reduce((a, b) {
        return newClusterIdToCount[a]! > newClusterIdToCount[b]! ? a : b;
      });
      final int biggestSize = newClusterIdToCount[biggestClusterID]!;
      final biggestRatio = biggestSize / originalClusterSize;
      if (newClusterIdToCount.length > 1) {
        final List<String> clusterIDs = newClusterIdToCount.keys.toList();
        clusterIDs.remove(biggestClusterID);
        final String secondBiggestClusterID = clusterIDs.reduce((a, b) {
          return newClusterIdToCount[a]! > newClusterIdToCount[b]! ? a : b;
        });
        final int secondBiggestSize =
            newClusterIdToCount[secondBiggestClusterID]!;
        final secondBiggestRatio = secondBiggestSize / originalClusterSize;

        if (biggestRatio < 0.5 || secondBiggestRatio > 0.2) {
          final faceIdsOfCluster =
              await mlDataDB.getFaceIDsForCluster(clusterID);
          final uniqueFileIDs =
              faceIdsOfCluster.map(getFileIdFromFaceId<int>).toSet();
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
    String clusterID, {
    bool useDbscan = false,
  }) async {
    _logger.info(
      'breakUpCluster called for cluster $clusterID with dbscan $useDbscan',
    );
    final faceIDs = await mlDataDB.getFaceIDsForCluster(clusterID);
    final originalFaceIDsSet = faceIDs.toSet();

    final embeddings = await mlDataDB.getFaceEmbeddingMapForFaces(faceIDs);

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
  Future<List<(String, double, bool)>> _getSuggestions(
    PersonEntity p, {
    int sampleSize = 50,
    double maxMedianDistance = 0.62,
    double goodMedianDistance = 0.55,
    double maxMeanDistance = 0.65,
    double goodMeanDistance = 0.45,
  }) async {
    final w = (kDebugMode ? EnteWatch('getSuggestions') : null)?..start();
    // Get all the cluster data
    final allClusterIdsToCountMap = await mlDataDB.clusterIdToFaceCount();
    final ignoredClusters = await mlDataDB.getPersonIgnoredClusters(p.remoteID);
    final personClusters = await mlDataDB.getPersonClusterIDs(p.remoteID);
    final personFaceIDs = await mlDataDB.getFaceIDsForPerson(p.remoteID);
    final personFileIDs = personFaceIDs.map(getFileIdFromFaceId<int>).toSet();
    w?.log(
      '${p.data.name} has ${personClusters.length} existing clusters, getting all database data done',
    );
    final allClusterIdToFaceIDs = await mlDataDB.getAllClusterIdToFaceIDs();
    w?.log('getAllClusterIdToFaceIDs done');

    // First only do a simple check on the big clusters, if the person does not have small clusters yet
    final smallestPersonClusterSize = personClusters
        .map((clusterID) => allClusterIdsToCountMap[clusterID] ?? 0)
        .reduce((value, element) => min(value, element));
    final checkSizes = [20, kMinimumClusterSizeSearchResult, 10, 5, 1];
    Map<String, Vector> clusterAvgBigClusters = <String, Vector>{};
    final List<(String, double)> suggestionsMean = [];
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
        final List<(String, double, String)> suggestionsMeanBigClusters =
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
              .map((faceID) => getFileIdFromFaceId<int>(faceID))
              .toSet();
          final overlap = personFileIDs.intersection(suggestionSet);
          if (overlap.isNotEmpty &&
              ((overlap.length / suggestionSet.length) > 0.5)) {
            await mlDataDB.captureNotPersonFeedback(
              personID: p.remoteID,
              clusterID: suggestion.$1,
            );
            continue;
          }
          suggestionsMean.add((suggestion.$1, suggestion.$2));
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
    final List<(String, double, String)> moreSuggestionsMean =
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
          await mlDataDB.getFaceEmbeddingsForCluster(clusterID);
      personEmbeddingsProto.addAll(embeddings);
    }
    final sampledEmbeddingsProto = _randomSampleWithoutReplacement(
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
    final List<(String, double)> suggestionsMedian = [];
    final List<(String, double)> greatSuggestionsMedian = [];
    double minMedianDistance = maxMedianDistance;
    for (final otherClusterId in otherClusterIdsCandidates) {
      final Iterable<Uint8List> otherEmbeddingsProto =
          await mlDataDB.getFaceEmbeddingsForCluster(
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

    final List<(String, double, bool)> finalSuggestionsMedian =
        suggestionsMedian
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

  /// Returns a list of suggestions. For each suggestion we return a record consisting of the following elements:
  /// 1. clusterID: the ID of the cluster
  /// 2. distance: the distance between the person's cluster and the suggestion
  /// 3. personClusterID: the ID of the person's cluster
  Future<List<(String, double, String)>> _getFastSuggestions(
    PersonEntity person,
    String clusterID,
    double threshold, {
    Set<String>? extraIgnoredClusters,
  }) async {
    final allClusterIdsToCountMap = (await mlDataDB.clusterIdToFaceCount());
    final personignoredClusters =
        await mlDataDB.getPersonIgnoredClusters(person.remoteID);
    final ignoredClusters =
        personignoredClusters.union(extraIgnoredClusters ?? {});
    final startTime = DateTime.now();
    final Map<String, Vector> clusterAvg = await _getUpdateClusterAvg(
      allClusterIdsToCountMap,
      ignoredClusters,
      minClusterSize: kMinimumClusterSizeSearchResult,
    );
    final avgCalcTime = DateTime.now();

    // Returns a list of tuples containing the suggestion ID, distance, and personClusterID, respectively
    final List<(String, double, String)> foundSuggestions =
        await calcSuggestionsMeanInComputer(
      clusterAvg,
      {clusterID},
      ignoredClusters,
      threshold,
    );
    final suggestionCalcTime = DateTime.now();
    _logger.info(
      "Calculated average vectors in ${avgCalcTime.difference(startTime).inMilliseconds}ms and suggestions in ${suggestionCalcTime.difference(avgCalcTime).inMilliseconds}ms",
    );
    return foundSuggestions;
  }

  Future<Map<String, Vector>> _getUpdateClusterAvg(
    Map<String, int> allClusterIdsToCountMap,
    Set<String> ignoredClusters, {
    int minClusterSize = 1,
    int maxClusterInCurrentRun = 500,
    int maxEmbeddingToRead = 10000,
  }) async {
    final w = (kDebugMode ? EnteWatch('_getUpdateClusterAvg') : null)?..start();
    final startTime = DateTime.now();
    _logger.info(
      'start getUpdateClusterAvg for ${allClusterIdsToCountMap.length} clusters, minClusterSize $minClusterSize, maxClusterInCurrentRun $maxClusterInCurrentRun',
    );

    final Map<String, (Uint8List, int)> clusterToSummary =
        await mlDataDB.getAllClusterSummary(minClusterSize);
    final Map<String, (Uint8List, int)> updatesForClusterSummary = {};

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
    ) as (Map<String, Vector>, Set<String>, int, int, int);
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
    final List<String> clusterIdsToRead = [];
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

    final Map<String, Iterable<Uint8List>> clusterEmbeddings =
        await mlDataDB.getFaceEmbeddingsForClusters(clusterIdsToRead);

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
        await mlDataDB.clusterSummaryUpdate(updatesForClusterSummary);
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
      await mlDataDB.clusterSummaryUpdate(updatesForClusterSummary);
    }
    w?.logAndReset('done computing avg ');
    _logger.info(
      'end getUpdateClusterAvg for ${clusterAvg.length} clusters, done in ${DateTime.now().difference(startTime).inMilliseconds} ms',
    );

    return clusterAvg;
  }

  Future<List<(String, double, String)>> calcSuggestionsMeanInComputer(
    Map<String, Vector> clusterAvg,
    Set<String> personClusters,
    Set<String> ignoredClusters,
    double maxClusterDistance, {
    Map<String, Set<String>>? personClusterToIgnoredClusters,
  }) async {
    return await _computer.compute(
      _calcSuggestionsMean,
      param: {
        'clusterAvg': clusterAvg,
        'personClusters': personClusters,
        'ignoredClusters': ignoredClusters,
        'maxClusterDistance': maxClusterDistance,
        'personClusterToIgnoredClusters': personClusterToIgnoredClusters,
      },
    );
  }

  List<S> _randomSampleWithoutReplacement<S>(
    Iterable<S> embeddings,
    int sampleSize,
  ) {
    final random = Random();

    if (sampleSize >= embeddings.length) {
      return embeddings.toList();
    }

    // If sampleSize is more than half the list size, shuffle and take first sampleSize elements
    if (sampleSize > embeddings.length / 2) {
      final List<S> shuffled = List<S>.from(embeddings)..shuffle(random);
      return shuffled.take(sampleSize).toList(growable: false);
    }

    // Otherwise, use the set-based method for efficiency
    final selectedIndices = <int>{};
    final sampledEmbeddings = <S>[];
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
    PersonEntity? person,
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
    final w = (kDebugMode ? EnteWatch('sortSuggestions') : null)?..start();

    final Map<String, Vector> personAverages = {};
    if (person != null) {
      final avg = await _getPersonAvg(person.remoteID);
      w?.log('getPersonAvg');
      if (avg != null) personAverages[person.remoteID] = avg;
    }

    // Sort the suggestions based on the distance to the person
    for (final suggestion in suggestions) {
      if (onlySortBigSuggestions) {
        if (suggestion.filesInCluster.length <= 8) {
          continue;
        }
      }
      // get person average
      Vector? personAvg = personAverages[suggestion.person.remoteID];
      if (personAvg == null) {
        personAvg = await _getPersonAvg(suggestion.person.remoteID);
        if (personAvg != null) {
          personAverages[suggestion.person.remoteID] = personAvg;
        } else {
          continue;
        }
      }

      final clusterID = suggestion.clusterIDToMerge;
      final faceIDs = suggestion.faceIDsInCluster;
      final faceIdToEmbeddingMap = await mlDataDB.getFaceEmbeddingMapForFaces(
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
        fileIdToDistanceMap[getFileIdFromFaceId<int>(entry.key)] =
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
    _logger.fine(
      "Sorting suggestions based on distance to person took ${endTime.difference(startTime).inMilliseconds} ms for ${suggestions.length} suggestions",
    );
  }

  Future<Vector?> _getPersonAvg(String personID) async {
    final w = (kDebugMode ? EnteWatch('_getPersonAvg') : null)?..start();
    // Get the cluster averages for the person's clusters and the suggestions' clusters
    final personClusters = await mlDataDB.getPersonClusterIDs(personID);
    w?.log('got person clusters');
    final Map<String, (Uint8List, int)> personClusterToSummary =
        await mlDataDB.getClusterToClusterSummary(personClusters);
    w?.log('got cluster summaries');

    // remove personClusters that don't have any summary
    for (final clusterID in personClusters.toSet()) {
      if (!personClusterToSummary.containsKey(clusterID)) {
        _logger.warning('missing summary for $clusterID');
        personClusters.remove(clusterID);
      }
    }
    if (personClusters.isEmpty) {
      _logger.warning('No person clusters with summary found');
      return null;
    }

    // Calculate the avg embedding of the person
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
    return personAvg;
  }

  Future<void> debugLogClusterBlurValues(
    String clusterID, {
    int? clusterSize,
    bool logClusterSummary = false,
    bool logBlurValues = false,
  }) async {
    if (!kDebugMode) return;

    // Logging the clusterID
    _logger.info(
      "Debug logging for cluster $clusterID${clusterSize != null ? ' with $clusterSize photos' : ''}",
    );
    // todo:(laurens) remove to review
    const String biggestClusterID = 'some random id';

    // Logging the cluster summary for the cluster
    if (logClusterSummary) {
      final summaryMap = await mlDataDB.getClusterToClusterSummary(
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
        final Iterable<Uint8List> biggestEmbeddings =
            await mlDataDB.getFaceEmbeddingsForCluster(biggestClusterID);
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
            await mlDataDB.getFaceEmbeddingsForCluster(clusterID);
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
      final List<double> blurValues = await mlDataDB
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

/// Returns a list of suggestions for a cluster in a tuple. The values of the tuple are:
/// 1. The suggested cluster ID
/// 2. The distance between the two clusters
/// 3. The corresponding cluster ID of the person cluster
List<(String, double, String)> _calcSuggestionsMean(Map<String, dynamic> args) {
  // Fill in args
  final Map<String, Vector> clusterAvg = args['clusterAvg'];
  final Set<String> personClusters = args['personClusters'];
  final Set<String> ignoredClusters = args['ignoredClusters'];
  final double maxClusterDistance = args['maxClusterDistance'];
  final Map<String, Set<String>>? personClusterToIgnoredClusters =
      args['personClusterToIgnoredClusters'];
  final bool extraIgnoreCheck = personClusterToIgnoredClusters != null;

  final Map<String, List<(String, double)>> suggestions = {};
  const suggestionMax = 2000;
  int suggestionCount = 0;
  int comparisons = 0;
  final w = (kDebugMode ? EnteWatch('getSuggestions') : null)?..start();

  // ignore the clusters that belong to the person or is ignored
  Set<String> otherClusters =
      clusterAvg.keys.toSet().difference(personClusters);
  otherClusters = otherClusters.difference(ignoredClusters);

  for (final otherClusterID in otherClusters) {
    final Vector? otherAvg = clusterAvg[otherClusterID];
    if (otherAvg == null) {
      dev.log('[WARNING] no avg for othercluster $otherClusterID');
      continue;
    }
    String? nearestPersonCluster;
    double? minDistance;
    for (final personCluster in personClusters) {
      if (clusterAvg[personCluster] == null) {
        dev.log('[WARNING] no avg for personcluster $personCluster');
        continue;
      }
      if (extraIgnoreCheck &&
          personClusterToIgnoredClusters[personCluster] != null &&
          personClusterToIgnoredClusters[personCluster]!
              .contains(otherClusterID)) {
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
    final List<(String, double, String)> suggestClusterIds = [];
    for (final String personClusterID in suggestions.keys) {
      final suggestionss = suggestions[personClusterID]!;
      suggestClusterIds.addAll(
        suggestionss.map(
          (suggestion) => (suggestion.$1, suggestion.$2, personClusterID),
        ),
      );
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
    return <(String, double, String)>[];
  }
}

Future<(Map<String, Vector>, Set<String>, int, int, int)>
    checkAndSerializeCurrentClusterMeans(
  Map args,
) async {
  final Map<String, int> allClusterIdsToCountMap =
      args['allClusterIdsToCountMap'];
  final int minClusterSize = args['minClusterSize'] ?? 1;
  final Set<String> ignoredClusters = args['ignoredClusters'] ?? {};
  final Map<String, (Uint8List, int)> clusterToSummary =
      args['clusterToSummary'];

  final Map<String, Vector> clusterAvg = {};

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
