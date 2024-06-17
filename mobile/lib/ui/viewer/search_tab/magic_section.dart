import "dart:async";
import "dart:math";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/machine_learning/semantic_search/frameworks/ml_framework.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";
import "package:photos/utils/navigation_util.dart";

class MagicSection extends StatefulWidget {
  final List<GenericSearchResult> magicSearchResults;
  const MagicSection(this.magicSearchResults, {super.key});

  @override
  State<MagicSection> createState() => _MagicSectionState();
}

class _MagicSectionState extends State<MagicSection> {
  late List<GenericSearchResult> _magicSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _magicSearchResults = widget.magicSearchResults;

    //At times, ml framework is not initialized when the search results are
    //requested (widget.momentsSearchResults is empty) and is initialized
    //(which fires MLFrameworkInitializationUpdateEvent with
    //InitializationState.initialized) before initState of this widget is
    //called. We do listen to MLFrameworkInitializationUpdateEvent and reload
    //this widget but the event with InitializationState.initialized would have
    //already been fired in the above case.
    if (_magicSearchResults.isEmpty) {
      SectionType.magic
          .getData(
        context,
        limit: kSearchSectionLimit,
      )
          .then((value) {
        if (mounted) {
          setState(() {
            _magicSearchResults = value as List<GenericSearchResult>;
          });
        }
      });
    }

    final streamsToListenTo = SectionType.magic.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          final mlFrameWorkEvent =
              event as MLFrameworkInitializationUpdateEvent;
          if (mlFrameWorkEvent.state == InitializationState.initialized) {
            _magicSearchResults = (await SectionType.magic.getData(
              context,
              limit: kSearchSectionLimit,
            )) as List<GenericSearchResult>;
            setState(() {});
          }
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
  void didUpdateWidget(covariant MagicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    //widget.magicSearch is empty when doing a hot reload
    if (widget.magicSearchResults.isNotEmpty) {
      _magicSearchResults = widget.magicSearchResults;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_magicSearchResults.isEmpty) {
      // final textTheme = getEnteTextTheme(context);
      // return Padding(
      //   padding: const EdgeInsets.only(left: 12, right: 8),
      //   child: Row(
      //     children: [
      //       Expanded(
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               SectionType.magic.sectionTitle(context),
      //               style: textTheme.largeBold,
      //             ),
      //             const SizedBox(height: 24),
      //             Padding(
      //               padding: const EdgeInsets.only(left: 4),
      //               child: Text(
      //                 SectionType.magic.getEmptyStateText(context),
      //                 style: textTheme.smallMuted,
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
      //       const SizedBox(width: 8),
      //       const SearchSectionEmptyCTAIcon(SectionType.magic),
      //     ],
      //   ),
      // );
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              SectionType.magic,
              hasMore: (_magicSearchResults.length >= kSearchSectionLimit - 1),
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
                  children: _magicSearchResults
                      .map(
                        (magicSearchResult) =>
                            MagicRecommendation(magicSearchResult),
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

class MagicRecommendation extends StatelessWidget {
  static const _width = 100.0;
  static const _height = 110.0;
  static const _borderWidth = 1.0;
  static const _cornerRadius = 12.0;
  static const _cornerSmoothing = 1.0;
  final GenericSearchResult magicSearchResult;
  const MagicRecommendation(this.magicSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = magicSearchResult.heroTag() +
        (magicSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: max(2.5 - _borderWidth, 0)),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(magicSearchResult.name());
          if (magicSearchResult.onResultTap != null) {
            magicSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(
                magicSearchResult,
                enableGrouping: false,
              ),
            );
          }
        },
        child: SizedBox(
          width: _width + _borderWidth * 2,
          height: _height + _borderWidth * 2,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: _cornerRadius + _borderWidth,
                  cornerSmoothing: _cornerSmoothing,
                ),
                child: Container(
                  color: getEnteColorScheme(context).strokeFaint,
                  width: _width + _borderWidth * 2,
                  height: _height + _borderWidth * 2,
                ),
              ),
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
                        child: magicSearchResult.previewThumbnail() != null
                            ? Hero(
                                tag: heroTag,
                                child: ThumbnailWidget(
                                  magicSearchResult.previewThumbnail()!,
                                  shouldShowArchiveStatus: false,
                                  shouldShowSyncStatus: false,
                                ),
                              )
                            : const NoThumbnailWidget(),
                      ),
                      Container(
                        height: _height,
                        width: _width,
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
                            magicSearchResult.name(),
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
