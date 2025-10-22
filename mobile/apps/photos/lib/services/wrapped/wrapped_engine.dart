import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/wrapped/candidate_builders.dart";
import "package:photos/services/wrapped/models.dart";

final Logger _engineLogger = Logger("WrappedEngine");
final Logger _computeLogger = Logger("WrappedEngineIsolate");

/// Orchestrates the single-isolate computation pipeline for Ente Wrapped.
class WrappedEngine {
  const WrappedEngine._();

  /// Schedules the compute pipeline on a worker isolate.
  static Future<WrappedResult> compute({required int year}) async {
    final DateTime now = DateTime.now();
    _engineLogger.fine("Scheduling Wrapped compute for $year at $now");

    final _CollectedFiles collected = await _collectFilesForYear(year);
    _engineLogger.fine(
      "Collected ${collected.yearFiles.length} media items for Wrapped $year compute",
    );

    final WrappedPeopleContext peopleContext = await _collectPeopleContext(
      year: year,
      yearFiles: collected.yearFiles,
      fileByUploadedId: collected.fileByUploadedId,
    );

    return await Computer.shared().compute(
      _wrappedComputeIsolate,
      param: <String, Object?>{
        "year": year,
        "now": now,
        "files": collected.yearFiles,
        "people": peopleContext.toJson(),
      },
      taskName: "wrapped_compute_$year",
    ) as WrappedResult;
  }

  static Future<_CollectedFiles> _collectFilesForYear(int year) async {
    final List<EnteFile> allFiles =
        await SearchService.instance.getAllFilesForSearch();
    final List<EnteFile> filtered = <EnteFile>[];
    final Map<int, EnteFile> fileByUploadedId = <int, EnteFile>{};
    for (final EnteFile file in allFiles) {
      if (!file.isOwner) {
        continue;
      }
      final int? uploadedId = file.uploadedFileID;
      if (uploadedId != null) {
        fileByUploadedId[uploadedId] = file;
      }
      final int? creationTime = file.creationTime;
      if (creationTime == null) {
        continue;
      }
      final DateTime captured =
          DateTime.fromMicrosecondsSinceEpoch(creationTime);
      if (captured.year != year) {
        continue;
      }
      filtered.add(file);
    }

    filtered.sort(
      (EnteFile a, EnteFile b) {
        final int aTime = a.creationTime ?? 0;
        final int bTime = b.creationTime ?? 0;
        if (aTime != bTime) return aTime.compareTo(bTime);
        final int aId = a.uploadedFileID ?? a.generatedID ?? 0;
        final int bId = b.uploadedFileID ?? b.generatedID ?? 0;
        return aId.compareTo(bId);
      },
    );

    return _CollectedFiles(
      yearFiles: filtered,
      fileByUploadedId: fileByUploadedId,
    );
  }

  static Future<WrappedPeopleContext> _collectPeopleContext({
    required int year,
    required List<EnteFile> yearFiles,
    required Map<int, EnteFile> fileByUploadedId,
  }) async {
    if (yearFiles.isEmpty) {
      return WrappedPeopleContext.empty();
    }

    final Set<int> yearFileIDs = <int>{
      for (final EnteFile file in yearFiles)
        if (file.uploadedFileID != null) file.uploadedFileID!,
    };
    if (yearFileIDs.isEmpty) {
      return WrappedPeopleContext.empty();
    }

    final Map<int, List<FaceWithoutEmbedding>> facesByFile =
        <int, List<FaceWithoutEmbedding>>{};
    try {
      final Map<int, List<FaceWithoutEmbedding>> allFaces =
          await MLDataDB.instance.getFileIDsToFacesWithoutEmbedding();
      if (allFaces.isNotEmpty) {
        for (final MapEntry<int, List<FaceWithoutEmbedding>> entry
            in allFaces.entries) {
          if (yearFileIDs.contains(entry.key)) {
            facesByFile[entry.key] = entry.value;
          }
        }
      }
    } catch (error, stackTrace) {
      _engineLogger.warning(
        "Failed to fetch faces for Wrapped $year people context",
        error,
        stackTrace,
      );
      return WrappedPeopleContext.empty();
    }

    final Map<String, WrappedPersonEntry> personEntries =
        <String, WrappedPersonEntry>{};
    final Map<String, int> personFirstCaptureMicros = <String, int>{};
    final Map<String, String> faceIdToPerson = <String, String>{};
    final Map<String, String> faceIdToCluster = <String, String>{};

    if (PersonService.isInitialized) {
      try {
        final List<PersonEntity> persons =
            await PersonService.instance.getPersons();
        for (final PersonEntity person in persons) {
          final PersonData data = person.data;
          if (data.assigned.isEmpty) {
            continue;
          }
          final Map<String, int> clusterFaceCounts = <String, int>{};
          int? earliestMicros;
          for (final ClusterInfo cluster in data.assigned) {
            if (cluster.faces.isEmpty) {
              continue;
            }
            clusterFaceCounts[cluster.id] = cluster.faces.length;
            for (final String faceID in cluster.faces) {
              faceIdToPerson[faceID] = person.remoteID;
              faceIdToCluster[faceID] = cluster.id;
              final int? fileID = tryGetFileIdFromFaceId(faceID);
              if (fileID == null) {
                continue;
              }
              final EnteFile? file = fileByUploadedId[fileID];
              final int? captureMicros = file?.creationTime;
              if (captureMicros == null || captureMicros <= 0) {
                continue;
              }
              if (earliestMicros == null || captureMicros < earliestMicros) {
                earliestMicros = captureMicros;
              }
            }
          }
          if (clusterFaceCounts.isEmpty) {
            continue;
          }
          personEntries[person.remoteID] = WrappedPersonEntry(
            personID: person.remoteID,
            displayName: data.name,
            isHidden: data.isHidden,
            clusterFaceCounts: clusterFaceCounts,
          );
          if (earliestMicros != null) {
            personFirstCaptureMicros[person.remoteID] = earliestMicros;
          }
        }
      } catch (error, stackTrace) {
        _engineLogger.warning(
          "Failed to load persons for Wrapped $year",
          error,
          stackTrace,
        );
      }
    }

    final List<WrappedPeopleFile> peopleFiles = <WrappedPeopleFile>[];
    for (final EnteFile file in yearFiles) {
      final int? uploadedFileID = file.uploadedFileID;
      if (uploadedFileID == null) {
        continue;
      }
      final List<FaceWithoutEmbedding>? faces = facesByFile[uploadedFileID];
      if (faces == null || faces.isEmpty) {
        continue;
      }
      final List<WrappedFaceRef> faceRefs = faces
          .map(
            (FaceWithoutEmbedding face) => WrappedFaceRef(
              faceID: face.faceID,
              score: face.score,
              blur: face.blur,
              personID: faceIdToPerson[face.faceID],
              clusterID: faceIdToCluster[face.faceID],
            ),
          )
          .toList(growable: false);
      if (faceRefs.isEmpty) {
        continue;
      }
      peopleFiles.add(
        WrappedPeopleFile(
          uploadedFileID: uploadedFileID,
          captureMicros: file.creationTime ?? 0,
          faces: faceRefs,
        ),
      );
    }

    if (peopleFiles.isEmpty && personEntries.isEmpty) {
      return WrappedPeopleContext.empty();
    }

    return WrappedPeopleContext(
      files: peopleFiles,
      persons: personEntries,
      personFirstCaptureMicros: personFirstCaptureMicros,
    );
  }
}

Future<WrappedResult> _wrappedComputeIsolate(
  Map<String, Object?> args,
) async {
  final int year = args["year"] as int;
  final DateTime now = args["now"] as DateTime;
  final List<EnteFile> files =
      (args["files"] as List<dynamic>? ?? const <dynamic>[]).cast<EnteFile>();
  final Map<String, Object?> peopleRaw =
      (args["people"] as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
  final WrappedPeopleContext people = WrappedPeopleContext.fromJson(peopleRaw);

  _computeLogger.fine(
    "Wrapped compute isolate running for $year with ${files.length} media items",
  );

  final WrappedEngineContext context = WrappedEngineContext(
    year: year,
    now: now,
    files: files,
    people: people,
  );
  final List<WrappedCard> cards = <WrappedCard>[];
  for (final WrappedCandidateBuilder builder in wrappedCandidateBuilders) {
    _computeLogger.finer("Running candidate builder ${builder.debugLabel}");
    final List<WrappedCard> builtCards = await builder.build(context);
    if (builtCards.isEmpty) {
      continue;
    }
    cards.addAll(builtCards);
  }

  if (cards.isEmpty) {
    cards.add(
      WrappedCard(
        type: WrappedCardType.badge,
        title: "Wrapped $year is on its way",
        subtitle: "Full story coming soon.",
        meta: <String, Object?>{
          "generatedAt": now.toIso8601String(),
          "isStub": true,
        },
      ),
    );
  }

  return WrappedResult(
    cards: cards,
    year: year,
  );
}

class _CollectedFiles {
  _CollectedFiles({
    required List<EnteFile> yearFiles,
    required Map<int, EnteFile> fileByUploadedId,
  })  : yearFiles = List<EnteFile>.unmodifiable(yearFiles),
        fileByUploadedId = Map<int, EnteFile>.unmodifiable(fileByUploadedId);

  final List<EnteFile> yearFiles;
  final Map<int, EnteFile> fileByUploadedId;
}
