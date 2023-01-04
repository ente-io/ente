import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/services/collections_service.dart';

class MemoriesService extends ChangeNotifier {
  final _logger = Logger("MemoryService");
  final _memoriesDB = MemoriesDB.instance;
  final _filesDB = FilesDB.instance;
  static const daysInAYear = 365;
  static const yearsBefore = 30;
  static const daysBefore = 7;
  static const daysAfter = 1;

  List<Memory>? _cachedMemories;
  Future<List<Memory>>? _future;

  MemoriesService._privateConstructor();

  static final MemoriesService instance = MemoriesService._privateConstructor();

  void init() {
    addListener(() {
      _cachedMemories = null;
    });
    // Clear memory after a delay, in async manner.
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () {
      _memoriesDB.clearMemoriesSeenBeforeTime(
        DateTime.now().microsecondsSinceEpoch - (7 * microSecondsInDay),
      );
    });
  }

  void clearCache() {
    _cachedMemories = null;
    _future = null;
  }

  Future<List<Memory>> getMemories() async {
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
        CollectionsService.instance.collectionsHiddenFromTimeline();
    final files = await _filesDB.getFilesCreatedWithinDurations(
      durations,
      ignoredCollections,
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
