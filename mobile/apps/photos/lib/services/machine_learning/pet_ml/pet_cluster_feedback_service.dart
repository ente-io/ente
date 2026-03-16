import "dart:math" show sqrt;
import "dart:typed_data" show Float32List;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:uuid/uuid.dart";

final _logger = Logger("PetClusterFeedbackService");

class PetClusterFeedbackService {
  PetClusterFeedbackService._();
  static final instance = PetClusterFeedbackService._();

  MLDataDB get _db =>
      isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;

  /// Remove photos from a pet cluster. Creates singleton clusters for removed
  /// faces and records "not this pet" feedback to prevent re-assignment.
  Future<void> removePetFacesFromCluster(
    List<int> fileIds,
    String clusterId,
  ) async {
    final petFaceIds =
        await _db.getPetFaceIdsForFilesInCluster(fileIds, clusterId);
    if (petFaceIds.isEmpty) return;

    // Move each face to its own new singleton cluster
    final updates = <String, String>{};
    final feedback = <(String, String)>[];
    for (final faceId in petFaceIds) {
      final newClusterId = const Uuid().v4();
      updates[faceId] = newClusterId;
      feedback.add((clusterId, faceId));
    }

    // Record feedback first so that if the app crashes between the two writes,
    // re-clustering still respects the user's correction.
    await _db.bulkInsertNotPetFeedback(feedback);
    await _db.forceUpdatePetFaceClusterIds(updates);

    _logger.info(
      "Removed ${petFaceIds.length} faces from cluster $clusterId",
    );
    Bus.instance.fire(PetsChangedEvent(source: "removePetFaces"));
  }

  /// Move photos from one pet cluster to another.
  Future<void> movePetFacesToCluster(
    List<int> fileIds,
    String sourceClusterId,
    String targetClusterId,
  ) async {
    final petFaceIds =
        await _db.getPetFaceIdsForFilesInCluster(fileIds, sourceClusterId);
    if (petFaceIds.isEmpty) return;

    // Reassign all found faces to the target cluster
    final updates = <String, String>{};
    final feedback = <(String, String)>[];
    for (final faceId in petFaceIds) {
      updates[faceId] = targetClusterId;
      feedback.add((sourceClusterId, faceId));
    }

    // Record feedback first so that if the app crashes between the two writes,
    // re-clustering still respects the user's correction.
    await _db.bulkInsertNotPetFeedback(feedback);
    await _db.forceUpdatePetFaceClusterIds(updates);

    _logger.info(
      "Moved ${petFaceIds.length} faces from $sourceClusterId to $targetClusterId",
    );
    Bus.instance.fire(PetsChangedEvent(source: "movePetFaces"));
  }

  /// Merge two pet clusters into one. Recomputes the target cluster's
  /// centroid as a weighted average of the two clusters' centroids.
  Future<void> mergePetClusters(
    String sourceId,
    String targetId,
  ) async {
    // Fetch summaries to recompute centroid
    final summaries = await _db.getAllPetClusterSummary();
    final sourceSummary = summaries[sourceId];
    final targetSummary = summaries[targetId];

    await _db.reassignAllPetFacesInCluster(sourceId, targetId);
    await _db.deletePetClusterSummary(sourceId);

    // Recompute target centroid as weighted average
    if (sourceSummary != null && targetSummary != null) {
      final srcCentroid = Float32List.view(sourceSummary.$1.buffer);
      final tgtCentroid = Float32List.view(targetSummary.$1.buffer);
      final srcCount = sourceSummary.$2;
      final tgtCount = targetSummary.$2;
      final totalCount = srcCount + tgtCount;

      if (srcCentroid.length == tgtCentroid.length && totalCount > 0) {
        final merged = Float32List(tgtCentroid.length);
        for (int i = 0; i < merged.length; i++) {
          merged[i] = (tgtCentroid[i] * tgtCount + srcCentroid[i] * srcCount) /
              totalCount;
        }
        // L2-normalize so downstream dot-product comparisons remain valid.
        double norm = 0;
        for (int i = 0; i < merged.length; i++) {
          norm += merged[i] * merged[i];
        }
        norm = sqrt(norm);
        if (norm > 0) {
          for (int i = 0; i < merged.length; i++) {
            merged[i] /= norm;
          }
        }
        final species = targetSummary.$3;
        await _db.petClusterSummaryUpdate({
          targetId: (merged.buffer.asUint8List(), totalCount, species),
        });
      }
    }

    _logger.info("Merged pet cluster $sourceId into $targetId");
    Bus.instance.fire(PetsChangedEvent(source: "mergePetClusters"));
  }
}
