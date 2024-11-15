import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search_tab/people_section.dart";

class PeopleSectionAllPage extends StatelessWidget {
  final Future<List<SearchResult>> searchResults;

  const PeopleSectionAllPage({
    super.key,
    required this.searchResults,
  });

  @override
  Widget build(BuildContext context) {
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 4.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).people),
      ),
      body: FutureBuilder<List<SearchResult>>(
        future: searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No results found.'));
          } else {
            final results = snapshot.data!;
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = (screenWidth / 100).floor();

            final itemSize = (screenWidth -
                    ((horizontalEdgePadding * 2) +
                        (crossAxisCount * gridPadding))) /
                crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.all(horizontalEdgePadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: gridPadding,
                crossAxisSpacing: gridPadding,
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    itemSize / (itemSize + (18 * textScaleFactor)),
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return PersonSearchExample(
                  searchResult: results[index],
                  size: itemSize,
                );
              },
            );
          }
        },
      ),
    );
  }
}
