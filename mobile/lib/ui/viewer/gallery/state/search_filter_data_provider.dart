import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class SearchFilterDataProvider {
  final _appliedFiltersNotifier = _AppliedFiltersNotifier();
  final _recommendedFiltersNotifier = _RecommendedFiltersNotifier();

  get recommendations => _recommendedFiltersNotifier.recommendedFilters;
  get appliedFilters => _appliedFiltersNotifier.appliedFilters;

  void addRecommendations(List<HierarchicalSearchFilter> filters) {
    _recommendedFiltersNotifier.addFilters(filters);
  }

  void applyFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFiltersNotifier.addFilters(filters);
    _recommendedFiltersNotifier.removeFilters(filters);
  }

  void removeAppliedFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFiltersNotifier.removeFilters(filters);
    _recommendedFiltersNotifier.addFilters(filters);
  }

  void clearRecommendations() {
    _recommendedFiltersNotifier.clearFilters();
  }

  void addListener({
    bool toApplied = false,
    bool toRecommended = false,
    required VoidCallback listener,
  }) {
    if (toApplied) {
      _appliedFiltersNotifier.addListener(listener);
    }
    if (toRecommended) {
      _recommendedFiltersNotifier.addListener(listener);
    }
  }
}

class _AppliedFiltersNotifier extends ChangeNotifier {
  final List<HierarchicalSearchFilter> _appliedFilters = [];

  List<HierarchicalSearchFilter> get appliedFilters => _appliedFilters;

  void addFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFilters.addAll(filters);
    notifyListeners();
  }

  void removeFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFilters.removeWhere((filter) => filters.contains(filter));
    notifyListeners();
  }
}

class _RecommendedFiltersNotifier extends ChangeNotifier {
  final List<HierarchicalSearchFilter> _recommendedFilters = [];

  List<HierarchicalSearchFilter> get recommendedFilters => _recommendedFilters;

  void addFilters(List<HierarchicalSearchFilter> filters) {
    _recommendedFilters.addAll(filters);
    notifyListeners();
  }

  void removeFilters(List<HierarchicalSearchFilter> filters) {
    _recommendedFilters.removeWhere((filter) => filters.contains(filter));
    notifyListeners();
  }

  void clearFilters() {
    _recommendedFilters.clear();
    notifyListeners();
  }
}
