import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/only_them_filter.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/face_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/generic_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/only_them_filter_chip.dart";

class AppliedFiltersForAppbar extends StatefulWidget {
  const AppliedFiltersForAppbar({super.key});

  @override
  State<AppliedFiltersForAppbar> createState() =>
      _AppliedFiltersForAppbarState();
}

class _AppliedFiltersForAppbarState extends State<AppliedFiltersForAppbar> {
  late SearchFilterDataProvider _searchFilterDataProvider;
  late List<HierarchicalSearchFilter> _appliedFilters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inheritedSearchFilterData = InheritedSearchFilterData.of(context);
    assert(
      inheritedSearchFilterData.isHierarchicalSearchable,
      "Do not use this widget if gallery is not hierarchical searchable",
    );
    _searchFilterDataProvider =
        inheritedSearchFilterData.searchFilterDataProvider!;
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
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ListView.builder(
          itemBuilder: (context, index) {
            final filter = _appliedFilters[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: filter is FaceFilter
                  ? FaceFilterChip(
                      personId: filter.personId,
                      clusterId: filter.clusterId,
                      apply: () {
                        _searchFilterDataProvider.applyFilters([filter]);
                      },
                      remove: () {
                        _searchFilterDataProvider
                            .removeAppliedFilters([filter]);
                      },
                      isApplied: filter.isApplied,
                    )
                  : filter is OnlyThemFilter
                      ? OnlyThemFilterChip(
                          faceFilters: filter.faceFilters,
                          apply: () {
                            _searchFilterDataProvider.applyFilters([filter]);
                          },
                          remove: () {
                            _searchFilterDataProvider
                                .removeAppliedFilters([filter]);
                          },
                          isApplied: filter.isApplied,
                        )
                      : GenericFilterChip(
                          label: filter.name(),
                          apply: () {
                            _searchFilterDataProvider.applyFilters([filter]);
                          },
                          remove: () {
                            _searchFilterDataProvider
                                .removeAppliedFilters([filter]);
                          },
                          leadingIcon: filter.icon(),
                          isApplied: filter.isApplied,
                        ),
            );
          },
          scrollDirection: Axis.horizontal,
          itemCount: _appliedFilters.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        Container(
          width: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getEnteColorScheme(context).backdropBase,
                getEnteColorScheme(context).backdropBase.withValues(alpha: 0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }

  void onAppliedFiltersUpdate() {
    setState(() {
      _appliedFilters = _searchFilterDataProvider.appliedFilters;
    });
  }
}
