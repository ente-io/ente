import "dart:async";
import "dart:math";
import "dart:ui";

import "package:dotted_border/dotted_border.dart";
import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/map_screen.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/go_to_map_widget.dart";
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
            const GoToMap(),
          ],
        ),
      );
    } else {
      final recommendations = <Widget>[
        const RepaintBoundary(child: GoToMapWithBG()),
        ..._locationsSearchResults.map(
          (locationSearchResult) =>
              LocationRecommendation(locationSearchResult),
        ),
        const RepaintBoundary(child: LocationCTA()),
      ];
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
                  children: recommendations,
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
  static const width = 100.0;
  static const height = 123.0;
  static const thumbnailBorderWidth = 1.0;
  static const outerCornerRadius = 12.0;
  static const cornerSmoothing = 1.0;
  static const sideOfThumbnail = 90.0;
  static const outerStrokeWidth = 1.0;
  //This is the space between this widget's boundary and the border stroke of
  //thumbnail.
  static const outerPadding = 4.0;
  final GenericSearchResult locationSearchResult;
  const LocationRecommendation(this.locationSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = locationSearchResult.heroTag() +
        (locationSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: max(0, 2.5 - outerStrokeWidth)),
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
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: outerCornerRadius + outerStrokeWidth,
                  cornerSmoothing: cornerSmoothing,
                ),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: width + outerStrokeWidth * 2,
                  height: height + outerStrokeWidth * 2,
                ),
              ),
              SizedBox(
                width: width,
                height: height,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 1,
                        offset: Offset(0, 0),
                        color: Color.fromRGBO(0, 0, 0, 0.09),
                      ),
                      BoxShadow(
                        blurRadius: 1,
                        offset: Offset(1, 2),
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                      ),
                    ],
                  ),
                  child: ClipSmoothRect(
                    radius: SmoothBorderRadius(
                      cornerRadius: outerCornerRadius,
                      cornerSmoothing: cornerSmoothing,
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
                                      shouldShowFavoriteIcon: false,
                                    )
                                  : const NoThumbnailWidget(),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            outerPadding,
                            outerPadding,
                            outerPadding,
                            outerPadding,
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
                                          outerCornerRadius - outerPadding,
                                      cornerSmoothing: cornerSmoothing,
                                    ),
                                    child: Container(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      width: sideOfThumbnail +
                                          thumbnailBorderWidth * 2,
                                      height: sideOfThumbnail +
                                          thumbnailBorderWidth * 2,
                                    ),
                                  ),
                                  SizedBox(
                                    width: sideOfThumbnail,
                                    height: sideOfThumbnail,
                                    child: locationSearchResult
                                                .previewThumbnail() !=
                                            null
                                        ? Hero(
                                            tag: heroTag,
                                            child: ClipSmoothRect(
                                              radius: SmoothBorderRadius(
                                                cornerRadius:
                                                    outerCornerRadius -
                                                        outerPadding -
                                                        thumbnailBorderWidth,
                                                cornerSmoothing:
                                                    cornerSmoothing,
                                              ),
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              child: ThumbnailWidget(
                                                locationSearchResult
                                                    .previewThumbnail()!,
                                                shouldShowArchiveStatus: false,
                                                shouldShowSyncStatus: false,
                                                shouldShowFavoriteIcon: false,
                                              ),
                                            ),
                                          )
                                        : const NoThumbnailWidget(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: SizedBox(
                                  width: 90,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        locationSearchResult.name(),
                                        style: enteTextTheme.mini.copyWith(
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: Container(
                        color: const Color.fromRGBO(0, 0, 0, 0.6),
                        width: 15,
                        height: 15,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 0.5,
                          color: strokeSolidMutedLight,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on_sharp,
                      color: Colors.white,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Used for non-empty state of location section.
class GoToMapWithBG extends StatelessWidget {
  const GoToMapWithBG({super.key});

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: max(0, 2.5 - LocationRecommendation.outerStrokeWidth),
      ),
      child: GestureDetector(
        onTap: () async {
          final bool result = await requestForMapEnable(context);
          if (result) {
            // ignore: unawaited_futures
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  filesFutureFn: SearchService.instance.getAllFilesForSearch,
                ),
              ),
            );
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: LocationRecommendation.outerCornerRadius +
                    LocationRecommendation.outerStrokeWidth,
                cornerSmoothing: LocationRecommendation.cornerSmoothing,
              ),
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                width: LocationRecommendation.width +
                    LocationRecommendation.outerStrokeWidth * 2,
                height: LocationRecommendation.height +
                    LocationRecommendation.outerStrokeWidth * 2,
              ),
            ),
            SizedBox(
              width: LocationRecommendation.width,
              height: LocationRecommendation.height,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 1,
                      offset: Offset(0, 0),
                      color: Color.fromRGBO(0, 0, 0, 0.09),
                      blurStyle: BlurStyle.outer,
                    ),
                    BoxShadow(
                      blurRadius: 1,
                      offset: Offset(1, 2),
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurStyle: BlurStyle.outer,
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: LocationRecommendation.outerCornerRadius,
                    cornerSmoothing: LocationRecommendation.cornerSmoothing,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset("assets/earth_blurred.png"),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          LocationRecommendation.outerPadding,
                          LocationRecommendation.outerPadding,
                          LocationRecommendation.outerPadding,
                          LocationRecommendation.outerPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: LocationRecommendation.sideOfThumbnail,
                              height: LocationRecommendation.sideOfThumbnail,
                              child: Image.asset("assets/map_world.png"),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: SizedBox(
                                width: 90,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      S.of(context).yourMap,
                                      style: enteTextTheme.mini.copyWith(
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

class LocationCTA extends StatelessWidget {
  const LocationCTA({super.key});

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: max(0, 2.5 - LocationRecommendation.outerStrokeWidth),
      ),
      child: GestureDetector(
        onTap: SectionType.location.ctaOnTap(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: LocationRecommendation.outerCornerRadius +
                    LocationRecommendation.outerStrokeWidth,
                cornerSmoothing: LocationRecommendation.cornerSmoothing,
              ),
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                width: LocationRecommendation.width +
                    LocationRecommendation.outerStrokeWidth * 2,
                height: LocationRecommendation.height +
                    LocationRecommendation.outerStrokeWidth * 2,
              ),
            ),
            SizedBox(
              width: LocationRecommendation.width,
              height: LocationRecommendation.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 1,
                      offset: Offset(0, 0),
                      color: Color.fromRGBO(0, 0, 0, 0.09),
                      blurStyle: BlurStyle.outer,
                    ),
                    BoxShadow(
                      blurRadius: 1,
                      offset: Offset(1, 2),
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurStyle: BlurStyle.outer,
                    ),
                  ],
                  color: enteColorScheme.backgroundElevated,
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: LocationRecommendation.outerCornerRadius,
                    cornerSmoothing: LocationRecommendation.cornerSmoothing,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      LocationRecommendation.outerPadding + 2,
                      LocationRecommendation.outerPadding + 3,
                      LocationRecommendation.outerPadding + 2,
                      LocationRecommendation.outerPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DottedBorder(
                          dashPattern: const [2, 2],
                          color: enteColorScheme.strokeFaint,
                          strokeWidth: 1,
                          padding: const EdgeInsets.all(0),
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(4.5),
                          child: SizedBox(
                            width: 90,
                            height: 84,
                            child: Icon(
                              Icons.add_location_alt_outlined,
                              color: enteColorScheme.strokeFaint,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SizedBox(
                            width: 90,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  S.of(context).addNew,
                                  style: enteTextTheme.miniFaint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
