import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/search_tab.dart";

class NoResultWidget extends StatefulWidget {
  const NoResultWidget({Key? key}) : super(key: key);

  @override
  State<NoResultWidget> createState() => _NoResultWidgetState();
}

class _NoResultWidgetState extends State<NoResultWidget> {
  late final List<SectionType> searchTypes;
  final searchTypeToQuerySuggestion = <String, List<String>>{};
  @override
  void initState() {
    super.initState();
    searchTypes = SectionType.values.toList(growable: true);
    // remove face and content sectionType
    searchTypes.remove(SectionType.face);
    searchTypes.remove(SectionType.content);
    allSectionsExamples.then((value) {
      for (int i = 0; i < searchTypes.length; i++) {
        final querySuggestions = <String>[];
        for (int j = 0; j < 2 && j < value[i].length; j++) {
          querySuggestions.add(value[i][j].name());
        }
        if (querySuggestions.isNotEmpty) {
          searchTypeToQuerySuggestion
              .addAll({searchTypes[i].sectionTitle(context): querySuggestions});
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final searchTypeAndSuggestion = <Widget>[];
    searchTypeToQuerySuggestion.forEach(
      (key, value) {
        searchTypeAndSuggestion.add(
          Row(
            children: [
              Text(
                key,
                style: textTheme.bodyMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  formatList(value),
                  style: textTheme.miniMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOut,
              )
              .slide(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOut,
              ),
        );
      },
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // S.of(context).noResults,
                "No results found",
                style: textTheme.largeBold,
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.easeInOut,
                  )
                  .slide(
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 6),
              searchTypeToQuerySuggestion.isNotEmpty
                  ? Text(
                      "Modify your query, or try searching for",
                      style: textTheme.smallMuted,
                    )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 50),
                        curve: Curves.easeInOut,
                      )
                      .slide(
                        duration: const Duration(milliseconds: 50),
                        curve: Curves.easeInOut,
                      )
                  : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ListView.separated(
              itemBuilder: (context, index) {
                return searchTypeAndSuggestion[index];
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemCount: searchTypeToQuerySuggestion.length,
              shrinkWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String formatList(List<String> strings) {
    // Join the strings with ', ' and wrap each element with double quotes
    return strings.map((str) => '"$str"').join(', ');
  }
}
