import "dart:async";
import "dart:developer" as dev show log;
import "dart:math" show Random, max, min;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/memories_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/extensions/stop_watch.dart";
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
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/language_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/utils/text_embeddings_util.dart";

class MemoriesResult {
  final List<SmartMemory> memories;
  final List<BaseLocation> baseLocations;

  MemoriesResult(this.memories, this.baseLocations);

  get isEmpty => memories.isEmpty;
}

class SmartMemoriesService {
  final _logger = Logger("SmartMemoriesService");
  final _memoriesDB = MemoriesDB.instance;

  static const _clipSimilarImageThreshold = 0.75;
  static const _clipActivityQueryThreshold = 0.25;
  static const _clipMemoryTypeQueryThreshold = 0.25;

  static const yearsBefore = 30;

  static const minimumMemoryLength = 5;

  SmartMemoriesService();

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

      final (allFiles, allFileIdsToFile) = await _getFilesAndMapForMemories();
      _logger.info("All files length: ${allFiles.length} $t");

      final collectionIDsToExclude = await getCollectionIDsToExclude();
      _logger.info(
        'collectionIDsToExclude length: ${collectionIDsToExclude.length} $t',
      );

      final seenTimes = await _memoriesDB.getSeenTimes();
      _logger.info('seenTimes has ${seenTimes.length} entries $t');

      final persons = await PersonService.instance.getPersons();
      _logger.info('gotten all ${persons.length} persons $t');

      final currentUserEmail = Configuration.instance.getEmail();
      _logger.info('currentUserEmail: $currentUserEmail $t');

      final cities = await locationService.getCities();
      _logger.info('cities has ${cities.length} entries $t');

      final Map<int, List<FaceWithoutEmbedding>> fileIdToFaces =
          await MLDataDB.instance.getFileIDsToFacesWithoutEmbedding();
      _logger.info('fileIdToFaces has ${fileIdToFaces.length} entries $t');

      final allImageEmbeddings = await MLDataDB.instance.getAllClipVectors();
      _logger.info(
        'allImageEmbeddings has ${allImageEmbeddings.length} entries $t',
      );

      // Load pre-computed text embeddings from assets
      final textEmbeddings = await loadTextEmbeddingsFromAssets();
      if (textEmbeddings == null) {
        _logger.severe('Failed to load pre-computed text embeddings');
        throw Exception(
          'Failed to load pre-computed text embeddings',
        );
      }
      _logger.info('Using pre-computed text embeddings from assets');
      final clipPositiveTextVector = textEmbeddings.clipPositiveVector;
      final clipPeopleActivityVectors = textEmbeddings.peopleActivityVectors;
      final clipMemoryTypeVectors = textEmbeddings.clipMemoryTypeVectors;

      final local = await getLocale();
      final languageCode = local?.languageCode ?? "en";
      final s = await LanguageService.locals;

      _logger.info('get locale and S $t');

      _logger.info('all data fetched $t at ${DateTime.now()}, to computer');
      final memoriesResult = await Computer.shared().compute(
        _allMemoriesCalculations,
        param: <String, dynamic>{
          "allFiles": allFiles,
          "allFileIdsToFile": allFileIdsToFile,
          "collectionIDsToExclude": collectionIDsToExclude,
          "now": now,
          "oldCache": oldCache,
          "debugSurfaceAll": debugSurfaceAll,
          "seenTimes": seenTimes,
          "persons": persons,
          "currentUserEmail": currentUserEmail,
          "cities": cities,
          "fileIdToFaces": fileIdToFaces,
          "allImageEmbeddings": allImageEmbeddings,
          "clipPositiveTextVector": clipPositiveTextVector,
          "clipPeopleActivityVectors": clipPeopleActivityVectors,
          "clipMemoryTypeVectors": clipMemoryTypeVectors,
        },
      ) as MemoriesResult;
      _logger.info(
        '${memoriesResult.memories.length} memories computed in computer $t',
      );

      for (final memory in memoriesResult.memories) {
        memory.title = memory.createTitle(s, languageCode);
      }
      _logger.info('titles created for all memories $t');
      return memoriesResult;
    } catch (e, s) {
      _logger.severe("Error calculating smart memories", e, s);
      return MemoriesResult(<SmartMemory>[], <BaseLocation>[]);
    }
  }

  static List<EmbeddingVector> _getEmbeddingsForFileIDs(
    Map<int, EmbeddingVector> fileIDToImageEmbedding,
    Set<int> fileIDs,
  ) {
    final List<EmbeddingVector> embeddings = [];
    for (final fileID in fileIDs) {
      final embedding = fileIDToImageEmbedding[fileID];
      if (embedding != null) embeddings.add(embedding);
    }
    return embeddings;
  }

  Future<(Set<EnteFile>, Map<int, EnteFile>)>
      _getFilesAndMapForMemories() async {
    final allFilesFromSearchService = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final Set<EnteFile> allFiles = {};
    for (final file in allFilesFromSearchService) {
      if (file.uploadedFileID != null && file.creationTime != null) {
        allFiles.add(file);
      }
    }
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      allFileIdsToFile[file.uploadedFileID!] = file;
    }
    return (allFiles, allFileIdsToFile);
  }

  static Future<MemoriesResult> _allMemoriesCalculations(
    Map<String, dynamic> args,
  ) async {
    try {
      final TimeLogger t = TimeLogger(context: "_allMemoriesCalculations");
      // Arguments: direct data
      final Set<EnteFile> allFiles = args["allFiles"];
      final Map<int, EnteFile> allFileIdsToFile = args["allFileIdsToFile"];
      final Set<int> collectionIDsToExclude = args["collectionIDsToExclude"];
      final DateTime now = args["now"];
      final MemoriesCache oldCache = args["oldCache"];
      final bool debugSurfaceAll = args["debugSurfaceAll"] ?? false;
      final Map<int, int> seenTimes = args["seenTimes"];
      final List<PersonEntity> persons = args["persons"];
      final String? currentUserEmail = args["currentUserEmail"];
      final List<City> cities = args["cities"];
      final Map<int, List<FaceWithoutEmbedding>> fileIdToFaces =
          args["fileIdToFaces"];
      final List<EmbeddingVector> allImageEmbeddings =
          args["allImageEmbeddings"];
      final Vector clipPositiveTextVector = args["clipPositiveTextVector"];
      final Map<PeopleActivity, Vector> clipPeopleActivityVectors =
          args["clipPeopleActivityVectors"];
      final Map<ClipMemoryType, Vector> clipMemoryTypeVectors =
          args["clipMemoryTypeVectors"];
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
        currentUserEmail: currentUserEmail,
        fileIdToFaces: fileIdToFaces,
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
    final (allFiles, _) = await _getFilesAndMapForMemories();
    final seenTimes = await _memoriesDB.getSeenTimes();
    final collectionIDsToExclude = await getCollectionIDsToExclude();

    final List<SmartMemory> memories = [];

    // On this day memories
    final onThisDayMemories = await _getOnThisDayResults(
      allFiles,
      now,
      seenTimes: seenTimes,
      collectionIDsToExclude: collectionIDsToExclude,
    );
    if (onThisDayMemories.isNotEmpty &&
        onThisDayMemories.first.shouldShowNow()) {
      memories.add(onThisDayMemories.first);
      _deductUsedMemories(allFiles, [onThisDayMemories.first]);
    }

    // Filler memories
    final fillerMemories =
        await _getFillerResults(allFiles, now, seenTimes: seenTimes);
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
    String? currentUserEmail,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required Map<PeopleActivity, Vector> clipPeopleActivityVectors,
  }) async {
    final w = (kDebugMode ? EnteWatch('getPeopleResults') : null)?..start();
    final List<PeopleMemory> memoryResults = [];
    if (allFiles.isEmpty) return [];
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    w?.log('allFiles setup');

    // Get ordered (random) list of important people
    if (persons.isEmpty) return [];
    final personIdToPerson = <String, PersonEntity>{};
    final personIdToFaceIDs = <String, Set<String>>{};
    final personIdToFileIDs = <String, Set<int>>{};
    // final personIdToFaceIdToFace = <String, Map<String, Face>>{}; TODO: lau: try using relative face size as metric of importance
    for (final person in persons) {
      final personID = person.remoteID;
      personIdToPerson[personID] = person;
      personIdToFaceIDs[personID] = {};
      personIdToFileIDs[personID] = {};
      for (final cluster in person.data.assigned) {
        if (cluster.faces.isEmpty) continue;
        personIdToFaceIDs[personID]!.addAll(cluster.faces);
        personIdToFileIDs[personID]!
            .addAll(cluster.faces.map((faceID) => getFileIdFromFaceId(faceID)));
      }
    }
    final List<String> orderedImportantPersonsID = persons
        .where((person) => !person.data.isIgnored)
        .map((p) => p.remoteID)
        .toList();
    orderedImportantPersonsID.shuffle(Random());
    final amountOfPersons = orderedImportantPersonsID.length;
    w?.log('orderedImportantPersonsID setup');

    // Check if the user has assignmed "me"
    String? meID;
    for (final personEntity in persons) {
      if (personEntity.data.email == currentUserEmail) {
        meID = personEntity.remoteID;
        break;
      }
    }
    final bool isMeAssigned = meID != null;
    Set<int>? meFileIDs;
    if (isMeAssigned) meFileIDs = personIdToFileIDs[meID]!;

    // Loop through the people and find all memories
    final Map<String, Map<PeopleMemoryType, List<PeopleMemory>>>
        personToMemories = {};
    for (final personID in orderedImportantPersonsID) {
      final personFileIDs = personIdToFileIDs[personID]!;
      final personName = personIdToPerson[personID]!.data.name;
      w?.log('start with new person $personName');
      w?.log('personFilesToFaces setup');

      // Inside people loop, check for spotlight (Most likely every person will have a spotlight)
      final spotlightFiles = <EnteFile>[];
      for (final fileID in personFileIDs) {
        final int personsPresent = fileIdToFaces[fileID]?.length ?? 10;
        if (personsPresent > 1) continue;
        final file = allFileIdsToFile[fileID];
        if (file != null) {
          spotlightFiles.add(file);
        }
      }
      if (spotlightFiles.length > minimumMemoryLength) {
        final selectSpotlightMemories = await _bestSelectionPeople(
          spotlightFiles.map((f) => Memory.fromFile(f, seenTimes)).toList(),
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          clipPositiveTextVector: clipPositiveTextVector,
        );
        final spotlightMemory = PeopleMemory(
          selectSpotlightMemories,
          nowInMicroseconds,
          windowEnd,
          PeopleMemoryType.spotlight,
          personID,
          (isMeAssigned && meID == personID) ? null : personName,
        );
        personToMemories
            .putIfAbsent(personID, () => {})
            .putIfAbsent(PeopleMemoryType.spotlight, () => [spotlightMemory]);
      }
      w?.log('spotlight setup');

      // Inside people loop, check for youAndThem
      if (isMeAssigned && meID != personID) {
        final youAndThemFiles = <EnteFile>[];
        for (final fileID in personFileIDs) {
          final bool mePresent = meFileIDs!.contains(fileID);
          final personFaces = fileIdToFaces[fileID] ?? [];
          if (!mePresent || personFaces.length != 2) continue;
          final file = allFileIdsToFile[fileID];
          if (file != null) {
            youAndThemFiles.add(file);
          }
        }
        if (youAndThemFiles.length > minimumMemoryLength) {
          // final String title = "You and $personName";
          final selectYouAndThemMemories = await _bestSelectionPeople(
            youAndThemFiles.map((f) => Memory.fromFile(f, seenTimes)).toList(),
            fileIDToImageEmbedding: fileIDToImageEmbedding,
            clipPositiveTextVector: clipPositiveTextVector,
          );
          final youAndThemMemory = PeopleMemory(
            selectYouAndThemMemories,
            nowInMicroseconds,
            windowEnd,
            PeopleMemoryType.youAndThem,
            personID,
            personName,
          );
          personToMemories.putIfAbsent(personID, () => {}).putIfAbsent(
                PeopleMemoryType.youAndThem,
                () => [youAndThemMemory],
              );
        }
        w?.log('youAndThem setup');
      }

      // Inside people loop, check for doingSomethingTogether
      if (isMeAssigned && meID != personID) {
        final vectors = _getEmbeddingsForFileIDs(
          fileIDToImageEmbedding,
          personFileIDs,
        );
        w?.log('getting clip vectors for doingSomethingTogether');
        final activityFiles = <EnteFile>[];
        for (final activity in PeopleActivity.values) {
          activityFiles.clear();
          final Vector? activityVector = clipPeopleActivityVectors[activity];
          if (activityVector == null) {
            dev.log("No vector for activity $activity");
            continue;
          }
          final Map<int, double> similarities = {};
          for (final embedding in vectors) {
            similarities[embedding.fileID] =
                embedding.vector.dot(activityVector);
          }
          w?.log(
            'comparing embeddings for doingSomethingTogether and $activity',
          );
          for (final fileID in personFileIDs) {
            final similarity = similarities[fileID];
            if (similarity == null) continue;
            if (similarity > _clipActivityQueryThreshold) {
              final file = allFileIdsToFile[fileID];
              if (file != null) {
                activityFiles.add(file);
              }
            }
          }
          if (activityFiles.length > minimumMemoryLength) {
            final selectActivityMemories = await _bestSelectionPeople(
              activityFiles.map((f) => Memory.fromFile(f, seenTimes)).toList(),
              fileIDToImageEmbedding: fileIDToImageEmbedding,
              clipPositiveTextVector: clipPositiveTextVector,
            );
            final activityMemory = PeopleMemory(
              selectActivityMemories,
              nowInMicroseconds,
              windowEnd,
              PeopleMemoryType.doingSomethingTogether,
              personID,
              personName,
              activity: activity,
            );
            personToMemories
                .putIfAbsent(personID, () => {})
                .putIfAbsent(
                  PeopleMemoryType.doingSomethingTogether,
                  () => [],
                )
                .add(activityMemory);
          }
        }

        w?.log('doingSomethingTogether setup');
      }

      // Inside people loop, check for lastTimeYouSawThem
      final lastTimeYouSawThemFiles = <EnteFile>[];
      int lastCreationTime = 0;
      bool longAgo = true;
      for (final fileID in personFileIDs) {
        final file = allFileIdsToFile[fileID];
        if (file != null && file.creationTime != null) {
          final creationTime = file.creationTime!;
          final creationDateTime =
              DateTime.fromMicrosecondsSinceEpoch(creationTime);
          if (currentTime.difference(creationDateTime).inDays < 365) {
            longAgo = false;
            break;
          }
          if (creationTime > lastCreationTime - microSecondsInDay) {
            final lastDateTime =
                DateTime.fromMicrosecondsSinceEpoch(lastCreationTime);
            if (creationDateTime.difference(lastDateTime).inHours > 24) {
              lastTimeYouSawThemFiles.clear();
            }
            if (creationTime > lastCreationTime) {
              lastCreationTime = creationTime;
            }
            lastTimeYouSawThemFiles.add(file);
          }
        }
      }
      if (longAgo && lastTimeYouSawThemFiles.length >= 2 && meID != personID) {
        final lastTimeMemory = PeopleMemory(
          lastTimeYouSawThemFiles
              .map((f) => Memory.fromFile(f, seenTimes))
              .toList(),
          nowInMicroseconds,
          windowEnd,
          PeopleMemoryType.lastTimeYouSawThem,
          personID,
          personName,
          lastCreationTime: lastCreationTime,
        );
        personToMemories.putIfAbsent(personID, () => {}).putIfAbsent(
              PeopleMemoryType.lastTimeYouSawThem,
              () => [lastTimeMemory],
            );
      }
      w?.log('lastTimeYouSawThem setup');
    }

    // Surface everything just for debug checking
    if (surfaceAll) {
      for (final personID in personToMemories.keys) {
        final personMemories = personToMemories[personID]!;
        for (final memoryType in personMemories.keys) {
          memoryResults.addAll(personMemories[memoryType]!);
        }
      }
      return memoryResults;
    }

    // Loop through the people and check if we should surface anything based on relevancy (bday, last met)
    for (final personID in orderedImportantPersonsID) {
      final personMemories = personToMemories[personID];
      if (personMemories == null) continue;
      final person = personIdToPerson[personID]!;

      // Check if we should surface memory based on last met
      final lastMetMemory =
          personMemories[PeopleMemoryType.lastTimeYouSawThem]?.first;
      if (lastMetMemory != null) {
        final lastMetTime = DateTime.fromMicrosecondsSinceEpoch(
          lastMetMemory.lastCreationTime!,
        ).copyWith(year: currentTime.year);
        final daysSinceLastMet = lastMetTime.difference(currentTime).inDays;
        if (daysSinceLastMet < 7 && daysSinceLastMet >= 0) {
          memoryResults.add(lastMetMemory);
        }
      }

      // Check if we should surface memory based on birthday
      final birthdate = DateTime.tryParse(person.data.birthDate ?? "");
      if (birthdate != null) {
        final thisBirthday =
            DateTime(currentTime.year, birthdate.month, birthdate.day);
        final daysTillBirthday = thisBirthday.difference(currentTime).inDays;
        if (daysTillBirthday < 6 && daysTillBirthday >= 0) {
          final int newAge = currentTime.year - birthdate.year;
          final spotlightMem =
              personMemories[PeopleMemoryType.spotlight]?.first;
          if (spotlightMem != null && spotlightMem.personName != null) {
            final thisBirthday = birthdate.copyWith(year: currentTime.year);
            memoryResults.add(
              spotlightMem.copyWith(
                isBirthday: false,
                newAge: newAge,
                firstDateToShow: thisBirthday
                    .subtract(const Duration(days: 5))
                    .microsecondsSinceEpoch,
                lastDateToShow: thisBirthday.microsecondsSinceEpoch,
              ),
            );
            memoryResults.add(
              spotlightMem.copyWith(
                isBirthday: true,
                newAge: newAge,
                firstDateToShow: thisBirthday.microsecondsSinceEpoch,
                lastDateToShow:
                    thisBirthday.add(kDayItself).microsecondsSinceEpoch,
              ),
            );
          }
          final youAndThemMem =
              personMemories[PeopleMemoryType.youAndThem]?.first;
          if (youAndThemMem != null) {
            memoryResults.add(
              youAndThemMem.copyWith(
                isBirthday: false,
                newAge: newAge,
                firstDateToShow: thisBirthday
                    .subtract(const Duration(days: 5))
                    .microsecondsSinceEpoch,
                lastDateToShow: thisBirthday.microsecondsSinceEpoch,
              ),
            );
            memoryResults.add(
              youAndThemMem.copyWith(
                isBirthday: true,
                newAge: newAge,
                firstDateToShow: thisBirthday.microsecondsSinceEpoch,
                lastDateToShow:
                    thisBirthday.add(kDayItself).microsecondsSinceEpoch,
              ),
            );
          }
        }
      }
    }
    w?.log('relevancy setup');

    // Loop through the people (and memory types) and add based on rotation
    final shownPersonTimeout = Duration(
      days: min(
        kPersonShowTimeout.inDays,
        max(1, amountOfPersons) * kMemoriesUpdateFrequencyDays,
      ),
    );
    final shownPersonAndTypeTimeout =
        Duration(days: shownPersonTimeout.inDays * 2);
    peopleRotationLoop:
    for (final personID in orderedImportantPersonsID) {
      for (final memory in memoryResults) {
        if (memory.personID == personID) {
          continue peopleRotationLoop;
        }
      }
      for (final shownLog in shownPeople) {
        if (shownLog.personID != personID) continue;
        final shownDate =
            DateTime.fromMicrosecondsSinceEpoch(shownLog.lastTimeShown);
        final bool seenPersonRecently =
            currentTime.difference(shownDate) < shownPersonTimeout;
        if (seenPersonRecently) continue peopleRotationLoop;
      }
      if (personToMemories[personID] == null) continue peopleRotationLoop;
      int added = 0;
      final amountOfMemoryTypesForPerson = personToMemories[personID]!.length;
      final bool manyMemoryTypes = amountOfMemoryTypesForPerson > 2;
      potentialMemoryLoop:
      for (final memoriesForCategory in personToMemories[personID]!.values) {
        PeopleMemory potentialMemory = memoriesForCategory.first;
        if (memoriesForCategory.length > 1) {
          if (potentialMemory.peopleMemoryType !=
              PeopleMemoryType.doingSomethingTogether) {
            dev.log(
              'Something is going wrong, ${potentialMemory.peopleMemoryType} has multiple memories for same person',
            );
          } else {
            final randIdx = Random().nextInt(memoriesForCategory.length);
            potentialMemory = memoriesForCategory[randIdx];
          }
        }
        for (final shownLog in shownPeople) {
          if (shownLog.personID != personID) continue;
          if (shownLog.peopleMemoryType != potentialMemory.peopleMemoryType) {
            continue;
          }
          final shownTypeDate =
              DateTime.fromMicrosecondsSinceEpoch(shownLog.lastTimeShown);
          final bool seenPersonTypeRecently =
              currentTime.difference(shownTypeDate) < shownPersonAndTypeTimeout;
          if (manyMemoryTypes && seenPersonTypeRecently) {
            continue potentialMemoryLoop;
          }
        }
        memoryResults.add(potentialMemory);
        added++;
        if (added >= 2) break peopleRotationLoop;
      }
      if (added > 0) break peopleRotationLoop;
    }
    w?.log('rotation setup');

    return memoryResults;
  }

  static Future<List<ClipMemory>> _getClipResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
    List<ClipShownLog> shownClip, {
    bool surfaceAll = false,
    required Map<int, int> seenTimes,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Map<ClipMemoryType, Vector> clipMemoryTypeVectors,
  }) async {
    final w = (kDebugMode ? EnteWatch('getClipResults') : null)?..start();
    final List<ClipMemory> clipResults = [];
    if (allFiles.isEmpty) return [];
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final Map<ClipMemoryType, ClipMemory> clipTypeToMemory = {};
    w?.log('allFiles setup');

    // Loop through the clip types and find all memories
    final clipFiles = <EnteFile>[];
    for (final clipMemoryType in ClipMemoryType.values) {
      clipFiles.clear();
      final Vector? activityVector = clipMemoryTypeVectors[clipMemoryType];
      if (activityVector == null) {
        dev.log("No vector for clipMemoryType $clipMemoryType");
        continue;
      }
      final Map<int, double> similarities = {};
      for (final fileID in fileIDToImageEmbedding.keys) {
        similarities[fileID] =
            fileIDToImageEmbedding[fileID]!.vector.dot(activityVector);
      }
      w?.log(
        'comparing embeddings for clipMemoryType $clipMemoryType',
      );
      for (final file in allFiles) {
        final similarity = similarities[file.uploadedFileID!];
        if (similarity == null) continue;
        if (similarity > _clipMemoryTypeQueryThreshold) {
          clipFiles.add(file);
        }
      }
      if (clipFiles.length < 10) continue;
      // sort based on highest similarity first
      clipFiles.sort((a, b) {
        return similarities[b.uploadedFileID!]!
            .compareTo(similarities[a.uploadedFileID!]!);
      });
      clipTypeToMemory[clipMemoryType] = ClipMemory(
        clipFiles.take(10).map((f) => Memory.fromFile(f, seenTimes)).toList(),
        nowInMicroseconds,
        windowEnd,
        clipMemoryType,
      );
    }

    // Surface everything just for debug checking
    if (surfaceAll) {
      for (final clipMemoryType in ClipMemoryType.values) {
        final clipMemory = clipTypeToMemory[clipMemoryType];
        if (clipMemory != null) clipResults.add(clipMemory);
      }
      return clipResults;
    }

    // Loop through the clip types and add based on rotation
    clipMemoriesLoop:
    for (final clipMemoryType in [...ClipMemoryType.values]..shuffle()) {
      final clipMemory = clipTypeToMemory[clipMemoryType];
      if (clipMemory == null) continue;
      for (final shownLog in shownClip) {
        if (shownLog.clipMemoryType != clipMemoryType) continue;
        final shownDate =
            DateTime.fromMicrosecondsSinceEpoch(shownLog.lastTimeShown);
        final bool seenRecently =
            currentTime.difference(shownDate) < kClipShowTimeout;
        if (seenRecently) continue clipMemoriesLoop;
      }
      clipResults.add(clipMemory);
      break;
    }

    return clipResults;
  }

  static Future<(List<TripMemory>, List<BaseLocation>)> _getTripsResults(
    Iterable<EnteFile> allFiles,
    Map<int, EnteFile> allFileIdsToFile,
    DateTime currentTime,
    List<TripsShownLog> shownTrips, {
    bool surfaceAll = false,
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required List<City> cities,
  }) async {
    final List<TripMemory> memoryResults = [];
    if (allFiles.isEmpty) return (<TripMemory>[], <BaseLocation>[]);
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));

    const tripRadius = 100.0;
    const overlapRadius = 10.0;

    final List<(List<EnteFile>, Location)> smallRadiusClusters = [];
    final List<(List<EnteFile>, Location)> wideRadiusClusters = [];
    // Go through all files and cluster (incremental clustering)
    for (EnteFile file in allFiles) {
      if (!file.hasLocation) continue;
      // Small radius clustering for base locations
      bool addedToExistingSmallCluster = false;
      for (final cluster in smallRadiusClusters) {
        final clusterLocation = cluster.$2;
        if (isFileInsideLocationTag(
          clusterLocation,
          file.location!,
          baseRadius,
        )) {
          cluster.$1.add(file);
          addedToExistingSmallCluster = true;
          break;
        }
      }
      if (!addedToExistingSmallCluster) {
        smallRadiusClusters.add(([file], file.location!));
      }
      // Wide radius clustering for trip locations
      bool addedToExistingWideCluster = false;
      for (final cluster in wideRadiusClusters) {
        final clusterLocation = cluster.$2;
        if (isFileInsideLocationTag(
          clusterLocation,
          file.location!,
          tripRadius,
        )) {
          cluster.$1.add(file);
          addedToExistingWideCluster = true;
          break;
        }
      }
      if (!addedToExistingWideCluster) {
        wideRadiusClusters.add(([file], file.location!));
      }
    }

    // Identify base locations
    final List<BaseLocation> baseLocations = [];
    for (final cluster in smallRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      // Check that the photos are distributed over a longer time range (3+ months)
      final creationTimes = <int>[];
      final Set<int> uniqueDays = {};
      for (final file in files) {
        creationTimes.add(file.creationTime!);
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final dayStamp =
            DateTime(date.year, date.month, date.day).microsecondsSinceEpoch;
        uniqueDays.add(dayStamp);
      }
      creationTimes.sort();
      if (creationTimes.length < 10) continue;
      final firstCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.first,
      );
      final lastCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.last,
      );
      final daysRange = lastCreationTime.difference(firstCreationTime).inDays;
      if (daysRange < 90) {
        continue;
      }
      // Check for a minimum average number of days photos are clicked in range
      if (uniqueDays.length < daysRange * 0.1) continue;
      // Check that there isn't a huge time gap somewhere in the range
      final int gapThreshold = (daysRange * 0.6).round() * microSecondsInDay;
      int maxGap = 0;
      for (int i = 1; i < creationTimes.length; i++) {
        final gap = creationTimes[i] - creationTimes[i - 1];
        if (gap > maxGap) maxGap = gap;
      }
      if (maxGap > gapThreshold) continue;
      // Check if it's a current or old base location
      final bool isCurrent = lastCreationTime.isAfter(
        DateTime.now().subtract(
          const Duration(days: 90),
        ),
      );
      baseLocations.add(
        BaseLocation(
          files.map((file) => file.uploadedFileID!).toList(),
          location,
          isCurrent,
        ),
      );
    }

    // Identify trip locations
    final List<TripMemory> tripLocations = [];
    clusteredLocations:
    for (final cluster in wideRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      // Check that it's at least 10km away from any base or tag location
      for (final baseLocation in baseLocations) {
        if (isFileInsideLocationTag(
          baseLocation.location,
          location,
          overlapRadius,
        )) {
          continue clusteredLocations;
        }
      }

      // Check that the photos are distributed over a short time range (2-30 days) or multiple short time ranges only
      files.sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
      // Find distinct time blocks (potential trips)
      List<EnteFile> currentBlockFiles = [files.first];
      int blockStart = files.first.creationTime!;
      int lastTime = files.first.creationTime!;
      DateTime lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);

      for (int i = 1; i < files.length; i++) {
        final currentFile = files[i];
        final currentTime = currentFile.creationTime!;
        final gap = DateTime.fromMicrosecondsSinceEpoch(currentTime)
            .difference(lastDateTime)
            .inDays;

        // If gap is too large, end current block and check if it's a valid trip
        if (gap > 15) {
          // 10 days gap to separate trips. If gap is small, it's likely not a trip
          if (gap < 90) continue clusteredLocations;

          final blockDuration = lastDateTime
              .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
              .inDays;

          // Check if current block is a valid trip (2-30 days)
          if (blockDuration >= 2 && blockDuration <= 30) {
            tripLocations.add(
              TripMemory(
                Memory.fromFiles(
                  currentBlockFiles,
                  seenTimes,
                ),
                0,
                0,
                location,
                firstCreationTime: blockStart,
                lastCreationTime: lastTime,
              ),
            );
          }

          // Start new block
          currentBlockFiles = [];
          blockStart = currentTime;
        }

        currentBlockFiles.add(currentFile);
        lastTime = currentTime;
        lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);
      }
      // Check final block
      final lastBlockDuration = lastDateTime
          .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
          .inDays;
      if (lastBlockDuration >= 2 && lastBlockDuration <= 30) {
        tripLocations.add(
          TripMemory(
            Memory.fromFiles(currentBlockFiles, seenTimes),
            0,
            0,
            location,
            firstCreationTime: blockStart,
            lastCreationTime: lastTime,
          ),
        );
      }
    }

    // Check if any trip locations should be merged
    final List<TripMemory> mergedTrips = [];
    for (final trip in tripLocations) {
      final tripFirstTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.firstCreationTime!,
      );
      final tripLastTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.lastCreationTime!,
      );
      bool merged = false;
      for (int idx = 0; idx < mergedTrips.length; idx++) {
        final otherTrip = mergedTrips[idx];
        final otherTripFirstTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.firstCreationTime!);
        final otherTripLastTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.lastCreationTime!);
        if (tripFirstTime
                .isBefore(otherTripLastTime.add(const Duration(days: 3))) &&
            tripLastTime.isAfter(
              otherTripFirstTime.subtract(const Duration(days: 3)),
            )) {
          mergedTrips[idx] = TripMemory(
            otherTrip.memories + trip.memories,
            0,
            0,
            otherTrip.location,
            firstCreationTime:
                min(otherTrip.firstCreationTime!, trip.firstCreationTime!),
            lastCreationTime:
                max(otherTrip.lastCreationTime!, trip.lastCreationTime!),
          );
          dev.log('Merged two trip locations');
          merged = true;
          break;
        }
      }
      if (merged) continue;
      mergedTrips.add(
        TripMemory(
          trip.memories,
          0,
          0,
          trip.location,
          firstCreationTime: trip.firstCreationTime,
          lastCreationTime: trip.lastCreationTime,
        ),
      );
    }

    // Remove too small and too recent trips
    final List<TripMemory> validTrips = [];
    for (final trip in mergedTrips) {
      if (trip.memories.length >= 20 &&
          trip.averageCreationTime() < cutOffTime.microsecondsSinceEpoch) {
        validTrips.add(trip);
      }
    }

    // For now for testing let's just surface all base locations
    // For now surface these on the location section TODO: lau: remove internal flag title
    if (surfaceAll) {
      for (final baseLocation in baseLocations) {
        String name =
            "Base (${baseLocation.isCurrentBase ? 'current' : 'old'})";
        final files = baseLocation.fileIDs
            .map((fileID) => allFileIdsToFile[fileID]!)
            .toList();
        final String? locationName = _tryFindLocationName(
          Memory.fromFiles(files, seenTimes),
          cities,
          base: true,
        );
        if (locationName != null) {
          name =
              "$locationName (Base, ${baseLocation.isCurrentBase ? 'current' : 'old'})";
        }
        memoryResults.add(
          TripMemory(
            Memory.fromFiles(files, seenTimes),
            nowInMicroseconds,
            windowEnd,
            baseLocation.location,
            locationName: name,
          ),
        );
      }
      for (final trip in validTrips) {
        final year = DateTime.fromMicrosecondsSinceEpoch(
          trip.averageCreationTime(),
        ).year;
        final String? locationName =
            _tryFindLocationName(trip.memories, cities);
        final photoSelection = await _bestSelection(
          trip.memories,
          fileIdToFaces: fileIdToFaces,
          faceIDsToPersonID: faceIDsToPersonID,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          clipPositiveTextVector: clipPositiveTextVector,
        );
        memoryResults.add(
          trip.copyWith(
            memories: photoSelection,
            tripYear: year,
            locationName: locationName,
            firstDateToShow: nowInMicroseconds,
            lastDateToShow: windowEnd,
          ),
        );
      }
      return (memoryResults, baseLocations);
    }

    // For now we surface the two most recent trips of current month, and if none, the earliest upcoming redundant trip
    // Group the trips per month and then year
    final Map<int, Map<int, List<TripMemory>>> tripsByMonthYear = {};
    for (final trip in validTrips) {
      final tripDate =
          DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime());
      tripsByMonthYear
          .putIfAbsent(tripDate.month, () => {})
          .putIfAbsent(tripDate.year, () => [])
          .add(trip);
    }

    // Flatten trips for the current month and annotate with their average date.
    final List<TripMemory> currentMonthTrips = [];
    if (tripsByMonthYear.containsKey(currentMonth)) {
      for (final trips in tripsByMonthYear[currentMonth]!.values) {
        for (final trip in trips) {
          currentMonthTrips.add(trip);
        }
      }
    }

    // If there are past trips this month, show the one or two most recent ones.
    if (currentMonthTrips.isNotEmpty) {
      currentMonthTrips.sort(
        (a, b) => b.averageCreationTime().compareTo(a.averageCreationTime()),
      );
      final tripsToShow = currentMonthTrips.take(2);
      for (final trip in tripsToShow) {
        final year =
            DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime())
                .year;
        final String? locationName =
            _tryFindLocationName(trip.memories, cities);
        final photoSelection = await _bestSelection(
          trip.memories,
          fileIdToFaces: fileIdToFaces,
          faceIDsToPersonID: faceIDsToPersonID,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          clipPositiveTextVector: clipPositiveTextVector,
        );
        final firstCreationDate = DateTime.fromMicrosecondsSinceEpoch(
          trip.firstCreationTime!,
        );
        final firstDateToShow = DateTime(
          currentTime.year,
          firstCreationDate.month,
          firstCreationDate.day,
        ).subtract(kMemoriesMargin).microsecondsSinceEpoch;
        final lastCreationDate = DateTime.fromMicrosecondsSinceEpoch(
          trip.lastCreationTime!,
        );
        final lastDateToShow = DateTime(
          currentTime.year,
          lastCreationDate.month,
          lastCreationDate.day,
        ).add(kMemoriesMargin).microsecondsSinceEpoch;
        memoryResults.add(
          trip.copyWith(
            memories: photoSelection,
            tripYear: year,
            locationName: locationName,
            firstDateToShow: firstDateToShow,
            lastDateToShow: lastDateToShow,
          ),
        );
      }
    }
    // Otherwise, if no trips happened in the current month,
    // look for the earliest upcoming trip in another month that has 3+ trips.
    else {
      final sortedUpcomingMonths =
          List<int>.generate(6, (i) => ((currentMonth + i) % 12) + 1);
      checkUpcomingMonths:
      for (final month in sortedUpcomingMonths) {
        if (tripsByMonthYear.containsKey(month)) {
          final List<TripMemory> thatMonthTrips = [];
          for (final trips in tripsByMonthYear[month]!.values) {
            thatMonthTrips.addAll(trips);
          }
          if (thatMonthTrips.length >= 3) {
            // take and use the third earliest trip
            thatMonthTrips.sort(
              (a, b) =>
                  a.averageCreationTime().compareTo(b.averageCreationTime()),
            );
            checkPotentialTrips:
            for (final trip in thatMonthTrips.sublist(2)) {
              for (final shownTrip in shownTrips) {
                final distance =
                    calculateDistance(trip.location, shownTrip.location);
                final shownTripDate = DateTime.fromMicrosecondsSinceEpoch(
                  shownTrip.lastTimeShown,
                );
                final shownRecently =
                    currentTime.difference(shownTripDate) < kTripShowTimeout;
                if (distance < overlapRadius && shownRecently) {
                  continue checkPotentialTrips;
                }
              }
              final year = DateTime.fromMicrosecondsSinceEpoch(
                trip.averageCreationTime(),
              ).year;
              final String? locationName =
                  _tryFindLocationName(trip.memories, cities);
              final photoSelection = await _bestSelection(
                trip.memories,
                fileIdToFaces: fileIdToFaces,
                faceIDsToPersonID: faceIDsToPersonID,
                fileIDToImageEmbedding: fileIDToImageEmbedding,
                clipPositiveTextVector: clipPositiveTextVector,
              );
              memoryResults.add(
                trip.copyWith(
                  memories: photoSelection,
                  tripYear: year,
                  locationName: locationName,
                  firstDateToShow: nowInMicroseconds,
                  lastDateToShow: windowEnd,
                ),
              );
              break checkUpcomingMonths;
            }
          }
        }
      }
    }
    return (memoryResults, baseLocations);
  }

  static Future<List<TimeMemory>> _onThisDayOrWeekResults(
    Set<EnteFile> allFiles,
    DateTime currentTime, {
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    final List<TimeMemory> memoryResult = [];
    if (allFiles.isEmpty) return [];

    final currentDayMonth = currentTime.month * 100 + currentTime.day;
    final currentWeek = _getWeekNumber(currentTime);
    final currentMonth = currentTime.month;
    final currentYear = currentTime.year;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));
    final averageDailyPhotos = allFiles.length / 365;
    final significantDayThreshold = averageDailyPhotos * 0.25;
    final significantWeekThreshold = averageDailyPhotos * 0.40;

    // Group files by day-month and year
    final dayMonthYearGroups = <int, Map<int, List<Memory>>>{};

    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final dayMonth = creationTime.month * 100 + creationTime.day;
      final year = creationTime.year;

      dayMonthYearGroups
          .putIfAbsent(dayMonth, () => {})
          .putIfAbsent(year, () => [])
          .add(Memory.fromFile(file, seenTimes));
    }

    // Process each nearby day-month to find significant days
    for (final dayMonth in dayMonthYearGroups.keys) {
      final dayDiff = dayMonth - currentDayMonth;
      if (dayDiff < 0 || dayDiff > kMemoriesUpdateFrequency.inDays) continue;
      // TODO: lau: this doesn't cover month changes properly

      final yearGroups = dayMonthYearGroups[dayMonth]!;
      final significantDays = yearGroups.entries
          .where((e) => e.value.length > significantDayThreshold)
          .map((e) => e.key)
          .toList();

      if (significantDays.length >= 3) {
        // Combine all years for this day-month
        final date =
            DateTime(currentTime.year, dayMonth ~/ 100, dayMonth % 100);
        final allPhotos = yearGroups.values.expand((x) => x).toList();
        final photoSelection = await _bestSelection(
          allPhotos,
          fileIdToFaces: fileIdToFaces,
          faceIDsToPersonID: faceIDsToPersonID,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          clipPositiveTextVector: clipPositiveTextVector,
        );

        memoryResult.add(
          TimeMemory(
            photoSelection,
            day: date,
            date.subtract(kMemoriesMargin).microsecondsSinceEpoch,
            date.add(kDayItself).microsecondsSinceEpoch,
          ),
        );
      } else {
        // Individual entries for significant years
        for (final year in significantDays) {
          final date = DateTime(year, dayMonth ~/ 100, dayMonth % 100);
          final showDate =
              DateTime(currentYear, dayMonth ~/ 100, dayMonth % 100);
          final files = yearGroups[year]!;
          final photoSelection = await _bestSelection(
            files,
            fileIdToFaces: fileIdToFaces,
            faceIDsToPersonID: faceIDsToPersonID,
            fileIDToImageEmbedding: fileIDToImageEmbedding,
            clipPositiveTextVector: clipPositiveTextVector,
          );
          memoryResult.add(
            TimeMemory(
              photoSelection,
              day: date,
              yearsAgo: currentTime.year - date.year,
              showDate.subtract(kMemoriesMargin).microsecondsSinceEpoch,
              showDate.add(kDayItself).microsecondsSinceEpoch,
            ),
          );
        }
      }
    }

    // process to find significant weeks (only if there are no significant days)
    if (memoryResult.isEmpty) {
      // Group files by week and year
      final currentWeekYearGroups = <int, List<Memory>>{};
      for (final file in allFiles) {
        if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

        final creationTime =
            DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final week = _getWeekNumber(creationTime);
        if (week != currentWeek) continue;
        final year = creationTime.year;

        currentWeekYearGroups
            .putIfAbsent(year, () => [])
            .add(Memory.fromFile(file, seenTimes));
      }

      // Process the week and see if it's significant
      if (currentWeekYearGroups.isNotEmpty) {
        final significantWeeks = currentWeekYearGroups.entries
            .where((e) => e.value.length > significantWeekThreshold)
            .map((e) => e.key)
            .toList();
        if (significantWeeks.length >= 3) {
          // Combine all years for this week
          final allPhotos =
              currentWeekYearGroups.values.expand((x) => x).toList();
          final photoSelection = await _bestSelection(
            allPhotos,
            fileIdToFaces: fileIdToFaces,
            faceIDsToPersonID: faceIDsToPersonID,
            fileIDToImageEmbedding: fileIDToImageEmbedding,
            clipPositiveTextVector: clipPositiveTextVector,
          );
          // const name = "This week through the years";
          memoryResult.add(
            TimeMemory(
              photoSelection,
              currentTime.subtract(kMemoriesMargin).microsecondsSinceEpoch,
              currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch,
            ),
          );
        } else {
          // Individual entries for significant years
          for (final year in significantWeeks) {
            final date = DateTime(year, 1, 1).add(
              Duration(days: (currentWeek - 1) * 7),
            );
            final files = currentWeekYearGroups[year]!;
            final photoSelection = await _bestSelection(
              files,
              fileIdToFaces: fileIdToFaces,
              faceIDsToPersonID: faceIDsToPersonID,
              fileIDToImageEmbedding: fileIDToImageEmbedding,
              clipPositiveTextVector: clipPositiveTextVector,
            );
            memoryResult.add(
              TimeMemory(
                photoSelection,
                yearsAgo: currentTime.year - date.year,
                currentTime.subtract(kMemoriesMargin).microsecondsSinceEpoch,
                currentTime
                    .add(kMemoriesUpdateFrequency)
                    .microsecondsSinceEpoch,
              ),
            );
          }
        }
      }
    }

    // process to find months memories
    const monthSelectionSize = 20;

    // Group files by month and year
    final currentMonthYearGroups = <int, List<Memory>>{};
    _deductUsedMemories(allFiles, memoryResult);
    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final month = creationTime.month;
      if (month != currentMonth) continue;
      final year = creationTime.year;

      currentMonthYearGroups
          .putIfAbsent(year, () => [])
          .add(Memory.fromFile(file, seenTimes));
    }

    // Add the largest two months plus the month through the years
    final sortedYearsForCurrentMonth = currentMonthYearGroups.keys.toList()
      ..sort(
        (a, b) => currentMonthYearGroups[b]!.length.compareTo(
              currentMonthYearGroups[a]!.length,
            ),
      );
    for (int i = 0; i < 2; i++) {
      if (sortedYearsForCurrentMonth.isEmpty) break;
      final year = sortedYearsForCurrentMonth.removeAt(0);
      final monthYearFiles = currentMonthYearGroups[year]!;
      final photoSelection = await _bestSelection(
        monthYearFiles,
        prefferedSize: monthSelectionSize,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
      );
      final daysLeftInMonth =
          DateTime(currentYear, currentMonth + 1, 0).day - currentTime.day + 1;
      memoryResult.add(
        TimeMemory(
          photoSelection,
          month: DateTime(year, currentMonth),
          yearsAgo: currentTime.year - year,
          currentTime.microsecondsSinceEpoch,
          currentTime
              .add(Duration(days: daysLeftInMonth))
              .microsecondsSinceEpoch,
        ),
      );
    }
    // Show the month through the remaining years
    if (sortedYearsForCurrentMonth.length <= 3) return memoryResult;
    final allPhotos = sortedYearsForCurrentMonth
        .expand((year) => currentMonthYearGroups[year]!)
        .toList();
    final photoSelection = await _bestSelection(
      allPhotos,
      prefferedSize: monthSelectionSize,
      fileIdToFaces: fileIdToFaces,
      faceIDsToPersonID: faceIDsToPersonID,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipPositiveTextVector: clipPositiveTextVector,
    );
    final daysLeftInMonth =
        DateTime(currentYear, currentMonth + 1, 0).day - currentTime.day + 1;
    memoryResult.add(
      TimeMemory(
        photoSelection,
        month: DateTime(currentYear, currentMonth),
        currentTime.microsecondsSinceEpoch,
        currentTime.add(Duration(days: daysLeftInMonth)).microsecondsSinceEpoch,
      ),
    );

    return memoryResult;
  }

  static Future<List<FillerMemory>> _getFillerResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime, {
    required Map<int, int> seenTimes,
  }) async {
    final List<FillerMemory> memoryResults = [];
    if (allFiles.isEmpty) return [];
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final currentYear = currentTime.year;
    final cutOffTime = currentTime
        .subtract(const Duration(days: 364) - kMemoriesUpdateFrequency);
    final timeTillYearEnd = DateTime(currentYear + 1).difference(currentTime);
    final bool almostYearEnd = timeTillYearEnd < kMemoriesUpdateFrequency;

    final Map<int, List<Memory>> yearsAgoToMemories = {};
    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) {
        continue;
      }
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final fileTimeInYear = fileDate.copyWith(year: currentYear);
      final diff = fileTimeInYear.difference(currentTime);
      if (!diff.isNegative && diff < kMemoriesUpdateFrequency) {
        final yearsAgo = currentYear - fileDate.year;
        yearsAgoToMemories
            .putIfAbsent(yearsAgo, () => [])
            .add(Memory.fromFile(file, seenTimes));
      } else if (almostYearEnd) {
        final altDiff = fileDate.copyWith(year: currentYear + 1).difference(
              currentTime,
            );
        if (!altDiff.isNegative && altDiff < kMemoriesUpdateFrequency) {
          final yearsAgo = currentYear - fileDate.year + 1;
          yearsAgoToMemories
              .putIfAbsent(yearsAgo, () => [])
              .add(Memory.fromFile(file, seenTimes));
        }
      }
    }
    for (var yearAgo = 1; yearAgo <= yearsBefore; yearAgo++) {
      final memories = yearsAgoToMemories[yearAgo];
      if (memories == null) continue;
      memories.sort(
        (a, b) => a.file.creationTime!.compareTo(b.file.creationTime!),
      );
      final fillerMemory = FillerMemory(
        memories,
        yearAgo,
        nowInMicroseconds,
        windowEnd,
      );
      memoryResults.add(fillerMemory);
    }
    return memoryResults;
  }

  Future<Set<int>> getCollectionIDsToExclude() async {
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

    final excludedCollectionIDs = <int>{};
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
  }) async {
    final List<OnThisDayMemory> memoryResults = [];
    if (allFiles.isEmpty) return [];

    final daysToCompute = kMemoriesUpdateFrequency.inDays;
    final currentYear = currentTime.year;
    final currentMonth = currentTime.month;
    final currentDay = currentTime.day;
    final startPoint = DateTime(currentYear, currentMonth, currentDay);
    final cutOffTime = startPoint
        .subtract(const Duration(days: 363) - kMemoriesUpdateFrequency);
    final diffThreshold = Duration(days: daysToCompute);

    final Map<int, List<Memory>> daysToMemories = {};
    final Map<int, List<int>> daysToYears = {};

    final timeTillYearEnd = DateTime(currentYear + 1).difference(startPoint);
    final bool almostYearEnd = timeTillYearEnd < diffThreshold;

    // Find all the relevant memories
    for (final file in allFiles) {
      if (collectionIDsToExclude.contains(file.collectionID)) continue;
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) {
        continue;
      }
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final fileTimeInYear = fileDate.copyWith(year: currentYear);
      final diff = fileTimeInYear.difference(startPoint);
      if (!diff.isNegative && diff < diffThreshold) {
        daysToMemories
            .putIfAbsent(diff.inDays, () => [])
            .add(Memory.fromFile(file, seenTimes));
        daysToYears.putIfAbsent(diff.inDays, () => []).add(fileDate.year);
      } else if (almostYearEnd) {
        final altDiff = fileDate.copyWith(year: currentYear + 1).difference(
              currentTime,
            );
        if (!altDiff.isNegative && altDiff < diffThreshold) {
          daysToMemories
              .putIfAbsent(altDiff.inDays, () => [])
              .add(Memory.fromFile(file, seenTimes));
          daysToYears.putIfAbsent(altDiff.inDays, () => []).add(fileDate.year);
        }
      }
    }

    // Per day, filter the memories to find the best ones
    for (var day = 0; day < daysToCompute; day++) {
      final memories = daysToMemories[day];
      if (memories == null) continue;
      if (memories.length < 5) continue;
      final years = daysToYears[day]!;
      if (years.toSet().length < 2) continue;

      final filteredMemories = <Memory>[];
      if (memories.length > 20) {
        // Group memories by year
        final Map<int, List<Memory>> memoriesByYear = {};
        for (final memory in memories) {
          final creationTime =
              DateTime.fromMicrosecondsSinceEpoch(memory.file.creationTime!);
          final year = creationTime.year;
          memoriesByYear.putIfAbsent(year, () => []).add(memory);
        }
        for (final year in memoriesByYear.keys) {
          memoriesByYear[year]!.shuffle(Random());
        }

        // Get all years, randonly select 20 years if there are more than 20
        List<int> years = memoriesByYear.keys.toList()..sort();
        if (years.length > 20) {
          years.shuffle(Random());
          years = years.take(20).toList()..sort();
        }

        // First round to take one memory from each year
        for (final year in years) {
          if (filteredMemories.length >= 20) break;
          final yearMemories = memoriesByYear[year]!;
          if (yearMemories.isNotEmpty) {
            filteredMemories.add(yearMemories.removeAt(0));
          }
        }

        // Second round to fill up to 20 memories
        while (filteredMemories.length < 20) {
          bool addedAny = false;
          for (final year in years) {
            if (filteredMemories.length >= 20) break;
            final yearMemories = memoriesByYear[year]!;
            if (yearMemories.isNotEmpty) {
              filteredMemories.add(yearMemories.removeAt(0));
              addedAny = true;
            }
          }
          if (!addedAny) break;
        }
      } else {
        filteredMemories.addAll(memories);
      }

      filteredMemories.sort(
        (a, b) => a.file.creationTime!.compareTo(b.file.creationTime!),
      );
      final onThisDayMemory = OnThisDayMemory(
        filteredMemories,
        startPoint.add(Duration(days: day)).microsecondsSinceEpoch,
        startPoint.add(Duration(days: day + 1)).microsecondsSinceEpoch,
      );
      memoryResults.add(onThisDayMemory);
    }
    return memoryResults;
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

  /// TODO: lau: replace this by just taking next 7 days
  static int _getWeekNumber(DateTime date) {
    // Get day of year (1-366)
    final int dayOfYear = int.parse(DateFormat('D').format(date));
    // Integer division by 7 and add 1 to start from week 1
    return ((dayOfYear - 1) ~/ 7) + 1;
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

  /// Creates a curated selection of memories for the People memories.
  /// The selection is based on the following things:
  /// - Distribution of photos over time
  /// - Nostalgia score of photos
  /// - Distribution of photos over locations
  static Future<List<Memory>> _bestSelectionPeople(
    List<Memory> memories, {
    int? prefferedSize,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    try {
      final w = (kDebugMode ? EnteWatch('getPeopleResults') : null)?..start();
      final fileCount = memories.length;
      final int targetSize = prefferedSize ?? 10;
      if (fileCount <= targetSize) return memories;

      // Sort by time
      final sortedTimeMemories = <Memory>[];
      for (final memory in memories) {
        if (memory.file.creationTime != null) {
          sortedTimeMemories.add(memory);
        }
      }
      sortedTimeMemories.sort(
        (a, b) => a.file.creationTime!.compareTo(b.file.creationTime!),
      );
      if (sortedTimeMemories.length < targetSize) return sortedTimeMemories;

      // Divide into 10 time buckets distributing all memories as evenly as possible.
      final int total = sortedTimeMemories.length;
      final int numBuckets = targetSize;
      final int quotient = total ~/ numBuckets;
      final int remainder = total % numBuckets;
      final List<List<Memory>> timeBuckets = [];
      int offset = 0;
      for (int i = 0; i < numBuckets; i++) {
        final int bucketSize = quotient + (i < remainder ? 1 : 0);
        timeBuckets
            .add(sortedTimeMemories.sublist(offset, offset + bucketSize));
        offset += bucketSize;
      }

      final finalSelection = <Memory>[];
      for (final bucket in timeBuckets) {
        // Get X% most nostalgic photos
        final bucketFileIDs =
            bucket.map((memory) => memory.file.uploadedFileID!).toSet().toSet();
        final bucketVectors = _getEmbeddingsForFileIDs(
          fileIDToImageEmbedding,
          bucketFileIDs,
        );
        final bool littleEmbeddings =
            bucketVectors.length < bucket.length * 0.5;
        final Map<int, double> nostalgiaScores = {};
        for (final embedding in bucketVectors) {
          nostalgiaScores[embedding.fileID] =
              embedding.vector.dot(clipPositiveTextVector);
        }
        final sortedNostalgia = bucket
          ..sort(
            (a, b) => (nostalgiaScores[b.file.uploadedFileID!] ?? 0.0)
                .compareTo((nostalgiaScores[a.file.uploadedFileID!] ?? 0.0)),
          );
        late List<Memory> mostNostalgic;
        if (littleEmbeddings) {
          mostNostalgic = sortedNostalgia;
        } else {
          mostNostalgic = sortedNostalgia
              .take((max(bucket.length * 0.3, 1)).toInt())
              .toList();
        }

        if (mostNostalgic.isEmpty) {
          dev.log('No nostalgic photos in bucket');
        }

        // If no selection yet, take the most nostalgic photo
        if (finalSelection.isEmpty) {
          finalSelection.add(mostNostalgic.first);
          continue;
        }

        // From nostalgic selection, take the photo furthest away from all currently selected ones
        double globalMaxMinDistance = 0;
        int farthestDistanceIdx = 0;
        for (var i = 0; i < mostNostalgic.length; i++) {
          final mem = mostNostalgic[i];
          double minDistance = double.infinity;
          for (final selected in finalSelection) {
            if (selected.file.location == null || mem.file.location == null) {
              continue;
            }
            final distance =
                calculateDistance(mem.file.location!, selected.file.location!);
            if (distance < minDistance) {
              minDistance = distance;
            }
          }
          if (minDistance > globalMaxMinDistance) {
            globalMaxMinDistance = minDistance;
            farthestDistanceIdx = i;
          }
        }
        finalSelection.add(mostNostalgic[farthestDistanceIdx]);
      }

      finalSelection
          .sort((a, b) => b.file.creationTime!.compareTo(a.file.creationTime!));

      dev.log(
        'People memories selection done, returning ${finalSelection.length} memories',
      );
      w?.log('People memories selection done');
      return finalSelection;
    } catch (e, s) {
      dev.log('Error in _bestSelectionPeople $e \n $s');
      return [];
    }
  }

  /// Returns the best selection of files from the given list, for time and trip memories.
  /// Makes sure that the selection is not more than [prefferedSize] or 10 files,
  /// and that each year of the original list is represented.
  static Future<List<Memory>> _bestSelection(
    List<Memory> memories, {
    int? prefferedSize,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    final fileCount = memories.length;
    int targetSize = prefferedSize ?? 10;
    if (fileCount <= targetSize) return memories;
    final fileIDs = memories.map((e) => e.file.uploadedFileID!).toSet();

    final allYears = memories.map((e) {
      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(e.file.creationTime!);
      return creationTime.year;
    }).toSet();

    // Get clip scores for each file
    final vectors = _getEmbeddingsForFileIDs(
      fileIDToImageEmbedding,
      fileIDs,
    );
    final Map<int, double> fileToScore = {};
    for (final embedding in vectors) {
      fileToScore[embedding.fileID] =
          embedding.vector.dot(clipPositiveTextVector);
    }

    // Get face scores for each file
    final fileToFaceCount = <int, int>{};
    for (final mem in memories) {
      final fileID = mem.file.uploadedFileID!;
      fileToFaceCount[fileID] = 0;
      final faces = fileIdToFaces[fileID];
      if (faces == null || faces.isEmpty) {
        continue;
      }
      for (final face in faces) {
        if (faceIDsToPersonID.containsKey(face.faceID)) {
          fileToFaceCount[fileID] = fileToFaceCount[fileID]! + 10;
        } else {
          fileToFaceCount[fileID] = fileToFaceCount[fileID]! + 1;
        }
      }
    }

    final filteredMemories = <Memory>[];
    if (allYears.length <= 1) {
      // TODO: lau: eventually this sorting might have to be replaced with some scoring system
      // sort first on clip embeddings score (descending)
      memories.sort(
        (a, b) => (fileToScore[b.file.uploadedFileID!] ?? 0.0)
            .compareTo((fileToScore[a.file.uploadedFileID!] ?? 0.0)),
      );
      // then sort on faces (descending), heavily prioritizing named faces
      memories.sort(
        (a, b) => fileToFaceCount[b.file.uploadedFileID!]!
            .compareTo(fileToFaceCount[a.file.uploadedFileID!]!),
      );

      // then filter out similar images as much as possible
      filteredMemories.add(memories.first);
      int skipped = 0;
      filesLoop:
      for (final mem in memories.sublist(1)) {
        if (filteredMemories.length >= targetSize) break;
        final clip = fileIDToImageEmbedding[mem.file.uploadedFileID!];
        if (clip != null && (fileCount - skipped) > targetSize) {
          for (final filteredMem in filteredMemories) {
            final fClip =
                fileIDToImageEmbedding[filteredMem.file.uploadedFileID!];
            if (fClip == null) continue;
            final similarity = clip.vector.dot(fClip.vector);
            if (similarity > _clipSimilarImageThreshold) {
              skipped++;
              continue filesLoop;
            }
          }
        }
        filteredMemories.add(mem);
      }
    } else {
      // Multiple years, each represented and roughly equally distributed
      if (prefferedSize == null && (allYears.length * 2) > 10) {
        targetSize = allYears.length * 3;
        if (fileCount < targetSize) return memories;
      }

      // Group files by year and sort each year's list by CLIP then face count
      final yearToFiles = <int, List<Memory>>{};
      for (final mem in memories) {
        final creationTime =
            DateTime.fromMicrosecondsSinceEpoch(mem.file.creationTime!);
        final year = creationTime.year;
        yearToFiles.putIfAbsent(year, () => []).add(mem);
      }

      for (final year in yearToFiles.keys) {
        final yearFiles = yearToFiles[year]!;
        // sort first on clip embeddings score (descending)
        yearFiles.sort(
          (a, b) => (fileToScore[b.file.uploadedFileID!] ?? 0.0)
              .compareTo((fileToScore[a.file.uploadedFileID!] ?? 0.0)),
        );
        // then sort on faces (descending), heavily prioritizing named faces
        yearFiles.sort(
          (a, b) => fileToFaceCount[b.file.uploadedFileID!]!
              .compareTo(fileToFaceCount[a.file.uploadedFileID!]!),
        );
      }

      // Then join the years together one by one and filter similar images
      final years = yearToFiles.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Recent years first
      int round = 0;
      int skipped = 0;
      whileLoop:
      while (filteredMemories.length + skipped < fileCount) {
        yearLoop:
        for (final year in years) {
          final yearFiles = yearToFiles[year]!;
          if (yearFiles.isEmpty) continue;
          final newMem = yearFiles.removeAt(0);
          if (round != 0 && (fileCount - skipped) > targetSize) {
            // check for filtering
            final clip = fileIDToImageEmbedding[newMem.file.uploadedFileID!];
            if (clip != null) {
              for (final filteredMem in filteredMemories) {
                final fClip =
                    fileIDToImageEmbedding[filteredMem.file.uploadedFileID!];
                if (fClip == null) continue;
                final similarity = clip.vector.dot(fClip.vector);
                if (similarity > _clipSimilarImageThreshold) {
                  skipped++;
                  continue yearLoop;
                }
              }
            }
          }
          filteredMemories.add(newMem);
          if (filteredMemories.length >= targetSize ||
              filteredMemories.length + skipped >= fileCount) {
            break whileLoop;
          }
        }
        round++;
        // Extra safety to prevent infinite loops
        if (round > fileCount) break;
      }
    }

    // Order the final selection chronologically
    filteredMemories
        .sort((a, b) => a.file.creationTime!.compareTo(b.file.creationTime!));
    return filteredMemories;
  }
}
