import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/album/row_item.dart";

class CollectionsHorizontalGridView extends StatelessWidget {
  static const maxThumbnailWidth = 160.0;
  static const albumNameSectionHeight = 21.0;
  static const rowItemBottomPadding = 12.0;

  final List<Collection>? collections;
  final EdgeInsetsGeometry? padding;

  const CollectionsHorizontalGridView(
    this.collections, {
    this.padding = const EdgeInsets.fromLTRB(8, 0, 8, 0),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double sizeBoxHeight =
        (maxThumbnailWidth + albumNameSectionHeight + rowItemBottomPadding) * 2;

    return SizedBox(
      height: sizeBoxHeight,
      child: ListView.builder(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final int firstIndex = index * 2;
          final int secondIndex = firstIndex + 1;
          return Column(
            children: [
              if (firstIndex < collections!.length)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8.0,
                    bottom: rowItemBottomPadding,
                  ),
                  child: AlbumRowItemWidget(
                    collections![firstIndex],
                    maxThumbnailWidth,
                  ),
                ),
              if (secondIndex < collections!.length)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8.0,
                    bottom: rowItemBottomPadding,
                  ),
                  child: AlbumRowItemWidget(
                    collections![secondIndex],
                    maxThumbnailWidth,
                  ),
                ),
            ],
          );
        },
        itemCount: (collections!.length / 2).ceil(),
      ),
    );
  }
}
