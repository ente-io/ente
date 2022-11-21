import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class CollectionSharingActions {
  final Logger _logger = Logger((CollectionSharingActions).toString());
  final CollectionsService collectionsService;

  CollectionSharingActions(this.collectionsService);

  Future<bool> publicLinkToggle(
    BuildContext context,
    Collection collection,
    bool enable,
  ) async {
    // confirm if user wants to disable the url
    if (!enable) {
      final choice = await showChoiceDialog(
        context,
        'Remove public link?',
        'This will remove the public link for accessing "${collection.name}".',
        firstAction: 'Yes, remove',
        secondAction: 'Cancel',
        actionType: ActionType.critical,
      );
      if (choice != DialogUserChoice.firstChoice) {
        return false;
      }
    }
    final dialog = createProgressDialog(
      context,
      enable ? "Creating link..." : "Disabling link...",
    );
    try {
      await dialog.show();
      enable
          ? await CollectionsService.instance.createShareUrl(collection)
          : await CollectionsService.instance.disableShareUrl(collection);
      dialog.hide();
      return true;
    } catch (e) {
      dialog.hide();
      if (e is SharingNotPermittedForFreeAccountsError) {
        _showUnSupportedAlert(context);
      } else {
        _logger.severe("failed to share collection", e);
        showGenericErrorDialog(context);
      }
      return false;
    }
  }

  // removeParticipant remove the user from a share album
  Future<bool> removeParticipant(
    BuildContext context,
    Collection collection,
    User user,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      await CollectionsService.instance.unshare(collection.id, user.email);
      collection.sharees!.removeWhere((u) => u!.email == user.email);
      await dialog.hide();
      showToast(context, "Stopped sharing with " + user.email + ".");
      return true;
    } catch (e, s) {
      Logger("EmailItemWidget").severe(e, s);
      await dialog.hide();
      await showGenericErrorDialog(context);
      return false;
    }
  }

  void _showUnSupportedAlert(BuildContext context) {
    final AlertDialog alert = AlertDialog(
      title: const Text("Sorry"),
      content: const Text(
        "Sharing is not permitted for free accounts, please subscribe",
      ),
      actions: [
        TextButton(
          child: Text(
            "Subscribe",
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return getSubscriptionPage();
                },
              ),
            );
          },
        ),
        TextButton(
          child: Text(
            "Ok",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
