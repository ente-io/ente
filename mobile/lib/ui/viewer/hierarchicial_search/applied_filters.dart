import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/filter_chip.dart";

class AppliedFilters extends StatefulWidget {
  const AppliedFilters({super.key});

  @override
  State<AppliedFilters> createState() => _AppliedFiltersState();
}

class _AppliedFiltersState extends State<AppliedFilters> {
  late SearchFilterDataProvider _searchFilterDataProvider;
  late List<HierarchicalSearchFilter> _appliedFilters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final temp = InheritedSearchFilterData.of(context).searchFilterDataProvider;
    assert(temp != null, "SearchFilterDataProvider is null");
    _searchFilterDataProvider = temp!;
    _appliedFilters = _searchFilterDataProvider.appliedFilters;

    _searchFilterDataProvider.removeListener(
      fromApplied: true,
      listener: onAppliedFiltersUpdate,
    );
    _searchFilterDataProvider.addListener(
      toApplied: true,
      listener: onAppliedFiltersUpdate,
    );
  }

  @override
  void dispose() {
    _searchFilterDataProvider.removeListener(
      fromApplied: true,
      listener: onAppliedFiltersUpdate,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final filter = _appliedFilters[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: filter is FaceFilter
              ? FaceFilterChip(
                  personId: filter.personId,
                  clusterId: filter.clusterId,
                  faceThumbnailFile: EnteFile(),
                  name: filter.name(),
                  onTap: () {
                    _searchFilterDataProvider.removeAppliedFilters([filter]);
                  },
                )
              : GenericFilterChip(
                  label: filter.name(),
                  onTap: () {
                    _searchFilterDataProvider.removeAppliedFilters([filter]);
                  },
                  leadingIcon: filter.icon(),
                ),
        );
      },
      scrollDirection: Axis.horizontal,
      itemCount: _appliedFilters.length,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void onAppliedFiltersUpdate() {
    setState(() {
      _appliedFilters = _searchFilterDataProvider.appliedFilters;
    });
  }
}
