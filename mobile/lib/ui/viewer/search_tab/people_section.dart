import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/settings/ml/machine_learning_settings_page.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import 'package:photos/ui/viewer/search/result/person_face_widget.dart';
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import 'package:photos/ui/viewer/search/result/search_section_all_page.dart';
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/utils/navigation_util.dart";

class PeopleSection extends StatefulWidget {
  final SectionType sectionType = SectionType.face;
  final List<SearchResult> examples;
  final int limit;

  const PeopleSection({
    Key? key,
    required this.examples,
    this.limit = 7,
  }) : super(key: key);

  @override
  State<PeopleSection> createState() => _PeopleSectionState();
}

class _PeopleSectionState extends State<PeopleSection> {
  late List<SearchResult> _examples;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _examples = widget.examples;

    final streamsToListenTo = widget.sectionType.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _examples = await widget.sectionType.getData(
            context,
            limit: kSearchSectionLimit,
          );
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
  void didUpdateWidget(covariant PeopleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _examples = widget.examples;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for ${widget.sectionType.name}");
    final shouldShowMore = _examples.length >= widget.limit - 1;
    final textTheme = getEnteTextTheme(context);
    return _examples.isNotEmpty
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (shouldShowMore) {
                routeToPage(
                  context,
                  SearchSectionAllPage(
                    sectionType: widget.sectionType,
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.sectionType.sectionTitle(context),
                        style: textTheme.largeBold,
                      ),
                    ),
                    shouldShowMore
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.chevron_right_outlined,
                              color: getEnteColorScheme(context).strokeMuted,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 2),
                SearchExampleRow(_examples, widget.sectionType),
              ],
            ),
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              routeToPage(
                context,
                const MachineLearningSettingsPage(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sectionType.sectionTitle(context),
                            style: textTheme.largeBold,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.sectionType.getEmptyStateText(context),
                            style: textTheme.smallMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SearchSectionEmptyCTAIcon(widget.sectionType),
                ],
              ),
            ),
          );
  }
}

class SearchExampleRow extends StatelessWidget {
  final SectionType sectionType;
  final List<SearchResult> examples;

  const SearchExampleRow(this.examples, this.sectionType, {super.key});

  @override
  Widget build(BuildContext context) {
    //Cannot use listView.builder here
    final scrollableExamples = <Widget>[];
    examples.forEachIndexed((index, element) {
      scrollableExamples.add(
        SearchExample(
          searchResult: examples.elementAt(index),
        ),
      );
    });
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
    final bool isCluster = (searchResult.type() == ResultType.faces &&
        int.tryParse(searchResult.name()) != null);
    late final double width;
    if (textScaleFactor <= 1.0) {
      width = 85.0;
    } else {
      width = 85.0 + ((textScaleFactor - 1.0) * 64);
    }
    final heroTag =
        searchResult.heroTag() + (searchResult.previewThumbnail()?.tag ?? "");
    return GestureDetector(
      onTap: () {
        RecentSearches().add(searchResult.name());

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
          final albumSearchResult = searchResult as GenericSearchResult;
          routeToPage(
            context,
            SearchResultPage(
              albumSearchResult,
              tagPrefix: albumSearchResult.heroTag(),
            ),
          );
        }
      },
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: searchResult.previewThumbnail() != null
                    ? Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.elliptical(16, 12)),
                          child: searchResult.type() != ResultType.faces
                              ? ThumbnailWidget(
                                  searchResult.previewThumbnail()!,
                                  shouldShowSyncStatus: false,
                                )
                              : FaceSearchResult(searchResult, heroTag),
                        ),
                      )
                    : const ClipRRect(
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(16, 12)),
                        child: NoThumbnailWidget(
                          addBorder: false,
                        ),
                      ),
              ),
              isCluster
                  ? GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        final result = await showAssignPersonAction(
                          context,
                          clusterID: searchResult.name(),
                        );
                        if (result != null &&
                            result is (PersonEntity, EnteFile)) {
                          // ignore: unawaited_futures
                          routeToPage(context, PeoplePage(person: result.$1));
                        } else if (result != null && result is PersonEntity) {
                          // ignore: unawaited_futures
                          routeToPage(context, PeoplePage(person: result));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 16),
                        child: Text(
                          "Add name",
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: getEnteTextTheme(context).mini,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 16),
                      child: Text(
                        searchResult.name(),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: getEnteTextTheme(context).mini,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceSearchResult extends StatelessWidget {
  final SearchResult searchResult;
  final String heroTagPrefix;
  const FaceSearchResult(this.searchResult, this.heroTagPrefix, {super.key});

  @override
  Widget build(BuildContext context) {
    return PersonFaceWidget(
      searchResult.previewThumbnail()!,
      personId: (searchResult as GenericSearchResult).params[kPersonParamID],
      clusterID: (searchResult as GenericSearchResult).params[kClusterParamId],
    );
  }
}
