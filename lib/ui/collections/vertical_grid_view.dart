import "dart:math";

import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/album/row_item.dart";

class CollectionVerticalGridView extends StatelessWidget {
  static const maxThumbnailWidth = 224.0;
  static const fixedGapBetweenAlbum = 8.0;
  static const minGapForHorizontalPadding = 8.0;

  final List<Collection>? collections;
  final Widget? appTitle;

  const CollectionVerticalGridView(
    this.collections, {
    this.appTitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: appTitle,
      ),
      body: SafeArea(
        child: _getBody(context),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
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
        physics: const ScrollPhysics(),
        // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return AlbumRowItemWidget(
            collections![index],
            sideOfThumbnail,
          );
        },
        itemCount: collections!.length,
        // To include the + button
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 12,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ), //24 is height of album title
      ),
    );
  }
}
