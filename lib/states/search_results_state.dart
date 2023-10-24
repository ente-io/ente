import "package:flutter/cupertino.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/typedefs.dart";

class SearchResultsProvider extends StatefulWidget {
  final Widget child;
  const SearchResultsProvider({
    required this.child,
    super.key,
  });

  @override
  State<SearchResultsProvider> createState() => _SearchResultsProviderState();
}

class _SearchResultsProviderState extends State<SearchResultsProvider> {
  var searchResults = <SearchResult>[];
  @override
  Widget build(BuildContext context) {
    return InheritedSearchResults(
      searchResults,
      updateSearchResults,
      child: widget.child,
    );
  }

  void updateSearchResults(List<SearchResult> newResult) {
    setState(() {
      searchResults = newResult;
    });
  }
}

class InheritedSearchResults extends InheritedWidget {
  final List<SearchResult> results;
  final VoidCallbackParamSearchResults updateResults;
  const InheritedSearchResults(
    this.results,
    this.updateResults, {
    required super.child,
    super.key,
  });

  static InheritedSearchResults of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedSearchResults>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedSearchResults oldWidget) {
    return results != oldWidget.results;
  }
}
