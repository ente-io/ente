import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";

class TripMemory {
  final List<EnteFile> files;
  final Location location;
  final int firstCreationTime;
  final int lastCreationTime;

  TripMemory(
    this.files,
    this.location,
    this.firstCreationTime,
    this.lastCreationTime,
  );

  int get averageCreationTime => (firstCreationTime + lastCreationTime) ~/ 2;

  TripMemory copyWith({
    List<EnteFile>? files,
    Location? location,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return TripMemory(
      files ?? this.files,
      location ?? this.location,
      firstCreationTime ?? this.firstCreationTime,
      lastCreationTime ?? this.lastCreationTime,
    );
  }
}
