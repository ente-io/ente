import "package:photos/models/location/location.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class TripMemory extends SmartMemory {
  final Location location;

  TripMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow,
    this.location, {
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.trips,
          title,
          firstDateToShow,
          lastDateToShow,
        );

  TripMemory copyWith({
    List<Memory>? memories,
    String? title,
    int? firstDateToShow,
    int? lastDateToShow,
    Location? location,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return TripMemory(
      memories ?? this.memories,
      title ?? this.title,
      firstDateToShow ?? this.firstDateToShow,
      lastDateToShow ?? this.lastDateToShow,
      location ?? this.location,
      firstCreationTime: firstCreationTime ?? this.firstCreationTime,
      lastCreationTime: lastCreationTime ?? this.lastCreationTime,
    );
  }
}
