import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
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
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class AlbumSelectionActionWidget extends StatefulWidget {
  final SelectedAlbums selectedAlbums;
  final UISectionType sectionType;
  final bool isCollapsed;

  const AlbumSelectionActionWidget(
    this.selectedAlbums,
    this.sectionType, {
    this.isCollapsed = false,
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
  final PageController _pageController = PageController();

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
          labelText: S.of(context).share,
          icon: Icons.adaptive.share,
          onTap: _shareCollection,
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
    }

    if (widget.sectionType == UISectionType.incomingCollections) {
      items.add(
        SelectionActionButton(
          labelText: S.of(context).leaveAlbum,
          icon: Icons.logout,
          onTap: _leaveAlbum,
        ),
      );
    }

    final List<SelectionActionButton> visibleItems = items
        .where((item) => item.shouldShow == null || item.shouldShow == true)
        .toList();

    final List<SelectionActionButton> firstThreeItems =
        visibleItems.length > 3 ? visibleItems.take(3).toList() : visibleItems;

    final List<SelectionActionButton> otherItems =
        visibleItems.length > 3 ? visibleItems.sublist(3) : [];

    otherItems.add(
      SelectionActionButton(
        labelText: S.of(context).archive,
        icon: Icons.archive_outlined,
        onTap: _archiveClick,
      ),
    );

    final List<List<SelectionActionButton>> groupedOtherItems = [];
    for (int i = 0; i < otherItems.length; i += 4) {
      int end = (i + 4 < otherItems.length) ? i + 4 : otherItems.length;
      groupedOtherItems.add(otherItems.sublist(i, end));
    }

    if (visibleItems.isNotEmpty) {
      return MediaQuery(
        data: MediaQuery.of(context).removePadding(removeBottom: true),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Column(
              children: [
                // First Row
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    for (int i = 0; i < firstThreeItems.length; i++) ...[
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.10,
                              decoration: BoxDecoration(
                                color: getEnteColorScheme(context)
                                    .backgroundElevated2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            firstThreeItems[i],
                          ],
                        ),
                      ),
                      if (i != firstThreeItems.length - 1)
                        const SizedBox(width: 15),
                    ],
                  ],
                ),

                // Second Row
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    opacity: widget.isCollapsed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: widget.isCollapsed
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              if (groupedOtherItems.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: getEnteColorScheme(context)
                                        .backgroundElevated2,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: groupedOtherItems.length,
                                    onPageChanged: (index) {
                                      if (index >= groupedOtherItems.length &&
                                          groupedOtherItems.isNotEmpty) {
                                        _pageController.animateToPage(
                                          groupedOtherItems.length - 1,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    itemBuilder: (context, pageIndex) {
                                      if (pageIndex >=
                                          groupedOtherItems.length) {
                                        return const SizedBox();
                                      }

                                      final currentGroup =
                                          groupedOtherItems[pageIndex];

                                      return Row(
                                        children: currentGroup.map((item) {
                                          return Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 100),
                                              transitionBuilder: (
                                                Widget child,
                                                Animation<double> animation,
                                              ) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                              child: item is Widget
                                                  ? KeyedSubtree(
                                                      key: ValueKey(
                                                        item.hashCode,
                                                      ),
                                                      child: item,
                                                    )
                                                  : const SizedBox(),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (groupedOtherItems.length > 1)
                                  SmoothPageIndicator(
                                    controller: _pageController,
                                    count: groupedOtherItems.length,
                                    effect: const WormEffect(
                                      dotHeight: 6,
                                      dotWidth: 6,
                                      spacing: 6,
                                      activeDotColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
          labelText: S.of(context).leaveAlbum,
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
          labelText: S.of(context).cancel,
        ),
      ],
      title: S.of(context).leaveSharedAlbum,
      body: S.of(context).photosAddedByYouWillBeRemovedFromTheAlbum,
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
      S.of(context).actionNotSupportedOnFavouritesAlbum,
    );
  }
}
