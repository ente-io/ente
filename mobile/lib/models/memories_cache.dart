

import "dart:convert";

import "package:photos/models/location/location.dart";
import "package:photos/models/people_memory.dart";
import "package:photos/models/smart_memory.dart";
import "package:photos/models/trip_memory.dart";

class MemoriesCache {
  final List<ToShowMemory> toShowMemories;
  final List<PeopleShownLogs> peopleShownLogs;
  final List<TripsShownLogs> tripsShownLogs;

  MemoriesCache({
    required this.toShowMemories,
    required this.peopleShownLogs,
    required this.tripsShownLogs,
  });

  factory MemoriesCache.fromJson(Map<String, dynamic> json) {
    return MemoriesCache(
      toShowMemories: ToShowMemory.decodeJsonToList(json['toShowMemories']),
      peopleShownLogs:
          PeopleShownLogs.decodeJsonToList(json['peopleShownLogs']),
      tripsShownLogs: TripsShownLogs.decodeJsonToList(json['tripsShownLogs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toShowMemories': ToShowMemory.encodeListToJson(toShowMemories),
      'peopleShownLogs': PeopleShownLogs.encodeListToJson(peopleShownLogs),
      'tripsShownLogs': TripsShownLogs.encodeListToJson(tripsShownLogs),
    };
  }

  static String encodeToJsonString(MemoriesCache cache) {
    return jsonEncode(cache.toJson());
  }

  static MemoriesCache decodeFromJsonString(String jsonString) {
    return MemoriesCache.fromJson(jsonDecode(jsonString));
  }
}

class ToShowMemory {
  final String title;
  final List<int> fileUploadedIDs;
  final MemoryType type;
  final int firstTimeToShow;
  final int lastTimeToShow;

  final String? personID;
  final PeopleMemoryType? peopleMemoryType;
  final Location? location;

  bool get shouldShowNow {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now >= firstTimeToShow && now <= lastTimeToShow;
  }

  bool get isOld {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now > lastTimeToShow;
  }

  ToShowMemory(
    this.title,
    this.fileUploadedIDs,
    this.type,
    this.firstTimeToShow,
    this.lastTimeToShow, {
    this.personID,
    this.peopleMemoryType,
    this.location,
  }) : assert(
          (type == MemoryType.people &&
                  personID != null &&
                  peopleMemoryType != null) ||
              (type == MemoryType.trips && location != null) ||
              (type != MemoryType.people && type != MemoryType.trips),
          "PersonID and peopleMemoryType must be provided for people memory type, and location must be provided for trips memory type",
        );

  factory ToShowMemory.fromSmartMemory(SmartMemory memory) {
    assert(memory.firstDateToShow != null && memory.lastDateToShow != null);
    String? personID;
    PeopleMemoryType? peopleMemoryType;
    Location? location;
    if (memory is PeopleMemory) {
      personID = memory.personID;
      peopleMemoryType = memory.peopleMemoryType;
    } else if (memory is TripMemory) {
      location = memory.location;
    }
    return ToShowMemory(
      memory.name,
      memory.memories.map((m) => m.file.uploadedFileID!).toList(),
      memory.type,
      memory.firstDateToShow!,
      memory.lastDateToShow!,
      personID: personID,
      peopleMemoryType: peopleMemoryType,
      location: location,
    );
  }

  factory ToShowMemory.fromJson(Map<String, dynamic> json) {
    return ToShowMemory(
      json['title'],
      List<int>.from(json['fileUploadedIDs']),
      memoryTypeFromString(json['type']),
      json['firstTimeToShow'],
      json['lastTimeToShow'],
      personID: json['personID'],
      peopleMemoryType: peopleMemoryTypeFromString(json['peopleMemoryType']),
      location: json['location'] != null
          ? Location(
              latitude: json['location']['latitude'],
              longitude: json['location']['longitude'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUploadedIDs': fileUploadedIDs.toList(),
      'type': type.toString().split('.').last,
      'firstTimeToShow': firstTimeToShow,
      'lastTimeToShow': lastTimeToShow,
      'personID': personID,
      'peopleMemoryType': peopleMemoryType.toString().split('.').last,
      'location': location != null
          ? {
              'latitude': location!.latitude!,
              'longitude': location!.longitude!,
            }
          : null,
    };
  }

  static String encodeListToJson(List<ToShowMemory> toShowMemories) {
    final jsonList = toShowMemories.map((memory) => memory.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<ToShowMemory> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ToShowMemory.fromJson(json)).toList();
  }
}

class PeopleShownLogs {
  final String personID;
  final PeopleMemoryType peopleMemoryType;
  final int lastTimeShown;

  PeopleShownLogs(
    this.personID,
    this.peopleMemoryType,
    this.lastTimeShown,
  );

  factory PeopleShownLogs.fromOldCacheMemory(ToShowMemory memory) {
    assert(
      memory.type == MemoryType.people &&
          memory.personID != null &&
          memory.peopleMemoryType != null,
    );
    return PeopleShownLogs(
      memory.personID!,
      memory.peopleMemoryType!,
      memory.lastTimeToShow,
    );
  }

  factory PeopleShownLogs.fromJson(Map<String, dynamic> json) {
    return PeopleShownLogs(
      json['personID'],
      peopleMemoryTypeFromString(json['peopleMemoryType']),
      json['lastTimeShown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personID': personID,
      'peopleMemoryType': peopleMemoryType.toString().split('.').last,
      'lastTimeShown': lastTimeShown,
    };
  }

  static String encodeListToJson(List<PeopleShownLogs> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<PeopleShownLogs> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PeopleShownLogs.fromJson(json)).toList();
  }
}

class TripsShownLogs {
  final Location location;
  final int lastTimeShown;

  TripsShownLogs(
    this.location,
    this.lastTimeShown,
  );

  factory TripsShownLogs.fromOldCacheMemory(ToShowMemory memory) {
    assert(memory.type == MemoryType.trips && memory.location != null);
    return TripsShownLogs(
      memory.location!,
      memory.lastTimeToShow,
    );
  }

  factory TripsShownLogs.fromJson(Map<String, dynamic> json) {
    return TripsShownLogs(
      Location(
        latitude: json['location']['latitude'],
        longitude: json['location']['longitude'],
      ),
      json['lastTimeShown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'latitude': location.latitude!,
        'longitude': location.longitude!,
      },
      'lastTimeShown': lastTimeShown,
    };
  }

  static String encodeListToJson(List<TripsShownLogs> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<TripsShownLogs> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TripsShownLogs.fromJson(json)).toList();
  }
}