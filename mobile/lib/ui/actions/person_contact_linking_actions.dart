import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/user_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/share_util.dart";

class PersonContactLinkingActions {
  final _logger = Logger('PersonContactLinkingActions');

  Future<bool> linkEmailToPerson(
    String email,
    String personID,
    BuildContext context,
  ) async {
    String? publicKey;

    try {
      publicKey = await UserService.instance.getPublicKey(email);
    } catch (e) {
      _logger.severe("Failed to get public key", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    // getPublicKey can return null when no user is associated with given
    // email id
    if (publicKey == null || publicKey == '') {
      await showDialogWidget(
        context: context,
        title: "No Ente account!",
        icon: Icons.info_outline,
        body: S.of(context).emailNoEnteAccount(email),
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            icon: Icons.adaptive.share,
            labelText: S.of(context).invite,
            isInAlert: true,
            onTap: () async {
              unawaited(
                shareText(
                  S.of(context).shareTextRecommendUsingEnte,
                ),
              );
            },
          ),
        ],
      );
      return false;
    } else {
      try {
        final personEntity = await PersonService.instance.getPerson(personID);
        late final PersonEntity updatedPerson;

        if (personEntity == null) {
          //Note: The idea is, email cannot be linked before a name is assigned
          //to the person.
          throw AssertionError(
            "Cannot link email to non-existent person. First save the person",
          );
        } else {
          updatedPerson = await PersonService.instance
              .updateAttributes(personID, email: email);
        }

        Bus.instance.fire(
          PeopleChangedEvent(
            type: PeopleEventType.saveOrEditPerson,
            source: "linkEmailToPerson",
            person: updatedPerson,
          ),
        );
        return true;
      } catch (e) {
        _logger.severe("Failed to link email to person", e);
        await showGenericErrorDialog(context: context, error: e);
        return false;
      }
    }
  }

  //TODO: Remove this method if not used anywhere
  Future<bool> unlinkEmailFromPerson(
    String personID,
    BuildContext context,
  ) async {
    try {
      final personEntity = await PersonService.instance.getPerson(personID);
      final name = personEntity?.data.name ?? '';
      final email = personEntity?.data.email;
      if (email == null || email.isEmpty) {
        throw Exception("Email cannot be empty");
      }
      final result = await showDialogWidget(
        context: context,
        title: name.isEmpty
            ? "Unlink email from person"
            : "Unlink email from $name",
        icon: Icons.info_outline,
        body: name.isEmpty
            ? "This will unlink $email from this person"
            : "This will unlink $email from $name",
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonAction: ButtonAction.first,
            buttonType: ButtonType.neutral,
            labelText: "Unlink",
            isInAlert: true,
            onTap: () async {
              final updatedPerson = await PersonService.instance
                  .updateAttributes(personID, email: '');
              Bus.instance.fire(
                PeopleChangedEvent(
                  type: PeopleEventType.saveOrEditPerson,
                  source: "unlinkEmailFromPerson",
                  person: updatedPerson,
                ),
              );
            },
          ),
          ButtonWidget(
            buttonAction: ButtonAction.cancel,
            buttonType: ButtonType.secondary,
            labelText: S.of(context).cancel,
            isInAlert: true,
          ),
        ],
      );

      if (result != null && result.exception != null) {
        _logger.severe("Failed to unlink email from person", result.exception);
        return false;
      } else if (result != null && result.action == ButtonAction.first) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _logger.severe("Failed to unlink email from person", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
  }

  Future<PersonEntity?> linkPersonToContact(
    BuildContext context, {
    required String emailToLink,
    required PersonEntity personEntity,
  }) async {
    final personName = personEntity.data.name;
    PersonEntity? updatedPerson;
    final result = await showDialogWidget(
      context: context,
      title: "Link person to $emailToLink",
      icon: Icons.info_outline,
      body: "This will link $personName to $emailToLink",
      isDismissible: true,
      buttons: [
        ButtonWidget(
          buttonAction: ButtonAction.first,
          buttonType: ButtonType.neutral,
          labelText: "Link",
          isInAlert: true,
          onTap: () async {
            updatedPerson = await PersonService.instance
                .updateAttributes(personEntity.remoteID, email: emailToLink);
            Bus.instance.fire(
              PeopleChangedEvent(
                type: PeopleEventType.saveOrEditPerson,
                source: "linkPersonToContact",
                person: updatedPerson,
              ),
            );
          },
        ),
        ButtonWidget(
          buttonAction: ButtonAction.cancel,
          buttonType: ButtonType.secondary,
          labelText: S.of(context).cancel,
          isInAlert: true,
        ),
      ],
    );

    if (result?.exception != null) {
      _logger.severe("Failed to link person to contact", result!.exception);
      await showGenericErrorDialog(context: context, error: result.exception);
      return null;
    } else {
      return updatedPerson;
    }
  }

  Future<void> reassignMe({
    required String currentPersonID,
    required String newPersonID,
  }) async {
    try {
      final email = Configuration.instance.getEmail();
      final updatedPerson1 = await PersonService.instance
          .updateAttributes(currentPersonID, email: '');
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "reassignMe",
          person: updatedPerson1,
        ),
      );
      final updatedPerson2 = await PersonService.instance
          .updateAttributes(newPersonID, email: email);
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "reassignMe",
          person: updatedPerson2,
        ),
      );
    } catch (e) {
      _logger.severe("Failed to reassign me", e);
      rethrow;
    }
  }
}
