import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/search/search_result.dart";

class RecentSearches with ChangeNotifier {
  static RecentSearches? _instance;

  RecentSearches._();

  factory RecentSearches() => _instance ??= RecentSearches._();

  final searches = <SearchResult>{};

  void add(SearchResult result) {
    searches.add(result);
    while (searches.length > searchSectionLimit) {
      searches.remove(searches.first);
    }
    //buffer for not surfacing a new recent search before going to the next
    //screen
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
