import "package:flutter/material.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";

class InheritedSearchFilterData extends InheritedWidget {
  const InheritedSearchFilterData({
    super.key,
    required this.searchFilterDataProvider,
    required super.child,
  });

  final SearchFilterDataProvider? searchFilterDataProvider;

  static InheritedSearchFilterData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedSearchFilterData>();
  }

  static InheritedSearchFilterData of(BuildContext context) {
    final InheritedSearchFilterData? result = maybeOf(context);
    assert(result != null, 'No InheritedSearchFilterData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedSearchFilterData oldWidget) =>
      searchFilterDataProvider != oldWidget.searchFilterDataProvider;
}
