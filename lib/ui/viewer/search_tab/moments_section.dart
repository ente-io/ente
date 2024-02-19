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

class MomentsSection extends StatefulWidget {
  final List<GenericSearchResult> momentsSearchResults;
  const MomentsSection(this.momentsSearchResults, {super.key});

  @override
  State<MomentsSection> createState() => _MomentsSectionState();
}

class _MomentsSectionState extends State<MomentsSection> {
  late List<GenericSearchResult> _momentsSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _momentsSearchResults = widget.momentsSearchResults;

    final streamsToListenTo = SectionType.moment.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _momentsSearchResults = (await SectionType.moment.getData(
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
  void didUpdateWidget(covariant MomentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _momentsSearchResults = widget.momentsSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_momentsSearchResults.isEmpty) {
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
                    SectionType.moment.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.moment.getEmptyStateText(context),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.moment),
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
              SectionType.moment,
              hasMore:
                  (_momentsSearchResults.length >= kSearchSectionLimit - 1),
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
                  children: _momentsSearchResults
                      .map(
                        (momentsSearchResult) =>
                            MomentsRecommendation(momentsSearchResult),
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

class MomentsRecommendation extends StatelessWidget {
  final GenericSearchResult momentsSearchResult;
  const MomentsRecommendation(this.momentsSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = momentsSearchResult.heroTag() +
        (momentsSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(momentsSearchResult.name());
          if (momentsSearchResult.onResultTap != null) {
            momentsSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(momentsSearchResult),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6.25,
                offset: const Offset(-1.25, 2.5),
              ),
            ],
          ),
          child: Center(
            child: ClipSmoothRect(
              radius: SmoothBorderRadius(cornerRadius: 5, cornerSmoothing: 1),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 100,
                    height: 145,
                    child: momentsSearchResult.previewThumbnail() != null
                        ? Hero(
                            tag: heroTag,
                            child: ThumbnailWidget(
                              momentsSearchResult.previewThumbnail()!,
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
                        momentsSearchResult.name(),
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
        ),
      ),
    );
  }
}
