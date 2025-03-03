import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

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
