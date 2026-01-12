import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/create_new_album_event.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/hidden_service.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/collections/album/column_item.dart";
import "package:photos/ui/collections/album/new_list_item.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/sharing/share_collection_page.dart";
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class AlbumVerticalListWidget extends StatefulWidget {
  final List<Collection> collections;
  final List<Collection> recentCollections;
  final List<Collection> sharedCollections;
  final CollectionActionType actionType;
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final String searchQuery;
  final bool shouldShowCreateAlbum;
  final bool enableSelection;
  final List<Collection> selectedCollections;
  final Function()? onSelectionChanged;
  final List<String>? selectedPeople;

  const AlbumVerticalListWidget(
    this.collections,
    this.actionType,
    this.selectedFiles,
    this.sharedFiles,
    this.selectedPeople,
    this.searchQuery,
    this.shouldShowCreateAlbum, {
    required this.selectedCollections,
    this.recentCollections = const [],
    this.sharedCollections = const [],
    this.enableSelection = false,
    this.onSelectionChanged,
    super.key,
  });

  @override
  State<AlbumVerticalListWidget> createState() =>
      _AlbumVerticalListWidgetState();
}

class _AlbumVerticalListWidgetState extends State<AlbumVerticalListWidget> {
  final _logger = Logger("CollectionsListWidgetState");

  final CollectionActions _collectionActions =
      CollectionActions(CollectionsService.instance);

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.sharedFiles != null
        ? widget.sharedFiles!.length
        : widget.selectedPeople != null
            ? widget.selectedPeople!.length
            : widget.selectedFiles?.files.length ?? 0;

    final hasRecentCollections = widget.recentCollections.isNotEmpty;
    final hasSharedCollections = widget.sharedCollections.isNotEmpty;

    if (widget.collections.isEmpty &&
        !hasRecentCollections &&
        !hasSharedCollections) {
      if (widget.shouldShowCreateAlbum) {
        return _getNewAlbumWidget(context, filesCount);
      }
      return const EmptyState();
    }

    // Calculate item count:
    // - Create new album (optional)
    // - Recent header (if recent collections exist)
    // - Recent collections
    // - Divider (if recent collections exist and regular collections exist)
    // - All collections
    // - Shared header (if shared collections exist)
    // - Shared collections
    final createAlbumOffset = widget.shouldShowCreateAlbum ? 1 : 0;
    final recentHeaderOffset = hasRecentCollections ? 1 : 0;
    final recentItemsCount = widget.recentCollections.length;
    final showDivider = hasRecentCollections && widget.collections.isNotEmpty;
    final dividerOffset = showDivider ? 1 : 0;
    final sharedHeaderOffset = hasSharedCollections ? 1 : 0;
    final sharedItemsCount = widget.sharedCollections.length;

    final totalItemCount = createAlbumOffset +
        recentHeaderOffset +
        recentItemsCount +
        dividerOffset +
        widget.collections.length +
        sharedHeaderOffset +
        sharedItemsCount;

    return ListView.separated(
      itemBuilder: (context, index) {
        // Create new album button
        if (index == 0 && widget.shouldShowCreateAlbum) {
          return _getNewAlbumWidget(context, filesCount);
        }

        final adjustedIndex = index - createAlbumOffset;

        // Recent header
        if (hasRecentCollections && adjustedIndex == 0) {
          return _buildSectionHeader(
            context,
            AppLocalizations.of(context).recent,
          );
        }

        // Recent collections
        final recentStartIndex = recentHeaderOffset;
        if (hasRecentCollections &&
            adjustedIndex >= recentStartIndex &&
            adjustedIndex < recentStartIndex + recentItemsCount) {
          final recentIndex = adjustedIndex - recentStartIndex;
          final item = widget.recentCollections[recentIndex];
          return _buildCollectionItem(context, item);
        }

        // Divider between recent and regular collections
        final dividerIndex = recentStartIndex + recentItemsCount;
        if (showDivider && adjustedIndex == dividerIndex) {
          return _buildDivider(context);
        }

        // Regular collections
        final collectionsStartIndex =
            recentStartIndex + recentItemsCount + dividerOffset;
        final collectionsEndIndex =
            collectionsStartIndex + widget.collections.length;
        if (adjustedIndex >= collectionsStartIndex &&
            adjustedIndex < collectionsEndIndex) {
          final collectionIndex = adjustedIndex - collectionsStartIndex;
          final item = widget.collections[collectionIndex];
          return _buildCollectionItem(context, item);
        }

        // Shared header
        final sharedHeaderIndex = collectionsEndIndex;
        if (hasSharedCollections && adjustedIndex == sharedHeaderIndex) {
          return _buildSectionHeader(
            context,
            "Shared with you",
          );
        }

        // Shared collections
        final sharedStartIndex = sharedHeaderIndex + sharedHeaderOffset;
        if (hasSharedCollections && adjustedIndex >= sharedStartIndex) {
          final sharedIndex = adjustedIndex - sharedStartIndex;
          final item = widget.sharedCollections[sharedIndex];
          return _buildSharedCollectionItem(context, item);
        }

        return const SizedBox.shrink();
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: totalItemCount,
      shrinkWrap: false,
      physics: const BouncingScrollPhysics(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: textTheme.smallMuted.copyWith(color: colorScheme.textMuted),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.strokeFaint,
      ),
    );
  }

  Widget _buildCollectionItem(BuildContext context, Collection item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.enableSelection
          ? _toggleCollectionSelection(item)
          : _albumListItemOnTap(context, item),
      child: AlbumColumnItemWidget(
        item,
        selectedCollections: widget.selectedCollections,
      ),
    );
  }

  Widget _buildSharedCollectionItem(BuildContext context, Collection item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _sharedAlbumOnTap(context, item),
      child: AlbumColumnItemWidget(
        item,
        selectedCollections: widget.selectedCollections,
      ),
    );
  }

  Future<void> _sharedAlbumOnTap(
    BuildContext context,
    Collection item,
  ) async {
    // Show dialog asking if user wants to add instead of move
    final result = await showChoiceActionSheet(
      context,
      title: "Can't move to shared albums",
      body:
          "Items can only be added to shared albums, not moved. Would you like to add instead?\n\n(i) This option is shown for internal users only",
      icon: Icons.info_outline,
      firstButtonLabel: AppLocalizations.of(context).add,
      secondButtonLabel: AppLocalizations.of(context).cancel,
    );
    if (result?.action == ButtonAction.first) {
      // Perform add operation after dialog is dismissed
      final success = await _addToCollection(context, item.id, true);
      if (success) {
        showShortToast(
          context,
          AppLocalizations.of(context)
              .addedSuccessfullyTo(albumName: item.displayName),
        );
        Navigator.pop(context);
        await _navigateToCollection(context, item);
      }
    } else if (result?.action == ButtonAction.error &&
        result?.exception != null) {
      await showGenericErrorDialog(
        context: context,
        error: result!.exception,
      );
    }
  }

  Future<void> _toggleCollectionSelection(
    Collection collection,
  ) async {
    if (widget.selectedCollections.contains(collection)) {
      widget.selectedCollections.remove(collection);
    } else {
      widget.selectedCollections.isEmpty
          ? await HapticFeedback.mediumImpact()
          : null;
      widget.selectedCollections.add(collection);
    }
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!();
    }
    setState(() {});
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
        title: AppLocalizations.of(context).albumTitle,
        submitButtonLabel: AppLocalizations.of(context).ok,
        hintText: AppLocalizations.of(context).enterAlbumName,
        onSubmit: (name) async {
          return await _nameAlbum(context, name);
        },
        showOnlyLoadingState: true,
        textCapitalization: TextCapitalization.words,
        popnavAfterSubmission: true,
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
        AppLocalizations.of(context).createAlbumActionHint,
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

      if (widget.actionType == CollectionActionType.moveToHiddenCollection ||
          widget.actionType == CollectionActionType.addToHiddenAlbum) {
        collection =
            await CollectionsService.instance.createHiddenAlbum(albumName);
        hasVerifiedLock = true;
      } else {
        collection = await _createAlbum(albumName);
      }

      if (collection != null) {
        if (widget.enableSelection) {
          Bus.instance.fire(CreateNewAlbumEvent(collection));
        } else {
          if (await _runCollectionAction(
            context,
            collection,
            showProgressDialog: false,
          )) {
            if (widget.actionType == CollectionActionType.restoreFiles) {
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

      if (widget.actionType == CollectionActionType.addFiles) {
        toastMessage = AppLocalizations.of(context)
            .addedSuccessfullyTo(albumName: item.displayName);
        shouldNavigateToCollection = true;
      } else if (widget.actionType == CollectionActionType.moveFiles ||
          widget.actionType == CollectionActionType.restoreFiles ||
          widget.actionType == CollectionActionType.unHide) {
        toastMessage = AppLocalizations.of(context)
            .movedSuccessfullyTo(albumName: item.displayName);
        shouldNavigateToCollection = true;
      } else if (widget.actionType ==
          CollectionActionType.moveToHiddenCollection) {
        toastMessage = AppLocalizations.of(context)
            .movedSuccessfullyTo(albumName: item.displayName);
        shouldNavigateToCollection = true;
        hasVerifiedLock = true;
      } else if (widget.actionType == CollectionActionType.addToHiddenAlbum) {
        toastMessage = AppLocalizations.of(context)
            .addedSuccessfullyTo(albumName: item.displayName);
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
    switch (widget.actionType) {
      case CollectionActionType.addFiles:
      case CollectionActionType.addToHiddenAlbum:
      case CollectionActionType.autoAddPeople:
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
      selectedFiles: widget.selectedFiles?.files.toList(),
      sharedFiles: widget.sharedFiles,
    );
    if (result) {
      CollectionsService.instance.recordCollectionUsage(collectionID);
      widget.selectedFiles?.clearAll();
    }
    return result;
  }

  Future<bool> _moveFilesToCollection(
    BuildContext context,
    int toCollectionID,
  ) async {
    late final String message;
    if (widget.actionType == CollectionActionType.moveFiles ||
        widget.actionType == CollectionActionType.moveToHiddenCollection) {
      message = AppLocalizations.of(context).movingFilesToAlbum;
    } else {
      message = AppLocalizations.of(context).unhidingFilesToAlbum;
    }

    final dialog = createProgressDialog(context, message, isDismissible: true);
    await dialog.show();
    try {
      final int fromCollectionID =
          widget.selectedFiles!.files.first.collectionID!;
      await CollectionsService.instance.move(
        widget.selectedFiles!.files.toList(),
        toCollectionID: toCollectionID,
        fromCollectionID: fromCollectionID,
      );
      await dialog.hide();
      CollectionsService.instance.recordCollectionUsage(toCollectionID);
      unawaited(RemoteSyncService.instance.sync(silently: true));
      widget.selectedFiles?.clearAll();

      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        AppLocalizations.of(context).oops,
        e.message as String?,
      );
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
      AppLocalizations.of(context).restoringFiles,
      isDismissible: true,
    );
    await dialog.show();
    try {
      await CollectionsService.instance
          .restore(toCollectionID, widget.selectedFiles!.files.toList());
      CollectionsService.instance.recordCollectionUsage(toCollectionID);
      unawaited(RemoteSyncService.instance.sync(silently: true));
      widget.selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        AppLocalizations.of(context).oops,
        e.message as String?,
      );
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
  }
}
