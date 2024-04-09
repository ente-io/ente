import "dart:convert";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/services/entity_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class PersonService {
  final EntityService entityService;
  final FaceMLDataDB faceMLDataDB;
  final SharedPreferences prefs;
  PersonService(this.entityService, this.faceMLDataDB, this.prefs);
  // instance
  static PersonService? _instance;
  static PersonService get instance {
    if (_instance == null) {
      throw Exception("PersonService not initialized");
    }
    return _instance!;
  }

  late Logger logger = Logger("PersonService");

  static init(
    EntityService entityService,
    FaceMLDataDB faceMLDataDB,
    SharedPreferences prefs,
  ) {
    _instance = PersonService(entityService, faceMLDataDB, prefs);
  }

  Future<List<PersonEntity>> getPersons() async {
    final entities = await entityService.getEntities(EntityType.person);
    return entities
        .map(
          (e) => PersonEntity(e.id, PersonData.fromJson(json.decode(e.data))),
        )
        .toList();
  }

  Future<PersonEntity?> getPerson(String id) {
    return entityService.getEntity(EntityType.person, id).then((e) {
      if (e == null) {
        return null;
      }
      return PersonEntity(e.id, PersonData.fromJson(json.decode(e.data)));
    });
  }

  Future<Map<String, PersonEntity>> getPersonsMap() async {
    final entities = await entityService.getEntities(EntityType.person);
    final Map<String, PersonEntity> map = {};
    for (var e in entities) {
      final person =
          PersonEntity(e.id, PersonData.fromJson(json.decode(e.data)));
      map[person.remoteID] = person;
    }
    return map;
  }

  Future<Set<String>> personIDs() async {
    final entities = await entityService.getEntities(EntityType.person);
    return entities.map((e) => e.id).toSet();
  }

  Future<PersonEntity> addPerson(String name, int clusterID) async {
    final faceIds = await faceMLDataDB.getFaceIDsForCluster(clusterID);
    final data = PersonData(
      name: name,
      assigned: <ClusterInfo>[
        ClusterInfo(
          id: clusterID,
          faces: faceIds.toSet(),
        ),
      ],
    );
    final result = await entityService.addOrUpdate(
      EntityType.person,
      json.encode(data.toJson()),
    );
    await faceMLDataDB.assignClusterToPerson(
      personID: result.id,
      clusterID: clusterID,
    );
    return PersonEntity(result.id, data);
  }

  Future<void> assignClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final person = (await getPerson(personID))!;
    final personData = person.data;
    final faceIds = await faceMLDataDB.getFaceIDsForCluster(clusterID);
    final clusterInfo = ClusterInfo(
      id: clusterID,
      faces: faceIds.toSet(),
    );
    personData.assigned!.add(clusterInfo);
    await entityService.addOrUpdate(
      EntityType.person,
      json.encode(personData.toJson()),
      id: personID,
    );
    await faceMLDataDB.assignClusterToPerson(
      personID: personID,
      clusterID: clusterID,
    );
  }

  Future<void> removeClusterToPerson({
    required String personID,
    required int clusterID,
  }) async {
    final person = (await getPerson(personID))!;
    final personData = person.data;
    personData.assigned!.removeWhere((element) => element.id != clusterID);
    await entityService.addOrUpdate(
      EntityType.person,
      json.encode(personData.toJson()),
      id: personID,
    );
    await faceMLDataDB.removeClusterToPerson(
      personID: personID,
      clusterID: clusterID,
    );
  }

  Future<void> deletePerson(String personID, {bool onlyMapping = true}) async {
    if (onlyMapping) {
      final PersonEntity? entity = await getPerson(personID);
      if (entity == null) {
        return;
      }
      final PersonEntity justName =
          PersonEntity(personID, PersonData(name: entity.data.name));
      await entityService.addOrUpdate(
        EntityType.person,
        json.encode(justName.data.toJson()),
        id: personID,
      );
      await faceMLDataDB.removePerson(personID);
    } else {
      await entityService.deleteEntry(personID);
      await faceMLDataDB.removePerson(personID);
    }

    // fire PeopleChangeEvent
    Bus.instance.fire(PeopleChangedEvent());
  }

  Future<void> storeRemoteFeedback() async {
    await entityService.syncEntities();
    final entities = await entityService.getEntities(EntityType.person);
    entities.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final Map<String, int> faceIdToClusterID = {};
    final Map<int, String> clusterToPersonID = {};
    for (var e in entities) {
      final personData = PersonData.fromJson(json.decode(e.data));
      int faceCount = 0;
      for (var cluster in personData.assigned!) {
        faceCount += cluster.faces.length;
        for (var faceId in cluster.faces) {
          if (faceIdToClusterID.containsKey(faceId)) {
            throw Exception("Face $faceId is already assigned to a cluster");
          }
          faceIdToClusterID[faceId] = cluster.id;
        }
        clusterToPersonID[cluster.id] = e.id;
      }
      if(kDebugMode) {
        logger.info(
          "Person ${e.id} ${personData.name} has ${personData.assigned!
              .length} clusters with $faceCount faces",
        );
      }
    }

    logger.info("Storing feedback for ${faceIdToClusterID.length} faces");
    await faceMLDataDB.updateClusterIdToFaceId(faceIdToClusterID);
    await faceMLDataDB.bulkAssignClusterToPersonID(clusterToPersonID);
  }

  Future<void> updatePerson(PersonEntity updatePerson) async {
    await entityService.addOrUpdate(
      EntityType.person,
      json.encode(updatePerson.data.toJson()),
      id: updatePerson.remoteID,
    );
  }
}
