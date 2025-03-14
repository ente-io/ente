import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

enum ClipMemoryType {
  sunrise,
  sunset,
  mountains,
  greenery,
  beach,
  city,
  moon,
  onTheRoad,
  food,
  pets
}

ClipMemoryType clipMemoryTypeFromString(String type) {
  switch (type) {
    case "sunrise":
      return ClipMemoryType.sunrise;
    case "sunset":
      return ClipMemoryType.sunset;
    case "mountains":
      return ClipMemoryType.mountains;
    case "greenery":
      return ClipMemoryType.greenery;
    case "beach":
      return ClipMemoryType.beach;
    case "city":
      return ClipMemoryType.city;
    case "moon":
      return ClipMemoryType.moon;
    case "onTheRoad":
      return ClipMemoryType.onTheRoad;
    case "food":
      return ClipMemoryType.food;
    case "pets":
      return ClipMemoryType.pets;
    default:
      throw ArgumentError("Invalid people memory type: $type");
  }
}

String clipQuery(ClipMemoryType clipMemoryType) {
  switch (clipMemoryType) {
    case ClipMemoryType.sunrise:
      return "Photo of an absolutely stunning sunrise";
    case ClipMemoryType.sunset:
      return "Photo of an absolutely stunning sunset";
    case ClipMemoryType.mountains:
      return "Photo of a beautiful mountain range";
    case ClipMemoryType.greenery:
      return "Photo of lush greenery";
    case ClipMemoryType.beach:
      return "Photo of a beautiful beach";
    case ClipMemoryType.city:
      return "Beautiful photo showing a metropolitan city";
    case ClipMemoryType.moon:
      return "Photo of a beautiful moon";
    case ClipMemoryType.onTheRoad:
      return "Photo of a nostalgic road trip";
    case ClipMemoryType.food:
      return "Photo of delicious looking food";
    case ClipMemoryType.pets:
      return "Photo of cute pets";
  }
}

String clipTitle(ClipMemoryType clipMemoryType) {
  switch (clipMemoryType) {
    case ClipMemoryType.sunrise:
      return "Sunrise";
    case ClipMemoryType.sunset:
      return "Sunset";
    case ClipMemoryType.mountains:
      return "Mountains";
    case ClipMemoryType.greenery:
      return "Greenery";
    case ClipMemoryType.beach:
      return "Beach";
    case ClipMemoryType.city:
      return "City";
    case ClipMemoryType.moon:
      return "Moon";
    case ClipMemoryType.onTheRoad:
      return "On the Road";
    case ClipMemoryType.food:
      return "Food";
    case ClipMemoryType.pets:
      return "Pets";
  }
}

class ClipMemory extends SmartMemory {
  final ClipMemoryType clipMemoryType;

  ClipMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow,
    this.clipMemoryType, {
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.clip,
          title,
          firstDateToShow,
          lastDateToShow,
        );

  ClipMemory copyWith({
    List<Memory>? memories,
    String? title,
    int? firstDateToShow,
    int? lastDateToShow,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return ClipMemory(
      memories ?? this.memories,
      title ?? this.title,
      firstDateToShow ?? this.firstDateToShow,
      lastDateToShow ?? this.lastDateToShow,
      clipMemoryType,
      firstCreationTime: firstCreationTime ?? this.firstCreationTime,
      lastCreationTime: lastCreationTime ?? this.lastCreationTime,
    );
  }
}
