import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class SearchFilterDataProvider {
  final _appliedFiltersNotifier = _AppliedFiltersNotifier();
  final _recommendedFiltersNotifier = _RecommendedFiltersNotifier();

  //TODO: Make this non-nullable and required so every time this is wrapped
  //over a gallery's scaffold, it's forced to provide an initial gallery filter
  HierarchicalSearchFilter? initialGalleryFilter;

  List<HierarchicalSearchFilter> get recommendations =>
      _recommendedFiltersNotifier.recommendedFilters;
  List<HierarchicalSearchFilter> get appliedFilters =>
      _appliedFiltersNotifier.appliedFilters;

  void addRecommendations(List<HierarchicalSearchFilter> filters) {
    _recommendedFiltersNotifier.addFilters(
      filters,
      initialGalleryFilter: initialGalleryFilter,
    );
  }

  void applyFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFiltersNotifier.addFilters(filters);
    _recommendedFiltersNotifier.removeFilters(filters);
  }

  void removeAppliedFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFiltersNotifier.removeFilters(filters);
    _recommendedFiltersNotifier.addFilters(
      filters,
      initialGalleryFilter: initialGalleryFilter,
    );
  }

  void clearRecommendations() {
    _recommendedFiltersNotifier.clearFilters();
  }

  void addListener({
    bool toApplied = false,
    bool toRecommended = false,
    required VoidCallback listener,
  }) {
    assert(
      toApplied != false || toRecommended != false,
      "Listener not added to any notifier",
    );
    if (toApplied) {
      _appliedFiltersNotifier.addListener(listener);
    } else if (toRecommended) {
      _recommendedFiltersNotifier.addListener(listener);
    }
  }

  void removeListener({
    bool fromApplied = false,
    bool fromRecommended = false,
    required VoidCallback listener,
  }) {
    assert(
      fromApplied != false || fromRecommended != false,
      "Listener not removed from any notifier",
    );
    if (fromApplied) {
      _appliedFiltersNotifier.removeListener(listener);
    } else if (fromRecommended) {
      _recommendedFiltersNotifier.removeListener(listener);
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

  void addFilters(
    List<HierarchicalSearchFilter> filters, {
    required HierarchicalSearchFilter? initialGalleryFilter,
  }) {
    if (initialGalleryFilter != null) {
      for (HierarchicalSearchFilter filter in filters) {
        if (filter.isSameFilter(initialGalleryFilter)) {
          continue;
        }
        _recommendedFilters.add(filter);
      }
    } else {
      //To check if such cases come up during development of hierarchical search
      assert(
        false,
        "Initial gallery filter not provided",
      );
      _recommendedFilters.addAll(filters);
    }
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
