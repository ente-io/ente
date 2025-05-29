import "dart:async";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/hidden_service.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/collections/album/column_item.dart";
import "package:photos/ui/collections/album/new_list_item.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/sharing/share_collection_page.dart";
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class AlbumVerticalListWidget extends StatelessWidget {
  final List<Collection> collections;
  final CollectionActionType actionType;
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final String searchQuery;
  final bool shouldShowCreateAlbum;

  AlbumVerticalListWidget(
    this.collections,
    this.actionType,
    this.selectedFiles,
    this.sharedFiles,
    this.searchQuery,
    this.shouldShowCreateAlbum, {
    super.key,
  });

  final _logger = Logger("CollectionsListWidgetState");
  final CollectionActions _collectionActions =
      CollectionActions(CollectionsService.instance);

  @override
  Widget build(BuildContext context) {
    final filesCount = sharedFiles != null
        ? sharedFiles!.length
        : selectedFiles?.files.length ?? 0;

    if (collections.isEmpty) {
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
        final item = collections[index - (shouldShowCreateAlbum ? 1 : 0)];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _albumListItemOnTap(context, item),
          child: AlbumColumnItemWidget(
            item,
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: 8,
      ),
      itemCount: collections.length + (shouldShowCreateAlbum ? 1 : 0),
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
        title: S.of(context).albumTitle,
        submitButtonLabel: S.of(context).ok,
        hintText: S.of(context).enterAlbumName,
        onSubmit: (name) async {
          return await _nameAlbum(context, name);
        },
        showOnlyLoadingState: true,
        textCapitalization: TextCapitalization.words,
        popnavAfterSubmission: false,
      );
      if (result is Exception) {
        await showGenericErrorDialog(
          context: context,
          error: result,
        );
        _logger.severe(
          "Failed to name album",
          result,
        );
      }
    } else {
      Navigator.pop(context);
      showToast(
        context,
        S.of(context).createAlbumActionHint,
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
      bool hasVerifiedLock = false;
      late final Collection? collection;

      if (actionType == CollectionActionType.moveToHiddenCollection ||
          actionType == CollectionActionType.addToHiddenAlbum) {
        collection =
            await CollectionsService.instance.createHiddenAlbum(albumName);
        hasVerifiedLock = true;
      } else {
        collection = await _createAlbum(albumName);
      }

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

          Navigator.pop(context);
          Navigator.pop(context);

          await _navigateToCollection(
            context,
            collection,
            hasVerifiedLock: hasVerifiedLock,
          );
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
    Collection item,
  ) async {
    if (await _runCollectionAction(context, item)) {
      late final String toastMessage;
      bool shouldNavigateToCollection = false;
      bool hasVerifiedLock = false;

      if (actionType == CollectionActionType.addFiles) {
        toastMessage = S.of(context).addedSuccessfullyTo(item.displayName);
        shouldNavigateToCollection = true;
      } else if (actionType == CollectionActionType.moveFiles ||
          actionType == CollectionActionType.restoreFiles ||
          actionType == CollectionActionType.unHide) {
        toastMessage = S.of(context).movedSuccessfullyTo(item.displayName);
        shouldNavigateToCollection = true;
      } else if (actionType == CollectionActionType.moveToHiddenCollection) {
        toastMessage = S.of(context).movedSuccessfullyTo(item.displayName);
        shouldNavigateToCollection = true;
        hasVerifiedLock = true;
      } else if (actionType == CollectionActionType.addToHiddenAlbum) {
        toastMessage = S.of(context).addedSuccessfullyTo(item.displayName);
        shouldNavigateToCollection = true;
        hasVerifiedLock = true;
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
        Navigator.pop(context);

        await _navigateToCollection(
          context,
          item,
          hasVerifiedLock: hasVerifiedLock,
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
      case CollectionActionType.moveToHiddenCollection:
        return _moveFilesToCollection(context, collection.id);
      case CollectionActionType.addToHiddenAlbum:
        return _addToCollection(context, collection.id, showProgressDialog);
    }
  }

  Future<void> _navigateToCollection(
    BuildContext context,
    Collection collection, {
    bool hasVerifiedLock = false,
  }) async {
    await routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(collection, null),
        hasVerifiedLock: hasVerifiedLock,
      ),
    );
  }

  Future<bool> _showShareCollectionPage(
    BuildContext context,
    Collection collection,
  ) {
    if (Configuration.instance.getUserID() == collection.owner.id) {
      unawaited(
        routeToPage(
          context,
          ShareCollectionPage(collection),
        ),
      );
    } else {
      showGenericErrorDialog(
        context: context,
        error: Exception("Can not share collection owned by others"),
      ).ignore();
      _logger.severe("Cannot share collections owned by others");
    }
    return Future.value(true);
  }

  Future<bool> _addToCollection(
    BuildContext context,
    int collectionID,
    bool showProgressDialog,
  ) async {
    final bool result = await _collectionActions.addToCollection(
      context,
      collectionID,
      showProgressDialog,
      selectedFiles: selectedFiles?.files.toList(),
      sharedFiles: sharedFiles,
    );
    if (result) {
      selectedFiles?.clearAll();
    }
    return result;
  }

  Future<bool> _moveFilesToCollection(
    BuildContext context,
    int toCollectionID,
  ) async {
    late final String message;
    if (actionType == CollectionActionType.moveFiles ||
        actionType == CollectionActionType.moveToHiddenCollection) {
      message = S.of(context).movingFilesToAlbum;
    } else {
      message = S.of(context).unhidingFilesToAlbum;
    }

    final dialog = createProgressDialog(context, message, isDismissible: true);
    await dialog.show();
    try {
      final int fromCollectionID = selectedFiles!.files.first.collectionID!;
      await CollectionsService.instance.move(
        selectedFiles!.files.toList(),
        toCollectionID: toCollectionID,
        fromCollectionID: fromCollectionID,
      );
      await dialog.hide();
      unawaited(RemoteSyncService.instance.sync(silently: true));
      selectedFiles?.clearAll();

      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      // ignore: unawaited_futures
      showErrorDialog(context, S.of(context).oops, e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
  }

  Future<bool> _restoreFilesToCollection(
    BuildContext context,
    int toCollectionID,
  ) async {
    final dialog = createProgressDialog(
      context,
      S.of(context).restoringFiles,
      isDismissible: true,
    );
    await dialog.show();
    try {
      await CollectionsService.instance
          .restore(toCollectionID, selectedFiles!.files.toList());
      unawaited(RemoteSyncService.instance.sync(silently: true));
      selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      // ignore: unawaited_futures
      showErrorDialog(context, S.of(context).oops, e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
  }
}
