import "package:photos/generated/l10n.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class FillerMemory extends SmartMemory {
  // For creating the title
  int yearsAgo;
  FillerMemory(
    List<Memory> memories,
    this.yearsAgo,
    int firstDateToShow,
    int lastDateToShow, {
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.filler,
          'filler',
          firstDateToShow,
          lastDateToShow,
        );

  @override
  String createTitle(S s, String languageCode) {
    return s.yearsAgo(yearsAgo);
  }
}
