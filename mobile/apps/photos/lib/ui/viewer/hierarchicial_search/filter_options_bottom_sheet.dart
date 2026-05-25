import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/hierarchical_filter_chip.dart";
import "package:photos/utils/hierarchical_search_util.dart";

class FilterOptionsBottomSheet extends StatefulWidget {
  final SearchFilterDataProvider searchFilterDataProvider;
  const FilterOptionsBottomSheet(this.searchFilterDataProvider, {super.key});

  @override
  State<FilterOptionsBottomSheet> createState() =>
      _FilterOptionsBottomSheetState();
}

class _FilterOptionsBottomSheetState extends State<FilterOptionsBottomSheet> {
  late final List<List<HierarchicalSearchFilter>> _filterGroups;

  @override
  void initState() {
    super.initState();
    _filterGroups = getFiltersForBottomSheet(
      widget.searchFilterDataProvider,
    ).values.where((filters) => filters.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final filters in _filterGroups)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final filter in filters) _buildFilterChip(filter),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(HierarchicalSearchFilter filter) {
    return HierarchicalFilterChip(
      filter: filter,
      apply: () => _applyFilter(filter),
      remove: () => _removeFilter(filter),
    );
  }

  void _applyFilter(HierarchicalSearchFilter filter) {
    widget.searchFilterDataProvider.applyFilters([filter]);
    Navigator.of(context).pop();
  }

  void _removeFilter(HierarchicalSearchFilter filter) {
    widget.searchFilterDataProvider.removeAppliedFilters([filter]);
    Navigator.of(context).pop();
  }
}
