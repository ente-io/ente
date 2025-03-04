import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class FillerMemory extends SmartMemory {
  FillerMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow, {
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.filler,
          title,
          firstDateToShow,
          lastDateToShow,
        );
}
