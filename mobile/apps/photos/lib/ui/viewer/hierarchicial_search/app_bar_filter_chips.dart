import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/only_them_filter.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/face_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/generic_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/chip_widgets/only_them_filter_chip.dart";
import "package:photos/ui/viewer/hierarchicial_search/filter_options_bottom_sheet.dart";
import "package:photos/utils/hierarchical_search_util.dart";

class AppBarFilterChips extends StatefulWidget {
  const AppBarFilterChips({super.key});

  @override
  State<AppBarFilterChips> createState() => _AppBarFilterChipsState();
}

class _AppBarFilterChipsState extends State<AppBarFilterChips> {
  final _scrollController = ScrollController();
  final _filterChipKeys = Expando<GlobalKey>();
  late SearchFilterDataProvider _searchFilterDataProvider;
  late List<HierarchicalSearchFilter> _appliedFilters;
  late List<HierarchicalSearchFilter> _recommendations;
  HierarchicalSearchFilter? _filterToRevealAfterApply;

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
    _recommendations = getRecommendedFiltersForAppBar(
      _searchFilterDataProvider,
    );

    _searchFilterDataProvider.removeListener(
      fromApplied: true,
      listener: onFiltersUpdate,
    );
    _searchFilterDataProvider.removeListener(
      fromRecommended: true,
      listener: onFiltersUpdate,
    );
    _searchFilterDataProvider.addListener(
      toApplied: true,
      listener: onFiltersUpdate,
    );
    _searchFilterDataProvider.addListener(
      toRecommended: true,
      listener: onFiltersUpdate,
    );
  }

  @override
  void dispose() {
    _searchFilterDataProvider.removeListener(
      fromApplied: true,
      listener: onFiltersUpdate,
    );
    _searchFilterDataProvider.removeListener(
      fromRecommended: true,
      listener: onFiltersUpdate,
    );
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedFilters.isEmpty && _recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        // +1 to account for the filter's outer stroke width
        height: kFilterChipHeight + 1,
        child: ListView.builder(
          controller: _scrollController,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () {
                  showBarModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: FilterOptionsBottomSheet(
                          _searchFilterDataProvider,
                        ),
                      );
                    },
                    backgroundColor: getEnteColorScheme(
                      context,
                    ).backgroundElevated2,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: getEnteColorScheme(context).fillFaint,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(kFilterChipHeight / 2),
                      ),
                      border: Border.all(
                        color: getEnteColorScheme(context).strokeFaint,
                        width: 0.5,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.filter_list_rounded, size: 20),
                    ),
                  ),
                ),
              );
            }

            if (index <= _appliedFilters.length) {
              final filter = _appliedFilters[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildFilterChip(filter),
              );
            }

            final filter = _recommendations[index - _appliedFilters.length - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildFilterChip(filter),
            );
          },
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: _appliedFilters.length + _recommendations.length + 1,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildFilterChip(HierarchicalSearchFilter filter) {
    final chipKey = _keyForFilter(filter);
    return KeyedSubtree(
      key: chipKey,
      child: filter is FaceFilter
          ? FaceFilterChip(
              personId: filter.personId,
              clusterId: filter.clusterId,
              apply: () => _applyFilter(filter),
              remove: () => _removeFilter(filter),
              isApplied: filter.isApplied,
            )
          : filter is OnlyThemFilter
          ? OnlyThemFilterChip(
              faceFilters: filter.faceFilters,
              apply: () => _applyFilter(filter),
              remove: () => _removeFilter(filter),
              isApplied: filter.isApplied,
            )
          : GenericFilterChip(
              label: filter.name(),
              apply: () => _applyFilter(filter),
              remove: () => _removeFilter(filter),
              leadingIcon: filter.icon(),
              isApplied: filter.isApplied,
            ),
    );
  }

  GlobalKey _keyForFilter(HierarchicalSearchFilter filter) {
    return _filterChipKeys[filter] ??= GlobalKey(
      debugLabel: "app-bar-filter-${filter.filterTypeName}",
    );
  }

  void _applyFilter(HierarchicalSearchFilter filter) {
    _filterToRevealAfterApply = filter;
    _searchFilterDataProvider.applyFilters([filter]);
  }

  void _removeFilter(HierarchicalSearchFilter filter) {
    _searchFilterDataProvider.removeAppliedFilters([filter]);
  }

  void onFiltersUpdate() {
    setState(() {
      _appliedFilters = _searchFilterDataProvider.appliedFilters;
      _recommendations = getRecommendedFiltersForAppBar(
        _searchFilterDataProvider,
      );
    });
    _revealPendingAppliedFilter();
  }

  void _revealPendingAppliedFilter() {
    final filter = _filterToRevealAfterApply;
    if (filter == null) {
      return;
    }
    if (!_appliedFilters.any((applied) => applied.isSameFilter(filter))) {
      return;
    }

    _filterToRevealAfterApply = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final chipContext = _keyForFilter(filter).currentContext;
      if (chipContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        chipContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }
}
