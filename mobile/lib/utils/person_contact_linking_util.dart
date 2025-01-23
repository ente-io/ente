import "dart:io";

import "package:flutter/material.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/utils/dialog_util.dart";

Future<bool> checkIfEmailAlreadyAssignedToAPerson(
  BuildContext context,
  String email,
) async {
  final persons = await PersonService.instance.getPersons();
  for (var person in persons) {
    if (person.data.email == email) {
      await showErrorDialog(
        context,
        "Email already linked",
        "This email is already linked to a person",
        useRootNavigator: Platform.isIOS,
      );

      return true;
    }
  }
  return false;
}
