import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";

class SearchSection extends StatelessWidget {
  final SectionType sectionType;
  final List<SearchResult> examples;

  const SearchSection({
    Key? key,
    required this.sectionType,
    required this.examples,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for ${sectionType.name}");
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionType.sectionTitle(context),
              style: textTheme.largeBold,
            ),
            const SizedBox(height: 16),
            // wrap below text in next line
            // Text(
            //   sectionType.getEmptyStateText(context),
            //   style: textTheme.smallMuted,
            //   softWrap: true,
            // ),
            SearchExampleRow(examples, sectionType),
          ],
        ),
      ),
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
    return SizedBox(
      width: 84,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: ThumbnailWidget(searchResult.previewThumbnail()!),
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
    );
  }
}
