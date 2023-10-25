import 'package:flutter/material.dart';
import "package:photos/models/search/search_types.dart";
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
    return const SizedBox.shrink();
  }
}
