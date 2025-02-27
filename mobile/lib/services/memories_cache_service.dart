import "dart:async";
import "dart:io" show File;

import "package:flutter/foundation.dart" show kDebugMode;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/memories_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/memories_cache.dart";
import "package:photos/models/memory.dart";
import "package:photos/models/people_memory.dart";
import "package:photos/models/smart_memory.dart";
import "package:photos/models/trip_memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class MemoriesCacheService {
  static const _lastMemoriesCacheUpdateTimeKey = "lastMemoriesCacheUpdateTime";
  static const _showAnyMemoryKey = "memories.enabled";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 10);
  static const _kUpdateFrequency = Duration(days: 7);

  final SharedPreferences _prefs;
  late final Logger _logger = Logger("MemoriesCacheService");

  final _memoriesDB = MemoriesDB.instance;

  List<SmartMemory>? _cachedMemories;
  bool _shouldUpdate = false;
  bool _isUpdateInProgress = false;

  late Map<int, int> _seenTimes;

  MemoriesCacheService(this._prefs) {
    _logger.fine("MemoriesCacheService constructor");

    Future.delayed(_kCacheUpdateDelay, () {
      _checkIfTimeToUpdateCache();
    });

    unawaited(_memoriesDB.getSeenTimes().then((value) => _seenTimes = value));
    unawaited(
      _memoriesDB.clearMemoriesSeenBeforeTime(
        DateTime.now().subtract(_kUpdateFrequency).microsecondsSinceEpoch,
      ),
    );

    Bus.instance.on<FilesUpdatedEvent>().where((event) {
      return event.type == EventType.deletedFromEverywhere;
    }).listen((event) {
      if (_cachedMemories == null) return;
      final generatedIDs = event.updatedFiles
          .where((element) => element.generatedID != null)
          .map((e) => e.generatedID!)
          .toSet();
      for (final memory in _cachedMemories!) {
        memory.memories
            .removeWhere((m) => generatedIDs.contains(m.file.generatedID));
      }
    });
  }

  Future<void> _resetLastMemoriesCacheUpdateTime() async {
    await _prefs.setInt(
      _lastMemoriesCacheUpdateTimeKey,
      DateTime.now().microsecondsSinceEpoch,
    );
  }

  int get lastMemoriesCacheUpdateTime {
    return _prefs.getInt(_lastMemoriesCacheUpdateTimeKey) ?? 0;
  }

  bool get showAnyMemories {
    return _prefs.getBool(_showAnyMemoryKey) ?? true;
  }

  bool get enableSmartMemories => flagService.showSmartMemories;

  Future<void> _checkIfTimeToUpdateCache() async {
    if (lastMemoriesCacheUpdateTime <
        DateTime.now().subtract(_kUpdateFrequency).microsecondsSinceEpoch) {
      _shouldUpdate = true;
    }
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path +
        "/cache//test1/memories_cache";
    // TODO: lau: remove the test1 directory after testing
  }

  Future markMemoryAsSeen(Memory memory) async {
    memory.markSeen();
    await _memoriesDB.markMemoryAsSeen(
      memory,
      DateTime.now().microsecondsSinceEpoch,
    );
    if (_cachedMemories != null && memory.file.generatedID != null) {
      final generatedID = memory.file.generatedID!;
      for (final smartMemory in _cachedMemories!) {
        for (final mem in smartMemory.memories) {
          if (mem.file.generatedID == generatedID) {
            mem.markSeen();
          }
        }
      }
    }
  }

  Future<void> updateCache({bool forced = false}) async {
    if (!showAnyMemories || !enableSmartMemories) {
      return;
    }
    try {
      if ((!_shouldUpdate && !forced) || _isUpdateInProgress) {
        _logger.info(
          "No update needed as shouldUpdate: $_shouldUpdate, forced: $forced and isUpdateInProgress $_isUpdateInProgress",
        );
        return;
      }
      _logger.info("updating memories cache");
      _isUpdateInProgress = true;
      final EnteWatch? w = kDebugMode ? EnteWatch("memoriesCacheWatch") : null;
      w?.start();
      final memories = await SmartMemoriesService.instance.calcMemories();
      w?.log("calculated new memories");
      final oldCache = await _readCacheFromDisk();
      w?.log("gotten old cache");
      final MemoriesCache memoryCache =
          _fromMemoriesToCache(memories, oldCache);
      w?.log("gotten cache from memories");
      final file = File(await _getCachePath());
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      _cachedMemories = memories;
      await file.writeAsBytes(
        MemoriesCache.encodeToJsonString(memoryCache).codeUnits,
      );
      w?.log("cacheWritten");
      await _resetLastMemoriesCacheUpdateTime();
      w?.logAndReset('done');
      _shouldUpdate = false;
    } catch (e, s) {
      _logger.info("Error updating memories cache", e, s);
    } finally {
      _isUpdateInProgress = false;
    }
  }

  MemoriesCache _fromMemoriesToCache(
    List<SmartMemory> memories,
    MemoriesCache? oldCache,
  ) {
    final List<ToShowMemory> toShowMemories = [];
    final List<PeopleShownLogs> peopleShownLogs = [];
    final List<TripsShownLogs> tripsShownLogs = [];
    for (final memory in memories) {
      if (memory.isOld()) {
        if (memory is PeopleMemory) {
          peopleShownLogs.add(
            PeopleShownLogs(
              memory.personID,
              memory.peopleMemoryType,
              memory.lastDateToShow!,
            ),
          );
        } else if (memory is TripMemory) {
          tripsShownLogs.add(
            TripsShownLogs(
              memory.location,
              memory.lastDateToShow!,
            ),
          );
        }
      } else {
        if (memory.hasShowTime()) {
          toShowMemories.add(ToShowMemory.fromSmartMemory(memory));
        } else {
          _logger.severe('Memory has no first or last date to show');
        }
      }
    }
    if (oldCache != null) {
      for (final shownPerson in oldCache.peopleShownLogs) {
        if (peopleShownLogs.any(
          (person) =>
              (person.personID == shownPerson.personID) &&
              (person.peopleMemoryType == shownPerson.peopleMemoryType),
        )) {
          continue;
        }
        peopleShownLogs.add(shownPerson);
      }
      for (final shownTrip in oldCache.tripsShownLogs) {
        if (tripsShownLogs.any(
          (trip) => isFileInsideLocationTag(
            shownTrip.location,
            trip.location,
            10.0,
          ),
        )) {
          continue;
        }
        tripsShownLogs.add(shownTrip);
      }
      for (final oldMemory in oldCache.toShowMemories) {
        if (oldMemory.isOld) {
          if (oldMemory.type == MemoryType.people) {
            if (!peopleShownLogs.any(
              (person) =>
                  (person.personID == oldMemory.personID) &&
                  (person.peopleMemoryType == oldMemory.peopleMemoryType),
            )) {
              peopleShownLogs
                  .add(PeopleShownLogs.fromOldCacheMemory(oldMemory));
            }
          } else if (oldMemory.type == MemoryType.trips) {
            if (!tripsShownLogs.any(
              (trip) => isFileInsideLocationTag(
                oldMemory.location!,
                trip.location,
                10.0,
              ),
            )) {
              tripsShownLogs.add(TripsShownLogs.fromOldCacheMemory(oldMemory));
            }
          }
        }
      }
    }
    return MemoriesCache(
      toShowMemories: toShowMemories,
      peopleShownLogs: peopleShownLogs,
      tripsShownLogs: tripsShownLogs,
    );
  }

  Future<List<SmartMemory>> _fromCacheToMemories(MemoriesCache cache) async {
    final List<SmartMemory> memories = [];
    final allFiles = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      if (file.uploadedFileID != null) {
        allFileIdsToFile[file.uploadedFileID!] = file;
      }
    }

    for (final ToShowMemory memory in cache.toShowMemories) {
      if (memory.shouldShowNow) {
        memories.add(
          SmartMemory(
            memory.fileUploadedIDs
                .map(
                  (fileID) =>
                      Memory.fromFile(allFileIdsToFile[fileID]!, _seenTimes),
                )
                .toList(),
            memory.type,
            name: memory.title,
            firstDateToShow: memory.firstTimeToShow,
            lastDateToShow: memory.lastTimeToShow,
          ),
        );
      }
    }
    return memories;
  }

  Future<List<SmartMemory>> _getMemoriesFromCache() async {
    final cache = await _readCacheFromDisk();
    if (cache == null) {
      // TODO: lau: if there's no cache, maybe we fall back to old memories?
      return [];
    }
    final result = await _fromCacheToMemories(cache);
    return result;
  }

  Future<List<SmartMemory>> getMemories(int? limit) async {
    if (!showAnyMemories) {
      return [];
    }
    if (_cachedMemories != null) {
      return _cachedMemories!;
    }
    _cachedMemories = await _getMemoriesFromCache();
    return _cachedMemories!;
  }

  Future<MemoriesCache?> _readCacheFromDisk() async {
    _logger.info("Reading memories cache result from disk");
    final file = File(await _getCachePath());
    if (!file.existsSync()) {
      _logger.info("No memories cache found");
      return null;
    }
    final jsonString = file.readAsStringSync();
    return MemoriesCache.decodeFromJsonString(jsonString);
  }

  Future<void> clearMemoriesCache() async {
    await File(await _getCachePath()).delete();
    _cachedMemories = null;
  }
}
