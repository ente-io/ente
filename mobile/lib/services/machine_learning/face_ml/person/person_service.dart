import "dart:convert";
import "dart:developer";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
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

  Future<void> reconcileClusters() async {
    final EnteWatch? w = kDebugMode ? EnteWatch("reconcileClusters") : null;
    w?.start();
    await fetchRemoteClusterFeedback();
    w?.log("Stored remote feedback");
    final dbPersonClusterInfo =
        await faceMLDataDB.getPersonToClusterIdToFaceIds();
    w?.log("Got DB person cluster info");
    final persons = await getPersonsMap();
    w?.log("Got persons");
    for (var personID in dbPersonClusterInfo.keys) {
      final person = persons[personID];
      if (person == null) {
        logger.warning("Person $personID not found");
        continue;
      }
      final personData = person.data;
      final Map<int, Set<String>> dbPersonCluster =
          dbPersonClusterInfo[personID]!;
      if (_shouldUpdateRemotePerson(personData, dbPersonCluster)) {
        final personData = person.data;
        personData.assigned = dbPersonCluster.entries
            .map(
              (e) => ClusterInfo(
                id: e.key,
                faces: e.value,
              ),
            )
            .toList();
        entityService
            .addOrUpdate(
              EntityType.person,
              json.encode(personData.toJson()),
              id: personID,
            )
            .ignore();
        personData.logStats();
      }
    }
    w?.log("Reconciled clusters for ${persons.length} persons");
  }

  bool _shouldUpdateRemotePerson(
    PersonData personData,
    Map<int, Set<String>> dbPersonCluster,
  ) {
    bool result = false;
    if ((personData.assigned?.length ?? 0) != dbPersonCluster.length) {
      log(
        "Person ${personData.name} has ${personData.assigned?.length} clusters, but ${dbPersonCluster.length} clusters found in DB",
        name: "PersonService",
      );
      result = true;
    } else {
      for (ClusterInfo info in personData.assigned!) {
        final dbCluster = dbPersonCluster[info.id];
        if (dbCluster == null) {
          log(
            "Cluster ${info.id} not found in DB for person ${personData.name}",
            name: "PersonService",
          );
          result = true;
          continue;
        }
        if (info.faces.length != dbCluster.length) {
          log(
            "Cluster ${info.id} has ${info.faces.length} faces, but ${dbCluster.length} faces found in DB",
            name: "PersonService",
          );
          result = true;
        }
        for (var faceId in info.faces) {
          if (!dbCluster.contains(faceId)) {
            log(
              "Face $faceId not found in cluster ${info.id} for person ${personData.name}",
              name: "PersonService",
            );
            result = true;
          }
        }
      }
    }
    return result;
  }

  Future<PersonEntity> addPerson(
    String name,
    int clusterID, {
    bool isHidden = false,
  }) async {
    final faceIds = await faceMLDataDB.getFaceIDsForCluster(clusterID);
    final data = PersonData(
      name: name,
      assigned: <ClusterInfo>[
        ClusterInfo(
          id: clusterID,
          faces: faceIds.toSet(),
        ),
      ],
      isHidden: isHidden,
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
    personData.logStats();
  }

  Future<void> removeFilesFromPerson({
    required PersonEntity person,
    required Set<String> faceIDs,
  }) async {
    final personData = person.data;
    final List<int> emptiedClusters = [];
    for (final cluster in personData.assigned!) {
      cluster.faces.removeWhere((faceID) => faceIDs.contains(faceID));
      if (cluster.faces.isEmpty) {
        emptiedClusters.add(cluster.id);
      }
    }

    // Safety check to make sure we haven't created an empty cluster now, if so delete it
    for (final emptyClusterID in emptiedClusters) {
      personData.assigned!
          .removeWhere((element) => element.id != emptyClusterID);
      await faceMLDataDB.removeClusterToPerson(
        personID: person.remoteID,
        clusterID: emptyClusterID,
      );
    }

    
    await entityService.addOrUpdate(
      EntityType.person,
      json.encode(personData.toJson()),
      id: person.remoteID,
    );
    personData.logStats();
  }

  Future<void> deletePerson(String personID, {bool onlyMapping = false}) async {
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
      justName.data.logStats();
    } else {
      await entityService.deleteEntry(personID);
      await faceMLDataDB.removePerson(personID);
    }

    // fire PeopleChangeEvent
    Bus.instance.fire(PeopleChangedEvent());
  }

  Future<void> fetchRemoteClusterFeedback() async {
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
            final otherPersonID = clusterToPersonID[faceIdToClusterID[faceId]!];
            if (otherPersonID != e.id) {
              final otherPerson = await getPerson(otherPersonID!);
              throw Exception(
                "Face $faceId is already assigned to person $otherPersonID (${otherPerson!.data.name}) and person ${e.id} (${personData.name})",
              );
            }
          }
          faceIdToClusterID[faceId] = cluster.id;
        }
        clusterToPersonID[cluster.id] = e.id;
      }
      if (kDebugMode) {
        logger.info(
          "Person ${e.id} ${personData.name} has ${personData.assigned!.length} clusters with $faceCount faces",
        );
      }
    }

    logger.info("Storing feedback for ${faceIdToClusterID.length} faces");
    await faceMLDataDB.updateFaceIdToClusterId(faceIdToClusterID);
    await faceMLDataDB.bulkAssignClusterToPersonID(clusterToPersonID);
  }

  Future<void> updateAttributes(
    String id, {
    String? name,
    String? avatarFaceId,
    bool? isHidden,
    int? version,
    String? birthDate,
  }) async {
    final person = (await getPerson(id))!;
    final updatedPerson = person.copyWith(
      data: person.data.copyWith(
        name: name,
        avatarFaceId: avatarFaceId,
        isHidden: isHidden,
        version: version,
        birthDate: birthDate,
      ),
    );
    await _updatePerson(updatedPerson);
  }

  Future<void> _updatePerson(PersonEntity updatePerson) async {
    await entityService.addOrUpdate(
      EntityType.person,
      json.encode(updatePerson.data.toJson()),
      id: updatePerson.remoteID,
    );
    updatePerson.data.logStats();
  }
}
