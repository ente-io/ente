import "dart:math" as math;

import "package:photos/ui/viewer/search_tab/search_tab_horizontal_scroll.dart";

class SearchTabPreviewLimits {
  const SearchTabPreviewLimits({
    required this.faceResults,
    required this.magicResults,
    required this.locationResults,
    required this.contactResults,
    required this.ritualResults,
  });

  static const _extraItems = 4;
  static const _mediaTileWidth = 108.0;
  static const _mediaTileSpacing = 10.0;
  static const _contactTileWidth = 92.0;
  static const _contactTileSpacing = 12.0;
  static const _ritualTileWidth = 167.5;
  static const _ritualTileSpacing = 10.0;
  static const _fixedLocationTiles = 1;
  static const _fixedContactTiles = 1;
  static const _fixedRitualTiles = 1;

  final int faceResults;
  final int magicResults;
  final int locationResults;
  final int contactResults;
  final int ritualResults;

  int get faceFetchLimit => faceResults + 1;
  int get magicFetchLimit => magicResults + 1;
  int get locationFetchLimit => locationResults + 1;

  static SearchTabPreviewLimits forWidth(double width) {
    final rowWidth = width - (searchTabSectionHorizontalPadding * 2);
    final mediaLimit = _limitForRow(
      rowWidth: rowWidth,
      itemWidth: _mediaTileWidth,
      spacing: _mediaTileSpacing,
    );

    return SearchTabPreviewLimits(
      faceResults: mediaLimit,
      magicResults: mediaLimit,
      locationResults: mediaLimit - _fixedLocationTiles,
      contactResults:
          _limitForRow(
            rowWidth: rowWidth,
            itemWidth: _contactTileWidth,
            spacing: _contactTileSpacing,
          ) -
          _fixedContactTiles,
      ritualResults:
          _limitForRow(
            rowWidth: rowWidth,
            itemWidth: _ritualTileWidth,
            spacing: _ritualTileSpacing,
          ) -
          _fixedRitualTiles,
    );
  }

  static int _limitForRow({
    required double rowWidth,
    required double itemWidth,
    required double spacing,
  }) {
    final visibleItems = ((rowWidth + spacing) / (itemWidth + spacing)).floor();
    return math.max(1, visibleItems) + _extraItems;
  }
}
