import "dart:convert";

enum FacesTimelineStatus { ready, ineligible }

FacesTimelineStatus facesTimelineStatusFromString(String value) {
  switch (value) {
    case "ready":
      return FacesTimelineStatus.ready;
    case "ineligible":
      return FacesTimelineStatus.ineligible;
    default:
      throw ArgumentError.value(value, "value", "Unsupported timeline status");
  }
}

String facesTimelineStatusToString(FacesTimelineStatus status) {
  switch (status) {
    case FacesTimelineStatus.ready:
      return "ready";
    case FacesTimelineStatus.ineligible:
      return "ineligible";
  }
}

class FacesTimelineEntry {
  final String faceId;
  final int fileId;
  final int creationTimeMicros;
  final int year;

  const FacesTimelineEntry({
    required this.faceId,
    required this.fileId,
    required this.creationTimeMicros,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
        "faceId": faceId,
        "fileId": fileId,
        "creationTime": creationTimeMicros,
        "year": year,
      };

  factory FacesTimelineEntry.fromJson(Map<String, dynamic> json) {
    return FacesTimelineEntry(
      faceId: json["faceId"] as String,
      fileId: json["fileId"] as int,
      creationTimeMicros: json["creationTime"] as int,
      year: json["year"] as int,
    );
  }
}

class FacesTimelinePersonTimeline {
  final String personId;
  final FacesTimelineStatus status;
  final int updatedAtMicros;
  final List<FacesTimelineEntry> entries;

  const FacesTimelinePersonTimeline({
    required this.personId,
    required this.status,
    required this.updatedAtMicros,
    required this.entries,
  });

  bool get isReady => status == FacesTimelineStatus.ready;

  Map<String, dynamic> toJson() => {
        "personId": personId,
        "status": facesTimelineStatusToString(status),
        "updatedAt": updatedAtMicros,
        "entries": entries.map((entry) => entry.toJson()).toList(),
      };

  factory FacesTimelinePersonTimeline.fromJson(Map<String, dynamic> json) {
    final Iterable entriesJson = json["entries"] as Iterable? ?? [];
    return FacesTimelinePersonTimeline(
      personId: json["personId"] as String,
      status: facesTimelineStatusFromString(json["status"] as String),
      updatedAtMicros: json["updatedAt"] as int,
      entries: entriesJson
          .map(
            (entry) =>
                FacesTimelineEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  FacesTimelinePersonTimeline copyWith({
    FacesTimelineStatus? status,
    int? updatedAtMicros,
    List<FacesTimelineEntry>? entries,
  }) {
    return FacesTimelinePersonTimeline(
      personId: personId,
      status: status ?? this.status,
      updatedAtMicros: updatedAtMicros ?? this.updatedAtMicros,
      entries: entries ?? this.entries,
    );
  }
}

class FacesTimelineComputeLogEntry {
  final String personId;
  final String? name;
  final String? birthDate;
  final int faceCount;
  final int lastComputedMicros;
  final int logicVersion;

  const FacesTimelineComputeLogEntry({
    required this.personId,
    required this.faceCount,
    required this.lastComputedMicros,
    required this.logicVersion,
    this.name,
    this.birthDate,
  });

  Map<String, dynamic> toJson() => {
        "personId": personId,
        "name": name,
        "birthDate": birthDate,
        "faceCount": faceCount,
        "lastComputed": lastComputedMicros,
        "logicVersion": logicVersion,
      };

  factory FacesTimelineComputeLogEntry.fromJson(Map<String, dynamic> json) {
    return FacesTimelineComputeLogEntry(
      personId: json["personId"] as String,
      name: json["name"] as String?,
      birthDate: json["birthDate"] as String?,
      faceCount: json["faceCount"] as int? ?? 0,
      lastComputedMicros: json["lastComputed"] as int? ?? 0,
      logicVersion: json["logicVersion"] as int? ?? 0,
    );
  }

  FacesTimelineComputeLogEntry copyWith({
    String? name,
    String? birthDate,
    int? faceCount,
    int? lastComputedMicros,
    int? logicVersion,
  }) {
    return FacesTimelineComputeLogEntry(
      personId: personId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      faceCount: faceCount ?? this.faceCount,
      lastComputedMicros: lastComputedMicros ?? this.lastComputedMicros,
      logicVersion: logicVersion ?? this.logicVersion,
    );
  }
}

class FacesTimelineCachePayload {
  static const currentVersion = 1;
  static const currentComputeLogVersion = 1;

  final int version;
  final Map<String, FacesTimelinePersonTimeline> timelines;
  final int computeLogVersion;
  final Map<String, FacesTimelineComputeLogEntry> computeLog;

  const FacesTimelineCachePayload({
    required this.version,
    required this.timelines,
    required this.computeLogVersion,
    required this.computeLog,
  });

  FacesTimelineCachePayload.empty()
      : version = currentVersion,
        timelines = {},
        computeLogVersion = currentComputeLogVersion,
        computeLog = {};

  Map<String, dynamic> toJson() => {
        "version": version,
        "people": timelines.map((key, value) => MapEntry(key, value.toJson())),
        "computeLogVersion": computeLogVersion,
        "computeLog": computeLog.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };

  String toEncodedJson() => jsonEncode(toJson());

  FacesTimelinePersonTimeline? operator [](String personId) =>
      timelines[personId];

  Iterable<FacesTimelinePersonTimeline> get allTimelines => timelines.values;

  FacesTimelineCachePayload copyWithTimeline(
    FacesTimelinePersonTimeline timeline,
  ) {
    final updatedTimelines =
        Map<String, FacesTimelinePersonTimeline>.from(timelines);
    updatedTimelines[timeline.personId] = timeline;
    return FacesTimelineCachePayload(
      version: version,
      timelines: updatedTimelines,
      computeLogVersion: computeLogVersion,
      computeLog: computeLog,
    );
  }

  FacesTimelineCachePayload copyWithoutPerson(String personId) {
    final updatedTimelines =
        Map<String, FacesTimelinePersonTimeline>.from(timelines)
          ..remove(personId);
    final updatedLog =
        Map<String, FacesTimelineComputeLogEntry>.from(computeLog)
          ..remove(personId);
    return FacesTimelineCachePayload(
      version: version,
      timelines: updatedTimelines,
      computeLogVersion: computeLogVersion,
      computeLog: updatedLog,
    );
  }

  FacesTimelineCachePayload copyWithComputeLogEntry(
    FacesTimelineComputeLogEntry entry,
  ) {
    final updatedLog =
        Map<String, FacesTimelineComputeLogEntry>.from(computeLog);
    updatedLog[entry.personId] = entry;
    return FacesTimelineCachePayload(
      version: version,
      timelines: timelines,
      computeLogVersion: computeLogVersion,
      computeLog: updatedLog,
    );
  }

  FacesTimelineCachePayload copyWithComputeLog({
    required Map<String, FacesTimelineComputeLogEntry> entries,
    required int logVersion,
  }) {
    return FacesTimelineCachePayload(
      version: version,
      timelines: timelines,
      computeLogVersion: logVersion,
      computeLog: entries,
    );
  }

  factory FacesTimelineCachePayload.fromJson(Map<String, dynamic> json) {
    final int jsonVersion = json["version"] as int? ?? currentVersion;
    final peopleJson = json["people"] as Map<String, dynamic>? ?? {};
    final timelines = <String, FacesTimelinePersonTimeline>{};
    for (final entry in peopleJson.entries) {
      timelines[entry.key] = FacesTimelinePersonTimeline.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    final computeLogVersion =
        json["computeLogVersion"] as int? ?? currentComputeLogVersion;
    final computeLogJson = json["computeLog"] as Map<String, dynamic>? ?? {};
    final computeLog = <String, FacesTimelineComputeLogEntry>{};
    for (final entry in computeLogJson.entries) {
      computeLog[entry.key] = FacesTimelineComputeLogEntry.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return FacesTimelineCachePayload(
      version: jsonVersion,
      timelines: timelines,
      computeLogVersion: computeLogVersion,
      computeLog: computeLog,
    );
  }
}
