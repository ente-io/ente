import "dart:async";

import 'package:flutter/material.dart';
import "package:fluttertoast/fluttertoast.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import 'package:photos/db/files_db.dart';
import "package:photos/events/tab_changed_event.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/collection_action_sheet.dart";
import 'package:photos/ui/components/album_list_item_widget.dart';
import 'package:photos/ui/components/new_album_list_widget.dart';
import "package:photos/ui/sharing/share_collection_page.dart";
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class CollectionsListWidget extends StatelessWidget {
  final List<CollectionWithThumbnail> collectionsWithThumbnail;
  final CollectionActionType actionType;
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final String searchQuery;
  final bool shouldShowCreateAlbum;

  CollectionsListWidget(
    this.collectionsWithThumbnail,
    this.actionType,
    this.selectedFiles,
    this.sharedFiles,
    this.searchQuery,
    this.shouldShowCreateAlbum, {
    Key? key,
  }) : super(key: key);

  final _logger = Logger("CollectionsListWidgetState");

  @override
  Widget build(BuildContext context) {
    final filesCount = sharedFiles != null
        ? sharedFiles!.length
        : selectedFiles?.files.length ?? 0;

    if (collectionsWithThumbnail.isEmpty) {
      if (shouldShowCreateAlbum) {
        return _getNewAlbumWidget(context, filesCount);
      }
      return const EmptyState();
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        if (index == 0 && shouldShowCreateAlbum) {
          return _getNewAlbumWidget(context, filesCount);
        }
        final item =
            collectionsWithThumbnail[index - (shouldShowCreateAlbum ? 1 : 0)];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _albumListItemOnTap(context, item),
          child: AlbumListItemWidget(
            item,
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: 8,
      ),
      itemCount:
          collectionsWithThumbnail.length + (shouldShowCreateAlbum ? 1 : 0),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
    );
  }

  GestureDetector _getNewAlbumWidget(BuildContext context, int filesCount) {
    return GestureDetector(
      onTap: () async {
        await _createNewAlbumOnTap(context, filesCount);
      },
      behavior: HitTestBehavior.opaque,
      child: const NewAlbumListItemWidget(),
    );
  }

  Future<void> _createNewAlbumOnTap(
    BuildContext context,
    int filesCount,
  ) async {
    if (filesCount > 0) {
      final result = await showTextInputDialog(
        context,
        title: "Album title",
        submitButtonLabel: "OK",
        hintText: "Enter album name",
        onSubmit: (name) {
          return _nameAlbum(context, name);
        },
        showOnlyLoadingState: true,
        textCapitalization: TextCapitalization.words,
      );
      if (result is Exception) {
        showGenericErrorDialog(
          context: context,
        );
        _logger.severe(
          "Failed to name album",
          result,
        );
      }
    } else {
      Navigator.pop(context);
      await showToast(
        context,
        "Long press to select photos and click + to create an album",
        toastLength: Toast.LENGTH_LONG,
      );
      Bus.instance.fire(
        TabChangedEvent(
          0,
          TabChangedEventSource.collectionsPage,
        ),
      );
    }
  }

  Future<void> _nameAlbum(BuildContext context, String albumName) async {
    if (albumName.isNotEmpty) {
      final collection = await _createAlbum(albumName);
      if (collection != null) {
        if (await _runCollectionAction(
          context,
          collection,
          showProgressDialog: false,
        )) {
          if (actionType == CollectionActionType.restoreFiles) {
            showShortToast(
              context,
              'Restored files to album ' + albumName,
            );
          } else {
            showShortToast(
              context,
              "Album '" + albumName + "' created.",
            );
          }
          _navigateToCollection(context, collection);
        }
      }
    }
  }

  Future<Collection?> _createAlbum(String albumName) async {
    Collection? collection;
    try {
      collection = await CollectionsService.instance.createAlbum(albumName);
    } catch (e, s) {
      _logger.severe("Failed to create album", e, s);
      rethrow;
    }
    return collection;
  }

  Future<void> _albumListItemOnTap(
    BuildContext context,
    CollectionWithThumbnail item,
  ) async {
    if (await _runCollectionAction(context, item.collection)) {
      late final String toastMessage;
      bool shouldNavigateToCollection = false;
      if (actionType == CollectionActionType.addFiles) {
        toastMessage = "Added successfully to " + item.collection.name!;
        shouldNavigateToCollection = true;
      } else if (actionType == CollectionActionType.moveFiles ||
          actionType == CollectionActionType.restoreFiles ||
          actionType == CollectionActionType.unHide) {
        toastMessage = "Moved successfully to " + item.collection.name!;
        shouldNavigateToCollection = true;
      } else {
        toastMessage = "";
      }
      if (toastMessage.isNotEmpty) {
        showShortToast(
          context,
          toastMessage,
        );
      }
      if (shouldNavigateToCollection) {
        _navigateToCollection(
          context,
          item.collection,
        );
      }
    }
  }

  Future<bool> _runCollectionAction(
    BuildContext context,
    Collection collection, {
    bool showProgressDialog = true,
  }) async {
    switch (actionType) {
      case CollectionActionType.addFiles:
        return _addToCollection(
          context,
          collection.id,
          showProgressDialog,
        );
      case CollectionActionType.moveFiles:
        return _moveFilesToCollection(context, collection.id);
      case CollectionActionType.unHide:
        return _moveFilesToCollection(context, collection.id);
      case CollectionActionType.restoreFiles:
        return _restoreFilesToCollection(context, collection.id);
      case CollectionActionType.shareCollection:
        return _showShareCollectionPage(context, collection);
      case CollectionActionType.collectPhotos:
        return _createCollaborativeLink(context, collection);
    }
  }

  void _navigateToCollection(BuildContext context, Collection collection) {
    Navigator.pop(context);
    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(collection, null),
      ),
    );
  }

  Future<bool> _createCollaborativeLink(
    BuildContext context,
    Collection collection,
  ) async {
    final CollectionActions collectionActions =
        CollectionActions(CollectionsService.instance);

    if (collection.hasLink) {
      if (collection.publicURLs!.first!.enableCollect) {
        if (Configuration.instance.getUserID() == collection.owner!.id) {
          unawaited(
            routeToPage(
              context,
              ShareCollectionPage(collection),
            ),
          );
        }
        showToast(context, "This album already has a collaborative link");
        return Future.value(false);
      } else {
        try {
          unawaited(
            routeToPage(
              context,
              ShareCollectionPage(collection),
            ),
          );
          CollectionsService.instance
              .updateShareUrl(collection, {'enableCollect': true}).then(
            (value) => showToast(
              context,
              "Collaborative link created for " + collection.name!,
            ),
          );
          return true;
        } catch (e) {
          showGenericErrorDialog(context: context);
          return false;
        }
      }
    }
    final bool result = await collectionActions.enableUrl(
      context,
      collection,
      enableCollect: true,
    );
    if (result) {
      showToast(
        context,
        "Collaborative link created for " + collection.name!,
      );
      if (Configuration.instance.getUserID() == collection.owner!.id) {
        unawaited(
          routeToPage(
            context,
            ShareCollectionPage(collection),
          ),
        );
      } else {
        showGenericErrorDialog(context: context);
        _logger.severe("Cannot share collections owned by others");
      }
    }
    return result;
  }

  Future<bool> _showShareCollectionPage(
    BuildContext context,
    Collection collection,
  ) {
    if (Configuration.instance.getUserID() == collection.owner!.id) {
      unawaited(
        routeToPage(
          context,
          ShareCollectionPage(collection),
        ),
      );
    } else {
      showGenericErrorDialog(context: context);
      _logger.severe("Cannot share collections owned by others");
    }
    return Future.value(true);
  }

  Future<bool> _addToCollection(
    BuildContext context,
    int collectionID,
    bool showProgressDialog,
  ) async {
    final dialog = showProgressDialog
        ? createProgressDialog(
            context,
            "Uploading files to album"
            "...",
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    try {
      final List<File> files = [];
      final List<File> filesPendingUpload = [];
      final int currentUserID = Configuration.instance.getUserID()!;
      if (sharedFiles != null) {
        filesPendingUpload.addAll(
          await convertIncomingSharedMediaToFile(
            sharedFiles!,
            collectionID,
          ),
        );
      } else {
        for (final file in selectedFiles!.files) {
          File? currentFile;
          if (file.uploadedFileID != null) {
            currentFile = file;
          } else if (file.generatedID != null) {
            // when file is not uploaded, refresh the state from the db to
            // ensure we have latest upload status for given file before
            // queueing it up as pending upload
            currentFile = await (FilesDB.instance.getFile(file.generatedID!));
          } else if (file.generatedID == null) {
            _logger.severe("generated id should not be null");
          }
          if (currentFile == null) {
            _logger.severe("Failed to find fileBy genID");
            continue;
          }
          if (currentFile.uploadedFileID == null) {
            currentFile.collectionID = collectionID;
            filesPendingUpload.add(currentFile);
          } else {
            files.add(currentFile);
          }
        }
      }
      if (filesPendingUpload.isNotEmpty) {
        // Newly created collection might not be cached
        final Collection? c =
            CollectionsService.instance.getCollectionByID(collectionID);
        if (c != null && c.owner!.id != currentUserID) {
          showToast(context, "Can not upload to albums owned by others");
          await dialog?.hide();
          return false;
        } else {
          // filesPendingUpload might be getting ignored during auto-upload
          // because the user deleted these files from ente in the past.
          await IgnoredFilesService.instance
              .removeIgnoredMappings(filesPendingUpload);
          await FilesDB.instance.insertMultiple(filesPendingUpload);
        }
      }
      if (files.isNotEmpty) {
        await CollectionsService.instance.addToCollection(collectionID, files);
      }
      RemoteSyncService.instance.sync(silently: true);
      await dialog?.hide();
      selectedFiles?.clearAll();
      return true;
    } catch (e, s) {
      _logger.severe("Failed to add to album", e, s);
      await dialog?.hide();
      showGenericErrorDialog(context: context);
      rethrow;
    }
  }

  Future<bool> _moveFilesToCollection(
    BuildContext context,
    int toCollectionID,
  ) async {
    final String message = actionType == CollectionActionType.moveFiles
        ? "Moving files to album..."
        : "Unhiding files to album";
    final dialog = createProgressDialog(context, message, isDismissible: true);
    await dialog.show();
    try {
      final int fromCollectionID = selectedFiles!.files.first.collectionID!;
      await CollectionsService.instance.move(
        toCollectionID,
        fromCollectionID,
        selectedFiles!.files.toList(),
      );
      await dialog.hide();
      RemoteSyncService.instance.sync(silently: true);
      selectedFiles?.clearAll();

      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
    }
  }

  Future<bool> _restoreFilesToCollection(
    BuildContext context,
    int toCollectionID,
  ) async {
    final dialog = createProgressDialog(
      context,
      "Restoring files...",
      isDismissible: true,
    );
    await dialog.show();
    try {
      await CollectionsService.instance
          .restore(toCollectionID, selectedFiles!.files.toList());
      RemoteSyncService.instance.sync(silently: true);
      selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
    }
  }
}
