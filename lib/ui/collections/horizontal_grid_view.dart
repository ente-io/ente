import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/album/row_item.dart";
import 'package:photos/ui/collections/create_new_album_widget.dart';

class CollectionsGridViewHorizontal extends StatelessWidget {
  /*
  Aspect ratio 1:1 Max width 224 Fixed gap 8
  Width changes dynamically with screen width such that we can fit 2 in one row.
  Keep the width integral (center the albums to distribute excess pixels)
   */
  static const maxThumbnailWidth = 224.0;
  static const fixedGapBetweenAlbum = 60.0;
  static const minGapForHorizontalPadding = 8.0;

  final List<Collection>? collections;

  const CollectionsGridViewHorizontal(
    this.collections, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    double thumSize = (screenWidth - fixedGapBetweenAlbum) / 2;
    if (thumSize > maxThumbnailWidth) {
      thumSize = maxThumbnailWidth;
    }
    return SizedBox(
      height: thumSize * 2 + 100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final int firstIndex = index * 2;
          final int secondIndex = firstIndex + 1;
          return Column(
            children: [
              if (firstIndex < collections!.length)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: AlbumRowItemWidget(
                    collections![firstIndex],
                    thumSize,
                  ),
                ),
              if (secondIndex < collections!.length)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AlbumRowItemWidget(
                    collections![secondIndex],
                    thumSize,
                  ),
                ),
              if (secondIndex >= collections!.length)
                SizedBox(
                  width: thumSize,
                  height: thumSize,
                  child: const CreateNewAlbumWidget(),
                ),
            ],
          );
        },
        itemCount:
            (collections!.length / 2).ceil() + ((collections!.length + 1) % 2),
      ),
    );
  }
}
