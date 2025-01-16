import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
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

        if (personEntity == null) {
          await PersonService.instance.addPerson(name: '', clusterID: personID);
        } else {
          await PersonService.instance.updateAttributes(personID, email: email);
        }
        return true;
      } catch (e) {
        _logger.severe("Failed to link email to person", e);
        await showGenericErrorDialog(context: context, error: e);
        return false;
      }
    }
  }

  Future<bool> unlinkEmailFromPerson(
    String personID,
    BuildContext context,
  ) async {
    try {
      await PersonService.instance.updateAttributes(personID, email: '');
      return true;
    } catch (e) {
      _logger.severe("Failed to unlink email from person", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
  }
}
