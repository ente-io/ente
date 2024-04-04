import "package:photos/face/db.dart";
import "package:photos/services/entity_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class PersonService {
  final EntityService entityService;
  final FaceMLDataDB faceMLDataDB;
  final SharedPreferences _prefs;
  PersonService(this.entityService, this.faceMLDataDB, this._prefs);
}
