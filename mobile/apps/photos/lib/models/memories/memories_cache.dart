import "dart:convert";

import "package:photos/models/base/id.dart";
import "package:photos/models/base_location.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memories/clip_memory.dart";
import "package:photos/models/memories/people_memory.dart";
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/models/memories/smart_memory_constants.dart";
import "package:photos/models/memories/trip_memory.dart";

const kPersonShowTimeout = Duration(days: 16 * kMemoriesUpdateFrequencyDays);
const kClipShowTimeout = Duration(days: 10 * kMemoriesUpdateFrequencyDays);
const kTripShowTimeout = Duration(days: 50 * kMemoriesUpdateFrequencyDays);

final maxShowTimeout = [
      kPersonShowTimeout,
      kTripShowTimeout,
    ].reduce((value, element) => value > element ? value : element) *
    3;

class MemoriesCache {
  final List<ToShowMemory> toShowMemories;
  final List<PeopleShownLog> peopleShownLogs;
  final List<ClipShownLog> clipShownLogs;
  final List<TripsShownLog> tripsShownLogs;
  final List<BaseLocation> baseLocations;

  MemoriesCache({
    required this.toShowMemories,
    required this.peopleShownLogs,
    required this.clipShownLogs,
    required this.tripsShownLogs,
    required this.baseLocations,
  });

  factory MemoriesCache.fromJson(
    Map<String, dynamic> json,
  ) {
    return MemoriesCache(
      toShowMemories: ToShowMemory.decodeJsonToList(json['toShowMemories']),
      peopleShownLogs: PeopleShownLog.decodeJsonToList(json['peopleShownLogs']),
      clipShownLogs: ClipShownLog.decodeJsonToList(json['clipShownLogs']),
      tripsShownLogs: TripsShownLog.decodeJsonToList(json['tripsShownLogs']),
      baseLocations: json['baseLocations'] != null
          ? BaseLocation.decodeJsonToList(json['baseLocations'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toShowMemories': ToShowMemory.encodeListToJson(toShowMemories),
      'peopleShownLogs': PeopleShownLog.encodeListToJson(peopleShownLogs),
      'clipShownLogs': ClipShownLog.encodeListToJson(clipShownLogs),
      'tripsShownLogs': TripsShownLog.encodeListToJson(tripsShownLogs),
      'baseLocations': BaseLocation.encodeListToJson(baseLocations),
    };
  }

  static String encodeToJsonString(MemoriesCache cache) {
    return jsonEncode(cache.toJson());
  }

  static MemoriesCache decodeFromJsonString(
    String jsonString,
  ) {
    return MemoriesCache.fromJson(jsonDecode(jsonString));
  }
}

class ToShowMemory {
  final String title;
  final List<int> fileUploadedIDs;
  final MemoryType type;
  final int firstTimeToShow;
  final int lastTimeToShow;
  final int calculationTime;
  final String id;

  final String? personID;
  final String? personName;
  final bool? isBirthday;
  final PeopleMemoryType? peopleMemoryType;
  final ClipMemoryType? clipMemoryType;
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
    return relevantForNow && (calculatedForNow || type == MemoryType.onThisDay);
  }

  ToShowMemory(
    this.title,
    this.fileUploadedIDs,
    this.type,
    this.firstTimeToShow,
    this.lastTimeToShow,
    this.id,
    this.calculationTime, {
    this.personID,
    this.personName,
    this.isBirthday,
    this.peopleMemoryType,
    this.clipMemoryType,
    this.location,
  }) : assert(
          (type == MemoryType.people &&
                  personID != null &&
                  peopleMemoryType != null) ||
              (type == MemoryType.trips && location != null) ||
              (type == MemoryType.clip && clipMemoryType != null) ||
              (type != MemoryType.people &&
                  type != MemoryType.trips &&
                  type != MemoryType.clip),
          "PersonID and peopleMemoryType must be provided for people memory type, and location must be provided for trips memory type",
        );

  factory ToShowMemory.fromSmartMemory(SmartMemory memory, DateTime calcTime) {
    String? personID;
    String? personName;
    bool? isBirthday;
    PeopleMemoryType? peopleMemoryType;
    ClipMemoryType? clipMemoryType;
    Location? location;
    if (memory is PeopleMemory) {
      personID = memory.personID;
      personName = memory.personName;
      isBirthday = memory.isBirthday;
      peopleMemoryType = memory.peopleMemoryType;
    } else if (memory is TripMemory) {
      location = memory.location;
    } else if (memory is ClipMemory) {
      clipMemoryType = memory.clipMemoryType;
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
      memory.id,
      calcTime.microsecondsSinceEpoch,
      personID: personID,
      personName: personName,
      isBirthday: isBirthday,
      peopleMemoryType: peopleMemoryType,
      clipMemoryType: clipMemoryType,
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
      json['id'] ?? newID(json['type'] as String),
      json['calculationTime'],
      personID: json['personID'],
      isBirthday: json['isBirthday'],
      personName: json['personName'],
      peopleMemoryType: json['peopleMemoryType'] != null
          ? peopleMemoryTypeFromString(json['peopleMemoryType'])
          : null,
      clipMemoryType: json['clipMemoryType'] != null
          ? clipMemoryTypeFromString(json['clipMemoryType'])
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
      'id': id,
      'calculationTime': calculationTime,
      'personID': personID,
      'isBirthday': isBirthday,
      'personName': personName,
      'peopleMemoryType': peopleMemoryType?.toString().split('.').last,
      'clipMemoryType': clipMemoryType?.toString().split('.').last,
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

class ClipShownLog {
  final ClipMemoryType clipMemoryType;
  final int lastTimeShown;

  ClipShownLog(
    this.clipMemoryType,
    this.lastTimeShown,
  );

  factory ClipShownLog.fromOldCacheMemory(ToShowMemory memory) {
    assert(
      memory.type == MemoryType.clip && memory.clipMemoryType != null,
    );
    return ClipShownLog(
      memory.clipMemoryType!,
      memory.lastTimeToShow,
    );
  }

  factory ClipShownLog.fromJson(Map<String, dynamic> json) {
    return ClipShownLog(
      clipMemoryTypeFromString(json['clipMemoryType']),
      json['lastTimeShown'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clipMemoryType': clipMemoryType.toString().split('.').last,
      'lastTimeShown': lastTimeShown,
    };
  }

  static String encodeListToJson(List<ClipShownLog> shownLogs) {
    final jsonList = shownLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<ClipShownLog> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ClipShownLog.fromJson(json)).toList();
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
