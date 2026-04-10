import "package:flutter_test/flutter_test.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memories/memories_cache.dart";
import "package:photos/models/memories/time_memory.dart";
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/smart_memories_service.dart";

EnteFile _file({
  required int id,
  required DateTime createdAt,
  Location? location,
}) {
  final file = EnteFile()
    ..uploadedFileID = id
    ..generatedID = id
    ..creationTime = createdAt.microsecondsSinceEpoch
    ..fileType = FileType.image;
  if (location != null) {
    file.location = location;
  }
  return file;
}

Vector get _positiveTextVector => Vector.fromList([1.0]);

void main() {
  group("smart memories source selection", () {
    test(
      "TripMemoriesCalculatorV2 surfaces a trip from the full source set",
      () async {
        const tripLocation = Location(latitude: 48.8566, longitude: 2.3522);
        final currentTime = DateTime.utc(2026, 4, 10);
        final fullSourceFiles = <EnteFile>[
          for (int i = 0; i < 20; i++)
            _file(
              id: i + 1,
              createdAt: DateTime.utc(
                2024,
                1,
                10 + (i ~/ 7),
                8 + (i % 7) * 2,
              ),
              location: tripLocation,
            ),
        ];
        final depletedRemainingFiles = fullSourceFiles.take(6).toList();
        final allFileIdsToFile = {
          for (final file in fullSourceFiles) file.uploadedFileID!: file,
        };

        final (fullTrips, _) = await TripMemoriesCalculatorV2.compute(
          fullSourceFiles,
          allFileIdsToFile,
          currentTime,
          <TripsShownLog>[],
          surfaceAll: true,
          cachedTripMemories: const <ToShowMemory>[],
          isOfflineMode: false,
          seenTimes: const <int, int>{},
          fileIdToFaces: const <int, List<FaceWithoutEmbedding>>{},
          faceIDsToPersonID: const <String, String>{},
          fileIDToImageEmbedding: const <int, EmbeddingVector>{},
          clipPositiveTextVector: _positiveTextVector,
          cities: const <City>[],
        );

        final (remainingTrips, _) = await TripMemoriesCalculatorV2.compute(
          depletedRemainingFiles,
          allFileIdsToFile,
          currentTime,
          <TripsShownLog>[],
          surfaceAll: true,
          cachedTripMemories: const <ToShowMemory>[],
          isOfflineMode: false,
          seenTimes: const <int, int>{},
          fileIdToFaces: const <int, List<FaceWithoutEmbedding>>{},
          faceIDsToPersonID: const <String, String>{},
          fileIDToImageEmbedding: const <int, EmbeddingVector>{},
          clipPositiveTextVector: _positiveTextVector,
          cities: const <City>[],
        );

        expect(fullTrips, hasLength(1));
        expect(fullTrips.first.memories, hasLength(10));
        expect(remainingTrips, isEmpty);
      },
    );

    test(
      "TimeMemoriesCalculator uses the full recent source for last week",
      () async {
        final currentTime = DateTime.utc(2026, 4, 10);
        final fullRecentSource = <EnteFile>[
          for (int dayOffset = 0; dayOffset < 5; dayOffset++)
            for (int photoIndex = 0; photoIndex < 4; photoIndex++)
              _file(
                id: dayOffset * 10 + photoIndex + 1,
                createdAt: DateTime.utc(
                  2026,
                  4,
                  1 + dayOffset,
                  9 + photoIndex,
                ),
              ),
        ];
        final depletedRemainingFiles = fullRecentSource.take(6).toList();

        final memories = await TimeMemoriesCalculator.computeTimeMemories(
          depletedRemainingFiles,
          currentTime,
          recentSourceFiles: fullRecentSource,
          isOfflineMode: false,
          seenTimes: const <int, int>{},
          fileIdToFaces: const <int, List<FaceWithoutEmbedding>>{},
          faceIDsToPersonID: const <String, String>{},
          fileIDToImageEmbedding: const <int, EmbeddingVector>{},
          clipPositiveTextVector: _positiveTextVector,
        );

        final lastWeekMemory = memories.firstWhere(
          (memory) => memory.kind == TimeMemoryKind.lastWeek,
        );
        final distinctDays = lastWeekMemory.memories
            .map(
              (memory) => DateTime.fromMicrosecondsSinceEpoch(
                memory.file.creationTime!,
              ).day,
            )
            .toSet();

        expect(lastWeekMemory.memories, hasLength(10));
        expect(distinctDays.length, greaterThanOrEqualTo(4));
      },
    );
  });
}
