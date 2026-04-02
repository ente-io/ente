import "dart:convert";

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/gateways/entity/models/type.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/ml/face/person.dart" show ClusterInfo;
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/entity_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";

/// Manages pet entities synced via the entity sync service.
class PetService {
  final EntityService entityService;
  final MLDataDB mlDataDB;
  final _logger = Logger("PetService");

  PetService(this.entityService, this.mlDataDB);

  static PetService? _instance;

  static PetService get instance {
    if (_instance == null) {
      throw Exception("PetService not initialized");
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  Future<List<PetEntity>>? _cachedPetsFuture;
  int _lastCacheRefreshTime = 0;

  static Future<void> init(
    EntityService entityService,
    MLDataDB mlDataDB,
  ) async {
    _instance = PetService(entityService, mlDataDB);
    await _instance!._refreshCache();
  }

  void clearCache() {
    _cachedPetsFuture = null;
    _lastCacheRefreshTime = 0;
  }

  Future<void> _refreshCache() async {
    _lastCacheRefreshTime = 0;
    final _ = await getPets();
  }

  int _lastRemoteSyncTime() {
    return entityService.lastSyncTime(EntityType.pet);
  }

  Future<List<PetEntity>> getPets() async {
    if (_lastCacheRefreshTime != _lastRemoteSyncTime()) {
      _lastCacheRefreshTime = _lastRemoteSyncTime();
      _cachedPetsFuture = null;
    }
    _cachedPetsFuture ??= _fetchAndCachePets();
    return _cachedPetsFuture!;
  }

  Future<List<PetEntity>> _fetchAndCachePets() async {
    _logger.finest("reading all pets from local db");
    final entities = await entityService.getEntities(EntityType.pet);
    final pets = await Computer.shared().compute(
      _decodePetEntities,
      param: {"entity": entities},
      taskName: "decode_pet_entities",
    );
    return pets;
  }

  static List<PetEntity> _decodePetEntities(Map<String, dynamic> param) {
    final entities = param["entity"] as List<LocalEntityData>;
    return entities
        .map(
          (e) => PetEntity(
            e.id,
            PetData.fromJson(json.decode(e.data)),
          ),
        )
        .toList();
  }

  Future<PetEntity?> getPet(String id) async {
    final e = await entityService.getEntity(EntityType.pet, id);
    if (e == null) return null;
    return PetEntity(e.id, PetData.fromJson(json.decode(e.data)));
  }

  Future<Map<String, PetEntity>> getPetsMap() async {
    final pets = await getPets();
    return {for (final p in pets) p.remoteID: p};
  }

  Future<PetEntity> addPet(PetData data) async {
    final result = await _addOrUpdateEntity(data.toJson());
    Bus.instance.fire(PetsChangedEvent(source: "PetService.addPet"));
    return PetEntity(result.id, data);
  }

  Future<PetEntity> updatePet(String petID, PetData data) async {
    await _addOrUpdateEntity(data.toJson(), id: petID);
    Bus.instance.fire(PetsChangedEvent(source: "PetService.updatePet"));
    return PetEntity(petID, data);
  }

  Future<void> deletePet(String petID) async {
    await entityService.deleteEntry(petID);
    _invalidateCache();
    Bus.instance.fire(PetsChangedEvent(source: "PetService.deletePet"));
  }

  /// Delete all pet entities. Used for debug reset.
  Future<void> deleteAllPets() async {
    final pets = await getPets();
    for (final pet in pets) {
      await entityService.deleteEntry(pet.remoteID);
    }
    _invalidateCache();
  }

  /// Sync pet entities from remote. Returns true if data changed.
  Future<bool> syncPets() async {
    if (isOfflineMode) {
      _logger.finest("Skip syncing pets in offline mode");
      return false;
    }
    final int changedEntities = await entityService.syncEntity(EntityType.pet);
    return changedEntities > 0;
  }

  /// Sync remote pet entities to local DB, then push local changes back.
  ///
  /// Direction 1 (remote → local): Fetch pet entities from server, update
  /// local `pet_cluster_pet` mappings and face-to-cluster assignments.
  ///
  /// Direction 2 (local → remote): Read local pet-to-cluster mappings,
  /// compare with PetData.assigned, and sync any differences to the server.
  Future<void> reconcileClusters() async {
    await fetchRemoteClusterFeedback(skipIfNoChange: false);
    await _pushLocalClustersToRemote();
  }

  /// Fetch remote pet entities and update local ML DB mappings.
  /// Returns true if remote data changed.
  Future<bool> fetchRemoteClusterFeedback({
    bool skipIfNoChange = true,
  }) async {
    if (isOfflineMode) {
      _logger.finest("Skip fetching remote pet clusters in offline mode");
      return false;
    }
    final int changedEntities = await entityService.syncEntity(EntityType.pet);
    final bool changed = changedEntities > 0;
    if (!changed && skipIfNoChange) {
      return false;
    }

    final entities = await entityService.getEntities(EntityType.pet);
    final remotePetIDs = entities.map((e) => e.id).toSet();

    // Remove local mappings for pets that no longer exist remotely
    final localMappings = await mlDataDB.getClusterToPetId();
    final localPetIds = localMappings.values.toSet();
    int removedOrphans = 0;
    for (final localPetId in localPetIds) {
      if (!remotePetIDs.contains(localPetId)) {
        // Remove all cluster mappings for this orphaned pet
        for (final entry in localMappings.entries) {
          if (entry.value == localPetId) {
            await mlDataDB.removeClusterPetId(entry.key);
            removedOrphans++;
          }
        }
      }
    }
    if (removedOrphans > 0) {
      _logger.info(
        "Removed $removedOrphans orphaned local pet cluster mappings",
      );
    }

    // Apply remote assignments to local DB
    entities.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final Map<String, String> clusterToPetId = {};
    for (final e in entities) {
      final petData = PetData.fromJson(json.decode(e.data));
      for (final cluster in petData.assigned) {
        clusterToPetId[cluster.id] = e.id;
      }
      if (kDebugMode) {
        _logger.info(
          "Pet ${e.id} ${petData.name} has ${petData.assigned.length} clusters",
        );
      }
    }

    // Remove stale local mappings: clusters locally assigned to a pet that
    // still exists remotely but whose remote assignments no longer include
    // that cluster (i.e. unmerge/unassign done on another device).
    final remoteClusterIds = clusterToPetId.keys.toSet();
    int removedStale = 0;
    for (final entry in localMappings.entries) {
      if (remotePetIDs.contains(entry.value) &&
          !remoteClusterIds.contains(entry.key)) {
        await mlDataDB.removeClusterPetId(entry.key);
        removedStale++;
      }
    }
    if (removedStale > 0) {
      _logger.info(
        "Removed $removedStale stale local pet cluster mappings",
      );
    }

    // Write all cluster-to-pet mappings
    for (final entry in clusterToPetId.entries) {
      await mlDataDB.setClusterPetId(entry.key, entry.value);
    }

    return changed;
  }

  /// Push local cluster assignments to remote PetData.assigned.
  Future<void> _pushLocalClustersToRemote() async {
    final dbPetClusterInfo = await mlDataDB.getPetToClusterIdToFaceIds();
    final pets = await getPetsMap();

    for (final petID in dbPetClusterInfo.keys) {
      final pet = pets[petID];
      if (pet == null) {
        _logger.warning("Pet $petID not found in entities, skipping");
        continue;
      }
      final dbClusters = dbPetClusterInfo[petID]!;
      final petData = pet.data;

      if (!_shouldUpdateAssigned(petData, dbClusters)) {
        continue;
      }

      petData.assigned = dbClusters.entries
          .map(
            (e) => ClusterInfo(id: e.key, faces: e.value),
          )
          .toList();

      _addOrUpdateEntity(petData.toJson(), id: petID).ignore();
      petData.logStats();
    }
  }

  bool _shouldUpdateAssigned(
    PetData petData,
    Map<String, Set<String>> dbClusters,
  ) {
    if (petData.assigned.length != dbClusters.length) return true;
    for (final info in petData.assigned) {
      final dbCluster = dbClusters[info.id];
      if (dbCluster == null) return true;
      if (info.faces.length != dbCluster.length) return true;
      for (final faceId in info.faces) {
        if (!dbCluster.contains(faceId)) return true;
      }
    }
    return false;
  }

  Future<LocalEntityData> _addOrUpdateEntity(
    Map<String, dynamic> jsonMap, {
    String? id,
  }) async {
    final result =
        await entityService.addOrUpdate(EntityType.pet, jsonMap, id: id);
    _invalidateCache();
    return result;
  }

  void _invalidateCache() {
    _lastCacheRefreshTime = 0;
    _cachedPetsFuture = null;
  }
}
