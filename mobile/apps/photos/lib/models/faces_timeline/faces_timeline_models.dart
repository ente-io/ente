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

class FacesTimelineCachePayload {
  static const currentVersion = 1;

  final int version;
  final Map<String, FacesTimelinePersonTimeline> timelines;

  const FacesTimelineCachePayload({
    required this.version,
    required this.timelines,
  });

  FacesTimelineCachePayload.empty() : version = currentVersion, timelines = {};

  Map<String, dynamic> toJson() => {
    "version": version,
    "people": timelines.map((key, value) => MapEntry(key, value.toJson())),
  };

  String toEncodedJson() => jsonEncode(toJson());

  FacesTimelinePersonTimeline? operator [](String personId) =>
      timelines[personId];

  Iterable<FacesTimelinePersonTimeline> get allTimelines => timelines.values;

  FacesTimelineCachePayload copyWithTimeline(
    FacesTimelinePersonTimeline timeline,
  ) {
    final updated = Map<String, FacesTimelinePersonTimeline>.from(timelines);
    updated[timeline.personId] = timeline;
    return FacesTimelineCachePayload(version: version, timelines: updated);
  }

  FacesTimelineCachePayload copyWithoutPerson(String personId) {
    final updated = Map<String, FacesTimelinePersonTimeline>.from(timelines)
      ..remove(personId);
    return FacesTimelineCachePayload(version: version, timelines: updated);
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
    return FacesTimelineCachePayload(
      version: jsonVersion,
      timelines: timelines,
    );
  }
}
