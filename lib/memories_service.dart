import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/utils/date_time_util.dart';

class MemoriesService extends ChangeNotifier {
  final _logger = Logger("MemoryService");
  final _memoriesDB = MemoriesDB.instance;
  final _filesDB = FilesDB.instance;
  static final microSecondsInADay = 86400000000;
  static final daysInAYear = 365;
  static final yearsBefore = 30;
  static final daysBefore = 7;
  static final daysAfter = 1;

  MemoriesService._privateConstructor();

  static final MemoriesService instance = MemoriesService._privateConstructor();

  Future<void> init() async {
    await _memoriesDB.clearMemoriesSeenBeforeTime(
        DateTime.now().microsecondsSinceEpoch - (7 * microSecondsInADay));
  }

  Future<List<Memory>> getMemories() async {
    final filter = ImportantItemsFilter();
    final files = List<File>();
    final presentTime = DateTime.now();
    final present = presentTime.subtract(Duration(
        hours: presentTime.hour,
        minutes: presentTime.minute,
        seconds: presentTime.second));
    for (var yearAgo = 1; yearAgo <= yearsBefore; yearAgo++) {
      final date = _getDate(present, yearAgo);
      final startCreationTime =
          date.subtract(Duration(days: daysBefore)).microsecondsSinceEpoch;
      final endCreationTime =
          date.add(Duration(days: daysAfter)).microsecondsSinceEpoch;
      final filesInYear = await _filesDB.getFilesCreatedWithinDuration(
          startCreationTime, endCreationTime);
      if (filesInYear.length > 0)
        _logger.info("Got " +
            filesInYear.length.toString() +
            " memories between " +
            getFormattedTime(
                DateTime.fromMicrosecondsSinceEpoch(startCreationTime)) +
            " to " +
            getFormattedTime(
                DateTime.fromMicrosecondsSinceEpoch(endCreationTime)));
      files.addAll(filesInYear);
    }
    final seenTimes = await _memoriesDB.getSeenTimes();
    final memories = List<Memory>();
    for (final file in files) {
      if (filter.shouldInclude(file)) {
        final seenTime = seenTimes[file.generatedId] ?? -1;
        memories.add(Memory(file, seenTime));
      }
    }
    _logger.info("Number of memories: " + memories.length.toString());
    return memories;
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
    _logger.info("Marking memory " + memory.file.title + " as seen");
    await _memoriesDB.markMemoryAsSeen(
        memory, DateTime.now().microsecondsSinceEpoch);
    notifyListeners();
  }
}
