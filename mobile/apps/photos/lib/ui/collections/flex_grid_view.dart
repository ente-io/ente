import "dart:async";
import 'dart:math';

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_album_selections_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/collections/album/list_item.dart";
import "package:photos/ui/collections/album/new_list_item.dart";
import "package:photos/ui/collections/album/new_row_item.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/navigation_util.dart";

class CollectionsFlexiGridViewWidget extends StatefulWidget {
  /*
  Aspect ratio 1:1
  Width changes dynamically with screen width
  */

  static const maxThumbnailWidth = 224.0;
  static const crossAxisSpacing = 8.0;
  static const horizontalPadding = 16.0;
  final List<Collection>? collections;
  // At max how many albums to display
  final int displayLimitCount;

  // If true, the GridView will shrink-wrap its contents.
  final bool shrinkWrap;
  final String tag;

  final AlbumViewType albumViewType;
  final bool enableSelectionMode;
  final bool shouldShowCreateAlbum;
  final SelectedAlbums? selectedAlbums;
  final double scrollBottomSafeArea;
  final bool onlyAllowSelection;

  const CollectionsFlexiGridViewWidget(
    this.collections, {
    this.displayLimitCount = 9,
    this.shrinkWrap = false,
    this.tag = "",
    this.enableSelectionMode = false,
    super.key,
    this.albumViewType = AlbumViewType.grid,
    this.shouldShowCreateAlbum = false,
    this.selectedAlbums,
    this.scrollBottomSafeArea = 8,
    this.onlyAllowSelection = false,
  });

  @override
  State<CollectionsFlexiGridViewWidget> createState() =>
      _CollectionsFlexiGridViewWidgetState();
}

class _CollectionsFlexiGridViewWidgetState
    extends State<CollectionsFlexiGridViewWidget> {
  bool isAnyAlbumSelected = false;
  late StreamSubscription<ClearAlbumSelectionsEvent>
      _clearAlbumSelectionSubscription;

  @override
  void initState() {
    _clearAlbumSelectionSubscription =
        Bus.instance.on<ClearAlbumSelectionsEvent>().listen((event) {
      if (mounted) {
        setState(() {
          isAnyAlbumSelected = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _clearAlbumSelectionSubscription.cancel();
    super.dispose();
  }

  Future<void> _toggleAlbumSelection(Collection c) async {
    await HapticFeedback.lightImpact();
    widget.selectedAlbums!.toggleSelection(c);
    setState(() {
      isAnyAlbumSelected = widget.selectedAlbums!.albums.isNotEmpty;
    });
  }

  Future<void> _navigateToCollectionPage(Collection c) async {
    final thumbnail = await CollectionsService.instance.getCover(c);
    final bool isOwner = c.isOwner(Configuration.instance.getUserID()!);
    final String tagPrefix = (isOwner ? "collection" : "shared_collection") +
        widget.tag +
        "_" +
        c.id.toString();
    // ignore: unawaited_futures
    routeToPage(
      context,
      CollectionPage(
        tagPrefix: tagPrefix,
        CollectionWithThumbnail(c, thumbnail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isAnyAlbumSelected,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (isAnyAlbumSelected) {
          widget.selectedAlbums!.clearAll();
          setState(() {
            isAnyAlbumSelected = false;
          });
        }
      },
      child: widget.albumViewType == AlbumViewType.grid
          ? _buildGridView(context, const ValueKey("grid_view"))
          : _buildListView(context, const ValueKey("list_view")),
    );
  }

  Widget _buildGridView(BuildContext context, Key key) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int albumsCountInCrossAxis =
        max(screenWidth ~/ CollectionsFlexiGridViewWidget.maxThumbnailWidth, 3);
    final double totalCrossAxisSpacing = (albumsCountInCrossAxis - 1) *
        CollectionsFlexiGridViewWidget.crossAxisSpacing;

    final double sideOfThumbnail = (screenWidth -
            totalCrossAxisSpacing -
            CollectionsFlexiGridViewWidget.horizontalPadding) /
        albumsCountInCrossAxis;

    final int totalCollections = widget.collections!.length;
    final bool showCreateAlbum = widget.shouldShowCreateAlbum;
    final int totalItemCount = totalCollections + (showCreateAlbum ? 1 : 0);
    final int displayItemCount = min(totalItemCount, widget.displayLimitCount);

    return SliverPadding(
      key: key,
      padding: EdgeInsets.only(
        top: 8,
        left: CollectionsFlexiGridViewWidget.horizontalPadding / 2,
        right: CollectionsFlexiGridViewWidget.horizontalPadding / 2,
        bottom: widget.scrollBottomSafeArea,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (showCreateAlbum && index == 0) {
              return NewAlbumRowItemWidget(
                height: sideOfThumbnail,
                width: sideOfThumbnail,
              );
            }
            final collectionIndex = showCreateAlbum ? index - 1 : index;
            return AlbumRowItemWidget(
              widget.collections![collectionIndex],
              sideOfThumbnail,
              tag: widget.tag,
              selectedAlbums: widget.selectedAlbums,
              onTapCallback: (c) {
                isAnyAlbumSelected || widget.onlyAllowSelection
                    ? _toggleAlbumSelection(c)
                    : _navigateToCollectionPage(c);
              },
              onLongPressCallback: widget.enableSelectionMode
                  ? (c) {
                      isAnyAlbumSelected || widget.onlyAllowSelection
                          ? _navigateToCollectionPage(c)
                          : _toggleAlbumSelection(c);
                    }
                  : null,
            );
          },
          childCount: displayItemCount,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInCrossAxis,
          mainAxisSpacing: 8,
          crossAxisSpacing: CollectionsFlexiGridViewWidget.crossAxisSpacing,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, Key key) {
    final int totalCollections = widget.collections?.length ?? 0;
    final bool showCreateAlbum =
        widget.shouldShowCreateAlbum && !isAnyAlbumSelected;
    final int totalItemCount = totalCollections + (showCreateAlbum ? 1 : 0);
    final int displayItemCount = min(totalItemCount, widget.displayLimitCount);

    return SliverPadding(
      key: key,
      padding: EdgeInsets.only(
        top: 8,
        left: 8,
        right: 8,
        bottom: widget.scrollBottomSafeArea,
      ),
      sliver: SliverPrototypeExtentList(
        prototypeItem: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: showCreateAlbum
              ? const NewAlbumListItemWidget()
              : AlbumListItemWidget(
                  widget.collections![0],
                  selectedAlbums: widget.selectedAlbums,
                  onTapCallback: (c) {},
                ),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            Widget item;

            if (showCreateAlbum && index == 0) {
              item = GestureDetector(
                onTap: () async {
                  GestureDetector(
                    onTap: () async {
                      final result = await showTextInputDialog(
                        context,
                        title: AppLocalizations.of(context).newAlbum,
                        submitButtonLabel: AppLocalizations.of(context).create,
                        hintText: AppLocalizations.of(context).enterAlbumName,
                        alwaysShowSuccessState: false,
                        initialValue: "",
                        textCapitalization: TextCapitalization.words,
                        popnavAfterSubmission: false,
                        onSubmit: (String text) async {
                          if (text.trim() == "") {
                            return;
                          }

                          try {
                            final Collection c = await CollectionsService
                                .instance
                                .createAlbum(text);
                            // ignore: unawaited_futures
                            await routeToPage(
                              context,
                              CollectionPage(CollectionWithThumbnail(c, null)),
                            );
                            Navigator.of(context).pop();
                          } catch (e, s) {
                            Logger("CreateNewAlbumIcon")
                                .severe("Failed to rename album", e, s);
                            rethrow;
                          }
                        },
                      );

                      if (result is Exception) {
                        await showGenericErrorDialog(
                          context: context,
                          error: result,
                        );
                      }
                    },
                    child: const NewAlbumListItemWidget(),
                  );
                },
                child: const NewAlbumListItemWidget(),
              );
            } else {
              final collectionIndex = showCreateAlbum ? index - 1 : index;

              item = AlbumListItemWidget(
                widget.collections![collectionIndex],
                selectedAlbums: widget.selectedAlbums,
                onTapCallback: (c) {
                  isAnyAlbumSelected
                      ? _toggleAlbumSelection(c)
                      : _navigateToCollectionPage(c);
                },
                onLongPressCallback: widget.enableSelectionMode
                    ? (c) {
                        isAnyAlbumSelected
                            ? _navigateToCollectionPage(c)
                            : _toggleAlbumSelection(c);
                      }
                    : null,
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: item,
            );
          },
          childCount: displayItemCount,
        ),
      ),
    );
  }
}
