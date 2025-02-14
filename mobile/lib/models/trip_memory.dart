import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/smart_memory.dart";

class TripMemory extends SmartMemory {
  final Location location;

  TripMemory(
    files,
    this.location, {
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(files, MemoryType.trips);

  @override
  SmartMemory copyWith({
    List<EnteFile>? files,
    Location? location,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return TripMemory(
      files ?? this.files,
      location ?? this.location,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
    );
  }
}
