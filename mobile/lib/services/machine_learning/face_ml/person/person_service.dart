import "dart:convert";

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

  Future<Map<String, PersonEntity>> getPersonsMap() async {
    final entities = await entityService.getEntities(EntityType.person);
    final Map<String, PersonEntity> map = {};
    entities.forEach((e) {
      final person =
          PersonEntity(e.id, PersonData.fromJson(json.decode(e.data)));
      map[person.remoteID] = person;
    });
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
}
