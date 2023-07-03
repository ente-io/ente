import 'dart:math';

import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
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

  const CollectionsFlexiGridViewWidget(
    this.collections, {
    this.displayLimitCount = 6,
    Key? key,
  }) : super(key: key);

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return AlbumRowItemWidget(
            collections![index],
            sideOfThumbnail,
          );
        },
        itemCount: min(collections!.length, displayLimitCount),
        // To include the + button
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 4,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ), //24 is height of album title
      ),
    );
  }
}
