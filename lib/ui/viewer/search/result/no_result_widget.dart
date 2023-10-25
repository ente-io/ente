import 'package:flutter/material.dart';
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
  final searchTypeToSearchSuggestion = <String, List<String>>{};
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
        //todo: remove keys with empty list
        searchTypeToSearchSuggestion
            .addAll({searchTypes[i].sectionTitle(context): querySuggestions});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final examples = <Widget>[];
    searchTypeToSearchSuggestion.forEach(
      (key, value) {
        examples.add(
          Row(
            children: [
              Text(
                key,
                style: textTheme.bodyMuted,
              ),
              const SizedBox(width: 6),
              Text(
                formatList(value),
                style: textTheme.miniMuted,
              ),
            ],
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
              ),
              const SizedBox(height: 6),
              Text(
                "Modify your query, or try searching for",
                style: textTheme.smallMuted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ListView.separated(
              itemBuilder: (context, index) {
                return examples[index];
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemCount: searchTypeToSearchSuggestion.length,
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
