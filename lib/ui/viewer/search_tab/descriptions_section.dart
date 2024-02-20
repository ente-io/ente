import "dart:async";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";
import "package:photos/utils/navigation_util.dart";

class DescriptionsSection extends StatefulWidget {
  final List<GenericSearchResult> descriptionsSearchResults;
  const DescriptionsSection(this.descriptionsSearchResults, {super.key});

  @override
  State<DescriptionsSection> createState() => _DescriptionsSectionState();
}

class _DescriptionsSectionState extends State<DescriptionsSection> {
  late List<GenericSearchResult> _descriptionsSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _descriptionsSearchResults = widget.descriptionsSearchResults;

    final streamsToListenTo = SectionType.fileCaption.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _descriptionsSearchResults = (await SectionType.fileCaption.getData(
            context,
            limit: kSearchSectionLimit,
          )) as List<GenericSearchResult>;
          setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DescriptionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _descriptionsSearchResults = widget.descriptionsSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_descriptionsSearchResults.isEmpty) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SectionType.fileCaption.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.fileCaption.getEmptyStateText(context),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.fileCaption),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              SectionType.fileCaption,
              hasMore: (_descriptionsSearchResults.length >=
                  kSearchSectionLimit - 1),
            ),
            const SizedBox(height: 2),
            SizedBox(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _descriptionsSearchResults
                      .map(
                        (descriptionSearchResult) =>
                            DescriptionRecommendation(descriptionSearchResult),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class DescriptionRecommendation extends StatelessWidget {
  static const _width = 100.0;
  static const _height = 150.0;
  static const _cornerRadius = 5.0;
  static const _cornerSmoothing = 1.0;
  final GenericSearchResult descriptionSearchResult;
  const DescriptionRecommendation(this.descriptionSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = descriptionSearchResult.heroTag() +
        (descriptionSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(descriptionSearchResult.name());
          if (descriptionSearchResult.onResultTap != null) {
            descriptionSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(descriptionSearchResult),
            );
          }
        },
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6.25,
                      offset: const Offset(-1.25, 2.5),
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: _width,
                        height: _height,
                        child: descriptionSearchResult.previewThumbnail() !=
                                null
                            ? Hero(
                                tag: heroTag,
                                child: ThumbnailWidget(
                                  descriptionSearchResult.previewThumbnail()!,
                                  shouldShowArchiveStatus: false,
                                  shouldShowSyncStatus: false,
                                ),
                              )
                            : const NoThumbnailWidget(),
                      ),
                      Container(
                        height: 145,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0),
                              Colors.black.withOpacity(0),
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [
                              0,
                              0.1,
                              1,
                            ],
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 76,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: Text(
                            descriptionSearchResult.name(),
                            style: enteTextTheme.small.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
