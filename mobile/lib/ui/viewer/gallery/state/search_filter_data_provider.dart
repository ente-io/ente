import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class SearchFilterDataProvider {
  final _appliedFiltersNotifier = _AppliedFiltersNotifier();
  final _recommendedFiltersNotifier = _RecommendedFiltersNotifier();

  //TODO: Make this non-nullable and required so every time this is wrapped
  //over a gallery's scaffold, it's forced to provide an initial gallery filter
  HierarchicalSearchFilter? initialGalleryFilter;
  final isSearchingNotifier = ValueNotifier(false);

  List<HierarchicalSearchFilter> get recommendations =>
      _recommendedFiltersNotifier.recommendedFilters;
  List<HierarchicalSearchFilter> get appliedFilters =>
      _appliedFiltersNotifier.appliedFilters;

  void clearAndAddRecommendations(List<HierarchicalSearchFilter> filters) {
    _recommendedFiltersNotifier.clearFilters();
    _safelyAddToRecommended(filters);
  }

  void applyFilters(List<HierarchicalSearchFilter> filters) {
    _recommendedFiltersNotifier.removeFilters(filters);
    if (!isSearchingNotifier.value) {
      isSearchingNotifier.value = true;
      _appliedFiltersNotifier.addFilters([initialGalleryFilter!, ...filters]);
    } else {
      _appliedFiltersNotifier.addFilters(filters);
    }
  }

  void removeAppliedFilters(List<HierarchicalSearchFilter> filters) {
    _appliedFiltersNotifier.removeFilters(filters);
    _safelyAddToRecommended(filters);
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

  void _safelyAddToRecommended(List<HierarchicalSearchFilter> filters) {
    _recommendedFiltersNotifier.addFilters(
      filters,
      filtersToAvoid: [
        initialGalleryFilter!,
        ...appliedFilters,
        ...recommendations,
      ],
    );
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
    ///This is to ensure that the filters that are being added are not already
    ///already in recommendations or applied filters
    required List<HierarchicalSearchFilter> filtersToAvoid,
  }) {
    for (HierarchicalSearchFilter filter in filters) {
      bool avoidFilter = false;
      for (HierarchicalSearchFilter filterToAvoid in filtersToAvoid) {
        if (filter.isSameFilter(filterToAvoid)) {
          avoidFilter = true;
          break;
        }
      }
      if (avoidFilter) {
        continue;
      }
      _recommendedFilters.add(filter);
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
