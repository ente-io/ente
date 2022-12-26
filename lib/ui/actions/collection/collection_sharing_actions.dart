import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/api/collection/create_request.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class CollectionActions {
  final Logger logger = Logger((CollectionActions).toString());
  final CollectionsService collectionsService;

  CollectionActions(this.collectionsService);

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
        logger.severe("Failed to update shareUrl collection", e);
        showGenericErrorDialog(context);
      }
      return false;
    }
  }

  Future<Collection?> createSharedCollectionLink(
    BuildContext context,
    List<File> files,
  ) async {
    final dialog =
        createProgressDialog(context, "Creating link...", isDismissible: true);
    dialog.show();
    try {
      // create album with emptyName, use collectionCreationTime on UI to
      // show name
      logger.finest("creating album for sharing files");
      final File fileWithMinCreationTime = files.reduce(
        (a, b) => (a.creationTime ?? 0) < (b.creationTime ?? 0) ? a : b,
      );
      final File fileWithMaxCreationTime = files.reduce(
        (a, b) => (a.creationTime ?? 0) > (b.creationTime ?? 0) ? a : b,
      );
      final String dummyName = getNameForDateRange(
        fileWithMinCreationTime.creationTime!,
        fileWithMaxCreationTime.creationTime!,
      );
      final CreateRequest req =
          await collectionsService.buildCollectionCreateRequest(
        dummyName,
        visibility: visibilityVisible,
        subType: subTypeSharedFilesCollection,
      );
      final collection = await collectionsService.createAndCacheCollection(
        null,
        createRequest: req,
      );
      logger.finest("adding files to share to new album");
      await collectionsService.addToCollection(collection.id, files);
      logger.finest("creating public link for the newly created album");
      await CollectionsService.instance.createShareUrl(collection);
      dialog.hide();
      return collection;
    } catch (e, s) {
      dialog.hide();
      showGenericErrorDialog(context);
      logger.severe("Failing to create link for selected files", e, s);
    }
    return null;
  }

  // removeParticipant remove the user from a share album
  Future<bool?> removeParticipant(
    BuildContext context,
    Collection collection,
    User user,
  ) async {
    final result = await showChoiceDialog(
      context,
      "Remove?",
      "${user.email} will be removed "
          "from this shared album.\n\nAny photos and videos added by them will also be removed from the album.",
      firstAction: "Yes, remove",
      secondAction: "Cancel",
      secondActionColor: getEnteColorScheme(context).strokeBase,
      actionType: ActionType.critical,
    );
    if (result != DialogUserChoice.firstChoice) {
      return Future.value(null);
    }
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final newSharees =
          await CollectionsService.instance.unshare(collection.id, user.email);
      collection.updateSharees(newSharees);
      await dialog.hide();
      showShortToast(context, "Stopped sharing with " + user.email + ".");
      return true;
    } catch (e, s) {
      Logger("EmailItemWidget").severe(e, s);
      await dialog.hide();
      await showGenericErrorDialog(context);
      return false;
    }
  }

  Future<bool?> addEmailToCollection(
    BuildContext context,
    Collection collection,
    String email, {
    CollectionParticipantRole role = CollectionParticipantRole.viewer,
    String? publicKey,
  }) async {
    if (!isValidEmail(email)) {
      await showErrorDialog(
        context,
        "Invalid email address",
        "Please enter a valid email address.",
      );
      return null;
    } else if (email == Configuration.instance.getEmail()) {
      await showErrorDialog(context, "Oops", "You cannot share with yourself");
      return null;
    } else {
      // if (collection.getSharees().any((user) => user.email == email)) {
      //   showErrorDialog(
      //     context,
      //     "Oops",
      //     "You're already sharing this with " + email,
      //   );
      //   return null;
      // }
    }
    if (publicKey == null) {
      final dialog = createProgressDialog(context, "Searching for user...");
      await dialog.show();
      try {
        publicKey = await UserService.instance.getPublicKey(email);
        await dialog.hide();
      } catch (e) {
        logger.severe("Failed to get public key", e);
        showGenericErrorDialog(context);
        await dialog.hide();
      }
    }
    // getPublicKey can return null
    // ignore: unnecessary_null_comparison
    if (publicKey == null || publicKey == '') {
      final dialog = AlertDialog(
        title: const Text("Invite to ente?"),
        content: Text(
          "Looks like " +
              email +
              " hasn't signed up for ente yet. would you like to invite them?",
          style: const TextStyle(
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Invite",
              style: TextStyle(
                color: Theme.of(context).colorScheme.greenAlternative,
              ),
            ),
            onPressed: () {
              shareText(
                "Hey, I have some photos to share. Please install https://ente.io so that I can share them privately.",
              );
            },
          ),
        ],
      );
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
      return null;
    } else {
      final dialog = createProgressDialog(context, "Sharing...");
      await dialog.show();
      try {
        final newSharees = await CollectionsService.instance
            .share(collection.id, email, publicKey, role);
        collection.updateSharees(newSharees);
        await dialog.hide();
        showShortToast(context, "Shared successfully!");
        return true;
      } catch (e) {
        await dialog.hide();
        if (e is SharingNotPermittedForFreeAccountsError) {
          _showUnSupportedAlert(context);
        } else {
          logger.severe("failed to share collection", e);
          showGenericErrorDialog(context);
        }
        return false;
      }
    }
  }

  void _showUnSupportedAlert(BuildContext context) {
    final AlertDialog alert = AlertDialog(
      title: const Text("Sorry"),
      content: const Text(
        "Looks like your subscription has expired. Please subscribe to enable"
        " sharing.",
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
            Navigator.of(context, rootNavigator: true).pop();
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
