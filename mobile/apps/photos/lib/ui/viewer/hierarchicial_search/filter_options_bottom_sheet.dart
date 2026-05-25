import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/theme/ente_theme.dart";
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
  static const _maxContentHeightFactor = 0.68;

  late final Map<String, List<HierarchicalSearchFilter>> _filtersByType;

  @override
  void initState() {
    super.initState();
    _filtersByType = getFiltersForBottomSheet(widget.searchFilterDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filterGroups = _filterGroups(context);

    return BottomSheetComponent(
      title: l10n.filter,
      closeTooltip: l10n.close,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * _maxContentHeightFactor,
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in filterGroups) ...[
                  _buildFilterGroup(context, group),
                  if (group != filterGroups.last) const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterGroup(BuildContext context, _FilterGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.label, style: getEnteTextTheme(context).smallBold),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final filter in group.filters) _buildFilterChip(filter),
          ],
        ),
      ],
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

  List<_FilterGroup> _filterGroups(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final peopleFilters = _peopleFilters;
    final groups = [
      _FilterGroup(l10n.people, peopleFilters),
      _FilterGroup(l10n.smartSuggestions, [
        ..._filters("magicFilters"),
        ..._filters("topLevelGenericFilter"),
      ]),
      _FilterGroup(l10n.contacts, _filters("contactsFilters")),
      _FilterGroup(l10n.searchResultUploadedBy, _filters("uploaderFilters")),
      _FilterGroup(l10n.camera, _filters("cameraFilters")),
      _FilterGroup(l10n.albums, _filters("albumFilters")),
      _FilterGroup(l10n.locations, _filters("locationFilters")),
      _FilterGroup(l10n.fileTypes, _filters("fileTypeFilters")),
    ];

    return groups.where((group) => group.filters.isNotEmpty).toList();
  }

  List<HierarchicalSearchFilter> get _peopleFilters {
    final faceFilters = _filters("faceFilters");
    final onlyThemFilters = _filters("onlyThemFilter");
    return [
      ...faceFilters.where((filter) => filter.isApplied),
      ...onlyThemFilters.where((filter) => filter.isApplied),
      ...onlyThemFilters.where((filter) => !filter.isApplied),
      ...faceFilters.where((filter) => !filter.isApplied),
    ];
  }

  List<HierarchicalSearchFilter> _filters(String type) {
    return _filtersByType[type] ?? const [];
  }
}

class _FilterGroup {
  final String label;
  final List<HierarchicalSearchFilter> filters;

  const _FilterGroup(this.label, this.filters);
}
