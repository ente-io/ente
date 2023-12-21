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
  Stream<List<SearchResult>>? searchResultsStream;
  @override
  Widget build(BuildContext context) {
    return InheritedSearchResults(
      searchResultsStream,
      updateSearchResults,
      child: widget.child,
    );
  }

  void updateSearchResults(Stream<List<SearchResult>> newStream) {
    setState(() {
      searchResultsStream = newStream;
    });
  }
}

class InheritedSearchResults extends InheritedWidget {
  final Stream<List<SearchResult>>? searchResultsStream;
  final VoidCallbackParamSearchResutlsStream updateStream;
  const InheritedSearchResults(
    this.searchResultsStream,
    this.updateStream, {
    required super.child,
    super.key,
  });

  static InheritedSearchResults of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedSearchResults>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedSearchResults oldWidget) {
    return searchResultsStream != oldWidget.searchResultsStream;
  }
}
