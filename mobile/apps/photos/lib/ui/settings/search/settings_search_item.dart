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

  /// Check if this item matches the search query
  bool matchesQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return false;

    // Check title
    if (title.toLowerCase().contains(normalizedQuery)) return true;

    // Check subtitle
    if (subtitle?.toLowerCase().contains(normalizedQuery) ?? false) return true;

    // Check section path
    if (sectionPath.toLowerCase().contains(normalizedQuery)) return true;

    // Check keywords
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(normalizedQuery)) return true;
    }

    return false;
  }
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
