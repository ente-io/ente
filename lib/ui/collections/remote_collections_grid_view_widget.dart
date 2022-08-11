import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/ui/collections/collection_item_widget.dart';
import 'package:photos/ui/collections/create_new_album_widget.dart';

class RemoteCollectionsGridViewWidget extends StatelessWidget {
  final List<CollectionWithThumbnail> collections;

  const RemoteCollectionsGridViewWidget(
    this.collections, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    Size size = MediaQuery.of(context).size;
    int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        horizontalPaddingOfGridRow -
        ((crossAxisSpacingOfGrid / 2) * (albumsCountInOneRow - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        // to disable GridView's scrolling
        itemBuilder: (context, index) {
          if (index < collections.length) {
            return CollectionItem(collections[index]);
          } else {
            return const CreateNewAlbumWidget();
          }
        },
        itemCount: collections.length + 1,
        // To include the + button
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumsCountInOneRow,
          mainAxisSpacing: 12,
          crossAxisSpacing: crossAxisSpacingOfGrid,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 24),
        ), //24 is height of album title
      ),
    );
  }
}
