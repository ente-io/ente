import "dart:async";
import "dart:math" show min, max;

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
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/memories/filler_memory.dart";
import "package:photos/models/memories/memories_cache.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/people_memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/models/memories/time_memory.dart";
import "package:photos/models/memories/trip_memory.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_computer.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/search_service.dart";

class MemoriesResult {
  final List<SmartMemory> memories;
  final List<BaseLocation> baseLocations;

  MemoriesResult(this.memories, this.baseLocations);
}

class SmartMemoriesService {
  final _logger = Logger("SmartMemoriesService");
  final _memoriesDB = MemoriesDB.instance;

  bool _isInit = false;

  Locale? _locale;
  late Map<int, int> _seenTimes;

  Vector? _clipPositiveTextVector;
  static const String clipPositiveQuery =
      'Photo of a precious and nostalgic memory radiating warmth, vibrant energy, or quiet beauty — alive with color, light, or emotion';

  final Map<PeopleActivity, Vector> _clipPeopleActivityVectors = {};

  static const _clipSimilarImageThreshold = 0.75;
  static const _clipActivityQueryThreshold = 0.25;

  static const yearsBefore = 30;

  SmartMemoriesService();

  Future<void> init() async {
    if (_isInit) return;
    _locale = await getLocale();

    _clipPositiveTextVector ??= Vector.fromList(
      await MLComputer.instance.runClipText(clipPositiveQuery),
    );
    for (final peopleActivity in PeopleActivity.values) {
      _clipPeopleActivityVectors[peopleActivity] = Vector.fromList(
        await MLComputer.instance.runClipText(activityQuery(peopleActivity)),
      );
    }
    _isInit = true;
    _logger.info("Smart memories service initialized");
  }

  // One general method to get all memories, which calls on internal methods for each separate memory type
  Future<MemoriesResult> calcMemories(
    DateTime now,
    MemoriesCache oldCache, {
    bool debugSurfaceAll = false,
  }) async {
    try {
      final TimeLogger t = TimeLogger(context: "calcMemories");
      _logger.finest('calcMemories called with time: $now $t');
      await init();
      final List<SmartMemory> memories = [];
      final allFiles = Set<EnteFile>.from(
        await SearchService.instance.getAllFilesForSearch(),
      );
      _seenTimes = await _memoriesDB.getSeenTimes();
      _logger.finest("All files length: ${allFiles.length} $t");

      final peopleMemories = await _getPeopleResults(
        allFiles,
        now,
        oldCache.peopleShownLogs,
        surfaceAll: debugSurfaceAll,
      );
      _deductUsedMemories(allFiles, peopleMemories);
      memories.addAll(peopleMemories);
      _logger.finest("All files length after people: ${allFiles.length} $t");

      // Trip memories
      final (tripMemories, bases) = await _getTripsResults(
        allFiles,
        now,
        oldCache.tripsShownLogs,
        surfaceAll: debugSurfaceAll,
      );
      _deductUsedMemories(allFiles, tripMemories);
      memories.addAll(tripMemories);
      _logger.finest("All files length after trips: ${allFiles.length} $t");

      // Time memories
      final timeMemories = await _onThisDayOrWeekResults(allFiles, now);
      _deductUsedMemories(allFiles, timeMemories);
      memories.addAll(timeMemories);
      _logger.finest("All files length after time: ${allFiles.length} $t");

      // Filler memories
      final fillerMemories = await _getFillerResults(allFiles, now);
      _deductUsedMemories(allFiles, fillerMemories);
      memories.addAll(fillerMemories);
      _logger.finest("All files length after filler: ${allFiles.length} $t");
      return MemoriesResult(memories, bases);
    } catch (e, s) {
      _logger.severe("Error calculating smart memories", e, s);
      return MemoriesResult(<SmartMemory>[], <BaseLocation>[]);
    }
  }

  void _deductUsedMemories(
    Set<EnteFile> files,
    List<SmartMemory> memories,
  ) {
    final usedFiles = <EnteFile>{};
    for (final memory in memories) {
      usedFiles.addAll(memory.memories.map((m) => m.file));
    }
    files.removeAll(usedFiles);
  }

  Future<List<PeopleMemory>> _getPeopleResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
    List<PeopleShownLog> shownPeople, {
    bool surfaceAll = false,
  }) async {
    final w = (kDebugMode ? EnteWatch('getPeopleResults') : null)?..start();
    final List<PeopleMemory> memoryResults = [];
    if (allFiles.isEmpty) return [];
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      if (file.uploadedFileID != null) {
        allFileIdsToFile[file.uploadedFileID!] = file;
      }
    }
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    w?.log('allFiles setup');

    // Get ordered list of important people (all named, from most to least files)
    final persons = await PersonService.instance.getPersons();
    if (persons.length < 5) return []; // Stop if not enough named persons
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
    final List<String> orderedImportantPersonsID =
        persons.map((p) => p.remoteID).toList();
    orderedImportantPersonsID.sort((a, b) {
      final aFaces = personIdToFaceIDs[a]!.length;
      final bFaces = personIdToFaceIDs[b]!.length;
      return bFaces.compareTo(aFaces);
    });
    w?.log('orderedImportantPersonsID setup');

    // Check if the user has assignmed "me"
    String? meID;
    final currentUserEmail = Configuration.instance.getEmail();
    for (final personEntity in persons) {
      if (personEntity.data.email == currentUserEmail) {
        meID = personEntity.remoteID;
        break;
      }
    }
    w?.log('meID setup part 1');
    final bool isMeAssigned = meID != null;
    Map<int, List<Face>>? meFilesToFaces;
    if (isMeAssigned) {
      final meFileIDs = personIdToFileIDs[meID]!;
      meFilesToFaces = await MLDataDB.instance.getFacesForFileIDs(
        meFileIDs,
      );
    }
    w?.log('meID setup part 2');

    // Loop through the people and find all memories
    final Map<String, Map<PeopleMemoryType, PeopleMemory>> personToMemories =
        {};
    for (final personID in orderedImportantPersonsID) {
      final personFileIDs = personIdToFileIDs[personID]!;
      final personName = personIdToPerson[personID]!.data.name;
      w?.log('start with new person $personName');
      final Map<int, List<Face>> personFilesToFaces =
          await MLDataDB.instance.getFacesForFileIDs(
        personFileIDs,
      );
      w?.log('personFilesToFaces setup');
      // Inside people loop, check for spotlight (Most likely every person will have a spotlight)
      final spotlightFiles = <EnteFile>[];
      for (final fileID in personFileIDs) {
        final int personsPresent = personFilesToFaces[fileID]?.length ?? 10;
        if (personsPresent > 1) continue;
        final file = allFileIdsToFile[fileID];
        if (file != null) {
          spotlightFiles.add(file);
        }
      }
      if (spotlightFiles.length > 5) {
        String title = "Spotlight on $personName";
        if (isMeAssigned && meID == personID) {
          title = "Spotlight on yourself";
        }
        final selectSpotlightMemories = await _bestSelectionPeople(
          spotlightFiles.map((f) => Memory.fromFile(f, _seenTimes)).toList(),
        );
        final spotlightMemory = PeopleMemory(
          selectSpotlightMemories,
          title,
          nowInMicroseconds,
          windowEnd,
          PeopleMemoryType.spotlight,
          personID,
        );
        personToMemories
            .putIfAbsent(personID, () => {})
            .putIfAbsent(PeopleMemoryType.spotlight, () => spotlightMemory);
      }
      w?.log('spotlight setup');

      // Inside people loop, check for youAndThem
      if (isMeAssigned && meID != personID) {
        final youAndThemFiles = <EnteFile>[];
        for (final fileID in personFileIDs) {
          final meFaces = meFilesToFaces![fileID];
          final personFaces = personFilesToFaces[fileID] ?? [];
          if (meFaces == null || personFaces.length != 2) continue;
          final file = allFileIdsToFile[fileID];
          if (file != null) {
            youAndThemFiles.add(file);
          }
        }
        if (youAndThemFiles.length > 5) {
          final String title = "You and $personName";
          final selectYouAndThemMemories = await _bestSelectionPeople(
            youAndThemFiles.map((f) => Memory.fromFile(f, _seenTimes)).toList(),
          );
          final youAndThemMemory = PeopleMemory(
            selectYouAndThemMemories,
            title,
            nowInMicroseconds,
            windowEnd,
            PeopleMemoryType.youAndThem,
            personID,
          );
          personToMemories
              .putIfAbsent(personID, () => {})
              .putIfAbsent(PeopleMemoryType.youAndThem, () => youAndThemMemory);
        }
        w?.log('youAndThem setup');
      }

      // Inside people loop, check for doingSomethingTogether
      if (isMeAssigned && meID != personID) {
        final vectors = await SemanticSearchService.instance
            .getClipVectorsForFileIDs(personFileIDs);
        w?.log('getting clip vectors for doingSomethingTogether');
        final activityFiles = <EnteFile>[];
        PeopleActivity lastActivity = PeopleActivity.values.first;
        activityLoop:
        for (final activity in PeopleActivity.values) {
          activityFiles.clear();
          lastActivity = activity;
          final Vector? activityVector = _clipPeopleActivityVectors[activity];
          if (activityVector == null) {
            _logger.severe("No vector for activity $activity");
            continue activityLoop;
          }
          final similarities = await MLComputer.instance
              .compareEmbeddings(vectors, activityVector);
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
          if (activityFiles.length > 5) break activityLoop;
        }
        if (activityFiles.length > 5) {
          final String title = activityTitle(lastActivity, personName);
          final selectActivityMemories = await _bestSelectionPeople(
            activityFiles.map((f) => Memory.fromFile(f, _seenTimes)).toList(),
          );
          final activityMemory = PeopleMemory(
            selectActivityMemories,
            title,
            nowInMicroseconds,
            windowEnd,
            PeopleMemoryType.doingSomethingTogether,
            personID,
          );
          personToMemories.putIfAbsent(personID, () => {}).putIfAbsent(
                PeopleMemoryType.doingSomethingTogether,
                () => activityMemory,
              );
        }
        w?.log('doingSomethingTogether setup');
      }

      // Inside people loop, check for lastTimeYouSawThem
      final lastTimeYouSawThemFiles = <EnteFile>[];
      int lastCreationTime = 0;
      bool longAgo = true;
      fileLoop:
      for (final fileID in personFileIDs) {
        final file = allFileIdsToFile[fileID];
        if (file != null && file.creationTime != null) {
          final creationTime = file.creationTime!;
          final creationDateTime =
              DateTime.fromMicrosecondsSinceEpoch(creationTime);
          if (currentTime.difference(creationDateTime).inDays < 365) {
            longAgo = false;
            break fileLoop;
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
        final String title = "Last time with $personName";
        final lastTimeMemory = PeopleMemory(
          lastTimeYouSawThemFiles
              .map((f) => Memory.fromFile(f, _seenTimes))
              .toList(),
          title,
          nowInMicroseconds,
          windowEnd,
          PeopleMemoryType.lastTimeYouSawThem,
          personID,
          lastCreationTime: lastCreationTime,
        );
        personToMemories.putIfAbsent(personID, () => {}).putIfAbsent(
              PeopleMemoryType.lastTimeYouSawThem,
              () => lastTimeMemory,
            );
      }
      w?.log('lastTimeYouSawThem setup');
    }

    // Surface everything just for debug checking
    if (surfaceAll) {
      for (final personID in personToMemories.keys) {
        final personMemories = personToMemories[personID]!;
        for (final memoryType in personMemories.keys) {
          memoryResults.add(personMemories[memoryType]!);
        }
      }
      return memoryResults;
    }

    // Loop through the people and check if we should surface anything based on relevancy (bday, last met)
    personRelevancyLoop:
    for (final personID in orderedImportantPersonsID) {
      final personMemories = personToMemories[personID];
      if (personID == meID || personMemories == null) continue;
      final person = personIdToPerson[personID]!;
      // Check if we should surface memory based on birthday
      final birthdate = DateTime.tryParse(person.data.birthDate ?? "");
      if (birthdate != null) {
        final thisBirthday =
            DateTime(currentTime.year, birthdate.month, birthdate.day);
        final daysTillBirthday = thisBirthday.difference(currentTime).inDays;
        if (daysTillBirthday < 7 && daysTillBirthday >= 0) {
          final personName = person.data.name;
          final int newAge = currentTime.year - birthdate.year;
          final spotlightMem = personMemories[PeopleMemoryType.spotlight];
          if (spotlightMem != null) {
            final String firstTitle = "$personName turning $newAge!";
            final String secondTitle = "$personName is $newAge!";
            final thisBirthday = birthdate.copyWith(year: currentTime.year);
            memoryResults.add(
              spotlightMem.copyWith(
                title: firstTitle,
                firstDateToShow: thisBirthday
                    .subtract(const Duration(days: 6))
                    .microsecondsSinceEpoch,
                lastDateToShow: thisBirthday.microsecondsSinceEpoch,
              ),
            );
            memoryResults.add(
              spotlightMem.copyWith(
                title: secondTitle,
                firstDateToShow: thisBirthday.microsecondsSinceEpoch,
                lastDateToShow:
                    thisBirthday.add(kDayItself).microsecondsSinceEpoch,
              ),
            );
          }
          final youAndThemMem = personMemories[PeopleMemoryType.youAndThem];
          if (youAndThemMem != null) {
            memoryResults.add(
              youAndThemMem.copyWith(
                firstDateToShow: thisBirthday
                    .subtract(const Duration(days: 6))
                    .microsecondsSinceEpoch,
                lastDateToShow:
                    thisBirthday.add(kDayItself).microsecondsSinceEpoch,
              ),
            );
          }
          continue personRelevancyLoop;
        }
      }

      // Check if we should surface memory based on last met
      final lastMetMemory = personMemories[PeopleMemoryType.lastTimeYouSawThem];
      if (lastMetMemory != null) {
        final lastMetTime = DateTime.fromMicrosecondsSinceEpoch(
          lastMetMemory.lastCreationTime!,
        ).copyWith(year: currentTime.year);
        final daysSinceLastMet = lastMetTime.difference(currentTime).inDays;
        if (daysSinceLastMet < 7 && daysSinceLastMet >= 0) {
          memoryResults.add(lastMetMemory);
        }
      }
    }
    w?.log('relevancy setup');

    // Loop through the people (and memory types) and add based on rotation
    if (memoryResults.length >= 3) return memoryResults;
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
            currentTime.difference(shownDate) < kPersonShowTimeout;
        if (seenPersonRecently) continue peopleRotationLoop;
      }
      if (personToMemories[personID] == null) continue peopleRotationLoop;
      int added = 0;
      potentialMemoryLoop:
      for (final potentialMemory in personToMemories[personID]!.values) {
        for (final shownLog in shownPeople) {
          if (shownLog.personID != personID) continue;
          if (shownLog.peopleMemoryType != potentialMemory.peopleMemoryType) {
            continue;
          }
          final shownTypeDate =
              DateTime.fromMicrosecondsSinceEpoch(shownLog.lastTimeShown);
          final bool seenPersonTypeRecently =
              currentTime.difference(shownTypeDate) < kPersonAndTypeShowTimeout;
          if (seenPersonTypeRecently) continue potentialMemoryLoop;
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

  Future<(List<TripMemory>, List<BaseLocation>)> _getTripsResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
    List<TripsShownLog> shownTrips, {
    bool surfaceAll = false,
  }) async {
    final List<TripMemory> memoryResults = [];
    final Iterable<LocalEntity<LocationTag>> locationTagEntities =
        (await locationService.getLocationTags());
    if (allFiles.isEmpty) return (<TripMemory>[], <BaseLocation>[]);
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));

    const tripRadius = 100.0;
    const overlapRadius = 10.0;

    final Map<LocalEntity<LocationTag>, List<EnteFile>> tagToItemsMap = {};
    for (int i = 0; i < locationTagEntities.length; i++) {
      tagToItemsMap[locationTagEntities.elementAt(i)] = [];
    }
    final List<(List<EnteFile>, Location)> smallRadiusClusters = [];
    final List<(List<EnteFile>, Location)> wideRadiusClusters = [];
    // Go through all files and cluster the ones not inside any location tag
    allFilesLoop:
    for (EnteFile file in allFiles) {
      if (!file.hasLocation ||
          file.uploadedFileID == null ||
          !file.isOwner ||
          file.creationTime == null) {
        continue allFilesLoop;
      }
      // Check if the file is inside any location tag
      bool hasLocationTag = false;
      for (LocalEntity<LocationTag> tag in tagToItemsMap.keys) {
        if (isFileInsideLocationTag(
          tag.item.centerPoint,
          file.location!,
          tag.item.radius,
        )) {
          hasLocationTag = true;
          tagToItemsMap[tag]!.add(file);
        }
      }
      // Cluster the files not inside any location tag (incremental clustering)
      if (hasLocationTag) continue allFilesLoop;
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
      baseLocations.add(BaseLocation(files, location, isCurrent));
    }

    // Identify trip locations
    final List<TripMemory> tripLocations = [];
    clusteredLocations:
    for (final cluster in wideRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      // Check that it's at least 10km away from any base or tag location
      bool tooClose = false;
      for (final baseLocation in baseLocations) {
        if (isFileInsideLocationTag(
          baseLocation.location,
          location,
          overlapRadius,
        )) {
          tooClose = true;
          break;
        }
      }
      for (final tag in tagToItemsMap.keys) {
        if (isFileInsideLocationTag(
          tag.item.centerPoint,
          location,
          overlapRadius,
        )) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue clusteredLocations;

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
                  _seenTimes,
                ),
                'Trip1',
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
            Memory.fromFiles(currentBlockFiles, _seenTimes),
            'Trip2',
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
            'Trip3',
            0,
            0,
            otherTrip.location,
            firstCreationTime:
                min(otherTrip.firstCreationTime!, trip.firstCreationTime!),
            lastCreationTime:
                max(otherTrip.lastCreationTime!, trip.lastCreationTime!),
          );
          _logger.finest('Merged two trip locations');
          merged = true;
          break;
        }
      }
      if (merged) continue;
      mergedTrips.add(
        TripMemory(
          trip.memories,
          'Trip4',
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
        final String? locationName = _tryFindLocationName(
          Memory.fromFiles(baseLocation.files, _seenTimes),
          base: true,
        );
        if (locationName != null) {
          name =
              "$locationName (Base, ${baseLocation.isCurrentBase ? 'current' : 'old'})";
        }
        memoryResults.add(
          TripMemory(
            Memory.fromFiles(baseLocation.files, _seenTimes),
            name,
            nowInMicroseconds,
            windowEnd,
            baseLocation.location,
          ),
        );
      }
      for (final trip in validTrips) {
        final year = DateTime.fromMicrosecondsSinceEpoch(
          trip.averageCreationTime(),
        ).year;
        final String? locationName = _tryFindLocationName(trip.memories);
        String name = "Trip in $year";
        if (locationName != null) {
          name = "Trip to $locationName";
        } else if (year == currentTime.year - 1) {
          name = "Last year's trip";
        }
        final photoSelection = await _bestSelection(trip.memories);
        memoryResults.add(
          trip.copyWith(
            memories: photoSelection,
            title: name,
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
        final String? locationName = _tryFindLocationName(trip.memories);
        String name =
            "Trip in $year"; // TODO lau: extract strings for translation
        if (locationName != null) {
          name = "Trip to $locationName";
        } else if (year == currentTime.year - 1) {
          name = "Last year's trip";
        }
        final photoSelection = await _bestSelection(trip.memories);
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
            title: name,
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
              final String? locationName = _tryFindLocationName(trip.memories);
              String name = "Trip in $year";
              if (locationName != null) {
                name = "Trip to $locationName";
              } else if (year == currentTime.year - 1) {
                name = "Last year's trip";
              }
              final photoSelection = await _bestSelection(trip.memories);
              memoryResults.add(
                trip.copyWith(
                  memories: photoSelection,
                  title: name,
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

  Future<List<TimeMemory>> _onThisDayOrWeekResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
  ) async {
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
          .add(Memory.fromFile(file, _seenTimes));
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
        final photoSelection = await _bestSelection(allPhotos);

        memoryResult.add(
          TimeMemory(
            photoSelection,
            "${DateFormat('MMMM d').format(date)} through the years",
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
          final photoSelection = await _bestSelection(files);
          String name = DateFormat.yMMMd(_locale?.languageCode).format(date);
          memoryResult.add(
            TimeMemory(
              photoSelection,
              name,
              showDate.subtract(kMemoriesMargin).microsecondsSinceEpoch,
              showDate.microsecondsSinceEpoch,
            ),
          );
          name = "This day, ${currentTime.year - date.year} years back";
          memoryResult.add(
            TimeMemory(
              photoSelection,
              name,
              showDate.microsecondsSinceEpoch,
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
            .add(Memory.fromFile(file, _seenTimes));
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
          final photoSelection = await _bestSelection(allPhotos);
          const name = "This week through the years";
          memoryResult.add(
            TimeMemory(
              photoSelection,
              name,
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
            final photoSelection = await _bestSelection(files);
            final name =
                "This week, ${currentTime.year - date.year} years back";

            memoryResult.add(
              TimeMemory(
                photoSelection,
                name,
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

    // process to find fillers (months)
    const wantedMemories = 3;
    final neededMemories = wantedMemories - memoryResult.length;
    if (neededMemories <= 0) return memoryResult;
    const monthSelectionSize = 20;

    // Group files by month and year
    final currentMonthYearGroups = <int, List<Memory>>{};
    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final month = creationTime.month;
      if (month != currentMonth) continue;
      final year = creationTime.year;

      currentMonthYearGroups
          .putIfAbsent(year, () => [])
          .add(Memory.fromFile(file, _seenTimes));
    }

    // Add the largest two months plus the month through the years
    final sortedYearsForCurrentMonth = currentMonthYearGroups.keys.toList()
      ..sort(
        (a, b) => currentMonthYearGroups[b]!.length.compareTo(
              currentMonthYearGroups[a]!.length,
            ),
      );
    if (neededMemories > 1) {
      for (int i = neededMemories; i > 1; i--) {
        if (sortedYearsForCurrentMonth.isEmpty) break;
        final year = sortedYearsForCurrentMonth.removeAt(0);
        final monthYearFiles = currentMonthYearGroups[year]!;
        final photoSelection = await _bestSelection(
          monthYearFiles,
          prefferedSize: monthSelectionSize,
        );
        final monthName = DateFormat.MMMM(_locale?.languageCode)
            .format(DateTime(year, currentMonth));
        final daysLeftInMonth = DateTime(currentYear, currentMonth + 1, 0).day -
            currentTime.day +
            1;
        final name = monthName + ", ${currentTime.year - year} years back";
        memoryResult.add(
          TimeMemory(
            photoSelection,
            name,
            currentTime.microsecondsSinceEpoch,
            currentTime
                .add(Duration(days: daysLeftInMonth))
                .microsecondsSinceEpoch,
          ),
        );
      }
    }
    // Show the month through the remaining years
    if (sortedYearsForCurrentMonth.isEmpty) return memoryResult;
    final allPhotos = sortedYearsForCurrentMonth
        .expand((year) => currentMonthYearGroups[year]!)
        .toList();
    final photoSelection =
        await _bestSelection(allPhotos, prefferedSize: monthSelectionSize);
    final monthName = DateFormat.MMMM(_locale?.languageCode)
        .format(DateTime(currentTime.year, currentMonth));
    final daysLeftInMonth =
        DateTime(currentYear, currentMonth + 1, 0).day - currentTime.day + 1;
    final name = monthName + " through the years";
    memoryResult.add(
      TimeMemory(
        photoSelection,
        name,
        currentTime.microsecondsSinceEpoch,
        currentTime.add(Duration(days: daysLeftInMonth)).microsecondsSinceEpoch,
      ),
    );

    return memoryResult;
  }

  Future<List<FillerMemory>> _getFillerResults(
    Iterable<EnteFile> allFiles,
    DateTime currentTime,
  ) async {
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
      if (file.creationTime == null ||
          file.creationTime! > cutOffTime.microsecondsSinceEpoch) {
        continue;
      }
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final fileTimeInYear = fileDate.copyWith(year: currentYear);
      final diff = fileTimeInYear.difference(currentTime);
      if (!diff.isNegative && diff < kMemoriesUpdateFrequency) {
        final yearsAgo = currentYear - fileDate.year;
        yearsAgoToMemories
            .putIfAbsent(yearsAgo, () => [])
            .add(Memory.fromFile(file, _seenTimes));
      } else if (almostYearEnd) {
        final altDiff = fileDate.copyWith(year: currentYear + 1).difference(
              currentTime,
            );
        if (!altDiff.isNegative && altDiff < kMemoriesUpdateFrequency) {
          final yearsAgo = currentYear - fileDate.year + 1;
          yearsAgoToMemories
              .putIfAbsent(yearsAgo, () => [])
              .add(Memory.fromFile(file, _seenTimes));
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
        "filler",
        nowInMicroseconds,
        windowEnd,
      );
      memoryResults.add(fillerMemory);
    }
    return memoryResults;
  }

  /// TODO: lau: replace this by just taking next 7 days
  int _getWeekNumber(DateTime date) {
    // Get day of year (1-366)
    final int dayOfYear = int.parse(DateFormat('D').format(date));
    // Integer division by 7 and add 1 to start from week 1
    return ((dayOfYear - 1) ~/ 7) + 1;
  }

  String? _tryFindLocationName(
    List<Memory> memories, {
    bool base = false,
  }) {
    final files = Memory.filesFromMemories(memories);
    final results = locationService.getFilesInCitySync(files);
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
  Future<List<Memory>> _bestSelectionPeople(
    List<Memory> memories, {
    int? prefferedSize,
  }) async {
    try {
      final w = (kDebugMode ? EnteWatch('getPeopleResults') : null)?..start();
      final fileCount = memories.length;
      final int targetSize = prefferedSize ?? 10;
      if (fileCount <= targetSize) return memories;
      final safeMemories = memories
          .where((memory) => memory.file.uploadedFileID != null)
          .toList();

      // Sort by time
      final sortedTimeMemories = <Memory>[];
      for (final memory in safeMemories) {
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
      bucketLoop:
      for (final bucket in timeBuckets) {
        // Get X% most nostalgic photos
        final bucketFileIDs = bucket
            .map((memory) => memory.file.uploadedFileID!)
            .toSet()
            .toList();
        final bucketVectors = await SemanticSearchService.instance
            .getClipVectorsForFileIDs(bucketFileIDs);
        final nostalgiaScores = await MLComputer.instance
            .compareEmbeddings(bucketVectors, _clipPositiveTextVector!);
        final sortedNostalgia = bucket
          ..sort(
            (a, b) => nostalgiaScores[b.file.uploadedFileID!]!
                .compareTo(nostalgiaScores[a.file.uploadedFileID!]!),
          );
        final mostNostalgic = sortedNostalgia
            .take((max(bucket.length * 0.3, 1)).toInt())
            .toList();

        if (mostNostalgic.isEmpty) {
          _logger.severe('No nostalgic photos in bucket');
        }

        // If no selection yet, take the most nostalgic photo
        if (finalSelection.isEmpty) {
          finalSelection.add(mostNostalgic.first);
          continue bucketLoop;
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

      _logger.finest(
        'People memories selection done, returning ${finalSelection.length} memories',
      );
      w?.log('People memories selection done');
      return finalSelection;
    } catch (e, s) {
      _logger.severe('Error in _bestSelectionPeople', e, s);
      return [];
    }
  }

  /// Returns the best selection of files from the given list, for time and trip memories.
  /// Makes sure that the selection is not more than [prefferedSize] or 10 files,
  /// and that each year of the original list is represented.
  Future<List<Memory>> _bestSelection(
    List<Memory> memories, {
    int? prefferedSize,
  }) async {
    final fileCount = memories.length;
    int targetSize = prefferedSize ?? 10;
    if (fileCount <= targetSize) return memories;
    final safeMemories =
        memories.where((memory) => memory.file.uploadedFileID != null).toList();
    final safeCount = safeMemories.length;
    final fileIDs = safeMemories.map((e) => e.file.uploadedFileID!).toSet();
    final fileIdToFace = await MLDataDB.instance.getFacesForFileIDs(fileIDs);
    final faceIDs =
        fileIdToFace.values.expand((x) => x.map((face) => face.faceID)).toSet();
    final faceIDsToPersonID =
        await MLDataDB.instance.getFaceIdToPersonIdForFaces(faceIDs);

    final allYears = safeMemories.map((e) {
      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(e.file.creationTime!);
      return creationTime.year;
    }).toSet();

    // Get clip scores for each file
    final vectors =
        await SemanticSearchService.instance.getClipVectorsForFileIDs(fileIDs);
    final fileToScore = await MLComputer.instance
        .compareEmbeddings(vectors, _clipPositiveTextVector!);
    final fileIdToClip = <int, EmbeddingVector>{};
    for (final vector in vectors) {
      fileIdToClip[vector.fileID] = vector;
    }

    // Get face scores for each file
    final fileToFaceCount = <int, int>{};
    for (final mem in safeMemories) {
      final fileID = mem.file.uploadedFileID!;
      fileToFaceCount[fileID] = 0;
      final faces = fileIdToFace[fileID];
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
      safeMemories.sort(
        (a, b) => fileToScore[b.file.uploadedFileID!]!
            .compareTo(fileToScore[a.file.uploadedFileID!]!),
      );
      // then sort on faces (descending), heavily prioritizing named faces
      safeMemories.sort(
        (a, b) => fileToFaceCount[b.file.uploadedFileID!]!
            .compareTo(fileToFaceCount[a.file.uploadedFileID!]!),
      );

      // then filter out similar images as much as possible
      filteredMemories.add(safeMemories.first);
      int skipped = 0;
      filesLoop:
      for (final mem in safeMemories.sublist(1)) {
        if (filteredMemories.length >= targetSize) break;
        final clip = fileIdToClip[mem.file.uploadedFileID!];
        if (clip != null && (safeCount - skipped) > targetSize) {
          for (final filteredMem in filteredMemories) {
            final fClip = fileIdToClip[filteredMem.file.uploadedFileID!];
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
        if (safeCount < targetSize) return safeMemories;
      }

      // Group files by year and sort each year's list by CLIP then face count
      final yearToFiles = <int, List<Memory>>{};
      for (final safeMem in safeMemories) {
        final creationTime =
            DateTime.fromMicrosecondsSinceEpoch(safeMem.file.creationTime!);
        final year = creationTime.year;
        yearToFiles.putIfAbsent(year, () => []).add(safeMem);
      }

      for (final year in yearToFiles.keys) {
        final yearFiles = yearToFiles[year]!;
        // sort first on clip embeddings score (descending)
        yearFiles.sort(
          (a, b) => fileToScore[b.file.uploadedFileID!]!
              .compareTo(fileToScore[a.file.uploadedFileID!]!),
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
      while (filteredMemories.length + skipped < safeCount) {
        yearLoop:
        for (final year in years) {
          final yearFiles = yearToFiles[year]!;
          if (yearFiles.isEmpty) continue;
          final newMem = yearFiles.removeAt(0);
          if (round != 0 && (safeCount - skipped) > targetSize) {
            // check for filtering
            final clip = fileIdToClip[newMem.file.uploadedFileID!];
            if (clip != null) {
              for (final filteredMem in filteredMemories) {
                final fClip = fileIdToClip[filteredMem.file.uploadedFileID!];
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
              filteredMemories.length + skipped >= safeCount) {
            break whileLoop;
          }
        }
        round++;
        // Extra safety to prevent infinite loops
        if (round > safeCount) break;
      }
    }

    // Order the final selection chronologically
    filteredMemories
        .sort((a, b) => a.file.creationTime!.compareTo(b.file.creationTime!));
    return filteredMemories;
  }
}
