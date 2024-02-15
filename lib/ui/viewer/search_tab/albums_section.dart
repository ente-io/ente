import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search_tab/search_tab.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";

class AlbumsSection extends StatelessWidget {
  final List<AlbumSearchResult> albumSearchResults;
  const AlbumsSection(this.albumSearchResults, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          SectionType.album,
          hasMore: (albumSearchResults.length > SearchTab.hasMoreThreshold),
        ),
        const SizedBox(height: 2),
        SizedBox(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 4.5),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: albumSearchResults
                  .map(
                    (albumSearchResult) =>
                        AlbumRecommendation(albumSearchResult),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class AlbumRecommendation extends StatelessWidget {
  final AlbumSearchResult albumSearchResult;
  const AlbumRecommendation(this.albumSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipSmoothRect(
            radius: SmoothBorderRadius(cornerRadius: 2.35, cornerSmoothing: 1),
            child: SizedBox(
              width: 100,
              height: 100,
              child: albumSearchResult.previewThumbnail() != null
                  ? ThumbnailWidget(
                      albumSearchResult.previewThumbnail()!,
                      shouldShowArchiveStatus: false,
                    )
                  : const NoThumbnailWidget(),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            albumSearchResult.name(),
            style: enteTextTheme.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            CollectionsService.instance
                .getCachedFileCount(
                  albumSearchResult.collectionWithThumbnail.collection,
                )
                .toString(),
            style: enteTextTheme.smallMuted,
          ),
        ],
      ),
    );
  }
}
