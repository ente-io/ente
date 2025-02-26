import "dart:async";
import "dart:convert";
import "dart:io" show File;

import "package:flutter/foundation.dart" show kDebugMode;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/memories_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memory.dart";
import "package:photos/models/people_memory.dart";
import "package:photos/models/smart_memory.dart";
import "package:photos/models/trip_memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class MemoriesCache {
  final List<ToShowMemory> toShowMemories;
  final List<PeopleShownLogs> peopleShownLogs;
  final List<TripsShownLogs> tripsShownLogs;

  MemoriesCache({
    required this.toShowMemories,
    required this.peopleShownLogs,
    required this.tripsShownLogs,
  });

  factory MemoriesCache.fromJson(Map<String, dynamic> json) {
    return MemoriesCache(
      toShowMemories: ToShowMemory.decodeJsonToList(json['toShowMemories']),
      peopleShownLogs:
          PeopleShownLogs.decodeJsonToList(json['peopleShownLogs']),
      tripsShownLogs: TripsShownLogs.decodeJsonToList(json['tripsShownLogs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toShowMemories': ToShowMemory.encodeListToJson(toShowMemories),
      'peopleShownLogs': PeopleShownLogs.encodeListToJson(peopleShownLogs),
      'tripsShownLogs': TripsShownLogs.encodeListToJson(tripsShownLogs),
    };
  }

  static String encodeToJsonString(MemoriesCache cache) {
    return jsonEncode(cache.toJson());
  }

  static MemoriesCache decodeFromJsonString(String jsonString) {
    return MemoriesCache.fromJson(jsonDecode(jsonString));
  }
}

class ToShowMemory {
  final String title;
  final List<int> fileUploadedIDs;
  final MemoryType type;
  final int firstTimeToShow;
  final int lastTimeToShow;

  final String? personID;
  final PeopleMemoryType? peopleMemoryType;
  final Location? location;

  bool get shouldShowNow {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now >= firstTimeToShow && now <= lastTimeToShow;
  }

  bool get isOld {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now > lastTimeToShow;
  }

  ToShowMemory(
    this.title,
    this.fileUploadedIDs,
    this.type,
    this.firstTimeToShow,
    this.lastTimeToShow, {
    this.personID,
    this.peopleMemoryType,
    this.location,
  }) : assert(
          (type == MemoryType.people &&
                  personID != null &&
                  peopleMemoryType != null) ||
              (type == MemoryType.trips && location != null) ||
              (type != MemoryType.people && type != MemoryType.trips),
          "PersonID and peopleMemoryType must be provided for people memory type, and location must be provided for trips memory type",
        );

  factory ToShowMemory.fromSmartMemory(SmartMemory memory) {
    assert(memory.firstDateToShow != null && memory.lastDateToShow != null);
    String? personID;
    PeopleMemoryType? peopleMemoryType;
    Location? location;
    if (memory is PeopleMemory) {
      personID = memory.personID;
      peopleMemoryType = memory.peopleMemoryType;
    } else if (memory is TripMemory) {
      location = memory.location;
    }
    return ToShowMemory(
      memory.name,
      memory.memories.map((m) => m.file.uploadedFileID!).toList(),
      memory.type,
      memory.firstDateToShow!,
      memory.lastDateToShow!,
      personID: personID,
      peopleMemoryType: peopleMemoryType,
      location: location,
    );
  }

  factory ToShowMemory.fromJson(Map<String, dynamic> json) {
    return ToShowMemory(
      json['title'],
      List<int>.from(json['fileUploadedIDs']),
      memoryTypeFromString(json['type']),
      json['firstTimeToShow'],
      json['lastTimeToShow'],
      personID: json['personID'],
      peopleMemoryType: peopleMemoryTypeFromString(json['peopleMemoryType']),
      location: json['location'] != null
          ? Location(
              latitude: json['location']['latitude'],
              longitude: json['location']['longitude'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUploadedIDs': fileUploadedIDs.toList(),
      'type': type.toString().split('.').last,
      'firstTimeToShow': firstTimeToShow,
      'lastTimeToShow': lastTimeToShow,
      'personID': personID,
      'peopleMemoryType': peopleMemoryType.toString().split('.').last,
      'location': location != null
          ? {
              'latitude': location!.latitude!,
              'longitude': location!.longitude!,
            }
          : null,
    };
  }

  static String encodeListToJson(List<ToShowMemory> toShowMemories) {
    final jsonList = toShowMemories.map((memory) => memory.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<ToShowMemory> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ToShowMemory.fromJson(json)).toList();
  }
}

class PeopleShownLogs {
  final String personID;
  final PeopleMemoryType peopleMemoryType;
  final int lastTimeShown;

  PeopleShownLogs(
    this.personID,
    this.peopleMemoryType,
    this.lastTimeShown,
  );

  factory PeopleShownLogs.fromOldCacheMemory(ToShowMemory memory) {
    assert(
      memory.type == MemoryType.people &&
          memory.personID != null &&
          memory.peopleMemoryType != null,
    );
    return PeopleShownLogs(
      memory.personID!,
      memory.peopleMemoryType!,
      memory.lastTimeToShow,
    );
  }

  factory PeopleShownLogs.fromJson(Map<String, dynamic> json) {
    return PeopleShownLogs(
      json['personID'],
      peopleMemoryTypeFromString(json['peopleMemoryType']),
      json['lastTimeShown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personID': personID,
      'peopleMemoryType': peopleMemoryType.toString().split('.').last,
      'lastTimeShown': lastTimeShown,
    };
  }

  static String encodeListToJson(List<PeopleShownLogs> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<PeopleShownLogs> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PeopleShownLogs.fromJson(json)).toList();
  }
}

class TripsShownLogs {
  final Location location;
  final int lastTimeShown;

  TripsShownLogs(
    this.location,
    this.lastTimeShown,
  );

  factory TripsShownLogs.fromOldCacheMemory(ToShowMemory memory) {
    assert(memory.type == MemoryType.trips && memory.location != null);
    return TripsShownLogs(
      memory.location!,
      memory.lastTimeToShow,
    );
  }

  factory TripsShownLogs.fromJson(Map<String, dynamic> json) {
    return TripsShownLogs(
      Location(
        latitude: json['location']['latitude'],
        longitude: json['location']['longitude'],
      ),
      json['lastTimeShown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'latitude': location.latitude!,
        'longitude': location.longitude!,
      },
      'lastTimeShown': lastTimeShown,
    };
  }

  static String encodeListToJson(List<TripsShownLogs> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<TripsShownLogs> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TripsShownLogs.fromJson(json)).toList();
  }
}

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
