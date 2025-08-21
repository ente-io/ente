import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/sharing/add_participant_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/magic_util.dart";
import "package:photos/utils/navigation_util.dart";

class AlbumSelectionActionWidget extends StatefulWidget {
  final SelectedAlbums selectedAlbums;
  final UISectionType sectionType;

  const AlbumSelectionActionWidget(
    this.selectedAlbums,
    this.sectionType, {
    super.key,
  });

  @override
  State<AlbumSelectionActionWidget> createState() =>
      _AlbumSelectionActionWidgetState();
}

class _AlbumSelectionActionWidgetState
    extends State<AlbumSelectionActionWidget> {
  final _logger = Logger("AlbumSelectionActionWidgetState");
  late CollectionActions collectionActions;
  bool hasFavorites = false;

  @override
  initState() {
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedAlbums.addListener(_selectionChangedListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedAlbums.removeListener(_selectionChangedListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedAlbums.albums.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<SelectionActionButton> items = [];
    final hasPinnedAlbum =
        widget.selectedAlbums.albums.any((album) => album.isPinned);
    final hasUnpinnedAlbum =
        widget.selectedAlbums.albums.any((album) => !album.isPinned);

    if (widget.sectionType == UISectionType.homeCollections ||
        widget.sectionType == UISectionType.outgoingCollections) {
      items.add(
        SelectionActionButton(
          labelText: AppLocalizations.of(context).share,
          icon: Icons.adaptive.share,
          onTap: _shareCollection,
        ),
      );
      items.add(
        SelectionActionButton(
          labelText: "Pin",
          icon: Icons.push_pin_rounded,
          onTap: _onPinClick,
          shouldShow: hasUnpinnedAlbum,
        ),
      );

      items.add(
        SelectionActionButton(
          labelText: "Unpin",
          icon: CupertinoIcons.pin_slash,
          onTap: _onUnpinClick,
          shouldShow: hasPinnedAlbum,
        ),
      );

      items.add(
        SelectionActionButton(
          labelText: AppLocalizations.of(context).delete,
          icon: Icons.delete_outline,
          onTap: _trashCollection,
        ),
      );
      items.add(
        SelectionActionButton(
          labelText: AppLocalizations.of(context).hide,
          icon: Icons.visibility_off_outlined,
          onTap: _onHideClick,
        ),
      );
    }

    items.add(
      SelectionActionButton(
        labelText: AppLocalizations.of(context).archive,
        icon: Icons.archive_outlined,
        onTap: _archiveClick,
      ),
    );

    if (widget.sectionType == UISectionType.incomingCollections) {
      items.add(
        SelectionActionButton(
          labelText: AppLocalizations.of(context).leaveAlbum,
          icon: Icons.logout,
          onTap: _leaveAlbum,
        ),
      );
    }

    final scrollController = ScrollController();

    return MediaQuery(
      data: MediaQuery.of(context).removePadding(removeBottom: true),
      child: SafeArea(
        child: Scrollbar(
          radius: const Radius.circular(1),
          thickness: 2,
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  ...items,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareCollection() async {
    await routeToPage(
      context,
      AddParticipantPage(
        widget.selectedAlbums.albums.toList(),
        const [ActionTypesToShow.addViewer, ActionTypesToShow.addCollaborator],
      ),
    );
    widget.selectedAlbums.clearAll();
  }

  Future<void> _trashCollection() async {
    int count = 0;
    final List<Collection> nonEmptyCollection = [];

    final List errors = [];
    for (final collection in widget.selectedAlbums.albums) {
      if (collection.type == CollectionType.favorites) {
        continue;
      }
      count = await FilesDB.instance.collectionFileCount(collection.id);
      final bool isEmptyCollection = count == 0;
      if (isEmptyCollection) {
        try {
          await CollectionsService.instance.trashEmptyCollection(collection);
        } catch (e, s) {
          _logger.warning("failed to trash collection", e, s);
          errors.add(e);
        }
      } else {
        nonEmptyCollection.add(collection);
      }
    }
    if (errors.isNotEmpty) {
      await showGenericErrorDialog(
        context: context,
        error: errors.first,
      );
    }

    if (nonEmptyCollection.isNotEmpty) {
      final bool result = await collectionActions.deleteMultipleCollectionSheet(
        context,
        nonEmptyCollection,
      );
      if (result == false) {
        debugPrint("Failed to delete collection");
      }
    }
    if (hasFavorites) {
      _showFavToast();
    }
    widget.selectedAlbums.clearAll();
  }

  Future<void> _onPinClick() async {
    for (final collection in widget.selectedAlbums.albums) {
      if (collection.type == CollectionType.favorites || collection.isPinned) {
        continue;
      }

      await updateOrder(
        context,
        collection,
        collection.isPinned ? 1 : 1,
      );
    }
    if (hasFavorites) {
      _showFavToast();
    }
    widget.selectedAlbums.clearAll();
  }

  Future<void> _onUnpinClick() async {
    for (final collection in widget.selectedAlbums.albums) {
      if (collection.type == CollectionType.favorites || !collection.isPinned) {
        continue;
      }

      await updateOrder(
        context,
        collection,
        collection.isPinned ? 0 : 0,
      );
    }
    if (hasFavorites) {
      _showFavToast();
    }
    widget.selectedAlbums.clearAll();
  }

  Future<void> _onHideClick() async {
    for (final collection in widget.selectedAlbums.albums) {
      if (collection.type == CollectionType.favorites) {
        continue;
      }
      final isHidden = collection.isHidden();
      final int prevVisiblity = isHidden ? hiddenVisibility : visibleVisibility;
      final int newVisiblity = isHidden ? visibleVisibility : hiddenVisibility;

      await changeCollectionVisibility(
        context,
        collection: collection,
        newVisibility: newVisiblity,
        prevVisibility: prevVisiblity,
      );
    }
    if (hasFavorites) {
      _showFavToast();
    }
    widget.selectedAlbums.clearAll();
  }

  Future<void> _archiveClick() async {
    for (final collection in widget.selectedAlbums.albums) {
      if (collection.type == CollectionType.favorites) {
        continue;
      }
      if (widget.sectionType == UISectionType.incomingCollections) {
        final hasShareeArchived = collection.hasShareeArchived();
        final int prevVisiblity =
            hasShareeArchived ? archiveVisibility : visibleVisibility;
        final int newVisiblity =
            hasShareeArchived ? visibleVisibility : archiveVisibility;

        await changeCollectionVisibility(
          context,
          collection: collection,
          newVisibility: newVisiblity,
          prevVisibility: prevVisiblity,
          isOwner: false,
        );
      } else {
        final isArchived = collection.isArchived();
        final int prevVisiblity =
            isArchived ? archiveVisibility : visibleVisibility;
        final int newVisiblity =
            isArchived ? visibleVisibility : archiveVisibility;

        await changeCollectionVisibility(
          context,
          collection: collection,
          newVisibility: newVisiblity,
          prevVisibility: prevVisiblity,
        );
      }
      if (hasFavorites) {
        _showFavToast();
      }
      if (mounted) {
        setState(() {});
      }
    }
    widget.selectedAlbums.clearAll();
  }

  Future<void> _leaveAlbum() async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: AppLocalizations.of(context).leaveAlbum,
          onTap: () async {
            for (final collection in widget.selectedAlbums.albums) {
              await CollectionsService.instance.leaveAlbum(collection);
            }
            widget.selectedAlbums.clearAll();
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: AppLocalizations.of(context).cancel,
        ),
      ],
      title: AppLocalizations.of(context).leaveSharedAlbum,
      body: AppLocalizations.of(context)
          .photosAddedByYouWillBeRemovedFromTheAlbum,
    );
    if (actionResult?.action != null && mounted) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      } else if (actionResult.action == ButtonAction.first) {
        Navigator.of(context).pop();
      }
    }
  }

  void _selectionChangedListener() {
    if (mounted) {
      hasFavorites = widget.selectedAlbums.albums
          .any((album) => album.type == CollectionType.favorites);
      setState(() {});
    }
  }

  void _showFavToast() {
    showShortToast(
      context,
      AppLocalizations.of(context).actionNotSupportedOnFavouritesAlbum,
    );
  }
}
