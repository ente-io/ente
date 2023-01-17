import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/ui/collections/collection_item_widget.dart';
import 'package:photos/ui/collections/create_new_album_widget.dart';

class RemoteCollectionsGridViewWidget extends StatelessWidget {
  /*
  Aspect ratio 1:1 Max width 224 Fixed gap 8
  Width changes dynamically with screen width such that we can fit 2 in one row.
  Keep the width integral (center the albums to distribute excess pixels)
   */
  static const maxThumbnailWidth = 224.0;
  static const fixedGapBetweenAlbum = 8.0;
  static const minGapForHorizontalPadding = 8.0;
  static const collectionItemsToPreload = 100;

  final List<CollectionWithThumbnail>? collections;

  const RemoteCollectionsGridViewWidget(
    this.collections, {
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
          if (index < collections!.length) {
            return CollectionItem(
              collections![index],
              sideOfThumbnail,
              shouldRender: index < collectionItemsToPreload,
            );
          } else {
            return const CreateNewAlbumWidget();
          }
        },
        itemCount: collections!.length + 1,
        // To include the + button
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 14,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 50),
        ), //24 is height of album title
      ),
    );
  }
}
