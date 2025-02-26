import "package:photos/models/location/location.dart";
import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

class TripMemory extends SmartMemory {
  final Location location;

  TripMemory(
    List<Memory> memories,
    this.location, {
    super.name,
    super.firstCreationTime,
    super.lastCreationTime,
    super.firstDateToShow,
    super.lastDateToShow,
  }) : super(memories, MemoryType.trips);

  @override
  TripMemory copyWith({
    List<Memory>? memories,
    Location? location,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
    int? firstDateToShow,
    int? lastDateToShow,
  }) {
    return TripMemory(
      memories ?? super.memories,
      location ?? this.location,
      name: name ?? super.name,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
      firstDateToShow: firstDateToShow ?? super.firstDateToShow,
      lastDateToShow: lastDateToShow ?? super.lastDateToShow,
    );
  }
}
