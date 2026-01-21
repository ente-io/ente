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
  List<SettingsSearchItem> _filteredItems = [];

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
        _filteredItems =
            _allItems!.where((item) => item.matchesQuery(query)).toList();
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
              GestureDetector(
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: colorScheme.textMuted,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.textMuted,
                  ),
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildSearchResultItem(item, colorScheme, textTheme);
      },
    );
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
                  if (item.isSubPage) ...[
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
}
