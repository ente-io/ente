import "package:photos/core/configuration.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

Future<bool> isMeAssigned() async {
  final personEntities = await PersonService.instance.getPersons();
  final currentUserEmail = Configuration.instance.getEmail();

  bool isAssigned = false;
  for (final personEntity in personEntities) {
    if (personEntity.data.email == currentUserEmail) {
      isAssigned = true;
      break;
    }
  }
  return isAssigned;
}
