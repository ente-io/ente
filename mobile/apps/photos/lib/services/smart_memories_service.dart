import "dart:async";
import "dart:developer" as dev show log;
import "dart:math" show Random, max, min;

import "package:computer/computer.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/memories_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/offline_files_db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/base_location.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memories/clip_memory.dart";
import "package:photos/models/memories/filler_memory.dart";
import "package:photos/models/memories/memories_cache.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/on_this_day_memory.dart";
import "package:photos/models/memories/people_memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/models/memories/smart_memory_constants.dart";
import "package:photos/models/memories/time_memory.dart";
import "package:photos/models/memories/trip_memory.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/language_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/memories/memories_computation_context.dart";
import "package:photos/services/memories/photo_selector.dart";
import "package:photos/services/search_service.dart";

part "smart_memories_clip_calculator.dart";
part "smart_memories_people_calculator.dart";
part "smart_memories_time_calculator.dart";
part "smart_memories_trip_calculator_v2.dart";

class MemoriesResult {
  final List<SmartMemory> memories;
  final List<BaseLocation> baseLocations;

  MemoriesResult(this.memories, this.baseLocations);

  get isEmpty => memories.isEmpty;
}

class SmartMemoriesService {
  final _logger = Logger("SmartMemoriesService");
  MemoriesDB get _memoriesDB =>
      isOfflineMode ? MemoriesDB.offlineInstance : MemoriesDB.instance;

  static const _clipSimilarImageThreshold =
      PhotoSelector.clipSimilarImageThreshold;
  static const _clipActivityQueryThreshold = 0.20;
  static const _clipMemoryTypeQueryThreshold = 0.225;
  static const _minimumMemoryTimeGap = PhotoSelector.minimumMemoryTimeGap;

  static const yearsBefore = 30;

  static const minimumMemoryLength = 5;
  static const _maximumUnnamedPeopleClusters = 10;
  static const _maximumUnnamedPeopleGroupSize = 6;
  static const _minimumUnnamedPeopleWithMePhotos = minimumMemoryLength;
  static const _minimumUnnamedPeopleNonGroupPhotos = minimumMemoryLength;
  static const _minimumUnnamedPeopleNonConsecutiveDays = 4;
  static const _minimumNamedPeopleBeforeDisablingUnnamedFallback = 5;
  static const _unnamedClusterPersonIDPrefix = "cluster:";
  static const _debugForceUnnamedClustersOnly = false;

  SmartMemoriesService();

  Future<
      ({
        Set<String> assignedClusterIDs,
        Map<String, int> clusterIdToFaceCount,
        Map<String, Iterable<String>> clusterIdToFaceIDs,
      })> _loadUnnamedClusterData({
    required MLDataDB mlDataDB,
    required List<PersonEntity> allPersons,
    required bool shouldLoadUnnamedClusterData,
    required TimeLogger t,
  }) async {
    if (!shouldLoadUnnamedClusterData) {
      _logger.info(
        'Skipping unnamed cluster data load (fallback disabled) $t',
      );
      return (
        assignedClusterIDs: <String>{},
        clusterIdToFaceCount: <String, int>{},
        clusterIdToFaceIDs: <String, Iterable<String>>{},
      );
    }

    final allPersonIDs =
        allPersons.map((person) => person.remoteID).toList(growable: false);
    final assignedClusterIDs = allPersonIDs.isEmpty
        ? <String>{}
        : await mlDataDB.getPersonsClusterIDs(allPersonIDs);
    _logger.info('assignedClusterIDs has ${assignedClusterIDs.length} $t');
    final clusterIdToFaceCount = await mlDataDB.clusterIdToFaceCount();
    _logger.info(
      'clusterIdToFaceCount has ${clusterIdToFaceCount.length} entries $t',
    );
    final clusterIdToFaceIDs = await mlDataDB.getAllClusterIdToFaceIDs();
    _logger.info(
      'clusterIdToFaceIDs has ${clusterIdToFaceIDs.length} entries $t',
    );
    return (
      assignedClusterIDs: assignedClusterIDs,
      clusterIdToFaceCount: clusterIdToFaceCount,
      clusterIdToFaceIDs: clusterIdToFaceIDs,
    );
  }

  // One general method to get all memories, which calls on internal methods for each separate memory type
  Future<MemoriesResult> calcSmartMemories(
    DateTime now,
    MemoriesCache oldCache, {
    bool debugSurfaceAll = false,
  }) async {
    try {
      final TimeLogger t = TimeLogger(context: "calcMemories");
      _logger.info(
        'calcMemories called with time: $now at ${DateTime.now()} $t',
      );

      final (allFiles, allFileIdsToFile) = await _getFilesAndMapForMemories(
        useLocalIntIds: isOfflineMode,
        requireLocalId: isOfflineMode,
      );
      _logger.info("All files length: ${allFiles.length} $t");

      final collectionIDsToExclude = await getCollectionIDsToExclude();
      _logger.info(
        'collectionIDsToExclude length: ${collectionIDsToExclude.length} $t',
      );

      final seenTimes = await _memoriesDB.getSeenTimes();
      _logger.info('seenTimes has ${seenTimes.length} entries $t');

      final mlDataDB =
          isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
      final allPersons = isOfflineMode
          ? const <PersonEntity>[]
          : await PersonService.instance.getPersons();
      final persons =
          allPersons.where((person) => !person.data.hideFromMemories).toList();
      _logger.info(
        'gotten all ${persons.length} persons after filtering $t',
      );
      final bool unnamedPeopleFallbackEnabled =
          localSettings.showOfflineModeOption;
      final amountOfNonIgnoredPersons =
          persons.where((person) => !person.data.isIgnored).length;
      final canUseUnnamedFallback = unnamedPeopleFallbackEnabled &&
          (isOfflineMode ||
              amountOfNonIgnoredPersons <
                  _minimumNamedPeopleBeforeDisablingUnnamedFallback);
      final shouldLoadUnnamedClusterData = unnamedPeopleFallbackEnabled &&
          (canUseUnnamedFallback ||
              debugSurfaceAll ||
              _debugForceUnnamedClustersOnly);
      final unnamedClusterData = await _loadUnnamedClusterData(
        mlDataDB: mlDataDB,
        allPersons: allPersons,
        shouldLoadUnnamedClusterData: shouldLoadUnnamedClusterData,
        t: t,
      );
      final assignedClusterIDs = unnamedClusterData.assignedClusterIDs;
      final clusterIdToFaceCount = unnamedClusterData.clusterIdToFaceCount;
      final clusterIdToFaceIDs = unnamedClusterData.clusterIdToFaceIDs;

      final currentUserEmail =
          isOfflineMode ? null : Configuration.instance.getEmail();
      _logger.info('currentUserEmail: $currentUserEmail $t');

      final cities = await locationService.getCities();
      _logger.info('cities has ${cities.length} entries $t');

      final Map<int, List<FaceWithoutEmbedding>> fileIdToFaces =
          await mlDataDB.getFileIDsToFacesWithoutEmbedding();
      _logger.info('fileIdToFaces has ${fileIdToFaces.length} entries $t');

      final allImageEmbeddings = await mlDataDB.getAllClipVectors();
      _logger.info(
        'allImageEmbeddings has ${allImageEmbeddings.length} entries $t',
      );

      _logger.info('Loading text embeddings via cache service');
      final clipPositiveTextVector = Vector.fromList(
        await textEmbeddingsCacheService.getEmbedding(
          "Photo of a precious and nostalgic memory radiating warmth, vibrant energy, or quiet beauty — alive with color, light, or emotion",
        ),
      );

      final clipPeopleActivityVectors = <PeopleActivity, Vector>{};
      for (final activity in PeopleActivity.values) {
        final query = activityQuery(activity);
        clipPeopleActivityVectors[activity] = Vector.fromList(
          await textEmbeddingsCacheService.getEmbedding(query),
        );
      }

      final clipMemoryTypeVectors = <ClipMemoryType, Vector>{};
      for (final memoryType in ClipMemoryType.values) {
        final query = clipQuery(memoryType);
        clipMemoryTypeVectors[memoryType] = Vector.fromList(
          await textEmbeddingsCacheService.getEmbedding(query),
        );
      }
      _logger.info('Text embeddings loaded via cache service');

      final local = await getLocale();
      final languageCode = local?.languageCode ?? "en";
      final s = await LanguageService.locals;

      _logger.info('get locale and S $t');

      _logger.info('all data fetched $t at ${DateTime.now()}, to computer');
      final computationContext = MemoriesComputationContext(
        allFiles: allFiles,
        allFileIdsToFile: allFileIdsToFile,
        collectionIDsToExclude: collectionIDsToExclude,
        isOfflineMode: isOfflineMode,
        now: now,
        oldCache: oldCache,
        debugSurfaceAll: debugSurfaceAll,
        canUseUnnamedFallback: canUseUnnamedFallback,
        seenTimes: seenTimes,
        persons: persons,
        currentUserEmail: currentUserEmail,
        cities: cities,
        fileIdToFaces: fileIdToFaces,
        clusterIdToFaceCount: clusterIdToFaceCount,
        clusterIdToFaceIDs: clusterIdToFaceIDs,
        assignedClusterIDs: assignedClusterIDs,
        allImageEmbeddings: allImageEmbeddings,
        clipPositiveTextVector: clipPositiveTextVector,
        clipPeopleActivityVectors: clipPeopleActivityVectors,
        clipMemoryTypeVectors: clipMemoryTypeVectors,
      );
      final memoriesResult = await Computer.shared().compute(
        _allMemoriesCalculations,
        param: computationContext.toIsolateArgs(),
      ) as MemoriesResult;
      _logger.info(
        '${memoriesResult.memories.length} memories computed in computer $t',
      );

      if (isOfflineMode && memoriesResult.isEmpty) {
        _logger.severe(
          "Smart memories returned empty in offline mode, falling back to simple memories",
        );
        final fallbackMemories = await calcSimpleMemories();
        return MemoriesResult(fallbackMemories, <BaseLocation>[]);
      }

      for (final memory in memoriesResult.memories) {
        memory.title = memory.createTitle(s, languageCode);
      }
      _logger.info('titles created for all memories $t');
      return memoriesResult;
    } catch (e, s) {
      _logger.severe("Error calculating smart memories", e, s);
      if (isOfflineMode) {
        try {
          _logger.warning(
            "Falling back to simple memories after smart memories failure in offline mode",
          );
          final fallbackMemories = await calcSimpleMemories();
          return MemoriesResult(fallbackMemories, <BaseLocation>[]);
        } catch (fallbackError, fallbackStackTrace) {
          _logger.severe(
            "Offline fallback to simple memories failed",
            fallbackError,
            fallbackStackTrace,
          );
        }
      }
      return MemoriesResult(<SmartMemory>[], <BaseLocation>[]);
    }
  }

  static List<EmbeddingVector> _getEmbeddingsForFileIDs(
    Map<int, EmbeddingVector> fileIDToImageEmbedding,
    Set<int> fileIDs,
  ) =>
      PhotoSelector.getEmbeddingsForFileIDs(fileIDToImageEmbedding, fileIDs);

  static bool _isNearDuplicate(
    int fileID,
    Iterable<int> selectedFileIDs,
    Map<int, EmbeddingVector> fileIDToImageEmbedding, {
    double similarityThreshold = _clipSimilarImageThreshold,
  }) =>
      PhotoSelector.isNearDuplicate(
        fileID,
        selectedFileIDs,
        fileIDToImageEmbedding,
        similarityThreshold: similarityThreshold,
      );

  static int? _memoryFileId(
    EnteFile file, {
    required bool isOfflineMode,
  }) =>
      PhotoSelector.memoryFileId(file, isOfflineMode: isOfflineMode);

  static int? _memoryFileIdFromMemory(
    Memory memory, {
    required bool isOfflineMode,
  }) =>
      PhotoSelector.memoryFileIdFromMemory(
        memory,
        isOfflineMode: isOfflineMode,
      );

  static bool _isTooCloseInTime(
    int? creationTime,
    Iterable<int> selectedCreationTimes, {
    Duration minGap = _minimumMemoryTimeGap,
  }) =>
      PhotoSelector.isTooCloseInTime(
        creationTime,
        selectedCreationTimes,
        minGap: minGap,
      );

  static List<Memory> _filterNearDuplicates(
    List<Memory> memories,
    Map<int, EmbeddingVector> fileIDToImageEmbedding, {
    int? minKeep,
    required bool isOfflineMode,
    double similarityThreshold = _clipSimilarImageThreshold,
  }) =>
      PhotoSelector.filterNearDuplicates(
        memories,
        fileIDToImageEmbedding,
        minKeep: minKeep,
        isOfflineMode: isOfflineMode,
        similarityThreshold: similarityThreshold,
      );

  static List<Memory> _filterByTimeSpacing(
    List<Memory> memories, {
    Duration minGap = _minimumMemoryTimeGap,
  }) =>
      PhotoSelector.filterByTimeSpacing(memories, minGap: minGap);

  static List<PeopleMemoryCandidate> _buildUnnamedClusterCandidates({
    required Map<String, int> clusterIdToFaceCount,
    required Map<String, Iterable<String>> clusterIdToFaceIDs,
    required Set<String> assignedClusterIDs,
    required Map<int, EnteFile> allFileIdsToFile,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Set<int>? meFileIDs,
    required bool isMeAssigned,
    required Map<int, int> seenTimes,
    required int nowInMicroseconds,
    required int windowEnd,
    required bool isOfflineMode,
    required PeopleSelectionBuilder selectionBuilder,
  }) {
    if (clusterIdToFaceCount.isEmpty || clusterIdToFaceIDs.isEmpty) {
      return <PeopleMemoryCandidate>[];
    }
    if (isMeAssigned && (meFileIDs == null || meFileIDs.isEmpty)) {
      return <PeopleMemoryCandidate>[];
    }
    final sortedUnassignedClusters = clusterIdToFaceCount.entries
        .where((entry) => !assignedClusterIDs.contains(entry.key))
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    // Wrap the selection builder to move the photo with the fewest faces to
    // the front, so the cover thumbnail clearly shows who the memory is about.
    Future<List<Memory>> coverOptimizedBuilder(List<Memory> memories) async {
      final selected = await selectionBuilder(memories);
      if (selected.length <= 1) return selected;
      int bestIdx = 0;
      int bestFaceCount = fileIdToFaces[_memoryFileIdFromMemory(
            selected[0],
            isOfflineMode: isOfflineMode,
          )]
              ?.length ??
          999;
      for (int i = 1; i < selected.length; i++) {
        final faceCount = fileIdToFaces[_memoryFileIdFromMemory(
              selected[i],
              isOfflineMode: isOfflineMode,
            )]
                ?.length ??
            999;
        if (faceCount < bestFaceCount) {
          bestFaceCount = faceCount;
          bestIdx = i;
        }
      }
      if (bestIdx == 0) return selected;
      return [
        selected[bestIdx],
        ...selected.sublist(0, bestIdx),
        ...selected.sublist(bestIdx + 1),
      ];
    }

    final unnamedCandidates = <PeopleMemoryCandidate>[];
    for (final entry in sortedUnassignedClusters) {
      if (unnamedCandidates.length >= _maximumUnnamedPeopleClusters) break;
      final clusterID = entry.key;
      final faceIDs = clusterIdToFaceIDs[clusterID];
      if (faceIDs == null || faceIDs.isEmpty) continue;

      final clusterFileIDs = <int>{};
      for (final faceID in faceIDs) {
        clusterFileIDs.add(getFileIdFromFaceId(faceID));
      }
      if (clusterFileIDs.isEmpty) continue;

      final nonGroupFiles = <EnteFile>[];
      final nonGroupCreationTimes = <int>[];
      int overlapWithMeInNonGroupFiles = 0;
      for (final fileID in clusterFileIDs) {
        final facesInPhoto = fileIdToFaces[fileID]?.length ?? 0;
        if (facesInPhoto == 0 ||
            facesInPhoto > _maximumUnnamedPeopleGroupSize) {
          continue;
        }
        final file = allFileIdsToFile[fileID];
        if (file == null || file.creationTime == null) continue;
        nonGroupFiles.add(file);
        nonGroupCreationTimes.add(file.creationTime!);
        if (isMeAssigned && meFileIDs!.contains(fileID)) {
          overlapWithMeInNonGroupFiles++;
        }
      }
      if (isMeAssigned &&
          overlapWithMeInNonGroupFiles < _minimumUnnamedPeopleWithMePhotos) {
        continue;
      }
      if (nonGroupFiles.length < _minimumUnnamedPeopleNonGroupPhotos) {
        continue;
      }
      final nonConsecutiveDays =
          _countNonConsecutiveDays(nonGroupCreationTimes);
      if (nonConsecutiveDays < _minimumUnnamedPeopleNonConsecutiveDays) {
        continue;
      }

      unnamedCandidates.add(
        PeopleMemoryCandidate(
          personID: "$_unnamedClusterPersonIDPrefix$clusterID",
          personName: null,
          type: PeopleMemoryType.spotlight,
          rawMemories: nonGroupFiles
              .map((file) => Memory.fromFile(file, seenTimes))
              .toList(growable: false),
          firstDateToShow: nowInMicroseconds,
          lastDateToShow: windowEnd,
          selectionBuilder: coverOptimizedBuilder,
          isUnnamedCluster: true,
        ),
      );
    }
    return unnamedCandidates;
  }

  static int _countNonConsecutiveDays(Iterable<int> creationTimes) {
    if (creationTimes.isEmpty) return 0;
    final uniqueDays = creationTimes
        .map((timestamp) => timestamp - (timestamp % microSecondsInDay))
        .toSet()
        .toList(growable: false)
      ..sort();
    if (uniqueDays.isEmpty) return 0;
    int count = 1;
    int previousDay = uniqueDays.first;
    for (final day in uniqueDays.skip(1)) {
      if (day - previousDay > microSecondsInDay) {
        count++;
      }
      previousDay = day;
    }
    return count;
  }

  static Map<String, int> _latestShownTimeByPersonID(
    Iterable<PeopleShownLog> shownPeople,
  ) {
    final latestShownTimeByPersonID = <String, int>{};
    for (final shownLog in shownPeople) {
      final oldValue = latestShownTimeByPersonID[shownLog.personID];
      if (oldValue == null || shownLog.lastTimeShown > oldValue) {
        latestShownTimeByPersonID[shownLog.personID] = shownLog.lastTimeShown;
      }
    }
    return latestShownTimeByPersonID;
  }

  static List<PeopleMemoryCandidate> _orderUnnamedCandidatesByRecencyAndRandom({
    required Iterable<PeopleMemoryCandidate> candidates,
    required Iterable<PeopleShownLog> shownPeople,
    required DateTime currentTime,
    required Duration shownPersonTimeout,
  }) {
    final remaining = candidates.toList(growable: true);
    if (remaining.length <= 1) return remaining;
    final random = Random();
    final latestShownTimeByPersonID = _latestShownTimeByPersonID(shownPeople);
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final unseenWeight = max(1, shownPersonTimeout.inDays * 2);
    final orderedCandidates = <PeopleMemoryCandidate>[];
    while (remaining.isNotEmpty) {
      final weights = <int>[];
      int totalWeight = 0;
      for (final candidate in remaining) {
        final latestShownTime = latestShownTimeByPersonID[candidate.personID];
        final weight = latestShownTime == null
            ? unseenWeight
            : max(
                1,
                (nowInMicroseconds - latestShownTime) ~/ microSecondsInDay,
              );
        weights.add(weight);
        totalWeight += weight;
      }
      var chosenWeight = random.nextInt(totalWeight);
      int chosenIndex = 0;
      for (; chosenIndex < weights.length; chosenIndex++) {
        chosenWeight -= weights[chosenIndex];
        if (chosenWeight < 0) break;
      }
      orderedCandidates.add(remaining.removeAt(chosenIndex));
    }
    return orderedCandidates;
  }

  static bool _wasPersonShownRecently({
    required String personID,
    required Iterable<PeopleShownLog> shownPeople,
    required DateTime currentTime,
    required Duration shownPersonTimeout,
  }) {
    for (final shownLog in shownPeople) {
      if (shownLog.personID != personID) continue;
      final shownDate =
          DateTime.fromMicrosecondsSinceEpoch(shownLog.lastTimeShown);
      if (currentTime.difference(shownDate) < shownPersonTimeout) {
        return true;
      }
    }
    return false;
  }

  Future<(Set<EnteFile>, Map<int, EnteFile>)> _getFilesAndMapForMemories({
    bool useGeneratedIds = false,
    bool requireLocalId = false,
    bool useLocalIntIds = false,
  }) async {
    final allFilesFromSearchService = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final archivedOrHiddenCollectionIDs =
        CollectionsService.instance.archivedOrHiddenCollectionIds();
    final excludedUploadFileIDs = <int>{};
    if (archivedOrHiddenCollectionIDs.isNotEmpty) {
      final filesInArchivedCollections =
          await FilesDB.instance.getAllFilesFromCollections(
        archivedOrHiddenCollectionIDs,
      );
      for (final archivedFile in filesInArchivedCollections) {
        final archivedUploadID = archivedFile.uploadedFileID;
        if (archivedUploadID != null && archivedUploadID != -1) {
          excludedUploadFileIDs.add(archivedUploadID);
        }
      }
    }
    final Set<EnteFile> candidateFiles = {};
    for (final file in allFilesFromSearchService) {
      final localId = file.localID;
      final hasLocalId = localId != null && localId.isNotEmpty;
      if (requireLocalId && !hasLocalId) {
        continue;
      }
      final hasId = useLocalIntIds
          ? hasLocalId
          : useGeneratedIds
              ? file.generatedID != null &&
                  (file.uploadedFileID != null || hasLocalId)
              : file.uploadedFileID != null;
      if (hasId && file.creationTime != null) {
        if (excludedUploadFileIDs.contains(file.uploadedFileID)) {
          continue;
        }
        if (file.magicMetadata.visibility == archiveVisibility ||
            file.magicMetadata.visibility == hiddenVisibility) {
          continue;
        }
        final collectionID = file.collectionID;
        if (collectionID != null &&
            archivedOrHiddenCollectionIDs.contains(collectionID)) {
          continue;
        }
        candidateFiles.add(file);
      }
    }
    final Map<String, int> localIdToIntId = useLocalIntIds
        ? await OfflineFilesDB.instance.ensureLocalIntIds(
            candidateFiles
                .map((file) => file.localID)
                .whereType<String>()
                .where((id) => id.isNotEmpty),
          )
        : <String, int>{};
    final Set<EnteFile> allFiles = {};
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in candidateFiles) {
      final localIntId = useLocalIntIds ? localIdToIntId[file.localID] : null;
      final mappedFile = localIntId != null
          ? file.copyWith(
              generatedID: localIntId,
            )
          : file;
      final key = useLocalIntIds
          ? localIntId
          : useGeneratedIds
              ? mappedFile.generatedID
              : mappedFile.uploadedFileID;
      if (key != null) {
        allFiles.add(mappedFile);
        allFileIdsToFile[key] = mappedFile;
      }
    }
    return (allFiles, allFileIdsToFile);
  }

  static Future<MemoriesResult> _allMemoriesCalculations(
    Map<String, dynamic> args,
  ) async {
    try {
      final TimeLogger t = TimeLogger(context: "_allMemoriesCalculations");
      final computationContext = MemoriesComputationContext.fromIsolateArgs(
        args,
      );
      final Set<EnteFile> allFiles = computationContext.allFiles;
      final Map<int, EnteFile> allFileIdsToFile =
          computationContext.allFileIdsToFile;
      final Set<int> collectionIDsToExclude =
          computationContext.collectionIDsToExclude;
      final bool isOfflineMode = computationContext.isOfflineMode;
      final DateTime now = computationContext.now;
      final MemoriesCache oldCache = computationContext.oldCache;
      final bool debugSurfaceAll = computationContext.debugSurfaceAll;
      final bool canUseUnnamedFallback =
          computationContext.canUseUnnamedFallback;
      final Map<int, int> seenTimes = computationContext.seenTimes;
      final List<PersonEntity> persons = computationContext.persons
          .where((person) => !person.data.hideFromMemories)
          .toList();
      final String? currentUserEmail = computationContext.currentUserEmail;
      final List<City> cities = computationContext.cities;
      final Map<int, List<FaceWithoutEmbedding>> fileIdToFaces =
          computationContext.fileIdToFaces;
      final Map<String, int> clusterIdToFaceCount =
          computationContext.clusterIdToFaceCount;
      final Map<String, Iterable<String>> clusterIdToFaceIDs =
          computationContext.clusterIdToFaceIDs;
      final Set<String> assignedClusterIDs =
          computationContext.assignedClusterIDs;
      final List<EmbeddingVector> allImageEmbeddings =
          computationContext.allImageEmbeddings;
      final Vector clipPositiveTextVector =
          computationContext.clipPositiveTextVector;
      final Map<PeopleActivity, Vector> clipPeopleActivityVectors =
          computationContext.clipPeopleActivityVectors;
      final Map<ClipMemoryType, Vector> clipMemoryTypeVectors =
          computationContext.clipMemoryTypeVectors;
      dev.log('All arguments (direct data) unwrapped $t');

      final Map<String, String> faceIDsToPersonID = {};
      for (final person in persons) {
        for (final cluster in person.data.assigned) {
          for (final faceID in cluster.faces) {
            faceIDsToPersonID[faceID] = person.remoteID;
          }
        }
      }
      final Map<int, EmbeddingVector> fileIDToImageEmbedding = {};
      for (final embedding in allImageEmbeddings) {
        fileIDToImageEmbedding[embedding.fileID] = embedding;
      }
      dev.log('arguments from indirect data calculated $t');
      dev.log('starting actual memory calculations ${DateTime.now()}');
      dev.log("All files length at start: ${allFiles.length} $t");
      final allFilesForRecentTimeMemories = Set<EnteFile>.from(allFiles);

      final List<SmartMemory> memories = [];

      // On this day memories
      final onThisDayMemories = await _getOnThisDayResults(
        allFiles,
        now,
        seenTimes: seenTimes,
        collectionIDsToExclude: collectionIDsToExclude,
      );
      _deductUsedMemories(allFiles, onThisDayMemories);
      memories.addAll(onThisDayMemories);
      dev.log("All files length after on this day: ${allFiles.length} $t");

      // People memories
      final peopleMemories = await _getPeopleResults(
        allFiles,
        allFileIdsToFile,
        now,
        oldCache.peopleShownLogs,
        surfaceAll: debugSurfaceAll,
        seenTimes: seenTimes,
        persons: persons,
        isOfflineMode: isOfflineMode,
        canUseUnnamedFallback: canUseUnnamedFallback,
        currentUserEmail: currentUserEmail,
        fileIdToFaces: fileIdToFaces,
        clusterIdToFaceCount: clusterIdToFaceCount,
        clusterIdToFaceIDs: clusterIdToFaceIDs,
        assignedClusterIDs: assignedClusterIDs,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
        clipPeopleActivityVectors: clipPeopleActivityVectors,
      );
      _deductUsedMemories(allFiles, peopleMemories);
      memories.addAll(peopleMemories);
      dev.log("All files length after people: ${allFiles.length} $t");

      // Trip memories
      final (tripMemories, bases) = await _getTripsResults(
        allFiles,
        allFileIdsToFile,
        now,
        oldCache.tripsShownLogs,
        surfaceAll: debugSurfaceAll,
        cachedTripMemories: oldCache.toShowMemories,
        isOfflineMode: isOfflineMode,
        seenTimes: seenTimes,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
        cities: cities,
      );
      _deductUsedMemories(allFiles, tripMemories);
      memories.addAll(tripMemories);
      dev.log("All files length after trips: ${allFiles.length} $t");

      // Clip memories
      final clipMemories = await _getClipResults(
        allFiles,
        now,
        oldCache.clipShownLogs,
        surfaceAll: debugSurfaceAll,
        isOfflineMode: isOfflineMode,
        seenTimes: seenTimes,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipMemoryTypeVectors: clipMemoryTypeVectors,
      );
      _deductUsedMemories(allFiles, clipMemories);
      memories.addAll(clipMemories);
      dev.log("All files length after clip memories: ${allFiles.length} $t");

      // Time memories
      final timeMemories = await _onThisDayOrWeekResults(
        allFiles,
        now,
        recentSourceFiles: allFilesForRecentTimeMemories,
        isOfflineMode: isOfflineMode,
        seenTimes: seenTimes,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
      );
      _deductUsedMemories(allFiles, timeMemories);
      memories.addAll(timeMemories);
      dev.log("All files length after time: ${allFiles.length} $t");

      // Filler memories
      final fillerMemories =
          await _getFillerResults(allFiles, now, seenTimes: seenTimes);
      _deductUsedMemories(allFiles, fillerMemories);
      memories.addAll(fillerMemories);
      dev.log("All files length after filler: ${allFiles.length} $t");
      dev.log('finished actual memory calculations ${DateTime.now()}');
      return MemoriesResult(memories, bases);
    } catch (e, s) {
      dev.log("Error in _allMemoriesCalculations \n Error:$e \n Stacktrace:$s");
      return MemoriesResult(<SmartMemory>[], <BaseLocation>[]);
    }
  }

  Future<List<SmartMemory>> calcSimpleMemories() async {
    final now = DateTime.now();
    final (allFiles, _) = await _getFilesAndMapForMemories(
      useLocalIntIds: isOfflineMode,
      requireLocalId: isOfflineMode,
    );
    final seenTimes = await _memoriesDB.getSeenTimes();
    final collectionIDsToExclude = await getCollectionIDsToExclude();
    final localIdToIntId = isOfflineMode
        ? await OfflineFilesDB.instance.ensureLocalIntIds(
            allFiles
                .map((file) => file.localID)
                .whereType<String>()
                .where((id) => id.isNotEmpty),
          )
        : <String, int>{};

    final List<SmartMemory> memories = [];

    // On this day memories
    final onThisDayMemories = await _getOnThisDayResults(
      allFiles,
      now,
      seenTimes: seenTimes,
      collectionIDsToExclude: collectionIDsToExclude,
      localIdToIntId: localIdToIntId,
    );
    if (onThisDayMemories.isNotEmpty &&
        onThisDayMemories.first.shouldShowNow()) {
      memories.add(onThisDayMemories.first);
      _deductUsedMemories(allFiles, [onThisDayMemories.first]);
    }

    // Filler memories
    final fillerMemories = await _getFillerResults(
      allFiles,
      now,
      seenTimes: seenTimes,
      localIdToIntId: localIdToIntId,
    );
    memories.addAll(fillerMemories);

    final local = await getLocale();
    final languageCode = local?.languageCode ?? "en";
    final s = await LanguageService.locals;

    _logger.info('get locale and S');
    for (final memory in memories) {
      memory.title = memory.createTitle(s, languageCode);
    }
    return memories;
  }

  static void _deductUsedMemories(
    Set<EnteFile> files,
    List<SmartMemory> memories,
  ) {
    final usedFiles = <EnteFile>{};
    for (final memory in memories) {
      usedFiles.addAll(memory.memories.map((m) => m.file));
    }
    files.removeAll(usedFiles);
  }

  static Future<List<PeopleMemory>> _getPeopleResults(
    Iterable<EnteFile> allFiles,
    Map<int, EnteFile> allFileIdsToFile,
    DateTime currentTime,
    List<PeopleShownLog> shownPeople, {
    bool surfaceAll = false,
    required Map<int, int> seenTimes,
    required List<PersonEntity> persons,
    required bool isOfflineMode,
    required bool canUseUnnamedFallback,
    String? currentUserEmail,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, int> clusterIdToFaceCount,
    required Map<String, Iterable<String>> clusterIdToFaceIDs,
    required Set<String> assignedClusterIDs,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required Map<PeopleActivity, Vector> clipPeopleActivityVectors,
  }) async {
    return PeopleMemoriesCalculator.compute(
      allFiles,
      allFileIdsToFile,
      currentTime,
      shownPeople,
      surfaceAll: surfaceAll,
      seenTimes: seenTimes,
      persons: persons,
      isOfflineMode: isOfflineMode,
      canUseUnnamedFallback: canUseUnnamedFallback,
      currentUserEmail: currentUserEmail,
      fileIdToFaces: fileIdToFaces,
      clusterIdToFaceCount: clusterIdToFaceCount,
      clusterIdToFaceIDs: clusterIdToFaceIDs,
      assignedClusterIDs: assignedClusterIDs,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipPositiveTextVector: clipPositiveTextVector,
      clipPeopleActivityVectors: clipPeopleActivityVectors,
    );
  }

  static Future<List<ClipMemory>> _getClipResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
    List<ClipShownLog> shownClip, {
    bool surfaceAll = false,
    required bool isOfflineMode,
    required Map<int, int> seenTimes,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Map<ClipMemoryType, Vector> clipMemoryTypeVectors,
  }) async {
    return ClipMemoriesCalculator.compute(
      allFiles,
      currentTime,
      shownClip,
      surfaceAll: surfaceAll,
      isOfflineMode: isOfflineMode,
      seenTimes: seenTimes,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipMemoryTypeVectors: clipMemoryTypeVectors,
    );
  }

  static Future<(List<TripMemory>, List<BaseLocation>)> _getTripsResults(
    Iterable<EnteFile> allFiles,
    Map<int, EnteFile> allFileIdsToFile,
    DateTime currentTime,
    List<TripsShownLog> shownTrips, {
    bool surfaceAll = false,
    required Iterable<ToShowMemory> cachedTripMemories,
    required bool isOfflineMode,
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required List<City> cities,
  }) async {
    return TripMemoriesCalculatorV2.compute(
      allFiles,
      allFileIdsToFile,
      currentTime,
      shownTrips,
      surfaceAll: surfaceAll,
      cachedTripMemories: cachedTripMemories,
      isOfflineMode: isOfflineMode,
      seenTimes: seenTimes,
      fileIdToFaces: fileIdToFaces,
      faceIDsToPersonID: faceIDsToPersonID,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipPositiveTextVector: clipPositiveTextVector,
      cities: cities,
    );
  }

  static Future<List<TimeMemory>> _onThisDayOrWeekResults(
    Set<EnteFile> allFiles,
    DateTime currentTime, {
    required Iterable<EnteFile> recentSourceFiles,
    required bool isOfflineMode,
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    return TimeMemoriesCalculator.computeTimeMemories(
      allFiles,
      currentTime,
      recentSourceFiles: recentSourceFiles,
      isOfflineMode: isOfflineMode,
      seenTimes: seenTimes,
      fileIdToFaces: fileIdToFaces,
      faceIDsToPersonID: faceIDsToPersonID,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipPositiveTextVector: clipPositiveTextVector,
    );
  }

  static Future<List<FillerMemory>> _getFillerResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime, {
    required Map<int, int> seenTimes,
    Map<String, int>? localIdToIntId,
  }) async {
    return TimeMemoriesCalculator.computeFillerMemories(
      allFiles,
      currentTime,
      seenTimes: seenTimes,
      localIdToIntId: localIdToIntId,
    );
  }

  Future<Set<int>> getCollectionIDsToExclude() async {
    if (isOfflineMode) {
      return <int>{};
    }
    final collections = CollectionsService.instance.getCollectionsForUI();

    // Names of collections to exclude
    const excludedNames = {
      'screenshot',
      'whatsapp',
      'telegram',
      'download',
      'facebook',
      'instagram',
      'messenger',
      'twitter',
      'reddit',
      'discord',
      'signal',
      'viber',
      'wechat',
      'line',
      'meme',
      'internet',
      'saved images',
      'document',
    };

    final excludedCollectionIDs = Set<int>.from(
      CollectionsService.instance.archivedOrHiddenCollectionIds(),
    );
    collectionLoop:
    for (final collection in collections) {
      final collectionName = collection.displayName.toLowerCase();
      for (final excludedName in excludedNames) {
        if (collectionName.contains(excludedName)) {
          excludedCollectionIDs.add(collection.id);
          continue collectionLoop;
        }
      }
    }

    return excludedCollectionIDs;
  }

  static Future<List<OnThisDayMemory>> _getOnThisDayResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime, {
    required Map<int, int> seenTimes,
    required Set<int> collectionIDsToExclude,
    Map<String, int>? localIdToIntId,
  }) async {
    return TimeMemoriesCalculator.computeOnThisDayMemories(
      allFiles,
      currentTime,
      seenTimes: seenTimes,
      collectionIDsToExclude: collectionIDsToExclude,
      localIdToIntId: localIdToIntId,
    );
  }

  static Future<String> getDateFormattedLocale({
    required int creationTime,
  }) async {
    final locale = await getLocale();

    return getDateFormatted(
      creationTime: creationTime,
      languageCode: locale!.languageCode,
    );
  }

  static String getDateFormatted({
    required int creationTime,
    BuildContext? context,
    String? languageCode,
  }) {
    return DateFormat.yMMMd(
      context != null
          ? Localizations.localeOf(context).languageCode
          : languageCode ?? "en",
    ).format(
      DateTime.fromMicrosecondsSinceEpoch(creationTime),
    );
  }

  static int? _seenTimeKeyForFile(
    EnteFile file,
    Map<String, int>? localIdToIntId,
  ) {
    if (localIdToIntId == null) return null;
    final localId = file.localID;
    if (localId == null || localId.isEmpty) return null;
    return localIdToIntId[localId];
  }

  static String? _tryFindLocationName(
    List<Memory> memories,
    List<City> cities, {
    bool base = false,
  }) {
    final files = Memory.filesFromMemories(memories);
    final results = getCityResults({
      "query": '',
      "cities": cities,
      "files": files,
    });
    final List<City> sortedByResultCount = results.keys.toList()
      ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
    if (sortedByResultCount.isEmpty) return null;
    final biggestPlace = sortedByResultCount.first;
    if (results[biggestPlace]!.length > files.length / 2) {
      return biggestPlace.city;
    }
    if (results.length > 2 &&
        results.keys.map((city) => city.country).toSet().length == 1 &&
        !base) {
      return biggestPlace.country;
    }
    return null;
  }

  static Future<List<Memory>> _bestSelectionPeople(
    List<Memory> memories, {
    int? prefferedSize,
    required bool isOfflineMode,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) =>
      PhotoSelector.bestSelectionPeople(
        memories,
        prefferedSize: prefferedSize,
        isOfflineMode: isOfflineMode,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
      );

  static Future<List<Memory>> _bestSelection(
    List<Memory> memories, {
    int? prefferedSize,
    SelectionDistribution? distributionOverride,
    required bool isOfflineMode,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) =>
      PhotoSelector.bestSelection(
        memories,
        prefferedSize: prefferedSize,
        distributionOverride: distributionOverride,
        isOfflineMode: isOfflineMode,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
      );
}
