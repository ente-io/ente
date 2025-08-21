import "package:android_intent_plus/android_intent.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

Future<void> onTapCollectEventPhotos(BuildContext context) async {
  final String currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
  final result = await showTextInputDialog(
    context,
    title: AppLocalizations.of(context).nameTheAlbum,
    submitButtonLabel: AppLocalizations.of(context).create,
    hintText: AppLocalizations.of(context).enterAlbumName,
    alwaysShowSuccessState: false,
    initialValue: currentDate,
    textCapitalization: TextCapitalization.words,
    popnavAfterSubmission: false,
    onSubmit: (String text) async {
      // indicates user cancelled the rename request
      if (text.trim() == "") {
        return;
      }

      try {
        final Collection c =
            await CollectionsService.instance.createAlbum(text);
        await routeToPage(
          context,
          CollectionPage(
            isFromCollectPhotos: true,
            CollectionWithThumbnail(c, null),
          ),
        );
        Navigator.of(context).pop();
      } catch (e, s) {
        Logger("Collect event photos from CollectPhotosCardWidget")
            .severe("Failed to rename album", e, s);
        rethrow;
      }
    },
  );
  if (result is Exception) {
    await showGenericErrorDialog(context: context, error: result);
  }
}

Future<void> requestPermissionToOpenLinksInApp(
  BuildContext context,
  String packageName,
) async {
  final logger = Logger("in-app-links request");
  logger.info("Requesting to allow opening public links in-app");
  try {
    final choice = await showChoiceActionSheet(
      isDismissible: false,
      context,
      title: AppLocalizations.of(context).seePublicAlbumLinksInApp,
      body: AppLocalizations.of(context).allowAppToOpenSharedAlbumLinks,
      firstButtonLabel: AppLocalizations.of(context).allow,
    );
    if (choice!.action == ButtonAction.first) {
      final AndroidIntent intent;
      if (packageName == 'io.ente.photos.independent') {
        intent = const AndroidIntent(
          action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
          package: 'io.ente.photos.independent',
          data: 'package:io.ente.photos.independent',
        );
        await intent.launch();
      } else if (packageName == 'io.ente.photos.fdroid') {
        intent = const AndroidIntent(
          action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
          package: 'io.ente.photos.fdroid',
          data: 'package:io.ente.photos.fdroid',
        );
        await intent.launch();
      }
      await localSettings.setConfiguredLinksInAppPermissions(true);
      logger.info("In-app links permissions granted");
    } else {
      await localSettings.setConfiguredLinksInAppPermissions(true);
      logger.info("In-app links permissions not granted");
    }
  } catch (e) {
    logger.severe("Failed to req deeplink permission for album links", e);
  }
}
