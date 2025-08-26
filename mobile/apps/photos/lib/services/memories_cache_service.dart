import "dart:async";
import "dart:io" show File;

import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/memories_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/memories_changed_event.dart";
import "package:photos/events/memories_setting_changed.dart";
import "package:photos/events/memory_seen_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/memories/memories_cache.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/people_memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/models/memories/smart_memory_constants.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/language_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/notification_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/ui/home/memories/all_memories_page.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/utils/cache_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class MemoriesCacheService {
  static const _lastMemoriesCacheUpdateTimeKey = "lastMemoriesCacheUpdateTime";
  static const _showAnyMemoryKey = "memories.enabled";
  static const _shouldUpdateCacheKey = "memories.shouldUpdateCache";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 5);

  final SharedPreferences _prefs;
  static final Logger _logger = Logger("MemoriesCacheService");

  final _memoriesDB = MemoriesDB.instance;

  List<SmartMemory>? _cachedMemories;
  bool _shouldUpdate = false;

  bool _isUpdatingMemories = false;
  bool get isUpdatingMemories => _isUpdatingMemories;

  final _memoriesUpdateLock = Lock();
  final _memoriesGetLock = Lock();

  MemoriesCacheService(this._prefs) {
    _logger.info("MemoriesCacheService constructor");

    Future.delayed(_kCacheUpdateDelay, () {
      _checkIfTimeToUpdateCache();
      _memoriesDB.clearMemoriesSeenBeforeTime(
        DateTime.now()
            .subtract(kMemoriesUpdateFrequency)
            .microsecondsSinceEpoch,
      );
    });

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

  int get lastMemoriesCacheUpdateTime {
    return _prefs.getInt(_lastMemoriesCacheUpdateTimeKey) ?? 0;
  }

  bool get showAnyMemories {
    return _prefs.getBool(_showAnyMemoryKey) ?? true;
  }

  Future<void> setShowAnyMemories(bool value) async {
    await _prefs.setBool(_showAnyMemoryKey, value);
    Bus.instance.fire(MemoriesSettingChanged());
  }

  bool get enableSmartMemories =>
      flagService.hasGrantedMLConsent &&
      localSettings.isMLLocalIndexingEnabled &&
      localSettings.isSmartMemoriesEnabled;

  bool get curatedMemoriesOption =>
      showAnyMemories &&
      flagService.hasGrantedMLConsent &&
      localSettings.isMLLocalIndexingEnabled;

  void _checkIfTimeToUpdateCache() {
    if (!enableSmartMemories) {
      return;
    }
    _shouldUpdate = _prefs.getBool(_shouldUpdateCacheKey) ?? _shouldUpdate;
    if (_timeToUpdateCache()) {
      queueUpdateCache();
    }
  }

  bool _timeToUpdateCache() {
    return lastMemoriesCacheUpdateTime <
        DateTime.now()
            .subtract(kMemoriesUpdateFrequency)
            .microsecondsSinceEpoch;
  }

  Future markMemoryAsSeen(Memory memory, bool lastInList) async {
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
    if (lastInList) Bus.instance.fire(MemorySeenEvent());
  }

  void queueUpdateCache() {
    _shouldUpdate = true;
    unawaited(_prefs.setBool(_shouldUpdateCacheKey, true));
  }

  Future<List<SmartMemory>> getMemories({bool onlyUseCache = false}) async {
    _logger.info("getMemories called");
    if (!showAnyMemories) {
      _logger.info('Showing memories is disabled in settings, showing none');
      return [];
    }
    return _memoriesGetLock.synchronized(() async {
      if (_cachedMemories != null && _cachedMemories!.isNotEmpty) {
        _logger.info("Found memories in memory cache");
        return _cachedMemories!;
      } else if (onlyUseCache) {
        _logger.info("Only using cache, no memories found");
        return [];
      }
      try {
        if (!enableSmartMemories) {
          await _calculateRegularFillers();
          return _cachedMemories!;
        }
        _cachedMemories = await _getMemoriesFromCache();
        if (_cachedMemories == null || _cachedMemories!.isEmpty) {
          _logger.warning(
            "No memories found in cache, force updating cache. Possible severe caching issue",
          );
          await updateCache(forced: true);
        } else {
          _logger.info("Found memories in cache");
        }
        if (_cachedMemories == null || _cachedMemories!.isEmpty) {
          _logger
              .severe("No memories found in (computed) cache, getting fillers");
          await _calculateRegularFillers();
        }
        return _cachedMemories!;
      } catch (e, s) {
        _logger.severe("Error in getMemories", e, s);
        return [];
      }
    });
  }

  Future<void> _calculateRegularFillers() async {
    if (_cachedMemories == null) {
      _cachedMemories = await smartMemoriesService.calcSimpleMemories();
      Bus.instance.fire(MemoriesChangedEvent());
    }
    return;
  }

  Future<List<SmartMemory>?> _getMemoriesFromCache() async {
    final cache = await _readCacheFromDisk();
    if (cache == null) {
      return null;
    }
    final result = await fromCacheToMemories(cache);
    return result;
  }

  Future<MemoriesCache?> _readCacheFromDisk() async {
    _logger.info("Reading memories cache result from disk");
    final cache = decodeJsonFile<MemoriesCache>(
      await _getCachePath(),
      MemoriesCache.decodeFromJsonString,
    );
    return cache;
  }

  static Future<List<SmartMemory>> fromCacheToMemories(
    MemoriesCache cache,
  ) async {
    try {
      _logger.info('Processing disk cache memories to smart memories');
      final List<SmartMemory> memories = [];
      final seenTimes = await MemoriesDB.instance.getSeenTimes();
      final minimalFileIDs = <int>{};
      for (final ToShowMemory memory in cache.toShowMemories) {
        if (memory.shouldShowNow()) {
          minimalFileIDs.addAll(memory.fileUploadedIDs);
        }
      }
      final minimalFiles = await FilesDB.instance.getFilesFromIDs(
        minimalFileIDs.toList(),
        collectionsToIgnore: SearchService.instance.ignoreCollections(),
      );
      final minimalFileIdsToFile = <int, EnteFile>{};
      for (final file in minimalFiles) {
        if (file.uploadedFileID != null) {
          minimalFileIdsToFile[file.uploadedFileID!] = file;
        }
      }

      for (final ToShowMemory memory in cache.toShowMemories) {
        if (memory.shouldShowNow()) {
          late final SmartMemory smartMemory;
          if (memory.type == MemoryType.people) {
            smartMemory = PeopleMemory(
              memory.fileUploadedIDs
                  .where((fileID) => minimalFileIdsToFile.containsKey(fileID))
                  .map(
                    (fileID) => Memory.fromFile(
                      minimalFileIdsToFile[fileID]!,
                      seenTimes,
                    ),
                  )
                  .toList(),
              memory.firstTimeToShow,
              memory.lastTimeToShow,
              memory.peopleMemoryType!,
              memory.personID!,
              memory.personName,
              title: memory.title,
              id: memory.id,
            );
          } else {
            smartMemory = SmartMemory(
              memory.fileUploadedIDs
                  .where((fileID) => minimalFileIdsToFile.containsKey(fileID))
                  .map(
                    (fileID) => Memory.fromFile(
                      minimalFileIdsToFile[fileID]!,
                      seenTimes,
                    ),
                  )
                  .toList(),
              memory.type,
              memory.title,
              memory.firstTimeToShow,
              memory.lastTimeToShow,
              id: memory.id,
            );
          }
          if (smartMemory.memories.isNotEmpty) {
            memories.add(smartMemory);
          }
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

  Future<void> updateCache({bool forced = false}) async {
    if (!showAnyMemories) {
      return;
    }
    if (!enableSmartMemories) {
      await _calculateRegularFillers();
      return;
    }
    _checkIfTimeToUpdateCache();

    return _memoriesUpdateLock.synchronized(() async {
      if ((!_shouldUpdate && !forced)) {
        _logger.info(
          "No update needed (shouldUpdate: $_shouldUpdate, forced: $forced)",
        );
        return;
      }
      _logger.info(
        "Updating memories cache (shouldUpdate: $_shouldUpdate, forced: $forced)",
      );
      _isUpdatingMemories = true;
      try {
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
        final nowResult =
            await smartMemoriesService.calcSmartMemories(now, newCache);
        if (nowResult.isEmpty) {
          _cachedMemories = [];
          _logger.warning(
            "No memories found for now, not updating cache and returning early",
          );
          return;
        }
        final nextResult =
            await smartMemoriesService.calcSmartMemories(next, newCache);
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
        _cachedMemories = nowResult.memories
            .where((memory) => memory.shouldShowNow())
            .toList();
        await _scheduleMemoryNotifications(
          [...nowResult.memories, ...nextResult.memories],
        );
        locationService.baseLocations = nowResult.baseLocations;
        await writeToJsonFile<MemoriesCache>(
          await _getCachePath(),
          newCache,
          MemoriesCache.encodeToJsonString,
        );
        w?.log("cacheWritten");
        await _cacheUpdated();
        w?.logAndReset('_cacheUpdated method done');
      } catch (e, s) {
        _logger.info("Error updating memories cache", e, s);
      } finally {
        _isUpdatingMemories = false;
      }
    });
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path +
        "/cache/memories_cache";
  }

  Future<void> _cacheUpdated() async {
    _shouldUpdate = false;
    unawaited(_prefs.setBool(_shouldUpdateCacheKey, false));
    await _prefs.setInt(
      _lastMemoriesCacheUpdateTimeKey,
      DateTime.now().microsecondsSinceEpoch,
    );
    Bus.instance.fire(MemoriesChangedEvent());
  }

  /// WARNING: Use for testing only, TODO: lau: remove later
  Future<MemoriesCache> debugCacheForTesting() async {
    final oldCache = await _readCacheFromDisk();
    final MemoriesCache newCache = _processOldCache(oldCache);
    return newCache;
  }

  MemoriesCache _processOldCache(MemoriesCache? oldCache) {
    final List<PeopleShownLog> peopleShownLogs = [];
    final List<ClipShownLog> clipShownLogs = [];
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
      for (final clipLog in oldCache.clipShownLogs) {
        if (now.difference(
              DateTime.fromMicrosecondsSinceEpoch(clipLog.lastTimeShown),
            ) <
            maxShowTimeout) {
          clipShownLogs.add(clipLog);
        }
      }
      for (final oldMemory in oldCache.toShowMemories) {
        if (oldMemory.isOld) {
          if (oldMemory.type == MemoryType.people) {
            peopleShownLogs.add(PeopleShownLog.fromOldCacheMemory(oldMemory));
          } else if (oldMemory.type == MemoryType.clip) {
            clipShownLogs.add(ClipShownLog.fromOldCacheMemory(oldMemory));
          } else if (oldMemory.type == MemoryType.trips) {
            tripsShownLogs.add(TripsShownLog.fromOldCacheMemory(oldMemory));
          }
        }
      }
    }
    return MemoriesCache(
      toShowMemories: [],
      peopleShownLogs: peopleShownLogs,
      clipShownLogs: clipShownLogs,
      tripsShownLogs: tripsShownLogs,
      baseLocations: [],
    );
  }

  Future<void> clearMemoriesCache({bool fromDisk = true}) async {
    if (fromDisk) {
      final file = File(await _getCachePath());
      if (file.existsSync()) {
        await file.delete();
      }
    }
    _cachedMemories = null;
  }

  Future<List<SmartMemory>> getMemoriesForWidget({
    required bool onThisDay,
    required bool pastYears,
    required bool smart,
    required bool hasAnyWidgets,
  }) async {
    if (!onThisDay && !pastYears && !smart) {
      _logger.info(
        'No memories requested, returning empty list',
      );
      return [];
    }
    final allMemories = await getMemories(onlyUseCache: !hasAnyWidgets);
    if (onThisDay && pastYears && smart) {
      return allMemories;
    }
    final filteredMemories = <SmartMemory>[];
    for (final memory in allMemories) {
      if (!memory.shouldShowNow()) continue;
      if (memory.type == MemoryType.onThisDay) {
        if (!onThisDay) continue;
      } else if (memory.type == MemoryType.filler) {
        if (!pastYears) continue;
      } else {
        if (!smart) continue;
      }
      filteredMemories.add(memory);
    }
    return filteredMemories;
  }

  Future<void> goToMemoryFromGeneratedFileID(
    BuildContext context,
    int generatedFileID,
  ) async {
    final allMemories = await getMemories();
    if (allMemories.isEmpty) return;
    int memoryIdx = 0;
    int fileIdx = 0;
    bool found = false;
    memoryLoop:
    for (final memory in _cachedMemories!) {
      for (final mem in memory.memories) {
        if (mem.file.generatedID == generatedFileID) {
          found = true;
          break memoryLoop;
        }
        fileIdx++;
      }
      memoryIdx++;
      fileIdx = 0;
    }
    if (!found) {
      _logger.warning(
        "Could not find memory with generatedFileID: $generatedFileID",
      );
      return;
    }
    await routeToPage(
      context,
      AllMemoriesPage(
        allMemories: _cachedMemories!.map((e) => e.memories).toList(),
        allTitles: _cachedMemories!.map((e) => e.title).toList(),
        initialPageIndex: memoryIdx,
        inititalFileIndex: fileIdx,
        isFromWidgetOrNotifications: true,
      ),
      forceCustomPageRoute: true,
    );
  }

  Future<void> goToOnThisDayMemory(BuildContext context) async {
    final allMemories = await getMemories();
    if (allMemories.isEmpty) return;
    int memoryIdx = 0;
    bool found = false;
    memoryLoop:
    for (final memory in allMemories) {
      if (memory.type == MemoryType.onThisDay) {
        found = true;
        break memoryLoop;
      }
      memoryIdx++;
    }
    if (!found) {
      _logger.warning(
        "Could not find onThisDay memory",
      );
      return;
    }
    await routeToPage(
      context,
      AllMemoriesPage(
        allMemories: allMemories.map((e) => e.memories).toList(),
        allTitles: allMemories.map((e) => e.title).toList(),
        initialPageIndex: memoryIdx,
        inititalFileIndex: 0,
        isFromWidgetOrNotifications: true,
      ),
      forceCustomPageRoute: true,
    );
  }

  Future<void> goToPersonMemory(BuildContext context, String personID) async {
    _logger.info("Going to person memory for personID: $personID");
    final allMemories = await getMemories();
    if (allMemories.isEmpty) return;
    final personMemories = <PeopleMemory>[];
    for (final memory in allMemories) {
      if (memory is PeopleMemory) {
        _logger.info("Found person memory");
        _logger.info("Person memory ID: ${memory.id}");
        _logger.info("Person memory personID: ${memory.personID}");
        _logger.info("Person memory isBirthday: ${memory.isBirthday}");
      }
      if (memory is PeopleMemory &&
          (memory.isBirthday ?? false) &&
          memory.personID == personID) {
        personMemories.add(memory);
      }
    }
    if (personMemories.isEmpty) {
      _logger.severe("No person memories found");
    }
    PeopleMemory? personMemory;
    for (final memory in personMemories) {
      if (memory.peopleMemoryType == PeopleMemoryType.youAndThem) {
        _logger.info("Found youAndThem person memory");
        personMemory = memory;
        break; // breaking to prefer youAndThem over spotlight
      }
      if (memory.peopleMemoryType == PeopleMemoryType.spotlight) {
        _logger.info("Found spotlight person memory");
        personMemory = memory;
      }
    }

    if (personMemory == null) {
      _logger.severe(
        "Could not find person memory, routing to person page instead",
      );
      final person = await PersonService.instance.getPerson(personID);
      if (person == null) {
        _logger.severe("Person with ID $personID not found");
        return;
      }
      await routeToPage(
        context,
        PeoplePage(
          person: person,
          searchResult: null,
        ),
        forceCustomPageRoute: true,
      );
    }
    _logger.info("Routing to the birthday memory");
    await routeToPage(
      context,
      FullScreenMemoryDataUpdater(
        initialIndex: 0,
        memories: personMemory!.memories,
        child: Container(
          color: backgroundBaseDark,
          width: double.infinity,
          height: double.infinity,
          child: FullScreenMemory(personMemory.title, 0),
        ),
      ),
      forceCustomPageRoute: true,
    );
  }

  Future<void> toggleOnThisDayNotifications() async {
    final oldValue = localSettings.isOnThisDayNotificationsEnabled;
    await localSettings.setOnThisDayNotificationsEnabled(!oldValue);
    _logger.info("Turning onThisDayNotifications ${oldValue ? "off" : "on"}");
    if (oldValue) {
      await _clearAllScheduledOnThisDayNotifications();
    } else {
      queueUpdateCache();
    }
  }

  Future<void> toggleBirthdayNotifications() async {
    final oldValue = localSettings.birthdayNotificationsEnabled;
    await localSettings.setBirthdayNotificationsEnabled(!oldValue);
    _logger.info("Turning birhtdayNotifications ${oldValue ? "off" : "on"}");
    if (oldValue) {
      await _clearAllScheduledBirthdayNotifications();
    } else {
      queueUpdateCache();
    }
  }

  Future<void> _scheduleMemoryNotifications(
    List<SmartMemory> allMemories,
  ) async {
    await _scheduleOnThisDayNotifications(allMemories);
    await _scheduleBirthdayNotifications(allMemories);
  }

  Future<void> _scheduleOnThisDayNotifications(
    List<SmartMemory> allMemories,
  ) async {
    if (!localSettings.isOnThisDayNotificationsEnabled) {
      _logger
          .info("On this day notifications are disabled, skipping scheduling");
      return;
    }
    await _clearAllScheduledOnThisDayNotifications();
    final scheduledDates = <DateTime>{};
    for (final memory in allMemories) {
      if (memory.type != MemoryType.onThisDay) {
        continue;
      }
      final numberOfMemories = memory.memories.length;
      if (numberOfMemories < 5) continue;
      final firstDateToShow =
          DateTime.fromMicrosecondsSinceEpoch(memory.firstDateToShow);
      final scheduleTime = DateTime(
        firstDateToShow.year,
        firstDateToShow.month,
        firstDateToShow.day,
        8,
      );
      if (scheduleTime.isBefore(DateTime.now())) {
        _logger.info(
          "Skipping scheduling notification for memory ${memory.id} because the date is in the past (date: $scheduleTime)",
        );
        continue;
      }
      if (scheduledDates.contains(scheduleTime)) {
        _logger.info(
          "Skipping scheduling notification for memory ${memory.id} because the date is already scheduled (date: $scheduleTime)",
        );
        continue;
      }
      final s = await LanguageService.locals;
      await NotificationService.instance.scheduleNotification(
        s.onThisDay,
        message: s.lookBackOnYourMemories,
        id: memory.id.hashCode,
        channelID: "onThisDay",
        channelName: s.onThisDay,
        payload: memory.id,
        dateTime: scheduleTime,
        timeoutDurationAndroid: const Duration(hours: 16),
      );
      scheduledDates.add(scheduleTime);
      _logger.info(
        "Scheduled notification for memory ${memory.id} on date: $scheduleTime",
      );
    }
  }

  Future<void> _scheduleBirthdayNotifications(
    List<SmartMemory> allMemories,
  ) async {
    if (!localSettings.birthdayNotificationsEnabled) {
      _logger.info("birthday notifications are disabled, skipping scheduling");
      return;
    }
    await _clearAllScheduledBirthdayNotifications();
    final scheduledPersons = <String>{};
    final toSchedule = <PeopleMemory>[];
    final peopleToBirthdayMemories = <String, List<PeopleMemory>>{};
    for (final memory in allMemories) {
      if (memory is PeopleMemory && (memory.isBirthday ?? false)) {
        peopleToBirthdayMemories
            .putIfAbsent(memory.personID, () => [])
            .add(memory);
      }
    }
    personLoop:
    for (final personID in peopleToBirthdayMemories.keys) {
      final birthdayMemories = peopleToBirthdayMemories[personID]!;
      for (final memory in birthdayMemories) {
        if (memory.peopleMemoryType == PeopleMemoryType.youAndThem) {
          toSchedule.add(memory);
          continue personLoop;
        }
      }
      for (final memory in birthdayMemories) {
        if (memory.peopleMemoryType == PeopleMemoryType.spotlight) {
          toSchedule.add(memory);
          continue personLoop;
        }
      }
    }
    for (final memory in toSchedule) {
      final firstDateToShow =
          DateTime.fromMicrosecondsSinceEpoch(memory.firstDateToShow);
      final scheduleTime = DateTime(
        firstDateToShow.year,
        firstDateToShow.month,
        firstDateToShow.day,
      );
      if (scheduleTime.isBefore(DateTime.now())) {
        _logger.info(
          "Skipping scheduling notification for memory ${memory.id} because the date is in the past",
        );
        continue;
      }
      if (scheduledPersons.contains(memory.personID)) {
        _logger.severe(
          "Skipping scheduling notification for memory ${memory.id} because the person's birthday is already scheduled",
        );
        continue;
      }
      final s = await LanguageService.locals;
      await NotificationService.instance.scheduleNotification(
        memory.personName != null
            ? s.wishThemAHappyBirthday(name: memory.personName!)
            : s.happyBirthday,
        id: memory.id.hashCode,
        channelID: "birthday",
        channelName: s.birthdays,
        payload: "birthday_${memory.personID}",
        dateTime: scheduleTime,
        timeoutDurationAndroid: const Duration(hours: 24),
      );
      scheduledPersons.add(memory.personID);
      _logger.info(
        "Scheduled birthday notification for person ${memory.personID} on date: $scheduleTime",
      );
    }
  }

  Future<void> _clearAllScheduledOnThisDayNotifications() async {
    _logger.info('Clearing all scheduled On This Day notifications');
    await NotificationService.instance
        .clearAllScheduledNotifications(containingPayload: "onThisDay");
  }

  Future<void> _clearAllScheduledBirthdayNotifications() async {
    _logger.info('Clearing all scheduled birthday notifications');
    await NotificationService.instance
        .clearAllScheduledNotifications(containingPayload: "birthday");
  }
}
