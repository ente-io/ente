import "dart:convert";

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/gateways/entity/models/type.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/ml/pet/pet_entity.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/entity_service.dart";

/// Manages pet entities synced via the entity sync service.
///
/// Reuses [EntityType.person] because PersonService migrated to
/// [EntityType.cgroup]. The "person" type slot is unused and safe for pets.
/// If a dedicated EntityType.pet is added later, a migration will be needed.
class PetService {
  final EntityService entityService;
  final _logger = Logger("PetService");

  PetService(this.entityService);

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

  static Future<void> init(EntityService entityService) async {
    _instance = PetService(entityService);
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
    return entityService.lastSyncTime(EntityType.person);
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
    final entities = await entityService.getEntities(EntityType.person);
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
    final e = await entityService.getEntity(EntityType.person, id);
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
    final int changedEntities =
        await entityService.syncEntity(EntityType.person);
    return changedEntities > 0;
  }

  Future<LocalEntityData> _addOrUpdateEntity(
    Map<String, dynamic> jsonMap, {
    String? id,
  }) async {
    final result =
        await entityService.addOrUpdate(EntityType.person, jsonMap, id: id);
    _invalidateCache();
    return result;
  }

  void _invalidateCache() {
    _lastCacheRefreshTime = 0;
    _cachedPetsFuture = null;
  }
}
