import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";

class BaseLocation {
  final List<EnteFile> files;
  int? firstCreationTime;
  int? lastCreationTime;
  final Location location;
  final bool isCurrentBase;

  BaseLocation(
    this.files,
    this.location,
    this.isCurrentBase, {
    this.firstCreationTime,
    this.lastCreationTime,
  });

  int averageCreationTime() {
    if (firstCreationTime != null && lastCreationTime != null) {
      return (firstCreationTime! + lastCreationTime!) ~/ 2;
    }
    final List<int> creationTimes = files
        .where((file) => file.creationTime != null)
        .map((file) => file.creationTime!)
        .toList();
    if (creationTimes.length < 2) {
      return creationTimes.isEmpty ? 0 : creationTimes.first;
    }
    creationTimes.sort();
    firstCreationTime ??= creationTimes.first;
    lastCreationTime ??= creationTimes.last;
    return (firstCreationTime! + lastCreationTime!) ~/ 2;
  }

  BaseLocation copyWith({
    List<EnteFile>? files,
    int? firstCreationTime,
    int? lastCreationTime,
    Location? location,
    bool? isCurrentBase,
  }) {
    return BaseLocation(
      files ?? this.files,
      location ?? this.location,
      isCurrentBase ?? this.isCurrentBase,
      firstCreationTime: firstCreationTime ?? this.firstCreationTime,
      lastCreationTime: lastCreationTime ?? this.lastCreationTime,
    );
  }
}
