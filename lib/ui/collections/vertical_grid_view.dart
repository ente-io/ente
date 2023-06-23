import "dart:math";

import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/album/row_item.dart";

class CollectionVerticalGridView extends StatelessWidget {
  static const maxThumbnailWidth = 160.0;

  final List<Collection>? collections;
  final Widget? appTitle;

  final double gapBetweenAlbums = 1.0;

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
    final int albumsCountInOneRow =
        max(screenWidth ~/ (maxThumbnailWidth + 24), 2);

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
      child: GridView.builder(
        physics: const ScrollPhysics(),
        // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return AlbumRowItemWidget(
            collections![index],
            maxThumbnailWidth,
          );
        },
        itemCount: collections!.length,
        // To include the + button
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: gapBetweenAlbums,
          crossAxisSpacing: gapBetweenAlbums,
          childAspectRatio: maxThumbnailWidth / (maxThumbnailWidth + 24),
        ),
      ),
    );
  }
}
