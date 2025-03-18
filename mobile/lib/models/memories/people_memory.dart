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
      return "Photo of two people admiring or looking at each other in a loving but non-intimate and non-physical way";
    case PeopleActivity.embracing:
      return "Photo of people hugging or embracing each other lovingly, without inappropriately kissing or other intimate actions";
    case PeopleActivity.party:
      return "Photo of people celebrating together";
    case PeopleActivity.hiking:
      return "Photo of people hiking or walking together in nature";
    case PeopleActivity.feast:
      return "Photo of people having a big feast together";
    case PeopleActivity.selfies:
      return "Happy and nostalgic selfie with people, clearly taken from the front camera of a phone";
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
  final PeopleActivity? activity;
  final String? personName;
  final bool? isBirthday;
  final int? newAge;

  PeopleMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow,
    this.peopleMemoryType,
    this.personID,
    this.personName, {
    super.firstCreationTime,
    super.lastCreationTime,
    this.activity,
    this.isBirthday,
    this.newAge,
  }) : super(
          memories,
          MemoryType.people,
          title,
          firstDateToShow,
          lastDateToShow,
        );

  PeopleMemory copyWith({
    int? firstDateToShow,
    int? lastDateToShow,
    bool? isBirthday,
    int? newAge,
  }) {
    return PeopleMemory(
      memories,
      title,
      firstDateToShow ?? this.firstDateToShow,
      lastDateToShow ?? this.lastDateToShow,
      peopleMemoryType,
      personID,
      personName,
      firstCreationTime: firstCreationTime,
      lastCreationTime: lastCreationTime,
      activity: activity,
      isBirthday: isBirthday ?? this.isBirthday,
      newAge: newAge ?? this.newAge,
    );
  }

  // TODO: extract strings below
  @override
  String createTitle() {
    switch (peopleMemoryType) {
      case PeopleMemoryType.youAndThem:
        assert(personName != null);
        return "You and $personName";
      case PeopleMemoryType.doingSomethingTogether:
        assert(activity != null);
        assert(personName != null);
        return activityTitle(activity!, personName!);
      case PeopleMemoryType.spotlight:
        if (personName == null) {
          return "Spotlight on yourself";
        } else if (newAge == null) {
          return "Spotlight on $personName";
        } else {
          if (isBirthday!) {
            return "$personName is $newAge!";
          } else {
            return "$personName turning $newAge soon";
          }
        }
      case PeopleMemoryType.lastTimeYouSawThem:
        return "Last time with $personName";
    }
  }
}
