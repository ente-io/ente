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
import "package:photos/service_locator.dart";
import "package:photos/services/faces_timeline/faces_timeline_cache_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";
import "package:photos/utils/standalone/task_queue.dart";

typedef _TimelineComputationResult = ({
  FacesTimelinePersonTimeline timeline,
  Map<int, EnteFile> filesById,
  int faceCount,
});

class FacesTimelineService {
  FacesTimelineService._internal();

  static final FacesTimelineService instance = FacesTimelineService._internal();

  static const _minimumYears = 5;
  static const _minimumFacesPerYear = 4;
  static const _minimumEligibleAgeYears = 5;
  static const _recomputeCooldown = Duration(hours: 2);
  static const _timelineLogicVersion = 2;
  static const _startupBackfillDelay = Duration(seconds: 15);
  static const _startupBackfillBatchSize = 200;

  final Logger _logger = Logger("FacesTimelineService");
  final FacesTimelineCacheService _cacheService =
      FacesTimelineCacheService.instance;
  final MLDataDB _mlDataDB = MLDataDB.instance;
  final FilesDB _filesDB = FilesDB.instance;
  final TaskQueue<String> _precomputeQueue = TaskQueue(
    maxConcurrentTasks: 1,
    taskTimeout: const Duration(minutes: 5),
    maxQueueSize: 1000,
  );

  final ValueNotifier<Set<String>> readyPersonIds = ValueNotifier<Set<String>>(
    {},
  );

  final Map<String, int> _lastForcedComputeMicros = {};
  final Map<String, _PendingRecomputeRequest> _pendingRequests = {};

  bool _initialized = false;

  StreamSubscription<PeopleChangedEvent>? _peopleChangedSubscription;
  Timer? _startupBackfillTimer;

  bool get isFeatureEnabled => flagService.facesTimeline;

  Future<void> init() async {
    if (_initialized) return;
    await _cacheService.init();
    await _cacheService.ensureComputeLogVersion(_timelineLogicVersion);
    await _refreshReadyPersonIds();
    _peopleChangedSubscription = Bus.instance.on<PeopleChangedEvent>().listen(
          _handlePeopleChange,
        );
    _scheduleStartupBackfill();
    _initialized = true;
  }

  Future<void> dispose() async {
    await _peopleChangedSubscription?.cancel();
    _startupBackfillTimer?.cancel();
    readyPersonIds.dispose();
  }

  Future<void> queueFullRecompute({
    bool force = false,
    String trigger = "",
  }) async {
    if (!isFeatureEnabled) {
      _logger.fine(
        "Faces timeline full recompute skipped ($trigger): feature disabled",
      );
      return;
    }
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
    if (!isFeatureEnabled) {
      _logger.fine(
        "Faces timeline recompute skipped for $personId ($trigger): feature disabled",
      );
      return;
    }
    if (personId.isEmpty) return;
    final normalizedTrigger = trigger.isEmpty ? "unspecified" : trigger.trim();
    final existing = _pendingRequests[personId];
    if (existing != null) {
      existing.merge(force: force, trigger: normalizedTrigger);
    } else {
      _pendingRequests[personId] = _PendingRecomputeRequest(
        force: force,
        trigger: normalizedTrigger,
      );
    }
    _precomputeQueue.addTask(personId, () async {
      final request = _pendingRequests.remove(personId) ??
          _PendingRecomputeRequest(
            force: force,
            trigger: normalizedTrigger,
          );
      await _recomputeTimelineForPerson(
        personId,
        force: request.force,
        trigger: request.trigger,
      );
    }).catchError((error, stackTrace) {
      _pendingRequests.remove(personId);
      _logger.warning(
        "Faces timeline recompute task failed to enqueue for $personId",
        error,
        stackTrace,
      );
    });
  }

  Future<FacesTimelinePersonTimeline?> getTimeline(String personId) {
    if (!isFeatureEnabled) return Future.value(null);
    return _cacheService.getTimeline(personId);
  }

  bool hasReadyTimelineSync(String personId) {
    if (!isFeatureEnabled) {
      return false;
    }
    return readyPersonIds.value.contains(personId);
  }

  Future<bool> hasReadyTimeline(String personId) async {
    if (!isFeatureEnabled) return false;
    final timeline = await _cacheService.getTimeline(personId);
    return timeline?.isReady ?? false;
  }

  Future<void> _handleIgnoredPerson(String personId) async {
    _pendingRequests.remove(personId);
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
    if (!isFeatureEnabled) {
      _logger.fine(
        "Faces timeline people change ignored (${event.type.name}): feature disabled",
      );
      return;
    }
    if (event.type == PeopleEventType.syncDone) {
      return;
    }
    unawaited(_processPeopleChange(event));
  }

  Future<void> _processPeopleChange(PeopleChangedEvent event) async {
    final person = event.person;
    if (person == null) {
      _logger.warning(
        "Faces timeline: people event ${event.type.name} missing person data",
      );
      _scheduleStartupBackfill();
      return;
    }
    if (person.data.isIgnored) {
      await _handleIgnoredPerson(person.remoteID);
      return;
    }
    final String triggerPrefix = "people_event_${event.type.name}";
    final logEntry = await _cacheService.getComputeLogEntry(person.remoteID);
    if (logEntry == null) {
      _logger.info(
        "Faces timeline: no compute log for ${person.remoteID}, forcing recompute ($triggerPrefix)",
      );
      schedulePersonRecompute(
        person.remoteID,
        force: true,
        trigger: "${triggerPrefix}_no_log",
      );
      return;
    }
    final Set<String> faceIds =
        await _mlDataDB.getFaceIDsForPerson(person.remoteID);
    final currentFaceCount = faceIds.length;
    final bool nameChanged = (logEntry.name ?? "") != person.data.name;
    final bool birthDateChanged =
        (logEntry.birthDate ?? "") != (person.data.birthDate ?? "");
    final bool faceCountChanged = logEntry.faceCount != currentFaceCount;

    if (!nameChanged && !birthDateChanged && !faceCountChanged) {
      _logger.fine(
        "Faces timeline: ${person.remoteID} change ignored "
        "(no name/dob/face count deltas)",
      );
      return;
    }

    final timeline = await _cacheService.getTimeline(person.remoteID);
    final Set<String> currentFaceIdSet = faceIds;

    if (_timelineFacesMissing(timeline, currentFaceIdSet)) {
      final trigger = "${triggerPrefix}_face_removed";
      _logger.info(
        "Faces timeline: recompute scheduled for ${person.remoteID} ($trigger)",
      );
      schedulePersonRecompute(person.remoteID, trigger: trigger);
      return;
    }

    if (birthDateChanged) {
      final trigger = "${triggerPrefix}_birthdate_changed";
      _logger.info(
        "Faces timeline: recompute scheduled for ${person.remoteID} ($trigger)",
      );
      schedulePersonRecompute(person.remoteID, trigger: trigger);
      return;
    }

    if (!faceCountChanged) {
      _logger.fine(
        "Faces timeline: ${person.remoteID} change skipped after checks "
        "(nameChanged=$nameChanged, faceCountChanged=$faceCountChanged)",
      );
      return;
    }

    final facesPerYear = await _countEligibleFacesByYear(person, faceIds);
    if (_hasNewYearWithTenFaces(timeline, facesPerYear)) {
      final trigger = "${triggerPrefix}_new_year";
      _logger.info(
        "Faces timeline: recompute scheduled for ${person.remoteID} ($trigger)",
      );
      schedulePersonRecompute(person.remoteID, trigger: trigger);
      return;
    }

    _logger.fine(
      "Faces timeline: ${person.remoteID} change skipped "
      "(nameChanged=$nameChanged, birthDateChanged=$birthDateChanged, "
      "faceCountChanged=$faceCountChanged)",
    );
  }

  void _scheduleStartupBackfill() {
    if (!isFeatureEnabled) return;
    _startupBackfillTimer?.cancel();
    _startupBackfillTimer = Timer(_startupBackfillDelay, () {
      if (!isFeatureEnabled) {
        return;
      }
      unawaited(_runStartupBackfill());
    });
  }

  Future<void> _runStartupBackfill() async {
    if (!isFeatureEnabled) return;
    if (!PersonService.isInitialized) {
      _logger.warning(
        "Faces timeline startup diff skipped: PersonService not initialized",
      );
      return;
    }
    try {
      final persons = await PersonService.instance.getPersons();
      final computeLog = await _cacheService.getComputeLog();
      final alreadyComputed = computeLog.values
          .where((entry) => entry.logicVersion == _timelineLogicVersion)
          .map((entry) => entry.personId)
          .toSet();
      final missingIds = <String>[];
      for (final person in persons) {
        if (person.data.isIgnored) continue;
        if (alreadyComputed.contains(person.remoteID)) continue;
        missingIds.add(person.remoteID);
        if (missingIds.length >= _startupBackfillBatchSize) {
          break;
        }
      }
      if (missingIds.isEmpty) {
        _logger.fine("Faces timeline startup diff: all persons covered");
        return;
      }
      for (final personId in missingIds) {
        schedulePersonRecompute(
          personId,
          force: true,
          trigger: "startup_diff",
        );
      }
      _logger.info(
        "Faces timeline startup diff queued ${missingIds.length} persons",
      );
    } catch (error, stackTrace) {
      _logger.severe(
        "Faces timeline startup diff failed",
        error,
        stackTrace,
      );
    }
  }

  Future<Map<int, int>> _countEligibleFacesByYear(
    PersonEntity person,
    Iterable<String> faceIds,
  ) async {
    if (faceIds.isEmpty) {
      return {};
    }
    final uniqueFileIds =
        faceIds.map(getFileIdFromFaceId<int>).toSet().toList();
    final fileMap = await _filesDB.getFileIDToFileFromIDs(uniqueFileIds);
    final minCreationTime = minimumEligibleCreationTimeMicros(
      person.data.birthDate,
    );
    final counts = <int, int>{};
    for (final faceId in faceIds) {
      final fileId = getFileIdFromFaceId<int>(faceId);
      final file = fileMap[fileId];
      final creationTime = file?.creationTime;
      if (creationTime == null || creationTime <= 0) {
        continue;
      }
      if (minCreationTime != null && creationTime < minCreationTime) {
        continue;
      }
      final year = DateTime.fromMicrosecondsSinceEpoch(creationTime).year;
      counts[year] = (counts[year] ?? 0) + 1;
    }
    return counts;
  }

  bool _timelineFacesMissing(
    FacesTimelinePersonTimeline? timeline,
    Set<String> currentFaceIds,
  ) {
    if (timeline == null || timeline.entries.isEmpty) {
      return false;
    }
    for (final entry in timeline.entries) {
      if (!currentFaceIds.contains(entry.faceId)) {
        return true;
      }
    }
    return false;
  }

  bool _hasNewYearWithTenFaces(
    FacesTimelinePersonTimeline? timeline,
    Map<int, int> facesPerYear,
  ) {
    if (facesPerYear.isEmpty) {
      return false;
    }
    final timelineYears =
        timeline?.entries.map((entry) => entry.year).toSet() ?? {};
    for (final entry in facesPerYear.entries) {
      if (!timelineYears.contains(entry.key) && entry.value >= 10) {
        return true;
      }
    }
    return false;
  }

  Future<void> _recomputeTimelineForPerson(
    String personId, {
    required bool force,
    required String trigger,
  }) async {
    if (!isFeatureEnabled) {
      _logger.fine(
        "Faces timeline compute skipped for $personId ($trigger): feature disabled",
      );
      return;
    }
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
      await _cacheService.upsertComputeLogEntry(
        FacesTimelineComputeLogEntry(
          personId: person.remoteID,
          name: person.data.name,
          birthDate: person.data.birthDate,
          faceCount: result.faceCount,
          lastComputedMicros: nowMicros,
          logicVersion: _timelineLogicVersion,
        ),
      );
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
    final minCreationTimeMicros =
        minimumEligibleCreationTimeMicros(person.data.birthDate);
    final faceIds = await _mlDataDB.getFaceIDsForPerson(personId);
    final totalFaceCount = faceIds.length;
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
      return (
        timeline: timeline,
        filesById: const <int, EnteFile>{},
        faceCount: totalFaceCount
      );
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

    if (minCreationTimeMicros != null) {
      faces.removeWhere(
        (face) => face.creationTimeMicros < minCreationTimeMicros,
      );
    }

    if (faces.isEmpty) {
      _logger.fine(
        "Faces timeline: person $personId has no usable faces after filtering,"
        " marking ineligible",
      );
      final timeline = FacesTimelinePersonTimeline(
        personId: personId,
        status: FacesTimelineStatus.ineligible,
        updatedAtMicros: nowMicros,
        entries: const [],
      );
      return (
        timeline: timeline,
        filesById: fileMap,
        faceCount: totalFaceCount
      );
    }

    final selectionResult = await Computer.shared().compute(
      selectTimelineEntriesTask,
      param: {
        "faces": faces.map((face) => face.toJson()).toList(),
        "minYears": _minimumYears,
        "minFaces": _minimumFacesPerYear,
        if (minCreationTimeMicros != null)
          "minCreationTime": minCreationTimeMicros,
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
      return (
        timeline: timeline,
        filesById: fileMap,
        faceCount: totalFaceCount
      );
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

    return (timeline: timeline, filesById: fileMap, faceCount: totalFaceCount);
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

  @visibleForTesting
  static int? minimumEligibleCreationTimeMicros(String? birthDateString) {
    if (birthDateString == null || birthDateString.isEmpty) {
      return null;
    }
    final birthDate = DateTime.tryParse(birthDateString);
    if (birthDate == null) {
      return null;
    }
    final targetYear = birthDate.year + _minimumEligibleAgeYears;
    final targetMonth = birthDate.month;
    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay =
        birthDate.day > daysInTargetMonth ? daysInTargetMonth : birthDate.day;
    final cutoff = DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );
    return cutoff.microsecondsSinceEpoch;
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
  final minCreationTimeMicros = param["minCreationTime"] as int?;

  final faces = facesJson.map(_TimelineFaceData.fromJson).toList();

  if (minCreationTimeMicros != null) {
    faces.removeWhere(
      (face) => face.creationTimeMicros < minCreationTimeMicros,
    );
  }

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
  final localDate = DateTime.fromMicrosecondsSinceEpoch(micros);
  return localDate.year * 10000 + localDate.month * 100 + localDate.day;
}

class _PendingRecomputeRequest {
  bool force;
  final Set<String> _triggers;

  _PendingRecomputeRequest({
    required this.force,
    required String trigger,
  }) : _triggers = {_normalizeTrigger(trigger)};

  void merge({required bool force, required String trigger}) {
    this.force = this.force || force;
    _triggers.add(_normalizeTrigger(trigger));
  }

  String get trigger => _triggers.join("|");

  static String _normalizeTrigger(String trigger) {
    final trimmed = trigger.trim();
    if (trimmed.isEmpty) return "unspecified";
    return trimmed;
  }
}
