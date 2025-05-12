import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/models/collection/collection.dart';
import "package:photos/ui/collections/album/new_row_item.dart";
import "package:photos/ui/collections/album/row_item.dart";

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

  final bool enableSelectionMode;
  final bool shouldShowCreateAlbum;
  final double scrollBottomSafeArea;

  const CollectionsFlexiGridViewWidget(
    this.collections, {
    this.displayLimitCount = 10,
    this.shrinkWrap = false,
    this.tag = "",
    super.key,
    this.enableSelectionMode = false,
    this.shouldShowCreateAlbum = false,
    this.scrollBottomSafeArea = 8,
  });

  @override
  State<CollectionsFlexiGridViewWidget> createState() =>
      _CollectionsFlexiGridViewWidgetState();
}

class _CollectionsFlexiGridViewWidgetState
    extends State<CollectionsFlexiGridViewWidget> {
  @override
  Widget build(BuildContext context) {
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

    final int totalCollections = widget.collections!.length;
    final bool showCreateAlbum = widget.shouldShowCreateAlbum;
    final int totalItemCount = totalCollections + (showCreateAlbum ? 1 : 0);
    final int displayItemCount = min(totalItemCount, widget.displayLimitCount);

    return SliverPadding(
      padding: EdgeInsets.only(
        top: 8,
        left: 8,
        right: 8,
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
              showFileCount: false,
            );
          },
          childCount: displayItemCount,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 2,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ),
      ),
    );
  }
}
