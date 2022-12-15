import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

extension CollectionFileActions on CollectionActions {
  Future<void> showRemoveFromCollectionSheet(
    BuildContext context,
    Collection collection,
    SelectedFiles selectedFiles,
  ) async {
    final count = selectedFiles.files.length;
    final action = CupertinoActionSheet(
      title: Text(
        "Remove " +
            count.toString() +
            " file" +
            (count == 1 ? "" : "s") +
            " from " +
            (collection.name ?? ""),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            final dialog = createProgressDialog(context, "Removing files...");
            await dialog.show();
            try {
              await collectionsService.removeFromCollection(
                collection.id,
                selectedFiles.files.toList(),
              );
              await dialog.hide();
              selectedFiles.clearAll();
            } catch (e, s) {
              logger.severe(e, s);
              await dialog.hide();
              showGenericErrorDialog(context);
            }
          },
          child: const Text("Remove"),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    await showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  Future<bool> updateFavorites(
    BuildContext context,
    List<File> files,
    bool markAsFavorite,
  ) async {
    final ProgressDialog dialog = createProgressDialog(
      context,
      markAsFavorite ? "Adding to favorites..." : "Removing from favorites...",
    );
    await dialog.show();

    try {
      await FavoritesService.instance.updateFavorites(files, markAsFavorite);
      return true;
    } catch (e, s) {
      logger.severe(e, s);
      showShortToast(
        context,
        "Sorry, could not" +
            (markAsFavorite ? "add  to favorites!" : "remove from favorites!"),
      );
    } finally {
      await dialog.hide();
    }
    return false;
  }
}
