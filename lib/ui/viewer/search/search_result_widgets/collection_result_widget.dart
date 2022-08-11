import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class AlbumSearchResultWidget extends StatelessWidget {
  final AlbumSearchResult albumSearchResult;

  const AlbumSearchResultWidget(this.albumSearchResult, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Theme.of(context).colorScheme.searchResultsColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Album',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.subTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      albumSearchResult.collectionWithThumbnail.collection.name,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<int>(
                      future: FilesDB.instance.collectionFileCount(
                        albumSearchResult.collectionWithThumbnail.collection.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data > 0) {
                          final noOfMemories = snapshot.data;
                          return RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .searchResultsCountTextColor,
                              ),
                              children: [
                                TextSpan(text: noOfMemories.toString()),
                                TextSpan(
                                  text: noOfMemories != 1
                                      ? ' memories'
                                      : ' memory',
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Hero(
                tag: "collection_search" +
                    albumSearchResult.collectionWithThumbnail.thumbnail.tag(),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: ThumbnailWidget(
                    albumSearchResult.collectionWithThumbnail.thumbnail,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      onTap: () {
        routeToPage(
          context,
          CollectionPage(
            albumSearchResult.collectionWithThumbnail,
            tagPrefix: "collection_search",
          ),
          forceCustomPageRoute: true,
        );
      },
    );
  }
}
