import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/generated/l10n.dart";
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

  static const chipHeight = 40.0;
  static const bottomPadding = 8.0;
  static const preferredHeight = chipHeight + bottomPadding;
  static const appBarHeight = kToolbarHeight + preferredHeight;

  @override
  State<AppBarFilterChips> createState() => _AppBarFilterChipsState();
}

class _AppBarFilterChipsState extends State<AppBarFilterChips> {
  final _filterChipKeys = <HierarchicalSearchFilter, GlobalKey>{};
  SearchFilterDataProvider? _searchFilterDataProvider;
  HierarchicalSearchFilter? _filterToRevealAfterApply;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inheritedSearchFilterData = InheritedSearchFilterData.of(context);
    assert(
      inheritedSearchFilterData.isHierarchicalSearchable,
      "Do not use this widget if gallery is not hierarchical searchable",
    );
    final searchFilterDataProvider =
        inheritedSearchFilterData.searchFilterDataProvider!;
    if (_searchFilterDataProvider == searchFilterDataProvider) {
      return;
    }
    _searchFilterDataProvider?.removeListener(
      fromApplied: true,
      listener: _onFiltersUpdate,
    );
    _searchFilterDataProvider?.removeListener(
      fromRecommended: true,
      listener: _onFiltersUpdate,
    );
    _searchFilterDataProvider = searchFilterDataProvider;
    searchFilterDataProvider.addListener(
      toApplied: true,
      listener: _onFiltersUpdate,
    );
    searchFilterDataProvider.addListener(
      toRecommended: true,
      listener: _onFiltersUpdate,
    );
  }

  @override
  void dispose() {
    _searchFilterDataProvider?.removeListener(
      fromApplied: true,
      listener: _onFiltersUpdate,
    );
    _searchFilterDataProvider?.removeListener(
      fromRecommended: true,
      listener: _onFiltersUpdate,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchFilterDataProvider = _searchFilterDataProvider!;
    final appliedFilters = searchFilterDataProvider.appliedFilters;
    final recommendations = getRecommendedFiltersForAppBar(
      searchFilterDataProvider,
    );
    if (appliedFilters.isEmpty && recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppBarFilterChips.bottomPadding),
      child: SizedBox(
        height: AppBarFilterChips.chipHeight,
        child: ListView.builder(
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAllFiltersButton(context, searchFilterDataProvider);
            }

            if (index <= appliedFilters.length) {
              final filter = appliedFilters[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildFilterChip(filter),
              );
            }

            final filter = recommendations[index - appliedFilters.length - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildFilterChip(filter),
            );
          },
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: appliedFilters.length + recommendations.length + 1,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildAllFiltersButton(
    BuildContext context,
    SearchFilterDataProvider searchFilterDataProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: AppBarFilterChips.chipHeight,
        child: Center(
          child: IconButtonComponent(
            icon: const Icon(Icons.filter_list_rounded),
            variant: IconButtonComponentVariant.primary,
            shouldSurfaceExecutionStates: false,
            tooltip: AppLocalizations.of(context).filter,
            onTap: () => showBarModalBottomSheet(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: FilterOptionsBottomSheet(searchFilterDataProvider),
                );
              },
              backgroundColor: getEnteColorScheme(context).backgroundElevated2,
            ),
          ),
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
    return _filterChipKeys[filter] ??= GlobalKey();
  }

  void _applyFilter(HierarchicalSearchFilter filter) {
    _filterToRevealAfterApply = filter;
    _searchFilterDataProvider!.applyFilters([filter]);
  }

  void _removeFilter(HierarchicalSearchFilter filter) {
    _searchFilterDataProvider!.removeAppliedFilters([filter]);
  }

  void _onFiltersUpdate() {
    setState(() {});
    _revealPendingAppliedFilter();
  }

  void _revealPendingAppliedFilter() {
    final filter = _filterToRevealAfterApply;
    if (filter == null) {
      return;
    }
    if (!_searchFilterDataProvider!.appliedFilters.any(
      (applied) => applied.isSameFilter(filter),
    )) {
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
