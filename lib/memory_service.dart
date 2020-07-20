import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/memories_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/memory.dart';

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
    final files = List<File>();
    for (var yearAgo = 1; yearAgo <= 100; yearAgo++) {
      var now = DateTime.now().microsecondsSinceEpoch;
      var checkPointDay = yearAgo * daysInAYear;
      final startCreationTime =
          now - ((checkPointDay - daysBefore) * microSecondsInADay);
      final endCreationTime =
          now - ((checkPointDay + daysAfter) * microSecondsInADay);
      files.addAll(await _filesDB.getFilesCreatedWithinDuration(
          startCreationTime, endCreationTime));
    }
    final seenFileIDs = await _memoriesDB.getSeenFileIDs();
    final memories = List<Memory>();
    for (final file in files) {
      memories.add(Memory(file, seenFileIDs.contains(file.generatedId)));
    }
    return memories;
  }

  Future markMemoryAsSeen(Memory memory) async {
    return _memoriesDB.markMemoryAsSeen(
        memory, DateTime.now().microsecondsSinceEpoch);
  }
}
