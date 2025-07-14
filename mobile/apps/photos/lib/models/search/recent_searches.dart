import "package:flutter/material.dart";
import "package:photos/core/constants.dart";

class RecentSearches with ChangeNotifier {
  static RecentSearches? _instance;

  RecentSearches._();

  factory RecentSearches() => _instance ??= RecentSearches._();

  final searches = <String>{};

  void add(String query) {
    searches.add(query);
    while (searches.length > kSearchSectionLimit) {
      searches.remove(searches.first);
    }
    //buffer for not surfacing a new recent search before going to the next
    //screen
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
