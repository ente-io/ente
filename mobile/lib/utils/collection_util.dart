import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

Future<void> onTapCollectEventPhotos(BuildContext context) async {
  final String currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
  final result = await showTextInputDialog(
    context,
    title: S.of(context).nameTheAlbum,
    submitButtonLabel: S.of(context).create,
    hintText: S.of(context).enterAlbumName,
    alwaysShowSuccessState: false,
    initialValue: currentDate,
    textCapitalization: TextCapitalization.words,
    onSubmit: (String text) async {
      // indicates user cancelled the rename request
      if (text.trim() == "") {
        return;
      }

      try {
        final Collection c =
            await CollectionsService.instance.createAlbum(text);
        // ignore: unawaited_futures
        routeToPage(
          context,
          CollectionPage(
            isFromCollectPhotos: true,
            CollectionWithThumbnail(c, null),
          ),
        );
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
