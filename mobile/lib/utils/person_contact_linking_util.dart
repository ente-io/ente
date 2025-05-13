import "package:collection/collection.dart";
import "package:flutter/widgets.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

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

Future<void> showAlreadyLinkedEmailDialog(
  BuildContext context,
  String email,
) async {
  final persons = await PersonService.instance.getPersons();
  final PersonEntity? person = persons.firstWhereOrNull(
    (person) => person.data.email == email,
  );
  if (person == null) {
    return;
  }

  await showChoiceActionSheet(
    context,
    title: 'Email already assigned',
    body: 'This email is already assigned to ${person?.data.name}.',
    firstButtonLabel: S.of(context).editPerson,
    firstButtonOnTap: () async {
      await routeToPage(
        context,
        SaveOrEditPerson(
          person.data.assigned.firstOrNull?.id,
          person: person,
          isEditing: true,
        ),
      );
    },
    isCritical: false,
  );
}
