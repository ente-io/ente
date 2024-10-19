import "dart:convert";
import "dart:developer";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/ml/face/face.dart';
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/entity_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class PersonService {
  final EntityService entityService;
  final MLDataDB faceMLDataDB;
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
    MLDataDB faceMLDataDB,
    SharedPreferences prefs,
  ) {
    _instance = PersonService(entityService, faceMLDataDB, prefs);
  }

  Future<List<PersonEntity>> getPersons() async {
    final entities = await entityService.getEntities(EntityType.cgroup);
    return entities
        .map(
          (e) => PersonEntity(e.id, PersonData.fromJson(json.decode(e.data))),
        )
        .toList();
  }

  Future<PersonEntity?> getPerson(String id) {
    return entityService.getEntity(EntityType.cgroup, id).then((e) {
      if (e == null) {
        return null;
      }
      return PersonEntity(e.id, PersonData.fromJson(json.decode(e.data)));
    });
  }

  Future<Map<String, PersonEntity>> getPersonsMap() async {
    final entities = await entityService.getEntities(EntityType.cgroup);
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
      final Map<String, Set<String>> dbPersonCluster =
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
            .addOrUpdate(EntityType.cgroup, personData.toJson(), id: personID)
            .ignore();
        personData.logStats();
      }
    }
    w?.log("Reconciled clusters for ${persons.length} persons");
  }

  bool _shouldUpdateRemotePerson(
    PersonData personData,
    Map<String, Set<String>> dbPersonCluster,
  ) {
    if ((personData.assigned?.length ?? 0) != dbPersonCluster.length) {
      log(
        "Person ${personData.name} has ${personData.assigned?.length} clusters, but ${dbPersonCluster.length} clusters found in DB",
        name: "PersonService",
      );
      return true;
    } else {
      for (ClusterInfo info in personData.assigned!) {
        final dbCluster = dbPersonCluster[info.id];
        if (dbCluster == null) {
          log(
            "Cluster ${info.id} not found in DB for person ${personData.name}",
            name: "PersonService",
          );
          return true;
        }
        if (info.faces.length != dbCluster.length) {
          log(
            "Cluster ${info.id} has ${info.faces.length} faces, but ${dbCluster.length} faces found in DB",
            name: "PersonService",
          );
          return true;
        }
        for (var faceId in info.faces) {
          if (!dbCluster.contains(faceId)) {
            log(
              "Face $faceId not found in cluster ${info.id} for person ${personData.name}",
              name: "PersonService",
            );
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<PersonEntity> addPerson(
    String name,
    String clusterID, {
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
      EntityType.cgroup,
      data.toJson(),
    );
    await faceMLDataDB.assignClusterToPerson(
      personID: result.id,
      clusterID: clusterID,
    );
    return PersonEntity(result.id, data);
  }

  Future<void> removeClusterToPerson({
    required String personID,
    required String clusterID,
  }) async {
    final person = (await getPerson(personID))!;
    final personData = person.data;
    personData.assigned!.removeWhere((element) => element.id != clusterID);
    await entityService.addOrUpdate(
      EntityType.cgroup,
      personData.toJson(),
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
    final List<String> emptiedClusters = [];
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
      EntityType.cgroup,
      personData.toJson(),
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
        EntityType.cgroup,
        justName.data.toJson(),
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
    await entityService.syncEntity(EntityType.cgroup);
    final entities = await entityService.getEntities(EntityType.cgroup);
    // todo: (neerajg) perf change, this can be expensive to do on every sync
    // especially when we have a lot of people. We should only do this when the
    // last sync time is updated for cgroup entity type. To avoid partial update,
    // we need to maintain a lastSyncTime value whenever this data is processed
    // and stored in the db.
    entities.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final Map<String, String> faceIdToClusterID = {};
    final Map<String, String> clusterToPersonID = {};
    for (var e in entities) {
      final personData = PersonData.fromJson(json.decode(e.data));
      int faceCount = 0;
      for (var cluster in personData.assigned!) {
        faceCount += cluster.faces.length;
        for (var faceId in cluster.faces) {
          if (faceIdToClusterID.containsKey(faceId)) {
            if (flagService.internalUser) {
              final otherPersonID =
                  clusterToPersonID[faceIdToClusterID[faceId]!];
              if (otherPersonID != e.id) {
                final otherPerson = await getPerson(otherPersonID!);
                logger.warning(
                  "Face $faceId is already assigned to person $otherPersonID (${otherPerson!.data.name}) and person ${e.id} (${personData.name})",
                );
              }
            }
          } else {
            faceIdToClusterID[faceId] = cluster.id;
          }
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

  Future<void> updateAvatar(PersonEntity p, EnteFile file) async {
    final Face? face = await MLDataDB.instance.getCoverFaceForPerson(
      recentFileID: file.uploadedFileID!,
      personID: p.remoteID,
    );
    if (face == null) {
      throw Exception(
        "No face found for person ${p.remoteID} in file ${file.uploadedFileID}",
      );
    }

    final person = (await getPerson(p.remoteID))!;
    final updatedPerson = person.copyWith(
      data: person.data.copyWith(avatarFaceId: face.faceID),
    );
    await _updatePerson(updatedPerson);
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
      EntityType.cgroup,
      updatePerson.data.toJson(),
      id: updatePerson.remoteID,
    );
    updatePerson.data.logStats();
  }
}
