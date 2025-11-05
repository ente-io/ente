import "dart:async";

import "package:collection/collection.dart";
import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/faces_timeline_changed_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/models/faces_timeline/faces_timeline_models.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/faces_timeline/faces_timeline_cache_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";
import "package:photos/utils/standalone/task_queue.dart";

typedef _TimelineComputationResult = ({
  FacesTimelinePersonTimeline timeline,
  Map<int, EnteFile> filesById,
});

class FacesTimelineService {
  FacesTimelineService._internal();

  static final FacesTimelineService instance = FacesTimelineService._internal();

  static const _minimumYears = 7;
  static const _minimumFacesPerYear = 4;
  static const _recomputeCooldown = Duration(hours: 24);

  final Logger _logger = Logger("FacesTimelineService");
  final FacesTimelineCacheService _cacheService =
      FacesTimelineCacheService.instance;
  final MLDataDB _mlDataDB = MLDataDB.instance;
  final FilesDB _filesDB = FilesDB.instance;
  final TaskQueue<String> _precomputeQueue = TaskQueue(
    maxConcurrentTasks: 1,
    taskTimeout: const Duration(minutes: 2),
    maxQueueSize: 200,
  );

  final ValueNotifier<Set<String>> readyPersonIds = ValueNotifier<Set<String>>(
    {},
  );

  final Map<String, int> _lastForcedComputeMicros = {};

  bool _initialized = false;

  StreamSubscription<PeopleChangedEvent>? _peopleChangedSubscription;

  Future<void> init() async {
    if (_initialized) return;
    await _cacheService.init();
    await _refreshReadyPersonIds();
    _peopleChangedSubscription = Bus.instance.on<PeopleChangedEvent>().listen(
          _handlePeopleChange,
        );
    _initialized = true;
  }

  Future<void> dispose() async {
    await _peopleChangedSubscription?.cancel();
    readyPersonIds.dispose();
  }

  Future<void> queueFullRecompute({
    bool force = false,
    String trigger = "",
  }) async {
    if (!PersonService.isInitialized) {
      _logger.warning(
        "Faces timeline full recompute skipped: PersonService not initialized",
      );
      return;
    }
    final persons = await PersonService.instance.getPersons();
    for (final person in persons) {
      if (person.data.isIgnored) {
        await _handleIgnoredPerson(person.remoteID);
        continue;
      }
      schedulePersonRecompute(
        person.remoteID,
        force: force,
        trigger: trigger.isEmpty ? "full_recompute" : trigger,
      );
    }
  }

  void schedulePersonRecompute(
    String personId, {
    bool force = false,
    String trigger = "",
  }) {
    if (personId.isEmpty) return;
    _precomputeQueue.addTask(personId, () async {
      await _recomputeTimelineForPerson(
        personId,
        force: force,
        trigger: trigger,
      );
    }).ignore();
  }

  Future<FacesTimelinePersonTimeline?> getTimeline(String personId) {
    return _cacheService.getTimeline(personId);
  }

  bool hasReadyTimelineSync(String personId) {
    return readyPersonIds.value.contains(personId);
  }

  Future<bool> hasReadyTimeline(String personId) async {
    final timeline = await _cacheService.getTimeline(personId);
    return timeline?.isReady ?? false;
  }

  Future<void> _handleIgnoredPerson(String personId) async {
    await _cacheService.removeTimeline(personId);
    await _refreshReadyPersonIds();
    Bus.instance.fire(
      FacesTimelineChangedEvent(
        personId: personId,
        status: FacesTimelineStatus.ineligible,
      ),
    );
  }

  void _handlePeopleChange(PeopleChangedEvent event) {
    final personId = event.person?.remoteID;
    switch (event.type) {
      case PeopleEventType.saveOrEditPerson:
      case PeopleEventType.addedClusterToPerson:
      case PeopleEventType.removedFaceFromCluster:
      case PeopleEventType.removedFilesFromCluster:
        if (personId != null) {
          schedulePersonRecompute(
            personId,
            force: true,
            trigger: "people_event_${event.type.name}",
          );
        } else {
          queueFullRecompute(
            force: true,
            trigger: "people_event_${event.type.name}",
          );
        }
        break;
      case PeopleEventType.syncDone:
        queueFullRecompute(force: true, trigger: "sync_done");
        break;
      case PeopleEventType.defaultType:
        if (personId != null) {
          schedulePersonRecompute(personId, trigger: "people_default");
        }
        break;
    }
  }

  Future<void> _recomputeTimelineForPerson(
    String personId, {
    required bool force,
    required String trigger,
  }) async {
    if (!PersonService.isInitialized) {
      _logger.warning(
        "Faces timeline recompute skipped for $personId: PersonService not initialized",
      );
      return;
    }

    final person = await PersonService.instance.getPerson(personId);
    if (person == null) {
      _logger.info("Faces timeline: person $personId missing, clearing cache");
      await _cacheService.removeTimeline(personId);
      await _refreshReadyPersonIds();
      Bus.instance.fire(
        FacesTimelineChangedEvent(
          personId: personId,
          status: FacesTimelineStatus.ineligible,
        ),
      );
      return;
    }
    if (person.data.isIgnored) {
      _logger.info("Faces timeline: person $personId ignored, clearing cache");
      await _handleIgnoredPerson(personId);
      return;
    }

    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final existing = await _cacheService.getTimeline(personId);
    final lastComputedMicros = existing?.updatedAtMicros;
    final lastForcedMicros = _lastForcedComputeMicros[personId];
    if (!force && lastComputedMicros != null) {
      final remaining = nowMicros - lastComputedMicros;
      if (remaining < _recomputeCooldown.inMicroseconds) {
        _logger.fine(
          "Faces timeline compute skipped for $personId due to cooldown "
          "(elapsed ${remaining / Duration.microsecondsPerHour} hours, trigger: $trigger)",
        );
        return;
      }
    }
    if (!force && lastForcedMicros != null) {
      final remaining = nowMicros - lastForcedMicros;
      if (remaining < _recomputeCooldown.inMicroseconds) {
        _logger.fine(
          "Faces timeline compute skipped for $personId due to forced cooldown "
          "(elapsed ${remaining / Duration.microsecondsPerHour} hours, trigger: $trigger)",
        );
        return;
      }
    }

    if (force) {
      _lastForcedComputeMicros[personId] = nowMicros;
    }

    try {
      final result = await _computeTimeline(person, nowMicros);
      await _cacheService.upsertTimeline(result.timeline);
      await _refreshReadyPersonIds();
      Bus.instance.fire(
        FacesTimelineChangedEvent(
          personId: person.remoteID,
          status: result.timeline.status,
        ),
      );
      if (result.timeline.isReady) {
        await _ensureFaceCrops(
          person,
          result.timeline.entries,
          result.filesById,
        );
      }
    } catch (error, stackTrace) {
      _logger.severe(
        "Faces timeline compute failed for $personId (trigger: $trigger)",
        error,
        stackTrace,
      );
    }
  }

  Future<_TimelineComputationResult> _computeTimeline(
    PersonEntity person,
    int nowMicros,
  ) async {
    final personId = person.remoteID;
    final faceIds = await _mlDataDB.getFaceIDsForPerson(personId);
    if (faceIds.isEmpty) {
      _logger.fine(
        "Faces timeline: person $personId has no faces, marking ineligible",
      );
      final timeline = FacesTimelinePersonTimeline(
        personId: personId,
        status: FacesTimelineStatus.ineligible,
        updatedAtMicros: nowMicros,
        entries: const [],
      );
      return (timeline: timeline, filesById: const <int, EnteFile>{});
    }

    final List<int> uniqueFileIds =
        faceIds.map(getFileIdFromFaceId<int>).toSet().toList();
    final fileMap = await _filesDB.getFileIDToFileFromIDs(uniqueFileIds);

    final faces = <_TimelineFaceData>[];
    final facesByFileId = <int, Map<String, Face>>{};
    for (final faceId in faceIds) {
      final fileId = getFileIdFromFaceId<int>(faceId);
      final file = fileMap[fileId];
      if (file == null) {
        continue;
      }
      final creationTime = file.creationTime;
      if (creationTime == null || creationTime <= 0) {
        continue;
      }
      Map<String, Face>? facesForFile = facesByFileId[fileId];
      if (facesForFile == null) {
        final fetchedFaces = await _mlDataDB.getFacesForGivenFileID(fileId);
        if (fetchedFaces == null) {
          facesForFile = {};
        } else {
          facesForFile = {
            for (final face in fetchedFaces) face.faceID: face,
          };
        }
        facesByFileId[fileId] = facesForFile;
      }
      final faceDetails = facesForFile[faceId];
      final faceScore = faceDetails?.score ?? 0.0;
      final blurScore = faceDetails?.blur ?? 0.0;
      final date = DateTime.fromMicrosecondsSinceEpoch(creationTime);
      faces.add(
        _TimelineFaceData(
          faceId: faceId,
          fileId: fileId,
          creationTimeMicros: creationTime,
          year: date.year,
          score: faceScore,
          blur: blurScore,
        ),
      );
    }

    if (faces.isEmpty) {
      _logger.fine(
        "Faces timeline: person $personId has no usable faces after filtering, marking ineligible",
      );
      final timeline = FacesTimelinePersonTimeline(
        personId: personId,
        status: FacesTimelineStatus.ineligible,
        updatedAtMicros: nowMicros,
        entries: const [],
      );
      return (timeline: timeline, filesById: fileMap);
    }

    final selectionResult = await Computer.shared().compute(
      selectTimelineEntriesTask,
      param: {
        "faces": faces.map((face) => face.toJson()).toList(),
        "minYears": _minimumYears,
        "minFaces": _minimumFacesPerYear,
      },
      taskName: "faces_timeline_select_${person.remoteID}",
    );

    if (selectionResult["status"] != "ready") {
      final eligibleYearCount =
          selectionResult["eligibleYearCount"] as int? ?? 0;
      _logger.info(
        "Faces timeline: person $personId ineligible "
        "(eligibleYears=$eligibleYearCount, faces=${faces.length})",
      );
      final timeline = FacesTimelinePersonTimeline(
        personId: personId,
        status: FacesTimelineStatus.ineligible,
        updatedAtMicros: nowMicros,
        entries: const [],
      );
      return (timeline: timeline, filesById: fileMap);
    }

    final entriesJson = (selectionResult["entries"] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final entries = entriesJson
        .map(
          (entryJson) => FacesTimelineEntry(
            faceId: entryJson["faceId"] as String,
            fileId: entryJson["fileId"] as int,
            creationTimeMicros: entryJson["creationTime"] as int,
            year: entryJson["year"] as int,
          ),
        )
        .toList();

    final timeline = FacesTimelinePersonTimeline(
      personId: personId,
      status: FacesTimelineStatus.ready,
      updatedAtMicros: nowMicros,
      entries: entries,
    );

    final years =
        (selectionResult["years"] as List<dynamic>?)?.cast<int>().join(", ") ??
            "unknown";
    _logger.info(
      "Faces timeline ready for $personId "
      "(frames=${entries.length}, years=$years)",
    );

    return (timeline: timeline, filesById: fileMap);
  }

  Future<void> _ensureFaceCrops(
    PersonEntity person,
    List<FacesTimelineEntry> entries,
    Map<int, EnteFile> fileMap,
  ) async {
    final personId = person.remoteID;
    final entriesByFile = <int, List<FacesTimelineEntry>>{};
    for (final entry in entries) {
      entriesByFile.putIfAbsent(entry.fileId, () => []).add(entry);
    }

    for (final entry in entriesByFile.entries) {
      final file = fileMap[entry.key];
      if (file == null) continue;
      final faces = await _mlDataDB.getFacesForGivenFileID(entry.key);
      if (faces == null || faces.isEmpty) continue;
      final selectedFaces = entry.value
          .map(
            (timelineEntry) => faces.firstWhereOrNull(
              (face) => face.faceID == timelineEntry.faceId,
            ),
          )
          .whereType<Face>()
          .toList();
      if (selectedFaces.isEmpty) continue;
      try {
        await getCachedFaceCrops(
          file,
          selectedFaces,
          useFullFile: true,
          personOrClusterID: personId,
          useTempCache: false,
        );
      } catch (error, stackTrace) {
        _logger.warning(
          "Faces timeline: failed to cache crops for $personId file ${entry.key}",
          error,
          stackTrace,
        );
      }
    }
  }

  Future<void> _refreshReadyPersonIds() async {
    final cache = await _cacheService.getCache();
    final current = cache.allTimelines
        .where((timeline) => timeline.isReady)
        .map((timeline) => timeline.personId)
        .toSet();
    readyPersonIds.value = current;
  }
}

class _TimelineFaceData {
  final String faceId;
  final int fileId;
  final int creationTimeMicros;
  final int year;
  final double score;
  final double blur;

  const _TimelineFaceData({
    required this.faceId,
    required this.fileId,
    required this.creationTimeMicros,
    required this.year,
    required this.score,
    required this.blur,
  });

  Map<String, dynamic> toJson() => {
        "faceId": faceId,
        "fileId": fileId,
        "creationTime": creationTimeMicros,
        "year": year,
        "score": score,
        "blur": blur,
      };

  factory _TimelineFaceData.fromJson(Map<String, dynamic> json) {
    return _TimelineFaceData(
      faceId: json["faceId"] as String,
      fileId: json["fileId"] as int,
      creationTimeMicros: json["creationTime"] as int,
      year: json["year"] as int,
      score: (json["score"] as num?)?.toDouble() ?? 0.0,
      blur: (json["blur"] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasHighScore => score >= 0.8;
}

Map<String, dynamic> selectTimelineEntriesTask(Map<String, dynamic> param) {
  final facesJson =
      (param["faces"] as List<dynamic>).cast<Map<String, dynamic>>();
  final minYears = param["minYears"] as int;
  final minFacesPerYear = param["minFaces"] as int;

  final faces = facesJson.map(_TimelineFaceData.fromJson).toList();

  if (faces.isEmpty) {
    return {"status": "ineligible", "eligibleYearCount": 0};
  }

  final yearGroups = <int, List<_TimelineFaceData>>{};
  for (final face in faces) {
    yearGroups.putIfAbsent(face.year, () => []).add(face);
  }

  final eligibleEntries = yearGroups.entries
      .where((entry) => entry.value.length >= minFacesPerYear)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  if (eligibleEntries.length < minYears) {
    return {
      "status": "ineligible",
      "eligibleYearCount": eligibleEntries.length,
    };
  }

  final selected = <_TimelineFaceData>[];
  final years = <int>[];
  for (final entry in eligibleEntries) {
    entry.value.sort(
      (a, b) => a.creationTimeMicros.compareTo(b.creationTimeMicros),
    );
    years.add(entry.key);
    final picks = _pickFacesForYear(entry.value);
    selected.addAll(picks);
  }

  selected.sort((a, b) => a.creationTimeMicros.compareTo(b.creationTimeMicros));

  return {
    "status": "ready",
    "entries": selected.map((face) => face.toJson()).toList(),
    "years": years,
  };
}

List<_TimelineFaceData> _pickFacesForYear(List<_TimelineFaceData> faces) {
  if (faces.isEmpty) {
    return <_TimelineFaceData>[];
  }

  final sortedByQuality = List<_TimelineFaceData>.from(faces)
    ..sort(_compareFaceQuality);

  final picks = <_TimelineFaceData>[];
  final selectedIds = <String>{};
  final usedDayKeys = <int>{};
  final uniqueDayKeys = sortedByQuality
      .map((face) => _dayKeyForMicros(face.creationTimeMicros))
      .toSet();
  final totalUniqueDays = uniqueDayKeys.length;
  final targetUniqueDayCount = totalUniqueDays >= 4 ? 4 : totalUniqueDays;
  final allowDuplicateDays = totalUniqueDays < 4;

  if (targetUniqueDayCount > 0) {
    for (final face in sortedByQuality) {
      final dayKey = _dayKeyForMicros(face.creationTimeMicros);
      if (usedDayKeys.contains(dayKey)) {
        continue;
      }
      picks.add(face);
      selectedIds.add(face.faceId);
      usedDayKeys.add(dayKey);
      if (picks.length == targetUniqueDayCount) {
        break;
      }
    }
  }

  if (picks.length < 4) {
    for (final face in sortedByQuality) {
      if (selectedIds.contains(face.faceId)) {
        continue;
      }
      final dayKey = _dayKeyForMicros(face.creationTimeMicros);
      if (!allowDuplicateDays && usedDayKeys.contains(dayKey)) {
        continue;
      }
      picks.add(face);
      selectedIds.add(face.faceId);
      usedDayKeys.add(dayKey);
      if (picks.length == 4) {
        break;
      }
    }
  }

  picks.sort((a, b) => a.creationTimeMicros.compareTo(b.creationTimeMicros));
  return picks;
}

int _compareFaceQuality(_TimelineFaceData a, _TimelineFaceData b) {
  final highScoreComparison =
      (b.hasHighScore ? 1 : 0) - (a.hasHighScore ? 1 : 0);
  if (highScoreComparison != 0) {
    return highScoreComparison;
  }

  final scoreComparison = b.score.compareTo(a.score);
  if (scoreComparison != 0) {
    return scoreComparison;
  }

  final blurComparison = b.blur.compareTo(a.blur);
  if (blurComparison != 0) {
    return blurComparison;
  }

  return a.creationTimeMicros.compareTo(b.creationTimeMicros);
}

int _dayKeyForMicros(int micros) {
  return micros ~/ Duration.microsecondsPerDay;
}
