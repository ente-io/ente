import "package:photos/generated/l10n.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

enum ClipMemoryType {
  sunrise,
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
      return "Photo of an absolutely stunning sunrise or sunset";
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

String clipTitle(S s, ClipMemoryType clipMemoryType) {
  switch (clipMemoryType) {
    case ClipMemoryType.sunrise:
      return s.sunrise;
    case ClipMemoryType.mountains:
      return s.mountains;
    case ClipMemoryType.greenery:
      return s.greenery;
    case ClipMemoryType.beach:
      return s.beach;
    case ClipMemoryType.city:
      return s.city;
    case ClipMemoryType.moon:
      return s.moon;
    case ClipMemoryType.onTheRoad:
      return s.onTheRoad;
    case ClipMemoryType.food:
      return s.food;
    case ClipMemoryType.pets:
      return s.pets;
  }
}

class ClipMemory extends SmartMemory {
  final ClipMemoryType clipMemoryType;

  ClipMemory(
    List<Memory> memories,
    int firstDateToShow,
    int lastDateToShow,
    this.clipMemoryType, {
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.clip,
          '',
          firstDateToShow,
          lastDateToShow,
        );

  @override
  String createTitle(S s, String languageCode) {
    return clipTitle(s, clipMemoryType);
  }
}
