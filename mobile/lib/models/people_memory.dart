import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

enum PeopleMemoryType {
  youAndThem,
  doingSomethingTogether,
  spotlight,
  lastTimeYouSawThem,
}

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

enum PeopleActivity { party, hiking, feast, selfies, sports }

String activityQuery(PeopleActivity activity) {
  switch (activity) {
    case PeopleActivity.party:
      return "Photo of people celebrating together";
    case PeopleActivity.hiking:
      return "Photo of people hiking together in nature";
    case PeopleActivity.feast:
      return "Photo of people having a big feast together";
    case PeopleActivity.selfies:
      return "Happy and nostalgic selfie with people";
    case PeopleActivity.sports:
      return "Photo of people joyfully playing sports together";
  }
}

String activityTitle(PeopleActivity activity, String personName) {
  switch (activity) {
    case PeopleActivity.party:
      return "Party with $personName";
    case PeopleActivity.hiking:
      return "Hiking with $personName";
    case PeopleActivity.feast:
      return "Feasting with $personName";
    case PeopleActivity.selfies:
      return "Selfies with $personName";
    case PeopleActivity.sports:
      return "Sports with $personName";
  }
}

class PeopleMemory extends SmartMemory {
  final String personID;
  final PeopleMemoryType peopleMemoryType;

  PeopleMemory(
    List<Memory> memories,
    this.peopleMemoryType,
    this.personID, {
    super.name,
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(memories, MemoryType.people);

  @override
  PeopleMemory copyWith({
    List<Memory>? memories,
    PeopleMemoryType? peopleMemoryType,
    String? personID,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return PeopleMemory(
      memories ?? super.memories,
      peopleMemoryType ?? this.peopleMemoryType,
      personID ?? this.personID,
      name: name ?? super.name,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
    );
  }
}
