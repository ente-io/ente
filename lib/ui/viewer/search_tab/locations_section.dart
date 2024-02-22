import "dart:async";
import "dart:math";
import "dart:ui";

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

class LocationsSection extends StatefulWidget {
  final List<GenericSearchResult> locationsSearchResults;
  const LocationsSection(this.locationsSearchResults, {super.key});

  @override
  State<LocationsSection> createState() => _LocationsSectionState();
}

class _LocationsSectionState extends State<LocationsSection> {
  late List<GenericSearchResult> _locationsSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _locationsSearchResults = widget.locationsSearchResults;

    final streamsToListenTo = SectionType.location.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _locationsSearchResults = (await SectionType.location.getData(
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
  void didUpdateWidget(covariant LocationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _locationsSearchResults = widget.locationsSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_locationsSearchResults.isEmpty) {
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
                    SectionType.location.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.location.getEmptyStateText(context),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.location),
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
              SectionType.location,
              hasMore:
                  (_locationsSearchResults.length >= kSearchSectionLimit - 1),
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
                  children: _locationsSearchResults
                      .map(
                        (locationSearchResult) =>
                            LocationRecommendation(locationSearchResult),
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

class LocationRecommendation extends StatelessWidget {
  static const _width = 100.0;
  static const _height = 123.0;
  static const _thumbnailBorderWidth = 1.0;
  static const _outerCornerRadius = 12.0;
  static const _cornerSmoothing = 1.0;
  static const _sideOfThumbnail = 90.0;
  static const _outerStrokeWidth = 1.0;
  //This is the space between this widget's boundary and the border stroke of
  //thumbnail.
  static const _outerPadding = 4.0;
  final GenericSearchResult locationSearchResult;
  const LocationRecommendation(this.locationSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = locationSearchResult.heroTag() +
        (locationSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: max(0, 2.5 - _outerStrokeWidth)),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(locationSearchResult.name());
          if (locationSearchResult.onResultTap != null) {
            locationSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(locationSearchResult),
            );
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: _outerCornerRadius + _outerStrokeWidth,
                cornerSmoothing: _cornerSmoothing,
              ),
              child: Container(
                color: Colors.white.withOpacity(0.1),
                width: _width + _outerStrokeWidth * 2,
                height: _height + _outerStrokeWidth * 2,
              ),
            ),
            SizedBox(
              width: _width,
              height: _height,
              // height: 145,

              child: Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      offset: Offset(0, 7.5),
                      color: Color.fromRGBO(68, 68, 68, 0.1),
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _outerCornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Stack(
                        children: [
                          ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                            child: locationSearchResult.previewThumbnail() !=
                                    null
                                ? ThumbnailWidget(
                                    locationSearchResult.previewThumbnail()!,
                                    shouldShowArchiveStatus: false,
                                    shouldShowSyncStatus: false,
                                  )
                                : const NoThumbnailWidget(),
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _outerPadding,
                          _outerPadding,
                          _outerPadding,
                          _outerPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipSmoothRect(
                                  radius: SmoothBorderRadius(
                                    cornerRadius:
                                        _outerCornerRadius - _outerPadding,
                                    cornerSmoothing: _cornerSmoothing,
                                  ),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.1),
                                    width: _sideOfThumbnail +
                                        _thumbnailBorderWidth * 2,
                                    height: _sideOfThumbnail +
                                        _thumbnailBorderWidth * 2,
                                  ),
                                ),
                                SizedBox(
                                  width: _sideOfThumbnail,
                                  height: _sideOfThumbnail,
                                  child: locationSearchResult
                                              .previewThumbnail() !=
                                          null
                                      ? Hero(
                                          tag: heroTag,
                                          child: ClipSmoothRect(
                                            radius: SmoothBorderRadius(
                                              cornerRadius: _outerCornerRadius -
                                                  _outerPadding -
                                                  _thumbnailBorderWidth,
                                              cornerSmoothing: _cornerSmoothing,
                                            ),
                                            clipBehavior:
                                                Clip.antiAliasWithSaveLayer,
                                            child: ThumbnailWidget(
                                              locationSearchResult
                                                  .previewThumbnail()!,
                                              shouldShowArchiveStatus: false,
                                              shouldShowSyncStatus: false,
                                            ),
                                          ),
                                        )
                                      : const NoThumbnailWidget(),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    locationSearchResult.name(),
                                    style: enteTextTheme.small
                                        .copyWith(color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_sharp,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
