import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import 'package:photos/ui/viewer/search/result/search_section_result_page.dart';
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/utils/navigation_util.dart";

class SearchSection extends StatelessWidget {
  final SectionType sectionType;
  final List<SearchResult> examples;
  final int limit;

  const SearchSection({
    Key? key,
    required this.sectionType,
    required this.examples,
    required this.limit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for ${sectionType.name}");
    final textTheme = getEnteTextTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                sectionType.sectionTitle(context),
                style: textTheme.largeBold,
              ),
            ),
            examples.length < (limit - 1)
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      routeToPage(
                        context,
                        SearchSectionResultPage(sectionType: sectionType),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.chevron_right_outlined,
                        color: getEnteColorScheme(context).strokeMuted,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 2),
        // wrap below text in next line
        // Text(
        //   sectionType.getEmptyStateText(context),
        //   style: textTheme.smallMuted,
        //   softWrap: true,
        // ),
        SearchExampleRow(examples, sectionType),
      ],
    );
  }
}

class SearchExampleRow extends StatelessWidget {
  final SectionType sectionType;
  final List<SearchResult> reccomendations;

  const SearchExampleRow(this.reccomendations, this.sectionType, {super.key});

  @override
  Widget build(BuildContext context) {
    //Cannot use listView.builder here
    final scrollableExamples = <Widget>[];
    reccomendations.forEachIndexed((index, element) {
      scrollableExamples.add(
        SearchExample(
          searchResult: reccomendations.elementAt(index),
        ),
      );
    });
    scrollableExamples.add(SearchSectionCTAIcon(sectionType));
    return SizedBox(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: scrollableExamples,
        ),
      ),
    );
  }
}

class SearchExample extends StatelessWidget {
  final SearchResult searchResult;
  const SearchExample({required this.searchResult, super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    late final double width;
    if (textScaleFactor <= 1.0) {
      width = 85.0;
    } else {
      width = 85.0 + ((textScaleFactor - 1.0) * 64);
    }
    return GestureDetector(
      onTap: () {
        if (searchResult is GenericSearchResult) {
          final genericSearchResult = searchResult as GenericSearchResult;
          if (genericSearchResult.onResultTap != null) {
            genericSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(searchResult),
            );
          }
        } else if (searchResult is AlbumSearchResult) {
          final albumSearchResult = searchResult as AlbumSearchResult;
          routeToPage(
            context,
            CollectionPage(
              albumSearchResult.collectionWithThumbnail,
              tagPrefix: albumSearchResult.heroTag(),
            ),
          );
        }
      },
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: searchResult.previewThumbnail() != null
                      ? ThumbnailWidget(
                          searchResult.previewThumbnail()!,
                          shouldShowSyncStatus: false,
                        )
                      : const NoThumbnailWidget(),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                searchResult.name(),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: getEnteTextTheme(context).mini,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
