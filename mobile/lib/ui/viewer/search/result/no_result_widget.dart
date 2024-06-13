import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/all_sections_examples_state.dart";
import "package:photos/theme/ente_theme.dart";

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
    searchTypes.remove(SectionType.magic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    InheritedAllSectionsExamples.of(context)
        .allSectionsExamplesFuture
        .then((value) {
      if (value.isEmpty) return;
      for (int i = 0; i < searchTypes.length; i++) {
        final querySuggestions = <String>[];
        for (int j = 0; j < 2 && j < value[i].length; j++) {
          querySuggestions.add(value[i][j].name());
        }
        if (querySuggestions.isNotEmpty) {
          searchTypeToQuerySuggestion.addAll({
            searchTypes[i].sectionTitle(context): querySuggestions,
          });
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
          ),
        );
      },
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Bus.instance.fire(ClearAndUnfocusSearchBar());
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).noResultsFound,
                  style: textTheme.largeBold,
                ),
                const SizedBox(height: 6),
                searchTypeToQuerySuggestion.isNotEmpty
                    ? Text(
                        S.of(context).modifyYourQueryOrTrySearchingFor,
                        style: textTheme.smallMuted,
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
      ),
    );
  }

  /// Join the strings with ', ' and wrap each element with double quotes
  String formatList(List<String> strings) {
    return strings.map((str) => '"$str"').join(', ');
  }
}
