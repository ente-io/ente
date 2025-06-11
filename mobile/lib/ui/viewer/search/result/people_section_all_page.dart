import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search_tab/people_section.dart";

class PeopleSectionAllPage extends StatelessWidget {
  const PeopleSectionAllPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SectionType.face.sectionTitle(context)),
        centerTitle: false,
      ),
      body: const PeopleSectionAllWidget(),
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

  bool get _showMoreLessOption => !widget.namedOnly && extraFaces.isNotEmpty;

  @override
  void initState() {
    super.initState();
    sectionData = getResults();

    final streamsToListenTo = SectionType.face.viewAllUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          setState(() {
            _isLoaded = false;
            sectionData = getResults();
          });
        }),
      );
    }
  }

  Future<List<GenericSearchResult>> getResults() async {
    final allFaces = await SearchService.instance
        .getAllFace(null, minClusterSize: kMinimumClusterSizeAllFaces);
    normalFaces.clear();
    extraFaces.clear();
    for (final face in allFaces) {
      if (face.fileCount() >= kMinimumClusterSizeSearchResult) {
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
      if (widget.selectedPeople?.personIds.isEmpty ?? false) {
        widget.selectedPeople!.select(
          results
              .take(2)
              .map((e) => e.params[kPersonParamID] as String)
              .toSet(),
        );
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
        if (!_isLoaded && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: EnteLoadingWidget());
        } else if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error_outline_rounded));
        } else if (normalFaces.isEmpty && _isLoaded) {
          return Center(child: Text(S.of(context).noResultsFound + '.'));
        } else {
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = (screenWidth / 100).floor();

          final itemSize = (screenWidth -
                  ((horizontalEdgePadding * 2) +
                      ((crossAxisCount - 1) * gridPadding))) /
              crossAxisCount;

          return CustomScrollView(
            slivers: [
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
                      return PersonSearchExample(
                        searchResult: normalFaces[index],
                        size: itemSize,
                        selectedPeople: widget.selectedPeople,
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
                        return PersonSearchExample(
                          searchResult: extraFaces[index],
                          size: itemSize,
                          selectedPeople: widget.selectedPeople,
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showingAllFaces ? "Show less faces" : "Show more faces",
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
