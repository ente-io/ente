import 'dart:math';
import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/memories/smart_memory.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class MemoryHomeWidgetService {
  // Constants
  static const String SELECTED_LAST_YEAR_MEMORIES_KEY =
      "selectedLastYearMemoriesHW";
  static const String SELECTED_ML_MEMORIES_KEY = "selectedMLMemoriesHW";
  static const String SELECTED_ON_THIS_DAY_MEMORIES_KEY =
      "selectedOnThisDayMemoriesHW";
  static const String ANDROID_CLASS_NAME = "EnteMemoryWidgetProvider";
  static const String IOS_CLASS_NAME = "EnteMemoryWidget";
  static const String MEMORY_STATUS_KEY = "memoryStatusKey.widget";
  static const String MEMORY_CHANGED_KEY = "memoryChanged.widget";
  static const String TOTAL_MEMORIES_KEY = "totalMemories";
  static const int MAX_MEMORIES_LIMIT = 50;

  // Singleton pattern
  static final MemoryHomeWidgetService instance =
      MemoryHomeWidgetService._privateConstructor();
  MemoryHomeWidgetService._privateConstructor();

  // Properties
  final Logger _logger = Logger((MemoryHomeWidgetService).toString());
  late final SharedPreferences _prefs;
  final _memoryForceRefreshLock = Lock();
  bool _hasSyncedMemory = false;

  // Initialization
  void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // Preference getters and setters
  Future<bool?> getSelectedLastYearMemories() async {
    return _prefs.getBool(SELECTED_LAST_YEAR_MEMORIES_KEY);
  }

  Future<void> setSelectedLastYearMemories(bool selectedMemories) async {
    await _prefs.setBool(SELECTED_LAST_YEAR_MEMORIES_KEY, selectedMemories);
  }

  Future<bool?> getSelectedMLMemories() async {
    return _prefs.getBool(SELECTED_ML_MEMORIES_KEY);
  }

  Future<void> setSelectedMLMemories(bool selectedMemories) async {
    await _prefs.setBool(SELECTED_ML_MEMORIES_KEY, selectedMemories);
  }

  Future<bool?> getSelectedOnThisDayMemories() async {
    return _prefs.getBool(SELECTED_ON_THIS_DAY_MEMORIES_KEY);
  }

  Future<void> setSelectedOnThisDayMemories(bool selectedMemories) async {
    await _prefs.setBool(SELECTED_ON_THIS_DAY_MEMORIES_KEY, selectedMemories);
  }

  // Public methods
  Future<void> initMemoryHomeWidget(bool? forceFetchNewMemories) async {
    if (await _hasAnyBlockers()) {
      await clearWidget();
      return;
    }

    await _memoryForceRefreshLock.synchronized(() async {
      if (await _hasAnyBlockers()) {
        return;
      }

      final isWidgetEmpty = await _isWidgetEmpty();
      forceFetchNewMemories ??= await _shouldForceFetchMemories(isWidgetEmpty);

      _logger.warning(
        "Initializing memory widget: forceFetch: $forceFetchNewMemories, isEmpty: $isWidgetEmpty",
      );

      if (forceFetchNewMemories!) {
        await _forceMemoryUpdate();
      } else if (!isWidgetEmpty) {
        await _syncExistingMemories();
      }
    });
  }

  Future<void> clearWidget() async {
    final isWidgetEmpty = await _isWidgetEmpty();
    if (isWidgetEmpty) {
      _logger.info("Widget already empty, nothing to clear");
      return;
    }

    _logger.info("Clearing MemoryHomeWidget");
    await _setTotalMemories(null);
    _hasSyncedMemory = false;
    await updateMemoriesStatus(WidgetStatus.syncedEmpty);
    await _refreshWidget(message: "MemoryHomeWidget cleared & updated");
  }

  Future<void> updateMemoryChanged(bool value) async {
    _logger.info("Updating memory changed flag to $value");
    await _prefs.setBool(MEMORY_CHANGED_KEY, value);
  }

  WidgetStatus getMemoriesStatus() {
    return WidgetStatus.values.firstWhereOrNull(
          (v) => v.index == (_prefs.getInt(MEMORY_STATUS_KEY) ?? 0),
        ) ??
        WidgetStatus.notSynced;
  }

  Future<void> updateMemoriesStatus(WidgetStatus value) async {
    await _prefs.setInt(MEMORY_STATUS_KEY, value.index);
  }

  Future<void> checkPendingMemorySync({bool addDelay = true}) async {
    if (addDelay) {
      await Future.delayed(const Duration(seconds: 5));
    }

    final isWidgetEmpty = await _isWidgetEmpty();
    final shouldForceFetch = await _shouldForceFetchMemories(isWidgetEmpty);

    if (_hasSyncedMemory && !shouldForceFetch) {
      _logger.info("Memories already synced, no action needed");
      return;
    }

    await initMemoryHomeWidget(shouldForceFetch);
  }

  Future<void> memoryChanged() async {
    await updateMemoryChanged(true);

    final cachedMemories = await _getMemoriesForWidget();
    final currentTotal = cachedMemories.length;
    final existingTotal = await _getTotalMemories() ?? 0;

    if (existingTotal == currentTotal && existingTotal == 0) {
      await updateMemoryChanged(false);
      _logger.info("Memories empty, no update needed");
      return;
    }

    _logger.info("Memories changed, updating widget");
    await initMemoryHomeWidget(true);
  }

  Future<int> countHomeWidgets() async {
    return await HomeWidgetService.instance.countHomeWidgets(
      ANDROID_CLASS_NAME,
      IOS_CLASS_NAME,
    );
  }

  Future<void> onLaunchFromWidget(int generatedId, BuildContext context) async {
    _hasSyncedMemory = true;
    await _syncExistingMemories();

    await memoriesCacheService.goToMemoryFromGeneratedFileID(
      context,
      generatedId,
    );
  }

  // Private methods
  Future<bool> _hasAnyBlockers() async {
    // Check if first import is completed
    final hasCompletedFirstImport =
        LocalSyncService.instance.hasCompletedFirstImport();
    if (!hasCompletedFirstImport) {
      _logger.warning("First import not completed");
      return true;
    }

    // Check if memories are enabled
    final areMemoriesShown = memoriesCacheService.showAnyMemories;
    if (!areMemoriesShown) {
      _logger.warning("Memories not enabled");
      return true;
    }

    return false;
  }

  Future<void> _forceMemoryUpdate() async {
    await _loadAndRenderMemories();
    await updateMemoryChanged(false);
  }

  Future<void> _syncExistingMemories() async {
    final homeWidgetCount = await countHomeWidgets();
    if (homeWidgetCount == 0) {
      _logger.warning("No active home widgets found");
      return;
    }

    await _refreshWidget(message: "Refreshing from existing memory set");
  }

  Future<bool> _isWidgetEmpty() async {
    final total = await _getTotalMemories();
    return total == 0 || total == null;
  }

  Future<bool> _shouldForceFetchMemories(bool isWidgetEmpty) async {
    // Check if memory changed flag is set
    final memoryChanged = _prefs.getBool(MEMORY_CHANGED_KEY) ?? true;
    if (memoryChanged == true) {
      return true;
    }

    final memoriesStatus = getMemoriesStatus();
    switch (memoriesStatus) {
      case WidgetStatus.notSynced:
        return true;
      case WidgetStatus.syncedPartially:
        return await countHomeWidgets() > 0;
      case WidgetStatus.syncedEmpty:
      case WidgetStatus.syncedAll:
        return false;
    }
  }

  Future<List<SmartMemory>> _getMemoriesForWidget() async {
    final lastYearValue = await getSelectedLastYearMemories();
    final mlValue = await getSelectedMLMemories();
    final onThisDayValue = await getSelectedOnThisDayMemories();
    final isMLEnabled = flagService.hasGrantedMLConsent;

    final memories = await memoriesCacheService.getMemoriesForWidget(
      onThisDay: onThisDayValue ?? !isMLEnabled,
      pastYears: lastYearValue ?? !isMLEnabled,
      smart: mlValue ?? isMLEnabled,
    );

    return memories;
  }

  Future<Map<String, Iterable<EnteFile>>> _getMemoriesWithFiles() async {
    final memories = await _getMemoriesForWidget();

    if (memories.isEmpty) {
      return {};
    }

    return Map.fromEntries(
      memories.map(
        (memory) =>
            MapEntry(memory.title, memory.memories.map((m) => m.file).toList()),
      ),
    );
  }

  Future<int?> _getTotalMemories() async {
    return HomeWidgetService.instance.getData<int>(TOTAL_MEMORIES_KEY);
  }

  Future<void> _setTotalMemories(int? total) async {
    await HomeWidgetService.instance.setData(TOTAL_MEMORIES_KEY, total);
  }

  Future<void> _refreshWidget({String? message}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: ANDROID_CLASS_NAME,
      iOSClass: IOS_CLASS_NAME,
    );

    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i][mem] ${message ?? "MemoryHomeWidget updated"}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    _logger.info("Home Widget updated: ${message ?? "standard update"}");
  }

  Future<void> _loadAndRenderMemories() async {
    final memoriesWithFiles = await _getMemoriesWithFiles();

    if (memoriesWithFiles.isEmpty) {
      _logger.warning("No memories found, clearing widget");
      await clearWidget();
      return;
    }

    final currentTotal = await _getTotalMemories();
    _logger.info("Current total memories in widget: $currentTotal");

    final bool isWidgetPresent = await countHomeWidgets() > 0;

    final limit = isWidgetPresent ? MAX_MEMORIES_LIMIT : 5;
    final maxAttempts = limit * 10;

    int renderedCount = 0;
    int attemptsCount = 0;

    await updateMemoriesStatus(WidgetStatus.notSynced);

    final memoriesWithFilesLength = memoriesWithFiles.length;
    final memoriesWithFilesEntries = memoriesWithFiles.entries.toList();
    final random = Random();

    while (renderedCount < limit && attemptsCount < maxAttempts) {
      final randomEntry =
          memoriesWithFilesEntries[random.nextInt(memoriesWithFilesLength)];

      if (randomEntry.value.isEmpty) continue;

      final randomMemoryFile = randomEntry.value.elementAt(
        random.nextInt(randomEntry.value.length),
      );
      final memoryTitle = randomEntry.key;

      final renderResult = await HomeWidgetService.instance
          .renderFile(
        randomMemoryFile,
        "memory_widget_$renderedCount",
        memoryTitle,
        null,
      )
          .catchError((e, stackTrace) {
        _logger.severe("Error rendering widget", e, stackTrace);
        return null;
      });

      if (renderResult != null) {
        // Check for blockers again before continuing
        if (await _hasAnyBlockers()) {
          return;
        }

        await _setTotalMemories(renderedCount);

        // Show update toast after first item is rendered
        if (renderedCount == 1) {
          await _refreshWidget(
            message: "First memory fetched, updating widget",
          );
          await updateMemoriesStatus(WidgetStatus.syncedPartially);
        }

        renderedCount++;
      }

      attemptsCount++;
    }

    if (attemptsCount >= maxAttempts) {
      _logger.warning(
        "Hit max attempts $maxAttempts. Only rendered $renderedCount of limit $limit.",
      );
    }

    if (renderedCount == 0) {
      return;
    }

    if (isWidgetPresent) {
      await updateMemoriesStatus(WidgetStatus.syncedAll);
    }

    await _refreshWidget(
      message: "Switched to next memory set, total: $renderedCount",
    );
  }
}
