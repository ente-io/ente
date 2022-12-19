import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/theme/ente_theme.dart';
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
    final textTheme = getEnteTextTheme(context);
    final showDeletePrompt = await _anyItemPresentOnlyInCurrentAlbum(
        selectedFiles.files, collection.id);
    final String title =
        showDeletePrompt ? "Delete items?" : "Remove from album?";
    final String message1 = showDeletePrompt
        ? "Some of the selected items are present only in this album and will be deleted."
        : "Selected items will be removed from this album.";

    final String message2 = showDeletePrompt
        ? "\n\nItems which are also "
            "present in other albums will be removed from this album but will remain elsewhere."
        : "";

    final action = CupertinoActionSheet(
      title: Text(
        title,
        style: textTheme.h3Bold,
        textAlign: TextAlign.left,
      ),
      message: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: message1, style: textTheme.body),
            TextSpan(text: message2, style: textTheme.body)
          ],
        ),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            final dialog = createProgressDialog(context,
                showDeletePrompt ? "Deleting files..." : "Removing files...",);
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
          child: Text(showDeletePrompt ? "Yes, delete" : "Yes, remove"),
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

  // check if any of the file only belongs in the given collection id.
  // if true, then we need to warn the user that some of the items will be
  // deleted
  Future<bool> _anyItemPresentOnlyInCurrentAlbum(
    Set<File> files,
    int collectionID,
  ) async {
    final List<int> uploadedIDs = files
        .where((e) => e.uploadedFileID != null)
        .map((e) => e.uploadedFileID!)
        .toList();

    final Map<int, List<File>> collectionToFilesMap =
        await FilesDB.instance.getAllFilesGroupByCollectionID(uploadedIDs);
    final Set<int> ids = uploadedIDs.toSet();
    for (MapEntry<int, List<File>> entry in collectionToFilesMap.entries) {
      if (entry.key == collectionID) {
        logger.finest('ignore the collection from which remove is happening');
        continue;
      }
      ids.removeAll(entry.value.map((f) => f.uploadedFileID!).toSet());
    }
    return ids.isNotEmpty;
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
