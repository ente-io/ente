import "package:flutter/material.dart";

class IndexOfStackNotifier with ChangeNotifier {
  int _index = 0;
  bool _isSearchQueryEmpty = true;
  bool _isSearchResultsEmpty = true;

  static IndexOfStackNotifier? _instance;

  IndexOfStackNotifier._();

  factory IndexOfStackNotifier() => _instance ??= IndexOfStackNotifier._();

  set isSearchQueryEmpty(bool value) {
    _isSearchQueryEmpty = value;
    setIndex();
  }

  set isSearchResultsEmpty(bool value) {
    _isSearchResultsEmpty = value;
    setIndex();
  }

  setIndex() {
    if (_isSearchResultsEmpty) {
      if (_isSearchQueryEmpty) {
        _index = 0;
      } else {
        _index = 2;
      }
    } else {
      _index = 1;
    }
    notifyListeners();
  }

  get index => _index;
}
