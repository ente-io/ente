import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/album/row_item.dart";
import 'package:photos/ui/collections/create_new_album_widget.dart';

class CollectionsGridViewHorizontal extends StatelessWidget {
  static const maxThumbnailWidth = 160.0;

  final List<Collection>? collections;

  const CollectionsGridViewHorizontal(
    this.collections, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxThumbnailWidth * 2 + 80,
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
                    vertical: 12.0,
                  ),
                  child: AlbumRowItemWidget(
                    collections![firstIndex],
                    maxThumbnailWidth,
                  ),
                ),
              if (secondIndex < collections!.length)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: AlbumRowItemWidget(
                    collections![secondIndex],
                    maxThumbnailWidth,
                  ),
                ),
              if (secondIndex >= collections!.length)
                const SizedBox(
                  width: maxThumbnailWidth,
                  height: maxThumbnailWidth,
                  child: CreateNewAlbumWidget(),
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
