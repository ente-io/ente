import "dart:async";
import 'dart:math';

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:logging/logging.dart";
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
  Aspect ratio 1:1 Max width 224 Fixed gap 8
  Width changes dynamically with screen width such that we can fit 2 in one row.
  Keep the width integral (center the albums to distribute excess pixels)
   */
  static const maxThumbnailWidth = 170.0;
  static const fixedGapBetweenAlbum = 2.0;
  static const minGapForHorizontalPadding = 8.0;
  static const collectionItemsToPreload = 20;

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
    // ignore: unawaited_futures
    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(c, thumbnail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.albumViewType == AlbumViewType.grid
        ? _buildGridView(context, const ValueKey("grid_view"))
        : _buildListView(context, const ValueKey("list_view"));
  }

  Widget _buildGridView(BuildContext context, Key key) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int albumsCountInOneRow =
        max(screenWidth ~/ CollectionsFlexiGridViewWidget.maxThumbnailWidth, 3);
    final double gapBetweenAlbums = (albumsCountInOneRow - 1) *
        CollectionsFlexiGridViewWidget.fixedGapBetweenAlbum;
    // gapOnSizeOfAlbums will be
    final double gapOnSizeOfAlbums =
        CollectionsFlexiGridViewWidget.minGapForHorizontalPadding +
            (screenWidth -
                    gapBetweenAlbums -
                    (2 *
                        CollectionsFlexiGridViewWidget
                            .minGapForHorizontalPadding)) %
                albumsCountInOneRow;

    final double sideOfThumbnail =
        (screenWidth - gapOnSizeOfAlbums - gapBetweenAlbums) /
            albumsCountInOneRow;

    final List<Widget> gridItems = [];
    if (widget.shouldShowCreateAlbum && !isAnyAlbumSelected) {
      gridItems.add(
        NewAlbumRowItemWidget(
          height: sideOfThumbnail,
          width: sideOfThumbnail,
        ),
      );
    }

    if (widget.collections != null && widget.collections!.isNotEmpty) {
      for (int i = 0; i < widget.collections!.length; i++) {
        gridItems.add(
          AlbumRowItemWidget(
            widget.collections![i],
            sideOfThumbnail,
            tag: widget.tag,
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
          ),
        );
      }
    }

    return SliverPadding(
      key: key,
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return gridItems[index];
          },
          childCount: min(gridItems.length, widget.displayLimitCount),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 4,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, Key key) {
    final List<Widget> listItems = [];

    if (widget.shouldShowCreateAlbum && !isAnyAlbumSelected) {
      listItems.add(
        GestureDetector(
          onTap: () async {
            final result = await showTextInputDialog(
              context,
              title: S.of(context).newAlbum,
              submitButtonLabel: S.of(context).create,
              hintText: S.of(context).enterAlbumName,
              alwaysShowSuccessState: false,
              initialValue: "",
              textCapitalization: TextCapitalization.words,
              popnavAfterSubmission: false,
              onSubmit: (String text) async {
                if (text.trim() == "") {
                  return;
                }

                try {
                  final Collection c =
                      await CollectionsService.instance.createAlbum(text);
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
              await showGenericErrorDialog(context: context, error: result);
            }
          },
          child: const NewAlbumListItemWidget(),
        ),
      );
    }

    if (widget.collections != null && widget.collections!.isNotEmpty) {
      for (var collection in widget.collections!) {
        listItems.add(
          AlbumListItemWidget(
            collection,
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
          ),
        );
      }
    }

    return SliverPadding(
      key: key,
      padding: const EdgeInsets.all(8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: listItems[index],
            );
          },
          childCount: min(listItems.length, widget.displayLimitCount),
        ),
      ),
    );
  }
}
