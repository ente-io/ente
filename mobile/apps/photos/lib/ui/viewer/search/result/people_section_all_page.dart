import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/events/event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/bottom_action_bar/people_bottom_action_bar_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/ui/viewer/people/person_gallery_suggestion.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search_tab/people_section.dart";
import "package:photos/utils/navigation_util.dart";

class PeopleSectionAllPage extends StatefulWidget {
  const PeopleSectionAllPage({
    super.key,
  });

  @override
  State<PeopleSectionAllPage> createState() => _PeopleSectionAllPageState();
}

class _PeopleSectionAllPageState extends State<PeopleSectionAllPage> {
  final _selectedPeople = SelectedPeople();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _selectedPeople,
      builder: (context, _) {
        final hasSelection = _selectedPeople.personIds.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(SectionType.face.sectionTitle(context)),
            centerTitle: false,
          ),
          body: PeopleSectionAllSelectionWrapper(
            selectedPeople: _selectedPeople,
          ),
          bottomNavigationBar: hasSelection
              ? PeopleBottomActionBarWidget(
                  _selectedPeople,
                  onCancel: () {
                    _selectedPeople.clearAll();
                  },
                )
              : null,
        );
      },
    );
  }
}

class PeopleSectionAllSelectionWrapper extends StatefulWidget {
  final SelectedPeople selectedPeople;

  const PeopleSectionAllSelectionWrapper({
    super.key,
    required this.selectedPeople,
  });

  @override
  State<PeopleSectionAllSelectionWrapper> createState() =>
      _PeopleSectionAllSelectionWrapperState();
}

class _PeopleSectionAllSelectionWrapperState
    extends State<PeopleSectionAllSelectionWrapper> {
  @override
  Widget build(BuildContext context) {
    return PeopleSectionAllWidget(
      selectedPeople: widget.selectedPeople,
    );
  }
}

class SelectablePersonSearchExample extends StatelessWidget {
  final GenericSearchResult searchResult;
  final double size;
  final SelectedPeople selectedPeople;
  final bool isDefaultFace;

  const SelectablePersonSearchExample({
    super.key,
    required this.searchResult,
    required this.selectedPeople,
    this.size = 102,
    this.isDefaultFace = false,
  });

  void _handleTap(BuildContext context) {
    if (selectedPeople.personIds.isNotEmpty) {
      _toggleSelection();
    } else {
      _handleNavigation(context);
    }
  }

  void _handleLongPress() {
    _toggleSelection();
  }

  void _toggleSelection() {
    final personId = searchResult.params[kPersonParamID] as String?;
    final clusterId = searchResult.params[kClusterParamId] as String?;

    final idToUse =
        (personId != null && personId.isNotEmpty) ? personId : clusterId;

    if (idToUse != null && idToUse.isNotEmpty) {
      selectedPeople.toggleSelection(idToUse);
    }
  }

  void _handleNavigation(BuildContext context) {
    RecentSearches().add(searchResult.name());
    if (searchResult.onResultTap != null) {
      searchResult.onResultTap!(context);
    } else {
      routeToPage(
        context,
        SearchResultPage(searchResult),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = 82 * (size / 102);
    final bool isCluster = (searchResult.type() == ResultType.faces &&
        int.tryParse(searchResult.name()) != null);

    return ListenableBuilder(
      listenable: selectedPeople,
      builder: (context, _) {
        final personId = searchResult.params[kPersonParamID] as String?;
        final clusterId = searchResult.params[kClusterParamId] as String?;
        final idToCheck =
            (personId != null && personId.isNotEmpty) ? personId : clusterId;
        final bool isSelected = idToCheck != null
            ? selectedPeople.isPersonSelected(idToCheck)
            : false;

        return GestureDetector(
          onTap: () => _handleTap(context),
          onLongPress: _handleLongPress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: getEnteColorScheme(context).strokeFaint,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      late Widget child;

                      if (searchResult.previewThumbnail() != null) {
                        child = searchResult.type() != ResultType.faces
                            ? ThumbnailWidget(
                                searchResult.previewThumbnail()!,
                                shouldShowSyncStatus: false,
                              )
                            : FaceSearchResult(
                                searchResult,
                                isDefaultFace: isDefaultFace,
                              );
                      } else {
                        child = const NoThumbnailWidget(
                          addBorder: false,
                        );
                      }
                      return SizedBox(
                        width: size - 2,
                        height: size - 2,
                        child: ClipPath(
                          clipper: ShapeBorderClipper(
                            shape: ContinuousRectangleBorder(
                              borderRadius:
                                  searchResult.previewThumbnail() != null
                                      ? BorderRadius.circular(borderRadius - 1)
                                      : BorderRadius.circular(81),
                            ),
                          ),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(
                                alpha: isSelected ? 0.4 : 0,
                              ),
                              BlendMode.darken,
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                ],
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
                          routeToPage(
                            context,
                            PeoplePage(
                              person: result.$1,
                              searchResult: null,
                            ),
                          );
                        } else if (result != null && result is PersonEntity) {
                          // ignore: unawaited_futures
                          routeToPage(
                            context,
                            PeoplePage(
                              person: result,
                              searchResult: null,
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 0),
                        child: Text(
                          "Add name",
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: getEnteTextTheme(context).small,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 0),
                      child: Text(
                        searchResult.name(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: getEnteTextTheme(context).small,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class FaceSearchResult extends StatelessWidget {
  final SearchResult searchResult;
  final bool isDefaultFace;

  const FaceSearchResult(
    this.searchResult, {
    super.key,
    this.isDefaultFace = false,
  });

  @override
  Widget build(BuildContext context) {
    final params = (searchResult as GenericSearchResult).params;
    return PersonFaceWidget(
      personId: params[kPersonParamID],
      clusterID: params[kClusterParamId],
      key: params.containsKey(kPersonWidgetKey)
          ? ValueKey(params[kPersonWidgetKey])
          : ValueKey(params[kPersonParamID] ?? params[kClusterParamId]),
      keepAlive: isDefaultFace,
    );
  }
}

class PeopleSectionAllWidget extends StatefulWidget {
  const PeopleSectionAllWidget({
    super.key,
    this.selectedPeople,
    this.namedOnly = false,
  });

  final SelectedPeople? selectedPeople;
  final bool namedOnly;

  @override
  State<PeopleSectionAllWidget> createState() => _PeopleSectionAllWidgetState();
}

class _PeopleSectionAllWidgetState extends State<PeopleSectionAllWidget> {
  late Future<List<GenericSearchResult>> sectionData;
  List<GenericSearchResult> normalFaces = [];
  List<GenericSearchResult> extraFaces = [];
  final streamSubscriptions = <StreamSubscription>[];
  bool _showingAllFaces = false;
  bool _isLoaded = false;
  bool _isInitialLoad = true;
  bool userDismissedPersonGallerySuggestion = false;

  bool get _showMoreLessOption => !widget.namedOnly && extraFaces.isNotEmpty;

  @override
  void initState() {
    super.initState();
    sectionData = getResults(init: true);

    final streamsToListenTo = SectionType.face.viewAllUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          if (event is PeopleChangedEvent &&
              event.type == PeopleEventType.addedClusterToPerson) {
            normalFaces.removeWhere(
              (person) =>
                  (person.params[kClusterParamId] as String?) == event.source,
            );
            extraFaces.removeWhere(
              (person) =>
                  (person.params[kClusterParamId] as String?) == event.source,
            );
            setState(() {});
          } else {
            setState(() {
              _isInitialLoad = false;
              _isLoaded = false;
              sectionData = getResults();
            });
          }
        }),
      );
    }
  }

  Future<List<GenericSearchResult>> getResults({bool init = false}) async {
    final allFaces = await SearchService.instance
        .getAllFace(null, minClusterSize: kMinimumClusterSizeAllFaces);
    normalFaces.clear();
    extraFaces.clear();
    for (final face in allFaces) {
      if (face.fileCount() >= kMinimumClusterSizeSearchResult ||
          face.name().isNotEmpty) {
        normalFaces.add(face);
      } else {
        extraFaces.add(face);
      }
    }
    if (normalFaces.isEmpty && extraFaces.isNotEmpty) {
      normalFaces = extraFaces;
      extraFaces = [];
    }
    final results =
        _showingAllFaces ? [...normalFaces, ...extraFaces] : normalFaces;

    if (widget.namedOnly) {
      results.removeWhere(
        (element) => element.params[kPersonParamID] == null,
      );

      if (init) {
        // sort widget.selectedPeople first
        results.sort((a, b) {
          final aIndex = widget.selectedPeople?.personIds
                  .contains(a.params[kPersonParamID]) ??
              false;
          final bIndex = widget.selectedPeople?.personIds
                  .contains(b.params[kPersonParamID]) ??
              false;
          if (aIndex && !bIndex) return -1;
          if (!aIndex && bIndex) return 1;
          return a.name().compareTo(b.name());
        });
      }
    }
    _isLoaded = true;
    return results;
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;

    return FutureBuilder<List<GenericSearchResult>>(
      future: sectionData,
      builder: (context, snapshot) {
        if (!_isLoaded &&
            snapshot.connectionState == ConnectionState.waiting &&
            _isInitialLoad) {
          return const Center(child: EnteLoadingWidget());
        } else if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error_outline_rounded));
        } else if (normalFaces.isEmpty && _isLoaded) {
          return Center(
            child: Text(AppLocalizations.of(context).noResultsFound + '.'),
          );
        } else {
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = (screenWidth / 100).floor();

          final itemSize = (screenWidth -
                  ((horizontalEdgePadding * 2) +
                      ((crossAxisCount - 1) * gridPadding))) /
              crossAxisCount;

          return CustomScrollView(
            slivers: [
              (!userDismissedPersonGallerySuggestion && !widget.namedOnly)
                  ? SliverToBoxAdapter(
                      child: Dismissible(
                        key: const Key("personGallerySuggestionAll"),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          setState(() {
                            userDismissedPersonGallerySuggestion = true;
                          });
                        },
                        child: PersonGallerySuggestion(
                          person: null,
                          onClose: () {
                            setState(() {
                              userDismissedPersonGallerySuggestion = true;
                            });
                          },
                        ),
                      ),
                    )
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  horizontalEdgePadding,
                  16,
                  horizontalEdgePadding,
                  16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: gridPadding,
                    crossAxisSpacing: gridPadding,
                    crossAxisCount: crossAxisCount,
                    childAspectRatio:
                        itemSize / (itemSize + (24 * textScaleFactor)),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: normalFaces.length,
                    (context, index) {
                      return !widget.namedOnly
                          ? SelectablePersonSearchExample(
                              searchResult: normalFaces[index],
                              size: itemSize,
                              selectedPeople: widget.selectedPeople!,
                              isDefaultFace: true,
                            )
                          : PersonSearchExample(
                              searchResult: normalFaces[index],
                              size: itemSize,
                              selectedPeople: widget.selectedPeople!,
                            );
                    },
                  ),
                ),
              ),
              if (_showMoreLessOption)
                SliverToBoxAdapter(child: _buildShowMoreOrLessButton(context)),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              if (_showingAllFaces)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalEdgePadding,
                    16,
                    horizontalEdgePadding,
                    16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: gridPadding,
                      crossAxisSpacing: gridPadding,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio:
                          itemSize / (itemSize + (24 * textScaleFactor)),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: extraFaces.length,
                      (context, index) {
                        return !widget.namedOnly
                            ? SelectablePersonSearchExample(
                                searchResult: extraFaces[index],
                                size: itemSize,
                                selectedPeople: widget.selectedPeople!,
                                isDefaultFace: false,
                              )
                            : PersonSearchExample(
                                searchResult: extraFaces[index],
                                size: itemSize,
                                selectedPeople: widget.selectedPeople!,
                              );
                      },
                    ),
                  ),
                ),
              if (_showingAllFaces)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildShowMoreOrLessButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            if (_showingAllFaces) {
              setState(() {
                _showingAllFaces = false;
              });
            } else {
              setState(() {
                _showingAllFaces = true;
              });
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showingAllFaces
                    ? AppLocalizations.of(context).showLessFaces
                    : AppLocalizations.of(context).showMoreFaces,
                style: getEnteTextTheme(context).small.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                _showingAllFaces
                    ? Icons.keyboard_double_arrow_up_outlined
                    : Icons.keyboard_double_arrow_down_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
