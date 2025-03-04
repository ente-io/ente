import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/models/collection/collection.dart';
import "package:photos/ui/collections/album/row_item.dart";

class CollectionsFlexiGridViewWidget extends StatelessWidget {
  /*
  Aspect ratio 1:1 Max width 224 Fixed gap 8
  Width changes dynamically with screen width such that we can fit 2 in one row.
  Keep the width integral (center the albums to distribute excess pixels)
   */
  static const maxThumbnailWidth = 224.0;
  static const fixedGapBetweenAlbum = 8.0;
  static const minGapForHorizontalPadding = 8.0;
  static const collectionItemsToPreload = 20;

  final List<Collection>? collections;
  // At max how many albums to display
  final int displayLimitCount;

  // If true, the GridView will shrink-wrap its contents.
  final bool shrinkWrap;
  final String tag;

  const CollectionsFlexiGridViewWidget(
    this.collections, {
    this.displayLimitCount = 10,
    this.shrinkWrap = false,
    this.tag = "",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int albumsCountInOneRow = max(screenWidth ~/ maxThumbnailWidth, 2);
    final double gapBetweenAlbums =
        (albumsCountInOneRow - 1) * fixedGapBetweenAlbum;
    // gapOnSizeOfAlbums will be
    final double gapOnSizeOfAlbums = minGapForHorizontalPadding +
        (screenWidth - gapBetweenAlbums - (2 * minGapForHorizontalPadding)) %
            albumsCountInOneRow;

    final double sideOfThumbnail =
        (screenWidth - gapOnSizeOfAlbums - gapBetweenAlbums) /
            albumsCountInOneRow;

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AlbumRowItemWidget(
              collections![index],
              sideOfThumbnail,
              tag: tag,
            );
          },
          childCount: min(collections!.length, displayLimitCount),
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
}
