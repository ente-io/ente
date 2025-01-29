import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

Future<bool> checkIfEmailAlreadyAssignedToAPerson(
  String email,
) async {
  final persons = await PersonService.instance.getPersons();
  for (var person in persons) {
    if (person.data.email == email) {
      return true;
    }
  }
  return false;
}
