part of 'package:photos/ui/wrapped/wrapped_viewer_page.dart';

Widget? buildStatsCardContent(
  WrappedCard card,
  EnteColorScheme colorScheme,
  EnteTextTheme textTheme,
) {
  switch (card.type) {
    case WrappedCardType.statsTotals:
      return _TotalsCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.statsVelocity:
      return _RhythmCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.busiestDay:
      return _BusiestDayCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.statsHeatmap:
      return _HeatmapCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    default:
      return null;
  }
}

class _TotalsCardContent extends StatelessWidget {
  const _TotalsCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");
    final String? firstCaptureLine = card.meta["firstCaptureLine"] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroMediaCollage(
          media: card.media,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        if (firstCaptureLine != null) ...[
          const SizedBox(height: 16),
          Text(
            firstCaptureLine,
            style: textTheme.smallMuted,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _RhythmCardContent extends StatelessWidget {
  const _RhythmCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 18),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        if (card.media.isNotEmpty) ...[
          const SizedBox(height: 22),
          _MediaRow(
            media: card.media.take(3).toList(growable: false),
            colorScheme: colorScheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _BusiestDayCardContent extends StatelessWidget {
  const _BusiestDayCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 18),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const SizedBox(height: 22),
        _MediaGrid(
          media: card.media.take(6).toList(growable: false),
          colorScheme: colorScheme,
        ),
        const Spacer(),
      ],
    );
  }
}

class _HeatmapCardContent extends StatelessWidget {
  const _HeatmapCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");
    final List<dynamic> rawQuarters =
        card.meta["quarters"] as List<dynamic>? ?? const <dynamic>[];
    final List<_QuarterBlock> quarters = rawQuarters
        .map(
          (dynamic entry) => _QuarterBlock.fromJson(
            (entry as Map).cast<String, Object?>(),
          ),
        )
        .where((_QuarterBlock block) => block.grid.isNotEmpty)
        .toList(growable: false);
    final List<String> weekdayLabels =
        (card.meta["weekdayLabels"] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    final int maxCount = (card.meta["maxCount"] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        const SizedBox(height: 18),
        if (quarters.isEmpty)
          _MediaPlaceholder(
            height: 180,
            colorScheme: colorScheme,
          )
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxWidth = constraints.maxWidth;
              final int columns =
                  quarters.length <= 1 ? 1 : (maxWidth >= 280 ? 2 : 1);
              final double spacing = columns > 1 ? 18 : 0;
              final double itemWidth = columns > 1
                  ? (maxWidth - ((columns - 1) * spacing)) / columns
                  : maxWidth;
              final int maxColumnCount = quarters
                  .map(
                    (_QuarterBlock block) =>
                        block.grid.isNotEmpty ? block.grid.first.length : 0,
                  )
                  .fold(0, math.max);
              const double labelColumnWidth = 20;
              const double cellSpacing = 1.5;
              const double fallbackCellSize = 6;
              const double maxCellWidth = 18;
              const double maxCellHeight = 12;

              double computeCellWidth(double availableWidth) {
                if (maxColumnCount <= 0) {
                  return fallbackCellSize;
                }
                final double usable = math.max(
                  0,
                  availableWidth -
                      cellSpacing * math.max(0, maxColumnCount - 1),
                );
                final double raw = usable / math.max(1, maxColumnCount);
                return raw.clamp(fallbackCellSize, maxCellWidth);
              }

              final double cellWidthWithLabels =
                  computeCellWidth(itemWidth - labelColumnWidth);
              final double cellWidthWithoutLabels = computeCellWidth(itemWidth);
              final double cellWidth =
                  math.min(cellWidthWithLabels, cellWidthWithoutLabels);
              final double cellHeight = math.min(
                maxCellHeight,
                cellWidth.clamp(fallbackCellSize, maxCellHeight),
              );
              return Wrap(
                spacing: spacing,
                runSpacing: 18,
                children: <Widget>[
                  for (final (int index, _QuarterBlock block)
                      in quarters.indexed)
                    SizedBox(
                      width: itemWidth,
                      child: _QuarterHeatmap(
                        block: block,
                        weekdayLabels: weekdayLabels,
                        maxCount: maxCount,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        showDayLabels: columns == 1 || index % columns == 0,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        cellSpacing: cellSpacing,
                        labelColumnWidth: labelColumnWidth,
                      ),
                    ),
                ],
              );
            },
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _QuarterBlock {
  _QuarterBlock({
    required this.label,
    required this.grid,
    required this.columnLabels,
  });

  final String label;
  final List<List<int>> grid;
  final List<String> columnLabels;

  static _QuarterBlock fromJson(Map<String, Object?> json) {
    final List<List<int>> grid =
        (json["grid"] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic row) => (row as List<dynamic>)
                  .map((dynamic value) => (value as num).toInt())
                  .toList(growable: false),
            )
            .toList(growable: false);
    final List<String> columnLabels =
        (json["columnLabels"] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    return _QuarterBlock(
      label: json["label"] as String? ?? "",
      grid: grid,
      columnLabels: columnLabels,
    );
  }
}

class _QuarterHeatmap extends StatelessWidget {
  const _QuarterHeatmap({
    required this.block,
    required this.weekdayLabels,
    required this.maxCount,
    required this.colorScheme,
    required this.textTheme,
    required this.showDayLabels,
    required this.cellWidth,
    required this.cellHeight,
    required this.cellSpacing,
    required this.labelColumnWidth,
  });

  final _QuarterBlock block;
  final List<String> weekdayLabels;
  final int maxCount;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool showDayLabels;
  final double cellWidth;
  final double cellHeight;
  final double cellSpacing;
  final double labelColumnWidth;

  @override
  Widget build(BuildContext context) {
    final int columnCount = block.grid.isEmpty ? 0 : block.grid.first.length;
    if (columnCount == 0) {
      return _MediaPlaceholder(
        height: 120,
        colorScheme: colorScheme,
      );
    }

    final TextStyle axisStyle =
        textTheme.tinyMuted.copyWith(fontSize: 8.5, height: 1.15);
    final List<String> headerLabels = List<String>.generate(
      columnCount,
      (int index) =>
          index < block.columnLabels.length ? block.columnLabels[index] : "",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.label,
          style: textTheme.smallBold,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(width: labelColumnWidth),
            for (int columnIndex = 0;
                columnIndex < headerLabels.length;
                columnIndex += 1) ...[
              SizedBox(
                width: cellWidth,
                child: Text(
                  headerLabels[columnIndex],
                  style: axisStyle,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              SizedBox(
                width: columnIndex == headerLabels.length - 1 ? 0 : cellSpacing,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Column(
          children: List<Widget>.generate(weekdayLabels.length, (int dayIndex) {
            final List<int> row = block.grid.length > dayIndex
                ? block.grid[dayIndex]
                : const <int>[];
            final String dayLabel =
                dayIndex < weekdayLabels.length ? weekdayLabels[dayIndex] : "";
            return Padding(
              padding: EdgeInsets.only(
                bottom: dayIndex == weekdayLabels.length - 1 ? 0 : cellSpacing,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: labelColumnWidth,
                    child: Visibility(
                      visible: showDayLabels,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text(
                        dayLabel,
                        style: axisStyle,
                      ),
                    ),
                  ),
                  for (int columnIndex = 0;
                      columnIndex < columnCount;
                      columnIndex += 1) ...[
                    _HeatmapCell(
                      value: columnIndex < row.length ? row[columnIndex] : -1,
                      width: cellWidth,
                      height: cellHeight,
                      colorScheme: colorScheme,
                      maxCount: maxCount,
                    ),
                    SizedBox(
                      width: columnIndex == columnCount - 1 ? 0 : cellSpacing,
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.value,
    required this.width,
    required this.height,
    required this.colorScheme,
    required this.maxCount,
  });

  final int value;
  final double width;
  final double height;
  final EnteColorScheme colorScheme;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (value == kWrappedHeatmapFutureValue) {
      return SizedBox(width: width, height: height);
    }
    if (value == kWrappedHeatmapPaddedValue) {
      final Color base = colorScheme.fillFaint;
      final double placeholderAlpha = (base.a * 0.4).clamp(0.0, 1.0).toDouble();
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: placeholderAlpha),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _heatmapColorForValue(value, maxCount, colorScheme),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
