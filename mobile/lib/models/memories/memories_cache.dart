import "dart:convert";

import "package:photos/models/base_location.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memories/people_memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/models/memories/trip_memory.dart";

const kPersonShowTimeout = Duration(days: 7 * 10);
const kPersonAndTypeShowTimeout = Duration(days: 7 * 26);
const kTripShowTimeout = Duration(days: 7 * 25);

final maxShowTimeout = [
      kPersonShowTimeout,
      kPersonAndTypeShowTimeout,
      kTripShowTimeout,
    ].reduce((value, element) => value > element ? value : element) *
    3;

class MemoriesCache {
  final List<ToShowMemory> toShowMemories;
  final List<PeopleShownLog> peopleShownLogs;
  final List<TripsShownLog> tripsShownLogs;
  final List<BaseLocation> baseLocations;

  MemoriesCache({
    required this.toShowMemories,
    required this.peopleShownLogs,
    required this.tripsShownLogs,
    required this.baseLocations,
  });

  factory MemoriesCache.fromJson(
    Map<String, dynamic> json,
    Map<int, EnteFile> filesMap,
  ) {
    return MemoriesCache(
      toShowMemories: ToShowMemory.decodeJsonToList(json['toShowMemories']),
      peopleShownLogs: PeopleShownLog.decodeJsonToList(json['peopleShownLogs']),
      tripsShownLogs: TripsShownLog.decodeJsonToList(json['tripsShownLogs']),
      baseLocations: json['baseLocations'] != null
          ? BaseLocation.decodeJsonToList(
              json['baseLocations'],
              filesMap,
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toShowMemories': ToShowMemory.encodeListToJson(toShowMemories),
      'peopleShownLogs': PeopleShownLog.encodeListToJson(peopleShownLogs),
      'tripsShownLogs': TripsShownLog.encodeListToJson(tripsShownLogs),
      'baseLocations': BaseLocation.encodeListToJson(baseLocations),
    };
  }

  static String encodeToJsonString(MemoriesCache cache) {
    return jsonEncode(cache.toJson());
  }

  static MemoriesCache decodeFromJsonString(
    String jsonString,
    Map<int, EnteFile> filesMap,
  ) {
    return MemoriesCache.fromJson(jsonDecode(jsonString), filesMap);
  }
}

class ToShowMemory {
  final String title;
  final List<int> fileUploadedIDs;
  final MemoryType type;
  final int firstTimeToShow;
  final int lastTimeToShow;
  final int calculationTime;

  final String? personID;
  final PeopleMemoryType? peopleMemoryType;
  final Location? location;

  bool get isOld {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now > lastTimeToShow;
  }

  bool shouldShowNow() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final relevantForNow = now >= firstTimeToShow && now < lastTimeToShow;
    final calculatedForNow = (now >= calculationTime) &&
        (now < calculationTime + kMemoriesUpdateFrequency.inMicroseconds);
    return relevantForNow && calculatedForNow;
  }

  ToShowMemory(
    this.title,
    this.fileUploadedIDs,
    this.type,
    this.firstTimeToShow,
    this.lastTimeToShow,
    this.calculationTime, {
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

  factory ToShowMemory.fromSmartMemory(SmartMemory memory, DateTime calcTime) {
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
      memory.title,
      memory.memories
          .where((m) => m.file.uploadedFileID != null)
          .map((m) => m.file.uploadedFileID!)
          .toList(),
      memory.type,
      memory.firstDateToShow,
      memory.lastDateToShow,
      calcTime.microsecondsSinceEpoch,
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
      json['calculationTime'],
      personID: json['personID'],
      peopleMemoryType: json['peopleMemoryType'] != null
          ? peopleMemoryTypeFromString(json['peopleMemoryType'])
          : null,
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
      'calculationTime': calculationTime,
      'personID': personID,
      'peopleMemoryType': peopleMemoryType?.toString().split('.').last,
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

class PeopleShownLog {
  final String personID;
  final PeopleMemoryType peopleMemoryType;
  final int lastTimeShown;

  PeopleShownLog(
    this.personID,
    this.peopleMemoryType,
    this.lastTimeShown,
  );

  factory PeopleShownLog.fromOldCacheMemory(ToShowMemory memory) {
    assert(
      memory.type == MemoryType.people &&
          memory.personID != null &&
          memory.peopleMemoryType != null,
    );
    return PeopleShownLog(
      memory.personID!,
      memory.peopleMemoryType!,
      memory.lastTimeToShow,
    );
  }

  factory PeopleShownLog.fromJson(Map<String, dynamic> json) {
    return PeopleShownLog(
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

  static String encodeListToJson(List<PeopleShownLog> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<PeopleShownLog> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PeopleShownLog.fromJson(json)).toList();
  }
}

class TripsShownLog {
  final Location location;
  final int lastTimeShown;

  TripsShownLog(
    this.location,
    this.lastTimeShown,
  );

  factory TripsShownLog.fromOldCacheMemory(ToShowMemory memory) {
    assert(memory.type == MemoryType.trips && memory.location != null);
    return TripsShownLog(
      memory.location!,
      memory.lastTimeToShow,
    );
  }

  factory TripsShownLog.fromJson(Map<String, dynamic> json) {
    return TripsShownLog(
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

  static String encodeListToJson(List<TripsShownLog> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<TripsShownLog> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TripsShownLog.fromJson(json)).toList();
  }
}
