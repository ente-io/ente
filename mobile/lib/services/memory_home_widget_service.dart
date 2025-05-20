import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class MemoryHomeWidgetService {
  final Logger _logger = Logger((MemoryHomeWidgetService).toString());

  MemoryHomeWidgetService._privateConstructor();

  static const _selectedLastYearMemoriesKey = "selectedLastYearMemoriesHW";
  static const _selectedMLMemoriesKey = "selectedMLMemoriesHW";
  static const _selectedOnThisDayMemoriesKey = "selectedOnThisDayMemoriesHW";
  static const _androidClass = "EnteMemoryWidgetProvider";
  static const _iOSClass = "EnteMemoryWidget";

  static final MemoryHomeWidgetService instance =
      MemoryHomeWidgetService._privateConstructor();

  late final SharedPreferences _prefs;

  final _memoryForceRefreshLock = Lock();
  bool _hasSyncedMemory = false;

  static const memoryChangedKey = "memoryChanged.widget";
  static const totalMemories = "totalMemories";

  init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<void> _forceMemoryUpdate() async {
    await _lockAndLoadMemories();
    await updateMemoryChanged(false);
  }

  Future<bool?> getSelectedLastYearMemories() async {
    final selectedMemories = _prefs.getBool(_selectedLastYearMemoriesKey);
    return selectedMemories;
  }

  Future<void> setSelectedLastYearMemories(bool selectedMemories) async {
    await _prefs.setBool(_selectedLastYearMemoriesKey, selectedMemories);
  }

  Future<bool?> getSelectedMLMemories() async {
    final selectedMemories = _prefs.getBool(_selectedMLMemoriesKey);
    return selectedMemories;
  }

  Future<void> setSelectedMLMemories(bool selectedMemories) async {
    await _prefs.setBool(_selectedMLMemoriesKey, selectedMemories);
  }

  Future<bool?> getSelectedOnThisDayMemories() async {
    final selectedMemories = _prefs.getBool(_selectedOnThisDayMemoriesKey);
    return selectedMemories;
  }

  Future<void> setSelectedOnThisDayMemories(bool selectedMemories) async {
    await _prefs.setBool(_selectedOnThisDayMemoriesKey, selectedMemories);
  }

  Future<int> countHomeWidgets() async {
    final installedWidgets =
        await HomeWidgetService.instance.getInstalledWidgets();

    final memoryWidgets = installedWidgets
        .where(
          (element) =>
              element.androidClassName == _androidClass ||
              element.iOSKind == _iOSClass,
        )
        .toList();

    return memoryWidgets.length;
  }

  Future<void> _memorySync() async {
    final homeWidgetCount = await countHomeWidgets();
    if (homeWidgetCount == 0) {
      _logger.warning("no home widget active");
      return;
    }

    await _updateWidget(text: "refreshing from same set");
  }

  Future<bool> hasAnyBlockers() async {
    final hasCompletedFirstImport =
        LocalSyncService.instance.hasCompletedFirstImport();
    if (!hasCompletedFirstImport) {
      _logger.warning("first import not completed");
      return true;
    }

    final areMemoriesShown = memoriesCacheService.showAnyMemories;
    if (!areMemoriesShown) {
      _logger.warning("memories not enabled");
      return true;
    }

    return false;
  }

  Future<void> initMemoryHW(bool? forceFetchNewMemories) async {
    final result = await hasAnyBlockers();
    if (result) {
      await clearWidget();
      return;
    }

    await _memoryForceRefreshLock.synchronized(() async {
      final result = await hasAnyBlockers();
      if (result) {
        return;
      }
      final isTotalEmpty = await _checkIfTotalEmpty();
      forceFetchNewMemories ??= await getForceFetchCondition(isTotalEmpty);

      _logger.warning(
        "init memory hw: forceFetch: $forceFetchNewMemories, isTotalEmpty: $isTotalEmpty",
      );

      if (forceFetchNewMemories!) {
        await _forceMemoryUpdate();
      } else if (!isTotalEmpty) {
        await _memorySync();
      }
    });
  }

  Future<void> clearWidget() async {
    final isTotalEmpty = await _checkIfTotalEmpty();
    if (isTotalEmpty) {
      _logger.info(">>> Nothing to clear");
      return;
    }

    _logger.info("Clearing MemoryHomeWidget");

    await _setTotal(null);
    _hasSyncedMemory = false;

    await _updateWidget(text: "MemoryHomeWidget cleared & updated");
  }

  Future<void> updateMemoryChanged(bool value) async {
    _logger.info("Updating memory changed to $value");
    await _prefs.setBool(memoryChangedKey, value);
  }

  Future<bool> _checkIfTotalEmpty() async {
    final total = await _getTotal();
    return total == 0 || total == null;
  }

  Future<bool> getForceFetchCondition(bool isTotalEmpty) async {
    final memoryChanged = _prefs.getBool(memoryChangedKey);
    if (memoryChanged == true) return true;

    final cachedMemories = await _getMemoriesForWidget();

    final forceFetchNewMemories = isTotalEmpty && cachedMemories.isNotEmpty;
    return forceFetchNewMemories;
  }

  Future<void> checkPendingMemorySync() async {
    await Future.delayed(const Duration(seconds: 5), () {});

    final isTotalEmpty = await _checkIfTotalEmpty();
    final forceFetchNewMemories = await getForceFetchCondition(isTotalEmpty);

    if (_hasSyncedMemory && !forceFetchNewMemories) {
      _logger.info(">>> Memory already synced");
      return;
    }
    await HomeWidgetService.instance.initHomeWidget();
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

  Future<Map<String, Iterable<EnteFile>>> _getMemories() async {
    final memories = await _getMemoriesForWidget();

    if (memories.isEmpty) {
      return {};
    }

    final files = Map.fromEntries(
      memories.map((m) {
        return MapEntry(m.title, m.memories.map((e) => e.file).toList());
      }),
    );

    return files;
  }

  Future<void> _updateWidget({String? text}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: _androidClass,
      iOSClass: _iOSClass,
    );
    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i] ${text ?? "MemoryHomeWidget updated"}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    _logger.info(">>> Home Widget updated, type: ${text ?? "normal"}");
  }

  Future<void> memoryChanged() async {
    final cachedMemories = await memoriesCacheService.getCachedMemories();
    final currentTotal = cachedMemories?.length ?? 0;

    final int total = await _getTotal() ?? 0;

    if (total == currentTotal && total == 0) {
      _logger.info(">>> Memories not changed, doing nothing");
      return;
    }

    _logger.info(">>> Memories changed, updating widget");
    await updateMemoryChanged(true);
    await initMemoryHW(true);
  }

  Future<int?> _getTotal() async {
    return HomeWidgetService.instance
        .getData<int>(totalMemories, iOSGroupIDMemory);
  }

  Future<void> _setTotal(int? total) async => await HomeWidgetService.instance
      .setData(totalMemories, total, iOSGroupIDMemory);

  Future<void> _lockAndLoadMemories() async {
    final files = await _getMemories();

    if (files.isEmpty) {
      _logger.warning("No files found, clearing everything");
      await clearWidget();
      return;
    }

    final total = await _getTotal();
    _logger.info(">>> Total memories before: $total");

    int index = 0;

    for (final i in files.entries) {
      for (final file in i.value) {
        final value = await HomeWidgetService.instance
            .renderFile(
          file,
          "memory_widget_$index",
          i.key,
          iOSGroupIDMemory,
        )
            .catchError(
          (e, sT) {
            _logger.severe("Error rendering widget", e, sT);
            return null;
          },
        );

        if (value != null) {
          final result = await hasAnyBlockers();
          if (result) {
            return;
          }
          if (index == 1) {
            await _updateWidget(
              text: "First memory fetched. updating widget",
            );
          }
          index++;
          await _setTotal(index);

          if (index >= 50) {
            _logger.warning(">>> Max memory limit reached");
            break;
          }
        }
      }

      if (index >= 50) {
        break;
      }
    }

    if (index == 0) {
      return;
    }

    await _updateWidget(
      text: ">>> Switching to next memory set, total: $index",
    );
  }

  Future<void> onLaunchFromWidget(int generatedId, BuildContext context) async {
    _hasSyncedMemory = true;
    await _memorySync();

    await memoriesCacheService.goToMemoryFromGeneratedFileID(
      context,
      generatedId,
    );
  }
}
