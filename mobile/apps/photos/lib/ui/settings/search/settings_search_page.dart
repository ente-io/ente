import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/settings/search/settings_search_item.dart";
import "package:photos/ui/settings/search/settings_search_registry.dart";

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  List<SettingsSearchItem>? _allItems;
  List<_SearchResultEntry> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    _allItems ??= SettingsSearchRegistry.getSearchableItems(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty || _allItems == null) {
        _filteredItems = [];
      } else {
        final l10n = AppLocalizations.of(context);
        final sectionOrder = <String, int>{};
        for (var i = 0; i < _allItems!.length; i++) {
          final item = _allItems![i];
          final sectionKey = _sectionKey(item.sectionPath);
          sectionOrder.putIfAbsent(sectionKey, () => i);
        }

        final freeUpSpacePriority = <String, int>{
          l10n.deleteSuggestions: 0,
          l10n.freeUpDeviceSpace: 1,
        };

        final entries = <_SearchResultEntry>[];
        for (var i = 0; i < _allItems!.length; i++) {
          final item = _allItems![i];
          final matchType = item.matchType(query);
          if (matchType == SettingsSearchMatchType.none) {
            continue;
          }
          final sectionKey = _sectionKey(item.sectionPath);
          final intraSectionOrder =
              sectionKey == l10n.freeUpSpace && freeUpSpacePriority.isNotEmpty
                  ? (freeUpSpacePriority[item.title] ?? 100 + i)
                  : i;
          entries.add(
            _SearchResultEntry(
              item: item,
              matchType: matchType,
              sectionKey: sectionKey,
              sectionOrder: sectionOrder[sectionKey] ?? i,
              itemOrder: i,
              intraSectionOrder: intraSectionOrder,
            ),
          );
        }

        final hasSubPageMatch = <String, bool>{};
        for (final entry in entries) {
          if (entry.item.isSubPage) {
            hasSubPageMatch[entry.sectionKey] = true;
          }
        }

        final filteredEntries = entries
            .where(
              (entry) =>
                  !(hasSubPageMatch[entry.sectionKey] ?? false) ||
                  entry.item.isSubPage,
            )
            .toList();

        filteredEntries.sort((a, b) {
          final matchPriority = _matchPriority(a.matchType)
              .compareTo(_matchPriority(b.matchType));
          if (matchPriority != 0) return matchPriority;
          final sectionPriority = a.sectionOrder.compareTo(b.sectionOrder);
          if (sectionPriority != 0) return sectionPriority;
          final intraSection =
              a.intraSectionOrder.compareTo(b.intraSectionOrder);
          if (intraSection != 0) return intraSection;
          return a.itemOrder.compareTo(b.itemOrder);
        });

        _filteredItems = filteredEntries;
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged("");
  }

  void _navigateToSetting(Widget Function(BuildContext) routeBuilder) {
    Navigator.of(context).pop();
    routeToPage(context, routeBuilder(context));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(colorScheme, textTheme),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildSuggestions(colorScheme, textTheme)
                  : _buildSearchResults(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search_rounded,
                size: 24,
                color: colorScheme.textMuted,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: textTheme.small.copyWith(color: colorScheme.textBase),
                cursorColor: colorScheme.textBase,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchSettings,
                  hintStyle: textTheme.small.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: _clearSearch,
                icon: Icon(
                  Icons.cancel_rounded,
                  color: colorScheme.textMuted,
                ),
              )
            else
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final suggestions = SettingsSearchRegistry.getSuggestions(
      context,
      (routeBuilder) => _navigateToSetting(routeBuilder),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).suggestions,
            style: textTheme.small.copyWith(
              color: colorScheme.textBase,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (suggestion) => _buildSuggestionChip(
                    suggestion,
                    colorScheme,
                    textTheme,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
    SettingsSearchSuggestion suggestion,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: suggestion.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          suggestion.title,
          style: textTheme.mini.copyWith(
            color: colorScheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context).noResultsFound,
            style: textTheme.body.copyWith(color: colorScheme.textMuted),
          ),
        ),
      );
    }

    final rows = _buildResultRows(colorScheme, textTheme);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        return rows[index];
      },
    );
  }

  List<Widget> _buildResultRows(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final sectionCounts = <String, int>{};
    for (final entry in _filteredItems) {
      sectionCounts.update(
        entry.sectionKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final rows = <Widget>[];
    String? currentSectionKey;
    for (final entry in _filteredItems) {
      final shouldShowHeader = sectionCounts[entry.sectionKey] != null &&
          sectionCounts[entry.sectionKey]! >= 2;
      if (shouldShowHeader && currentSectionKey != entry.sectionKey) {
        currentSectionKey = entry.sectionKey;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              entry.sectionKey,
              style: textTheme.mini.copyWith(
                color: colorScheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      rows.add(
        _buildSearchResultItem(entry.item, colorScheme, textTheme),
      );
    }
    return rows;
  }

  Widget _buildSearchResultItem(
    SettingsSearchItem item,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () => _navigateToSetting(item.routeBuilder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (item.icon != null) ...[
              HugeIcon(
                icon: item.icon!,
                color: colorScheme.menuItemIconStroke,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.small.copyWith(
                      color: colorScheme.textBase,
                    ),
                  ),
                  if (item.sectionPath != item.title) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.sectionPath,
                      style: textTheme.mini.copyWith(
                        color: colorScheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_outlined,
              size: 20,
              color: colorScheme.strokeMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _sectionKey(String sectionPath) {
    final parts = sectionPath.split(" > ");
    return parts.isNotEmpty ? parts.first : sectionPath;
  }

  int _matchPriority(SettingsSearchMatchType matchType) {
    switch (matchType) {
      case SettingsSearchMatchType.titlePrefix:
        return 0;
      case SettingsSearchMatchType.title:
        return 1;
      case SettingsSearchMatchType.subtitlePrefix:
        return 2;
      case SettingsSearchMatchType.subtitle:
        return 3;
      case SettingsSearchMatchType.sectionPathPrefix:
        return 4;
      case SettingsSearchMatchType.sectionPath:
        return 5;
      case SettingsSearchMatchType.keywordPrefix:
        return 6;
      case SettingsSearchMatchType.keyword:
        return 7;
      case SettingsSearchMatchType.none:
        return 8;
    }
  }
}

class _SearchResultEntry {
  final SettingsSearchItem item;
  final SettingsSearchMatchType matchType;
  final String sectionKey;
  final int sectionOrder;
  final int itemOrder;
  final int intraSectionOrder;

  _SearchResultEntry({
    required this.item,
    required this.matchType,
    required this.sectionKey,
    required this.sectionOrder,
    required this.itemOrder,
    required this.intraSectionOrder,
  });
}
