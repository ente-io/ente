import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/search/result/contact_result_page.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search/result/search_thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class SearchableItemWidget extends StatelessWidget {
  final SearchResult searchResult;
  final Future<int>? resultCount;
  final Function? onResultTap;
  const SearchableItemWidget(
    this.searchResult, {
    super.key,
    this.resultCount,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    //The "searchable_item" tag is to remove hero animation between section
    //examples and searchableItems in 'view all'. Animation should exist between
    //searchableItems and SearchResultPages, so passing the extra prefix to
    //SearchResultPage
    const additionalPrefix = "searchable_item";
    final heroTagPrefix = additionalPrefix + searchResult.heroTag();
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final bool isCluster = (searchResult.type() == ResultType.faces &&
        int.tryParse(searchResult.name()) != null);

    return GestureDetector(
      onTap: () {
        RecentSearches().add(searchResult.name());
        if (onResultTap != null) {
          onResultTap!();
        } else {
          if (searchResult.type() == ResultType.shared) {
            routeToPage(
              context,
              ContactResultPage(
                searchResult,
                tagPrefix: additionalPrefix,
              ),
            );
          } else {
            routeToPage(
              context,
              SearchResultPage(
                searchResult,
                tagPrefix: additionalPrefix,
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.strokeFainter),
          borderRadius: const BorderRadius.all(
            Radius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 6,
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: searchResult.type() == ResultType.shared
                        ? ContactSearchThumbnailWidget(
                            heroTagPrefix,
                            searchResult: searchResult as GenericSearchResult,
                          )
                        : SearchThumbnailWidget(
                            searchResult.previewThumbnail(),
                            heroTagPrefix,
                            searchResult: searchResult,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isCluster
                              ? const SizedBox.shrink()
                              : Text(
                                  searchResult.name(),
                                  style: searchResult.type() ==
                                          ResultType.locationSuggestion
                                      ? textTheme.bodyFaint
                                      : textTheme.body,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          const SizedBox(
                            height: 2,
                          ),
                          FutureBuilder<int>(
                            future: resultCount ??
                                Future.value(searchResult.resultFiles().length),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data! > 0) {
                                final noOfMemories = snapshot.data;
                                final String suffix =
                                    noOfMemories! > 1 ? " memories" : " memory";

                                return Text(
                                  noOfMemories.toString() + suffix,
                                  style: textTheme.smallMuted,
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: IconButtonWidget(
                icon: Icons.chevron_right_outlined,
                iconButtonType: IconButtonType.secondary,
                iconColor: colorScheme.blurStrokePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchableItemPlaceholder extends StatelessWidget {
  final SectionType sectionType;
  const SearchableItemPlaceholder(this.sectionType, {super.key});

  @override
  Widget build(BuildContext context) {
    if (sectionType.isCTAVisible == false) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.only(right: 1),
      child: GestureDetector(
        onTap: sectionType.ctaOnTap(context),
        child: DottedBorder(
          strokeWidth: 2,
          borderType: BorderType.RRect,
          radius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          dashPattern: const [4, 4],
          color: colorScheme.strokeFainter,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(4)),
                  color: colorScheme.fillFaint,
                ),
                child: Icon(
                  sectionType.getCTAIcon(),
                  color: colorScheme.strokeMuted,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                sectionType.getCTAText(context),
                style: textTheme.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
