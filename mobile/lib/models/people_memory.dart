import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

enum PeopleMemoryType {
  spotlight,
  youAndThem,
  doingSomethingTogether,
  lastTimeYouSawThem,
}

class PeopleMemory extends SmartMemory {
  final PeopleMemoryType peopleMemoryType;

  PeopleMemory(
    List<Memory> memories,
    this.peopleMemoryType, {
    super.name,
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(memories, MemoryType.people);

  @override
  PeopleMemory copyWith({
    List<Memory>? memories,
    PeopleMemoryType? peopleMemoryType,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return PeopleMemory(
      memories ?? super.memories,
      peopleMemoryType ?? this.peopleMemoryType,
      name: name ?? super.name,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
    );
  }
}
