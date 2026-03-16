import "dart:math" show sqrt;
import "dart:typed_data" show Float32List, Uint8List;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/pet_vector_db.dart";
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

    // Recompute summaries for the source cluster and the new singletons so
    // incremental clustering recognises the user's corrections.
    await _recomputeClusterSummaries([
      clusterId,
      ...updates.values,
    ]);

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

    // Recompute summaries for both clusters so centroids/counts stay current.
    await _recomputeClusterSummaries([sourceClusterId, targetClusterId]);

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

  /// Recompute cluster summaries for the given cluster IDs.
  ///
  /// Queries all faces currently assigned to each cluster, fetches their
  /// embeddings, and writes an L2-normalized mean centroid + count. Clusters
  /// that are now empty get their summary deleted.
  Future<void> _recomputeClusterSummaries(List<String> clusterIds) async {
    try {
      final summaries = <String, (Uint8List, int, int)>{};
      final emptyIds = <String>[];

      for (final clusterId in clusterIds.toSet()) {
        final faceIds = await _db.getPetFaceIdsForCluster(clusterId);
        if (faceIds.isEmpty) {
          emptyIds.add(clusterId);
          continue;
        }

        final details = await _db.getPetFaceDetails(faceIds);
        final vectorIds = <int>[];
        int? species;
        for (final d in details.values) {
          species ??= d.$1;
          if (d.$2 != null) vectorIds.add(d.$2!);
        }
        if (vectorIds.isEmpty || species == null) continue;

        final vdb = PetVectorDB.forModel(
          species: species,
          isFace: true,
          offline: isOfflineMode,
        );
        final embs = await vdb.getEmbeddings(vectorIds);
        if (embs.isEmpty) continue;

        // Mean centroid, L2-normalized.
        final dim = embs.first.length;
        final centroid = Float32List(dim);
        for (final emb in embs) {
          for (int i = 0; i < dim; i++) {
            centroid[i] += emb[i];
          }
        }
        final n = embs.length.toDouble();
        double norm = 0;
        for (int i = 0; i < dim; i++) {
          centroid[i] /= n;
          norm += centroid[i] * centroid[i];
        }
        norm = sqrt(norm);
        if (norm > 0) {
          for (int i = 0; i < dim; i++) {
            centroid[i] /= norm;
          }
        }

        summaries[clusterId] = (
          centroid.buffer.asUint8List(),
          faceIds.length,
          species,
        );
      }

      for (final id in emptyIds) {
        await _db.deletePetClusterSummary(id);
      }
      if (summaries.isNotEmpty) {
        await _db.petClusterSummaryUpdate(summaries);
      }
    } catch (e, s) {
      _logger.warning("Failed to recompute cluster summaries", e, s);
    }
  }
}
