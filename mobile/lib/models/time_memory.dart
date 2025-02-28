import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

class TimeMemory extends SmartMemory {
  TimeMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow, {
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.time,
          title,
          firstDateToShow,
          lastDateToShow,
        );
}
