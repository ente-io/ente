import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

enum PeopleMemoryType {
  youAndThem,
  doingSomethingTogether,
  spotlight,
  lastTimeYouSawThem,
}

const peopleRotationTypes = [
  PeopleMemoryType.youAndThem,
  PeopleMemoryType.doingSomethingTogether,
  PeopleMemoryType.spotlight,
];

PeopleMemoryType peopleMemoryTypeFromString(String type) {
  switch (type) {
    case "youAndThem":
      return PeopleMemoryType.youAndThem;
    case "doingSomethingTogether":
      return PeopleMemoryType.doingSomethingTogether;
    case "spotlight":
      return PeopleMemoryType.spotlight;
    case "lastTimeYouSawThem":
      return PeopleMemoryType.lastTimeYouSawThem;
    default:
      throw ArgumentError("Invalid people memory type: $type");
  }
}

enum PeopleActivity {
  admiring,
  embracing,
  party,
  hiking,
  feast,
  selfies,
  posing,
  background,
  sports,
  roadtrip
}

String activityQuery(PeopleActivity activity) {
  switch (activity) {
    case PeopleActivity.admiring:
      return "Photo of two people lovingly admiring or looking at each other";
    case PeopleActivity.embracing:
      return "Photo of people hugging or embracing each other lovingly";
    case PeopleActivity.party:
      return "Photo of people celebrating together";
    case PeopleActivity.hiking:
      return "Photo of people hiking or walking together in nature";
    case PeopleActivity.feast:
      return "Photo of people having a big feast together";
    case PeopleActivity.selfies:
      return "Happy and nostalgic selfie with people";
    case PeopleActivity.posing:
      return "Photo of people posing together in a funny manner for the camera";
    case PeopleActivity.background:
      return "Photo of people with an absolutely stunning or interesting background";
    case PeopleActivity.sports:
      return "Photo of people joyfully playing sports together";
    case PeopleActivity.roadtrip:
      return "Photo of people on a road trip together";
  }
}

String activityTitle(PeopleActivity activity, String personName) {
  switch (activity) {
    case PeopleActivity.admiring:
      return "Admiring $personName";
    case PeopleActivity.embracing:
      return "Embracing $personName";
    case PeopleActivity.party:
      return "Party with $personName";
    case PeopleActivity.hiking:
      return "Hiking with $personName";
    case PeopleActivity.feast:
      return "Feasting with $personName";
    case PeopleActivity.selfies:
      return "Selfies with $personName";
    case PeopleActivity.posing:
      return "Posing with $personName";
    case PeopleActivity.background:
      return "You, $personName, and what a background!";
    case PeopleActivity.sports:
      return "Sports with $personName";
    case PeopleActivity.roadtrip:
      return "Road trip with $personName";
  }
}

class PeopleMemory extends SmartMemory {
  final String personID;
  final PeopleMemoryType peopleMemoryType;

  PeopleMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow,
    this.peopleMemoryType,
    this.personID, {
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.people,
          title,
          firstDateToShow,
          lastDateToShow,
        );

  PeopleMemory copyWith({
    List<Memory>? memories,
    String? title,
    int? firstDateToShow,
    int? lastDateToShow,
    PeopleMemoryType? peopleMemoryType,
    String? personID,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return PeopleMemory(
      memories ?? this.memories,
      title ?? this.title,
      firstDateToShow ?? this.firstDateToShow,
      lastDateToShow ?? this.lastDateToShow,
      peopleMemoryType ?? this.peopleMemoryType,
      personID ?? this.personID,
      firstCreationTime: firstCreationTime ?? this.firstCreationTime,
      lastCreationTime: lastCreationTime ?? this.lastCreationTime,
    );
  }
}
