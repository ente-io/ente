import "dart:typed_data" show Float32List;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/ml/pet_cluster_centroid_vector_db.dart";
import "package:photos/db/ml/pet_vector_db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/utils/ml_util.dart" show computeL2MeanCentroid;
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
    // Clear any prior "not this pet" rejection for the target cluster,
    // otherwise re-clustering would eject the face again.
    await _db.clearNotPetFeedback(targetClusterId, petFaceIds);
    await _db.forceUpdatePetFaceClusterIds(updates);

    // Recompute summaries for both clusters so centroids/counts stay current.
    await _recomputeClusterSummaries([sourceClusterId, targetClusterId]);

    _logger.info(
      "Moved ${petFaceIds.length} faces from $sourceClusterId to $targetClusterId",
    );
    Bus.instance.fire(PetsChangedEvent(source: "movePetFaces"));
  }

  /// Merge two pet clusters by mapping them to the same [PetEntity].
  ///
  /// At least one cluster must already have a named pet. If neither does,
  /// returns false (caller should prompt the user to name a pet first).
  /// Both clusters keep their faces and summaries intact — only the
  /// `pet_cluster_pet` mapping is updated so both point to the same pet.
  /// This is reversible: removing the mapping "unmerges" the cluster.
  Future<bool> mergePetClusters(
    String sourceId,
    String targetId,
  ) async {
    final mappings = await _db.getClusterToPetId();
    String? petId;
    if (mappings.containsKey(targetId)) {
      petId = mappings[targetId]!;
    } else if (mappings.containsKey(sourceId)) {
      petId = mappings[sourceId]!;
      await _db.setClusterPetId(targetId, petId);
    }

    if (petId == null) {
      _logger.info(
        "Cannot merge: neither $sourceId nor $targetId has a named pet",
      );
      return false;
    }

    // Map the source cluster to the same pet.
    await _db.setClusterPetId(sourceId, petId);

    _logger.info("Merged pet cluster $sourceId into $targetId (pet $petId)");
    Bus.instance.fire(PetsChangedEvent(source: "mergePetClusters"));
    return true;
  }

  /// Remove a cluster from a pet (unmerge). The cluster's faces and summaries
  /// are preserved — only the `pet_cluster_pet` mapping is removed.
  Future<void> unmergePetCluster(String clusterId) async {
    await _db.removeClusterPetId(clusterId);
    _logger.info("Unmerged pet cluster $clusterId");
    Bus.instance.fire(PetsChangedEvent(source: "unmergePetCluster"));
  }

  /// Recompute cluster summaries for the given cluster IDs.
  ///
  /// Queries all faces currently assigned to each cluster, fetches their
  /// embeddings, and writes an L2-normalized mean centroid to the vector DB
  /// and count/species to SQLite. Empty clusters get their summary deleted.
  Future<void> _recomputeClusterSummaries(List<String> clusterIds) async {
    try {
      final sqlSummaries = <String, (int, int)>{};
      final centroidsBySpecies = <int, Map<String, Float32List>>{};
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

        final centroid = computeL2MeanCentroid(embs);
        sqlSummaries[clusterId] = (faceIds.length, species);
        centroidsBySpecies
            .putIfAbsent(species, () => {})
            .putIfAbsent(clusterId, () => centroid);
      }

      if (emptyIds.isNotEmpty) {
        // Look up species before deleting summaries so we can target the
        // correct centroid vector DB for cleanup.
        final existingSummaries = await _db.getAllPetClusterSummary();
        final sqlDb = await _db.asyncDB;
        for (final id in emptyIds) {
          await _db.deletePetClusterSummary(id);
          final species = existingSummaries[id]?.$2;
          if (species == null) continue;
          try {
            final centroidVdb = PetClusterCentroidVectorDB.forSpecies(
              species: species,
              offline: isOfflineMode,
            );
            final idMap = await centroidVdb.getClusterCentroidVectorIdMap(
              [id],
              db: sqlDb,
            );
            if (idMap.isNotEmpty) {
              await centroidVdb.deleteCentroids(idMap.values.toList());
              await centroidVdb.deleteClusterCentroidMapping(id, db: sqlDb);
            }
          } catch (e, s) {
            _logger.warning(
              "Failed to delete centroid for emptied cluster $id",
              e,
              s,
            );
          }
        }
      }
      if (sqlSummaries.isNotEmpty) {
        await _db.petClusterSummaryUpdate(sqlSummaries);
      }

      // Write centroids to vector DB, grouped by species.
      final sqlDb = await _db.asyncDB;
      for (final entry in centroidsBySpecies.entries) {
        final centroidVdb = PetClusterCentroidVectorDB.forSpecies(
          species: entry.key,
          offline: isOfflineMode,
        );
        final idMap = await centroidVdb.getClusterCentroidVectorIdMap(
          entry.value.keys,
          db: sqlDb,
          createIfMissing: true,
        );
        final vectorIds = <int>[];
        final centroids = <Float32List>[];
        for (final ce in entry.value.entries) {
          final vectorId = idMap[ce.key];
          if (vectorId != null) {
            vectorIds.add(vectorId);
            centroids.add(ce.value);
          }
        }
        if (vectorIds.isNotEmpty) {
          await centroidVdb.bulkInsertCentroids(
            vectorIds: vectorIds,
            centroids: centroids,
          );
        }
      }
    } catch (e, s) {
      _logger.warning("Failed to recompute cluster summaries", e, s);
    }
  }
}
