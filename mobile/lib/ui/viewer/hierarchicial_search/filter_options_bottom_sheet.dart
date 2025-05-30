import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/only_them_filter.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/face_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/generic_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/only_them_filter_chip.dart";
import "package:photos/utils/hierarchical_search_util.dart";

class FilterOptionsBottomSheet extends StatefulWidget {
  final SearchFilterDataProvider searchFilterDataProvider;
  const FilterOptionsBottomSheet(
    this.searchFilterDataProvider, {
    super.key,
  });

  @override
  State<FilterOptionsBottomSheet> createState() =>
      _FilterOptionsBottomSheetState();
}

class _FilterOptionsBottomSheetState extends State<FilterOptionsBottomSheet> {
  late final Map<String, List<HierarchicalSearchFilter>> _filters;

  @override
  void initState() {
    super.initState();
    _filters = getFiltersForBottomSheet(widget.searchFilterDataProvider);
    _filters.removeWhere((key, value) => value.isEmpty);
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
              for (String filterName in _filters.keys)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (HierarchicalSearchFilter filter
                          in _filters[filterName]!)
                        if (filter is FaceFilter)
                          FaceFilterChip(
                            personId: filter.personId,
                            clusterId: filter.clusterId,
                            isInAllFiltersView: true,
                            apply: () {
                              widget.searchFilterDataProvider
                                  .applyFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            remove: () {
                              widget.searchFilterDataProvider
                                  .removeAppliedFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            isApplied: filter.isApplied,
                          )
                        else if (filter is OnlyThemFilter)
                          OnlyThemFilterChip(
                            faceFilters: filter.faceFilters,
                            apply: () {
                              widget.searchFilterDataProvider
                                  .applyFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            remove: () {
                              widget.searchFilterDataProvider
                                  .removeAppliedFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            isApplied: filter.isApplied,
                            isInAllFiltersView: true,
                          )
                        else
                          GenericFilterChip(
                            label: filter.name(),
                            leadingIcon: filter.icon(),
                            apply: () {
                              widget.searchFilterDataProvider
                                  .applyFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            remove: () {
                              widget.searchFilterDataProvider
                                  .removeAppliedFilters([filter]);
                              Navigator.of(context).pop();
                            },
                            isApplied: filter.isApplied,
                            isInAllFiltersView: true,
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
