import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

enum PeopleMemoryType {
  youAndThem,
  doingSomethingTogether,
  spotlight,
  lastTimeYouSawThem,
}

enum PeopleActivity {
  celebration,
  // hiking,
  // feast,
  // selfies,
  // sports
}

String activityQuery(PeopleActivity activity) {
  switch (activity) {
    case PeopleActivity.celebration:
      return "Photo of people celebrating together";
  }
}

String activityTitle(PeopleActivity activity, String personName) {
  switch (activity) {
    case PeopleActivity.celebration:
      return "Celebrations with $personName";
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
