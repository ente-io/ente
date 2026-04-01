import "dart:developer" as dev show log;
import "dart:math" show max;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:ml_linalg/vector.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/ml/face/face_with_embedding.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/services/location_service.dart";

// ---------------------------------------------------------------------------
// Strategy enums
// ---------------------------------------------------------------------------

/// How to distribute photo selection across groups to ensure variety.
enum SelectionDistribution {
  /// No grouping. Iterate the scored list greedily.
  none,

  /// Divide into N equal time-buckets and pick one per bucket.
  /// Narrow each bucket to top [preNarrowTopPercent] before picking.
  timeBuckets,

  /// Group by year, round-robin through years (recent first).
  yearRoundRobin,
}

/// How to pick the winner from a set of candidates.
enum SelectionPick {
  /// Take the highest-scored candidate that passes filters.
  ranked,

  /// Pick the candidate geographically farthest from already-selected photos.
  geographicFarthest,
}

/// How to sort the final selection.
enum SelectionSort {
  /// Oldest first.
  chronological,

  /// Newest first.
  reverseChronological,
}

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// All the parameters that control how [PhotoSelector.select] works.
class SelectionConfig {
  final int targetSize;
  final bool isOfflineMode;
  final Map<int, EmbeddingVector> fileIDToImageEmbedding;

  /// Pre-computed score per file-ID. Higher = better.
  /// For time/trip memories this is typically a combined CLIP + face score.
  /// For people memories this is CLIP nostalgia only.
  final Map<int, double> scores;

  final SelectionDistribution distribution;
  final SelectionPick pick;
  final SelectionSort sort;

  /// For [SelectionDistribution.timeBuckets]: fraction of each bucket to keep
  /// after scoring (e.g. 0.3 = top 30%). `null` means keep all.
  /// When less than 50% of a bucket has embeddings this is auto-disabled.
  final double? preNarrowTopPercent;

  /// For [SelectionDistribution.yearRoundRobin]: if true, skip the
  /// near-duplicate check on the first round (to guarantee at least one
  /// photo per year even when all photos look similar).
  final bool skipDuplicateCheckOnFirstRound;

  const SelectionConfig({
    required this.targetSize,
    required this.isOfflineMode,
    required this.fileIDToImageEmbedding,
    required this.scores,
    required this.distribution,
    required this.pick,
    required this.sort,
    this.preNarrowTopPercent,
    this.skipDuplicateCheckOnFirstRound = false,
  });
}

// ---------------------------------------------------------------------------
// PhotoSelector
// ---------------------------------------------------------------------------

class PhotoSelector {
  static const clipSimilarImageThreshold = 0.80;
  static const minimumMemoryTimeGap = Duration(minutes: 10);

  // -----------------------------------------------------------------------
  // Unified selection entry point
  // -----------------------------------------------------------------------

  /// Selects up to [config.targetSize] memories from [memories], applying the
  /// distribution, filtering, picking and sorting strategies in [config].
  ///
  /// Returns [memories] unchanged if the list is already small enough.
  static Future<List<Memory>> select(
    List<Memory> memories,
    SelectionConfig config,
  ) async {
    if (memories.length < config.targetSize) return memories;
    if (memories.length == config.targetSize &&
        config.distribution != SelectionDistribution.yearRoundRobin) {
      return memories;
    }

    final List<Memory> result;
    switch (config.distribution) {
      case SelectionDistribution.none:
        result = _selectFlat(memories, config);
      case SelectionDistribution.timeBuckets:
        result = _selectTimeBuckets(memories, config);
      case SelectionDistribution.yearRoundRobin:
        result = _selectYearRoundRobin(memories, config);
    }

    return _sortResult(result, config.sort);
  }

  // -----------------------------------------------------------------------
  // Distribution strategies
  // -----------------------------------------------------------------------

  /// Flat selection: sort by score descending, greedily iterate.
  static List<Memory> _selectFlat(
    List<Memory> memories,
    SelectionConfig config,
  ) {
    final fileCount = memories.length;
    // Sort by score descending.
    memories.sort((a, b) {
      final aID =
          memoryFileIdFromMemory(a, isOfflineMode: config.isOfflineMode);
      final bID =
          memoryFileIdFromMemory(b, isOfflineMode: config.isOfflineMode);
      return (config.scores[bID] ?? 0.0).compareTo(config.scores[aID] ?? 0.0);
    });

    final selected = <Memory>[memories.first];
    final selectedCreationTimes = <int>[];
    final firstCreationTime = memories.first.file.creationTime;
    if (firstCreationTime != null) {
      selectedCreationTimes.add(firstCreationTime);
    }
    int skipped = 0;

    for (final mem in memories.sublist(1)) {
      if (selected.length >= config.targetSize) break;
      if (!_passesFilters(
        mem,
        selected,
        selectedCreationTimes,
        config,
        fileCount: fileCount,
        skipped: skipped,
      )) {
        skipped++;
        continue;
      }
      selected.add(mem);
      final ct = mem.file.creationTime;
      if (ct != null) selectedCreationTimes.add(ct);
    }

    return selected;
  }

  /// Time-bucket selection: divide into N equal chronological buckets, pick
  /// one per bucket using nostalgia narrowing + geographic or ranked pick.
  static List<Memory> _selectTimeBuckets(
    List<Memory> memories,
    SelectionConfig config,
  ) {
    // Filter to memories with creation time and sort chronologically.
    final sorted = memories.where((m) => m.file.creationTime != null).toList()
      ..sort((a, b) => a.file.creationTime!.compareTo(b.file.creationTime!));

    if (sorted.length < config.targetSize) return sorted;

    // Divide into N equal buckets.
    final int total = sorted.length;
    final int numBuckets = config.targetSize;
    final int quotient = total ~/ numBuckets;
    final int remainder = total % numBuckets;
    final List<List<Memory>> buckets = [];
    int offset = 0;
    for (int i = 0; i < numBuckets; i++) {
      final int bucketSize = quotient + (i < remainder ? 1 : 0);
      buckets.add(sorted.sublist(offset, offset + bucketSize));
      offset += bucketSize;
    }

    final finalSelection = <Memory>[];
    for (final bucket in buckets) {
      // Score within bucket.
      final bucketFileIDs = bucket
          .map(
            (m) =>
                memoryFileIdFromMemory(m, isOfflineMode: config.isOfflineMode),
          )
          .whereType<int>()
          .toSet();
      final bucketVectors =
          getEmbeddingsForFileIDs(config.fileIDToImageEmbedding, bucketFileIDs);
      final bool littleEmbeddings = bucketVectors.length < bucket.length * 0.5;

      // Sort bucket by score descending.
      bucket.sort((a, b) {
        final aID =
            memoryFileIdFromMemory(a, isOfflineMode: config.isOfflineMode);
        final bID =
            memoryFileIdFromMemory(b, isOfflineMode: config.isOfflineMode);
        return (config.scores[bID] ?? 0.0).compareTo(config.scores[aID] ?? 0.0);
      });

      // Optionally narrow to top N%.
      List<Memory> candidates;
      if (!littleEmbeddings && config.preNarrowTopPercent != null) {
        final keep =
            max(bucket.length * config.preNarrowTopPercent!, 1).toInt();
        candidates = bucket.take(keep).toList();
      } else {
        candidates = bucket;
      }

      if (candidates.isEmpty) {
        dev.log('No candidates in bucket');
        continue;
      }

      // Filter against already-selected photos.
      if (finalSelection.isNotEmpty) {
        final filteredCandidates = excludeNearDuplicates(
          candidates,
          finalSelection,
          config.fileIDToImageEmbedding,
          isOfflineMode: config.isOfflineMode,
        );
        if (filteredCandidates.isNotEmpty) {
          candidates = filteredCandidates;
        }
        candidates = excludeTooCloseInTime(candidates, finalSelection);
      }
      if (candidates.isEmpty) continue;

      // Pick the winner.
      final winner = _pickCandidate(candidates, finalSelection, config.pick);
      finalSelection.add(winner);
    }

    return finalSelection;
  }

  /// Year-round-robin selection: group by year, sort each year by score,
  /// round-robin through years taking one at a time.
  static List<Memory> _selectYearRoundRobin(
    List<Memory> memories,
    SelectionConfig config,
  ) {
    final fileCount = memories.length;

    // Group by year.
    final yearToFiles = <int, List<Memory>>{};
    for (final mem in memories) {
      final year =
          DateTime.fromMicrosecondsSinceEpoch(mem.file.creationTime!).year;
      yearToFiles.putIfAbsent(year, () => []).add(mem);
    }

    // Sort each year's list by score descending.
    for (final yearFiles in yearToFiles.values) {
      yearFiles.sort((a, b) {
        final aID =
            memoryFileIdFromMemory(a, isOfflineMode: config.isOfflineMode);
        final bID =
            memoryFileIdFromMemory(b, isOfflineMode: config.isOfflineMode);
        return (config.scores[bID] ?? 0.0).compareTo(config.scores[aID] ?? 0.0);
      });
    }

    final years = yearToFiles.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Recent years first

    final selected = <Memory>[];
    final selectedCreationTimes = <int>[];
    int round = 0;
    int skipped = 0;

    outerLoop:
    while (selected.length + skipped < fileCount) {
      for (final year in years) {
        final yearFiles = yearToFiles[year]!;
        if (yearFiles.isEmpty) continue;
        final candidate = yearFiles.removeAt(0);
        final creationTime = candidate.file.creationTime;

        if (isTooCloseInTime(creationTime, selectedCreationTimes)) {
          skipped++;
          continue;
        }

        // On round 0 skip duplicate check to guarantee year representation.
        final bool checkDuplicates =
            !(config.skipDuplicateCheckOnFirstRound && round == 0);
        if (checkDuplicates && (fileCount - skipped) > config.targetSize) {
          final candID = memoryFileIdFromMemory(
            candidate,
            isOfflineMode: config.isOfflineMode,
          );
          final clip =
              candID == null ? null : config.fileIDToImageEmbedding[candID];
          if (clip != null) {
            bool isDuplicate = false;
            for (final sel in selected) {
              final selID = memoryFileIdFromMemory(
                sel,
                isOfflineMode: config.isOfflineMode,
              );
              final selClip =
                  selID == null ? null : config.fileIDToImageEmbedding[selID];
              if (selClip == null) continue;
              if (clip.vector.dot(selClip.vector) > clipSimilarImageThreshold) {
                isDuplicate = true;
                break;
              }
            }
            if (isDuplicate) {
              skipped++;
              continue;
            }
          }
        }

        selected.add(candidate);
        if (creationTime != null) selectedCreationTimes.add(creationTime);
        if (selected.length >= config.targetSize ||
            selected.length + skipped >= fileCount) {
          break outerLoop;
        }
      }
      round++;
      if (round > fileCount) break; // safety
    }

    return selected;
  }

  // -----------------------------------------------------------------------
  // Picking strategies
  // -----------------------------------------------------------------------

  /// Picks one candidate from the list based on the pick strategy.
  static Memory _pickCandidate(
    List<Memory> candidates,
    List<Memory> alreadySelected,
    SelectionPick pick,
  ) {
    if (candidates.length == 1 || alreadySelected.isEmpty) {
      return candidates.first;
    }

    switch (pick) {
      case SelectionPick.ranked:
        return candidates.first;

      case SelectionPick.geographicFarthest:
        double globalMaxMinDistance = 0;
        int bestIdx = 0;
        for (var i = 0; i < candidates.length; i++) {
          final mem = candidates[i];
          double minDistance = double.infinity;
          for (final selected in alreadySelected) {
            if (selected.file.location == null || mem.file.location == null) {
              continue;
            }
            final distance =
                calculateDistance(mem.file.location!, selected.file.location!);
            if (distance < minDistance) {
              minDistance = distance;
            }
          }
          if (minDistance > globalMaxMinDistance) {
            globalMaxMinDistance = minDistance;
            bestIdx = i;
          }
        }
        return candidates[bestIdx];
    }
  }

  // -----------------------------------------------------------------------
  // Shared filtering
  // -----------------------------------------------------------------------

  /// Returns true if [mem] passes time-spacing and near-duplicate filters.
  static bool _passesFilters(
    Memory mem,
    List<Memory> selected,
    List<int> selectedCreationTimes,
    SelectionConfig config, {
    required int fileCount,
    required int skipped,
  }) {
    final creationTime = mem.file.creationTime;
    if (isTooCloseInTime(creationTime, selectedCreationTimes)) {
      return false;
    }
    final memFileID =
        memoryFileIdFromMemory(mem, isOfflineMode: config.isOfflineMode);
    final clip =
        memFileID == null ? null : config.fileIDToImageEmbedding[memFileID];
    if (clip != null && (fileCount - skipped) > config.targetSize) {
      for (final selMem in selected) {
        final selID =
            memoryFileIdFromMemory(selMem, isOfflineMode: config.isOfflineMode);
        final selClip =
            selID == null ? null : config.fileIDToImageEmbedding[selID];
        if (selClip == null) continue;
        if (clip.vector.dot(selClip.vector) > clipSimilarImageThreshold) {
          return false;
        }
      }
    }
    return true;
  }

  static List<Memory> _sortResult(List<Memory> memories, SelectionSort sort) {
    switch (sort) {
      case SelectionSort.chronological:
        memories.sort(
          (a, b) => a.file.creationTime!.compareTo(b.file.creationTime!),
        );
      case SelectionSort.reverseChronological:
        memories.sort(
          (a, b) => b.file.creationTime!.compareTo(a.file.creationTime!),
        );
    }
    return memories;
  }

  // -----------------------------------------------------------------------
  // Legacy entry points (delegate to select())
  // -----------------------------------------------------------------------

  /// Creates a curated selection of memories for the People memories.
  static Future<List<Memory>> bestSelectionPeople(
    List<Memory> memories, {
    int? prefferedSize,
    required bool isOfflineMode,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    try {
      final w = (kDebugMode ? EnteWatch('getPeopleResults') : null)?..start();
      final int targetSize = prefferedSize ?? 10;
      if (memories.length <= targetSize) return memories;

      // Pre-compute nostalgia scores.
      final Map<int, double> scores = {};
      for (final mem in memories) {
        final fileID = memoryFileIdFromMemory(
          mem,
          isOfflineMode: isOfflineMode,
        );
        if (fileID == null) continue;

        final embedding = fileIDToImageEmbedding[fileID];
        if (embedding == null) continue;

        scores[fileID] = embedding.vector.dot(clipPositiveTextVector);
      }

      final result = await select(
        memories,
        SelectionConfig(
          targetSize: targetSize,
          isOfflineMode: isOfflineMode,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          scores: scores,
          distribution: SelectionDistribution.timeBuckets,
          pick: SelectionPick.geographicFarthest,
          sort: SelectionSort.reverseChronological,
          preNarrowTopPercent: 0.3,
        ),
      );

      dev.log(
        'People memories selection done, returning ${result.length} memories',
      );
      w?.log('People memories selection done');
      return result;
    } catch (e, s) {
      dev.log('Error in bestSelectionPeople $e \n $s');
      return [];
    }
  }

  /// Returns the best selection for time and trip memories.
  static Future<List<Memory>> bestSelection(
    List<Memory> memories, {
    int? prefferedSize,
    required bool isOfflineMode,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
  }) async {
    final fileCount = memories.length;
    int targetSize = prefferedSize ?? 10;
    if (fileCount <= targetSize) return memories;

    // Pre-compute combined score: face count * 1000 + CLIP nostalgia.
    // This replicates the original two-level stable sort (faces primary,
    // CLIP secondary) as a single numeric score.
    final Map<int, double> scores = {};
    for (final mem in memories) {
      final fileID = memoryFileIdFromMemory(mem, isOfflineMode: isOfflineMode);
      if (fileID == null) continue;

      // CLIP score
      final embedding = fileIDToImageEmbedding[fileID];
      final clipScore = embedding != null
          ? embedding.vector.dot(clipPositiveTextVector)
          : 0.0;

      // Face score: named faces = 10, unnamed = 1
      int faceCount = 0;
      final faces = fileIdToFaces[fileID];
      if (faces != null) {
        for (final face in faces) {
          if (faceIDsToPersonID.containsKey(face.faceID)) {
            faceCount += 10;
          } else {
            faceCount += 1;
          }
        }
      }

      scores[fileID] = faceCount * 1000.0 + clipScore;
    }

    final allYears = memories.map((e) {
      return DateTime.fromMicrosecondsSinceEpoch(e.file.creationTime!).year;
    }).toSet();

    if (allYears.length <= 1) {
      return select(
        memories,
        SelectionConfig(
          targetSize: targetSize,
          isOfflineMode: isOfflineMode,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          scores: scores,
          distribution: SelectionDistribution.none,
          pick: SelectionPick.ranked,
          sort: SelectionSort.chronological,
        ),
      );
    } else {
      // Multiple years: adjust target size for many years.
      if (prefferedSize == null && (allYears.length * 2) > 10) {
        targetSize = allYears.length * 3;
        if (fileCount < targetSize) return memories;
      }

      return select(
        memories,
        SelectionConfig(
          targetSize: targetSize,
          isOfflineMode: isOfflineMode,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          scores: scores,
          distribution: SelectionDistribution.yearRoundRobin,
          pick: SelectionPick.ranked,
          sort: SelectionSort.chronological,
          skipDuplicateCheckOnFirstRound: true,
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Utility functions (shared building blocks)
  // -----------------------------------------------------------------------

  static List<EmbeddingVector> getEmbeddingsForFileIDs(
    Map<int, EmbeddingVector> fileIDToImageEmbedding,
    Set<int> fileIDs,
  ) {
    final List<EmbeddingVector> embeddings = [];
    for (final fileID in fileIDs) {
      final embedding = fileIDToImageEmbedding[fileID];
      if (embedding != null) embeddings.add(embedding);
    }
    return embeddings;
  }

  static bool isNearDuplicate(
    int fileID,
    Iterable<int> selectedFileIDs,
    Map<int, EmbeddingVector> fileIDToImageEmbedding, {
    double similarityThreshold = clipSimilarImageThreshold,
  }) {
    final candidate = fileIDToImageEmbedding[fileID];
    if (candidate == null) return false;
    for (final selectedID in selectedFileIDs) {
      final selected = fileIDToImageEmbedding[selectedID];
      if (selected == null) continue;
      final similarity = candidate.vector.dot(selected.vector);
      if (similarity > similarityThreshold) {
        return true;
      }
    }
    return false;
  }

  static int? memoryFileId(
    EnteFile file, {
    required bool isOfflineMode,
  }) {
    return isOfflineMode ? file.generatedID : file.uploadedFileID;
  }

  static int? memoryFileIdFromMemory(
    Memory memory, {
    required bool isOfflineMode,
  }) {
    return memoryFileId(memory.file, isOfflineMode: isOfflineMode);
  }

  static bool isTooCloseInTime(
    int? creationTime,
    Iterable<int> selectedCreationTimes, {
    Duration minGap = minimumMemoryTimeGap,
  }) {
    if (creationTime == null) return false;
    final minGapMicroseconds = minGap.inMicroseconds;
    for (final selectedTime in selectedCreationTimes) {
      if ((creationTime - selectedTime).abs() < minGapMicroseconds) {
        return true;
      }
    }
    return false;
  }

  static List<Memory> filterNearDuplicates(
    List<Memory> memories,
    Map<int, EmbeddingVector> fileIDToImageEmbedding, {
    int? minKeep,
    required bool isOfflineMode,
    double similarityThreshold = clipSimilarImageThreshold,
  }) {
    if (memories.length < 2) return memories;
    final filtered = <Memory>[];
    final selectedFileIDs = <int>[];
    int skipped = 0;
    final total = memories.length;
    for (final mem in memories) {
      final fileID = memoryFileIdFromMemory(
        mem,
        isOfflineMode: isOfflineMode,
      );
      final bool shouldSkip = fileID != null &&
          isNearDuplicate(
            fileID,
            selectedFileIDs,
            fileIDToImageEmbedding,
            similarityThreshold: similarityThreshold,
          ) &&
          (minKeep == null || (total - skipped) > minKeep);
      if (shouldSkip) {
        skipped++;
        continue;
      }
      filtered.add(mem);
      if (fileID != null) {
        selectedFileIDs.add(fileID);
      }
    }
    return filtered;
  }

  static List<Memory> excludeNearDuplicates(
    List<Memory> candidates,
    List<Memory> selected,
    Map<int, EmbeddingVector> fileIDToImageEmbedding, {
    required bool isOfflineMode,
    double similarityThreshold = clipSimilarImageThreshold,
  }) {
    if (selected.isEmpty || candidates.isEmpty) return candidates;
    final selectedFileIDs = selected
        .map(
          (mem) => memoryFileIdFromMemory(
            mem,
            isOfflineMode: isOfflineMode,
          ),
        )
        .whereType<int>()
        .toList(growable: false);
    if (selectedFileIDs.isEmpty) return candidates;
    final filtered = <Memory>[];
    for (final candidate in candidates) {
      final fileID = memoryFileIdFromMemory(
        candidate,
        isOfflineMode: isOfflineMode,
      );
      if (fileID == null ||
          !isNearDuplicate(
            fileID,
            selectedFileIDs,
            fileIDToImageEmbedding,
            similarityThreshold: similarityThreshold,
          )) {
        filtered.add(candidate);
      }
    }
    return filtered;
  }

  static List<Memory> filterByTimeSpacing(
    List<Memory> memories, {
    Duration minGap = minimumMemoryTimeGap,
  }) {
    if (memories.length < 2) return memories;
    final filtered = <Memory>[];
    final selectedCreationTimes = <int>[];
    for (final mem in memories) {
      final creationTime = mem.file.creationTime;
      if (isTooCloseInTime(
        creationTime,
        selectedCreationTimes,
        minGap: minGap,
      )) {
        continue;
      }
      filtered.add(mem);
      if (creationTime != null) {
        selectedCreationTimes.add(creationTime);
      }
    }
    return filtered;
  }

  static List<Memory> excludeTooCloseInTime(
    List<Memory> candidates,
    List<Memory> selected, {
    Duration minGap = minimumMemoryTimeGap,
  }) {
    if (selected.isEmpty || candidates.isEmpty) return candidates;
    final selectedTimes = selected
        .map((mem) => mem.file.creationTime)
        .whereType<int>()
        .toList(growable: false);
    if (selectedTimes.isEmpty) return candidates;
    final filtered = <Memory>[];
    for (final candidate in candidates) {
      if (!isTooCloseInTime(
        candidate.file.creationTime,
        selectedTimes,
        minGap: minGap,
      )) {
        filtered.add(candidate);
      }
    }
    return filtered;
  }
}
