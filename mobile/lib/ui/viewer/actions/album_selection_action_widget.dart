import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/magic_util.dart";

class AlbumSelectionActionWidget extends StatefulWidget {
  final SelectedAlbums selectedAlbums;
  const AlbumSelectionActionWidget(
    this.selectedAlbums, {
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

  @override
  initState() {
    collectionActions = CollectionActions(CollectionsService.instance);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedAlbums.albums.isEmpty) {
      return const SizedBox();
    }
    final List<SelectionActionButton> items = [];
    items.add(
      SelectionActionButton(
        labelText: S.of(context).share,
        icon: Icons.adaptive.share,
        onTap: _shareCollection,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: "Pin",
        icon: Icons.push_pin_rounded,
        onTap: _onPinClick,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: S.of(context).delete,
        icon: Icons.delete_outline,
        onTap: _trashCollection,
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: S.of(context).hide,
        icon: Icons.visibility_off_outlined,
        onTap: _onHideClick,
      ),
    );
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
    await collectionActions.shareMultipleCollectionSheet(
      context,
      widget.selectedAlbums.albums.toList(),
    );
    widget.selectedAlbums.clearAll();
  }

  Future<void> _trashCollection() async {
    int count = 0;
    final List<Collection> nonEmptyCollection = [];

    for (final collection in widget.selectedAlbums.albums) {
      count = await FilesDB.instance.collectionFileCount(collection.id);
      final bool isEmptyCollection = count == 0;
      if (isEmptyCollection) {
        try {
          await CollectionsService.instance.trashEmptyCollection(collection);
        } catch (e, s) {
          _logger.warning("failed to trash collection", e, s);
          await showGenericErrorDialog(context: context, error: e);
        }
      } else if (collection.type == CollectionType.favorites) {
        continue;
      } else {
        nonEmptyCollection.add(collection);
      }
    }

    if (nonEmptyCollection.isNotEmpty) {
      final bool result = await collectionActions.deleteMultipleCollectionSheet(
        context,
        nonEmptyCollection,
      );
      if (result == true) {
        Navigator.of(context).pop();
      } else {
        debugPrint("No pop");
      }
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
    widget.selectedAlbums.clearAll();
  }
}
