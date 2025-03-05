import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/core/event_bus.dart";
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/memories_setting_changed.dart";
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/memories/memory.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/services/collections_service.dart';
import "package:shared_preferences/shared_preferences.dart";

class MemoriesService extends ChangeNotifier {
  final _logger = Logger("MemoryService");
  final _memoriesDB = MemoriesDB.instance;
  final _filesDB = FilesDB.instance;
  late SharedPreferences _prefs;

  static const daysInAYear = 365;
  static const yearsBefore = 30;
  static const daysBefore = 7;
  static const daysAfter = 1;
  static const _showMemoryKey = "memories.enabled";

  List<Memory>? _cachedMemories;
  Future<List<Memory>>? _future;

  MemoriesService._privateConstructor();

  static final MemoriesService instance = MemoriesService._privateConstructor();

  void init(SharedPreferences prefs) {
    addListener(() {
      _cachedMemories = null;
    });
    _prefs = prefs;
    // Clear memory after a delay, in async manner.
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () {
      _memoriesDB.clearMemoriesSeenBeforeTime(
        DateTime.now().microsecondsSinceEpoch - (7 * microSecondsInDay),
      );
    });
    Bus.instance.on<FilesUpdatedEvent>().where((event) {
      return event.type == EventType.deletedFromEverywhere;
    }).listen((event) {
      final generatedIDs = event.updatedFiles
          .where((element) => element.generatedID != null)
          .map((e) => e.generatedID!)
          .toSet();
      _cachedMemories?.removeWhere((element) {
        return generatedIDs.contains(element.file.generatedID);
      });
    });
  }

  void clearCache() {
    _cachedMemories = null;
    _future = null;
  }

  bool get showMemories {
    return _prefs.getBool(_showMemoryKey) ?? true;
  }

  Future<void> setShowMemories(bool value) async {
    await _prefs.setBool(_showMemoryKey, value);
    Bus.instance.fire(MemoriesSettingChanged());
  }

  Future<List<Memory>> getMemories() async {
    if (!showMemories) {
      return [];
    }
    if (_cachedMemories != null) {
      return _cachedMemories!;
    }
    if (_future != null) {
      return _future!;
    }
    _future = _fetchMemories();
    return _future!;
  }

  Future<List<Memory>> _fetchMemories() async {
    final stopWatch = Stopwatch()..start();
    _logger.info("Fetching memories");
    final presentTime = DateTime.now();
    final present = presentTime.subtract(
      Duration(
        hours: presentTime.hour,
        minutes: presentTime.minute,
        seconds: presentTime.second,
      ),
    );
    final List<List<int>> durations = [];
    for (var yearAgo = 1; yearAgo <= yearsBefore; yearAgo++) {
      final date = _getDate(present, yearAgo);
      final startCreationTime = date
          .subtract(const Duration(days: daysBefore))
          .microsecondsSinceEpoch;
      final endCreationTime =
          date.add(const Duration(days: daysAfter)).microsecondsSinceEpoch;
      durations.add([startCreationTime, endCreationTime]);
    }
    final ignoredCollections =
        CollectionsService.instance.archivedOrHiddenCollectionIds();
    final files = await _filesDB.getFilesCreatedWithinDurations(
      durations,
      ignoredCollections,
      visibility: visibleVisibility,
    );
    final seenTimes = await _memoriesDB.getSeenTimes();
    final List<Memory> memories = [];
    final filter = ImportantItemsFilter();
    for (final file in files) {
      if (filter.shouldInclude(file)) {
        final seenTime = seenTimes[file.generatedID] ?? -1;
        memories.add(Memory(file, seenTime));
      }
    }
    _cachedMemories = memories;
    stopWatch.stop();
    _logger.info("Fetched memories, duration: ${stopWatch.elapsed}");
    return _cachedMemories!;
  }

  DateTime _getDate(DateTime present, int yearAgo) {
    final year = (present.year - yearAgo).toString();
    final month = present.month > 9
        ? present.month.toString()
        : "0" + present.month.toString();
    final day =
        present.day > 9 ? present.day.toString() : "0" + present.day.toString();
    final date = DateTime.parse(year + "-" + month + "-" + day);
    return date;
  }

  Future markMemoryAsSeen(Memory memory) async {
    memory.markSeen();
    await _memoriesDB.markMemoryAsSeen(
      memory,
      DateTime.now().microsecondsSinceEpoch,
    );
    notifyListeners();
  }
}
