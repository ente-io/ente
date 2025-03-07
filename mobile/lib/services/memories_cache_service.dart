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
import "package:photos/models/memories/memories_cache.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/search_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class MemoriesCacheService {
  static const _lastMemoriesCacheUpdateTimeKey = "lastMemoriesCacheUpdateTime";
  static const _showAnyMemoryKey = "memories.enabled";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 10);

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
        DateTime.now()
            .subtract(kMemoriesUpdateFrequency)
            .microsecondsSinceEpoch,
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
        DateTime.now()
            .subtract(kMemoriesUpdateFrequency)
            .microsecondsSinceEpoch) {
      _shouldUpdate = true;
    }
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path +
        "/cache/test3/memories_cache";
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
      final EnteWatch? w =
          kDebugMode ? EnteWatch("MemoriesCacheService") : null;
      w?.start();
      final oldCache = await _readCacheFromDisk();
      w?.log("gotten old cache");
      final MemoriesCache newCache = _processOldCache(oldCache);
      w?.log("processed old cache");
      // calculate memories for this period and for the next period
      final now = DateTime.now();
      final next = now.add(kMemoriesUpdateFrequency);
      final nowResult = await smartMemoriesService.calcMemories(now, newCache);
      final nextResult =
          await smartMemoriesService.calcMemories(next, newCache);
      w?.log("calculated new memories");
      for (final nowMemory in nowResult.memories) {
        newCache.toShowMemories
            .add(ToShowMemory.fromSmartMemory(nowMemory, now));
      }
      for (final nextMemory in nextResult.memories) {
        newCache.toShowMemories
            .add(ToShowMemory.fromSmartMemory(nextMemory, next));
      }
      newCache.baseLocations.addAll(nowResult.baseLocations);
      w?.log("added memories to cache");
      final file = File(await _getCachePath());
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      _cachedMemories =
          nowResult.memories.where((memory) => memory.shouldShowNow()).toList();
      locationService.baseLocations = nowResult.baseLocations;
      await file.writeAsBytes(
        MemoriesCache.encodeToJsonString(newCache).codeUnits,
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

  /// WARNING: Use for testing only, TODO: lau: remove later
  Future<MemoriesCache> debugCacheForTesting() async {
    final oldCache = await _readCacheFromDisk();
    final MemoriesCache newCache = _processOldCache(oldCache);
    return newCache;
  }

  MemoriesCache _processOldCache(MemoriesCache? oldCache) {
    final List<PeopleShownLog> peopleShownLogs = [];
    final List<TripsShownLog> tripsShownLogs = [];
    if (oldCache != null) {
      final now = DateTime.now();
      for (final peopleLog in oldCache.peopleShownLogs) {
        if (now.difference(
              DateTime.fromMicrosecondsSinceEpoch(peopleLog.lastTimeShown),
            ) <
            maxShowTimeout) {
          peopleShownLogs.add(peopleLog);
        }
      }
      for (final tripsLog in oldCache.tripsShownLogs) {
        if (now.difference(
              DateTime.fromMicrosecondsSinceEpoch(tripsLog.lastTimeShown),
            ) <
            maxShowTimeout) {
          tripsShownLogs.add(tripsLog);
        }
      }
      for (final oldMemory in oldCache.toShowMemories) {
        if (oldMemory.isOld) {
          if (oldMemory.type == MemoryType.people) {
            if (!peopleShownLogs.any(
              (person) =>
                  (person.personID == oldMemory.personID) &&
                  (person.peopleMemoryType == oldMemory.peopleMemoryType),
            )) {
              peopleShownLogs.add(PeopleShownLog.fromOldCacheMemory(oldMemory));
            }
          } else if (oldMemory.type == MemoryType.trips) {
            if (!tripsShownLogs.any(
              (trip) => isFileInsideLocationTag(
                oldMemory.location!,
                trip.location,
                10.0,
              ),
            )) {
              tripsShownLogs.add(TripsShownLog.fromOldCacheMemory(oldMemory));
            }
          }
        }
      }
    }
    return MemoriesCache(
      toShowMemories: [],
      peopleShownLogs: peopleShownLogs,
      tripsShownLogs: tripsShownLogs,
      baseLocations: [],
    );
  }

  Future<List<SmartMemory>> _fromCacheToMemories(MemoriesCache cache) async {
    try {
      _logger.info('Processing disk cache memories to smart memories');
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
        if (memory.shouldShowNow()) {
          memories.add(
            SmartMemory(
              memory.fileUploadedIDs
                  .map(
                    (fileID) =>
                        Memory.fromFile(allFileIdsToFile[fileID]!, _seenTimes),
                  )
                  .toList(),
              memory.type,
              memory.title,
              memory.firstTimeToShow,
              memory.lastTimeToShow,
            ),
          );
        }
      }
      locationService.baseLocations = cache.baseLocations;
      _logger.info('Processing of disk cache memories done');
      return memories;
    } catch (e, s) {
      _logger.severe("Error converting cache to memories", e, s);
      return [];
    }
  }

  Future<List<SmartMemory>> _getMemoriesFromCache() async {
    final cache = await _readCacheFromDisk();
    if (cache == null) {
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
    final allFiles = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      if (file.uploadedFileID != null) {
        allFileIdsToFile[file.uploadedFileID!] = file;
      }
    }
    final jsonString = file.readAsStringSync();
    return MemoriesCache.decodeFromJsonString(jsonString, allFileIdsToFile);
  }

  Future<void> clearMemoriesCache() async {
    await File(await _getCachePath()).delete();
    _cachedMemories = null;
  }
}
