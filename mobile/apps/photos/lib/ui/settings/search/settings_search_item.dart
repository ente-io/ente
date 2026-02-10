import "package:flutter/material.dart";

/// Represents a searchable settings item
class SettingsSearchItem {
  /// The title of the settings item
  final String title;

  /// Optional subtitle for more context
  final String? subtitle;

  /// Icon data for the item
  final List<List<dynamic>>? icon;

  /// The page/section path for navigation breadcrumb
  final String sectionPath;

  /// Whether this item represents a nested page
  final bool isSubPage;

  /// The route builder to navigate to this setting
  final Widget Function(BuildContext context) routeBuilder;

  /// Optional keywords for better search matching
  final List<String> keywords;

  const SettingsSearchItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.sectionPath,
    required this.routeBuilder,
    this.isSubPage = false,
    this.keywords = const [],
  });

  SettingsSearchMatchType matchType(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return SettingsSearchMatchType.none;

    final normalizedTitle = title.toLowerCase();
    if (normalizedTitle.startsWith(normalizedQuery)) {
      return SettingsSearchMatchType.titlePrefix;
    }
    if (normalizedTitle.contains(normalizedQuery)) {
      return SettingsSearchMatchType.title;
    }
    final normalizedSubtitle = subtitle?.toLowerCase();
    if (normalizedSubtitle?.startsWith(normalizedQuery) ?? false) {
      return SettingsSearchMatchType.subtitlePrefix;
    }
    if (normalizedSubtitle?.contains(normalizedQuery) ?? false) {
      return SettingsSearchMatchType.subtitle;
    }
    final normalizedSectionPath = sectionPath.toLowerCase();
    if (normalizedSectionPath.startsWith(normalizedQuery)) {
      return SettingsSearchMatchType.sectionPathPrefix;
    }
    if (normalizedSectionPath.contains(normalizedQuery)) {
      return SettingsSearchMatchType.sectionPath;
    }
    for (final keyword in keywords) {
      final normalizedKeyword = keyword.toLowerCase();
      if (normalizedKeyword.startsWith(normalizedQuery)) {
        return SettingsSearchMatchType.keywordPrefix;
      }
      if (normalizedKeyword.contains(normalizedQuery)) {
        return SettingsSearchMatchType.keyword;
      }
    }

    return SettingsSearchMatchType.none;
  }

  /// Check if this item matches the search query
  bool matchesQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return false;

    return matchType(normalizedQuery) != SettingsSearchMatchType.none;
  }

  bool matchesLabel(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return false;

    if (title.toLowerCase().contains(normalizedQuery)) return true;
    if (subtitle?.toLowerCase().contains(normalizedQuery) ?? false) return true;
    if (sectionPath.toLowerCase().contains(normalizedQuery)) return true;
    return false;
  }

  bool matchesKeyword(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return false;

    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(normalizedQuery)) return true;
    }
    return false;
  }
}

enum SettingsSearchMatchType {
  titlePrefix,
  title,
  subtitlePrefix,
  subtitle,
  sectionPathPrefix,
  sectionPath,
  keywordPrefix,
  keyword,
  none,
}

/// Represents a quick suggestion shown when search is empty
class SettingsSearchSuggestion {
  final String title;
  final List<List<dynamic>>? icon;
  final VoidCallback onTap;

  const SettingsSearchSuggestion({
    required this.title,
    this.icon,
    required this.onTap,
  });
}
