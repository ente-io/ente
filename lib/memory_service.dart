import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/utils/date_time_util.dart';

class MemoryService {
  final _logger = Logger("MemoryService");
  final _memoriesDB = MemoriesDB.instance;
  final _filesDB = FilesDB.instance;
  static final microSecondsInADay = 86400000000;
  static final daysInAYear = 365;
  static final daysBefore = 7;
  static final daysAfter = 1;

  MemoryService._privateConstructor();

  static final MemoryService instance = MemoryService._privateConstructor();

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
    for (var yearAgo = 1; yearAgo <= 100; yearAgo++) {
      final date = _getDate(present, yearAgo);
      final startCreationTime =
          date.subtract(Duration(days: 7)).microsecondsSinceEpoch;
      final endCreationTime =
          date.add(Duration(days: 1)).microsecondsSinceEpoch;
      final memories = await _filesDB.getFilesCreatedWithinDuration(
          startCreationTime, endCreationTime);
      if (memories.length > 0)
        _logger.info("Got " +
            memories.length.toString() +
            " memories between " +
            getFormattedTime(
                DateTime.fromMicrosecondsSinceEpoch(startCreationTime)) +
            " to " +
            getFormattedTime(
                DateTime.fromMicrosecondsSinceEpoch(endCreationTime)));
      files.addAll(memories);
    }
    final seenFileIDs = await _memoriesDB.getSeenFileIDs();
    final memories = List<Memory>();
    for (final file in files) {
      if (filter.shouldInclude(file)) {
        memories.add(Memory(file, seenFileIDs.contains(file.generatedId)));
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
    return _memoriesDB.markMemoryAsSeen(
        memory, DateTime.now().microsecondsSinceEpoch);
  }
}
