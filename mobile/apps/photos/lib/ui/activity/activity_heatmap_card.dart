import "dart:math";

import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";

class ActivityHeatmapCard extends StatelessWidget {
  const ActivityHeatmapCard({
    required this.summary,
    this.compact = false,
    this.allowHorizontalScroll = false,
    this.headerTitle,
    this.headerEmoji,
    super.key,
  });

  final ActivitySummary? summary;
  final bool compact;
  final bool allowHorizontalScroll;
  final String? headerTitle;
  final String? headerEmoji;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final last365 = summary?.last365Days ??
        List.generate(
          372,
          (i) => ActivityDay(
            date: DateTime.now().subtract(Duration(days: 371 - i)),
            hasActivity: false,
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? getEnteColorScheme(context).backgroundElevated2
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((headerTitle ?? "").isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if ((headerEmoji ?? "").isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                headerEmoji ?? "",
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              headerTitle ?? "",
                              style: textTheme.bodyMuted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            allowHorizontalScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: _Heatmap(
                      days: last365,
                      compact: compact,
                    ),
                  )
                : _Heatmap(
                    days: last365,
                    compact: compact,
                  ),
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.days,
    required this.compact,
  });

  final List<ActivityDay> days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final renderDays =
        days.length > 365 ? days.sublist(days.length - 365) : days;
    final dayHeader = ["", "M", "", "W", "", "F", ""];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final DateTime firstDay = renderDays.isNotEmpty
        ? DateTime(
            renderDays.first.date.year,
            renderDays.first.date.month,
            renderDays.first.date.day,
          )
        : todayMidnight.subtract(const Duration(days: 364));

    final normalizedDayMap = <int, ActivityDay>{
      for (final d in days)
        DateTime(d.date.year, d.date.month, d.date.day).millisecondsSinceEpoch:
            d,
    };

    // Always start on the Sunday before/including the first day to render
    final int startOffset = firstDay.weekday % 7;
    final DateTime gridStart =
        firstDay.subtract(Duration(days: startOffset)); // Sunday-aligned
    // End exactly on today; last row can be partial
    final DateTime gridEnd = todayMidnight;
    final int totalDays =
        gridEnd.difference(gridStart).inDays + 1; // inclusive of gridEnd

    final List<ActivityDay?> gridDays = List.generate(totalDays, (index) {
      final date = gridStart.add(Duration(days: index));
      // Leading days before the 365-day window can still be active if present
      // in the extended map (we fetched extra days), otherwise remain empty.
      final key =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final activity = normalizedDayMap[key];
      if (date.isBefore(firstDay)) {
        return activity ??
            ActivityDay(
              date: date,
              hasActivity: false,
            );
      }
      return activity ??
          ActivityDay(
            date: date,
            hasActivity: false,
          );
    });

    final weeks = <List<ActivityDay?>>[];
    for (int i = 0; i < gridDays.length; i += 7) {
      final slice = gridDays.skip(i).take(7).toList();
      while (slice.length < 7) {
        slice.add(null); // pad last row to full width
      }
      weeks.add(slice);
    }

    final monthLabels = <int, String>{};
    final seenMonths = <String>{};

    for (final day in gridDays.whereType<ActivityDay>()) {
      if (day.date.day != 1) continue;
      final daysSinceStart = day.date.difference(gridStart).inDays;
      final rowIndex = daysSinceStart ~/ 7;
      final key = _monthKey(day.date);
      if (seenMonths.contains(key)) continue;
      monthLabels[rowIndex] = _monthLabel(day.date.month);
      seenMonths.add(key);
    }

    if (monthLabels.isEmpty) {
      final rowIndex = firstDay.difference(gridStart).inDays ~/ 7;
      monthLabels[rowIndex] = _monthLabel(firstDay.month);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double baseMonthLabelWidth = compact ? 28 : 32;
        final double baseGapX = compact ? 2.5 : 4;
        final double baseGapY = compact ? 2 : 3;
        final double baseCellWidth = compact ? 30 : 38.31;
        final double baseCellHeight = compact ? 8.5 : 9.82;
        final double baseHeaderRowHeight = compact ? 13 : 16;
        final double baseHeaderToGridGap = compact ? 3 : 4;
        final double baseTotalWidth =
            (7 * baseCellWidth) + (7 * baseGapX) + baseMonthLabelWidth;
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : baseTotalWidth;
        double scale = availableWidth / baseTotalWidth;
        scale = scale.clamp(0.7, 1.0);
        final double monthLabelWidth = baseMonthLabelWidth * scale;
        final double gapX = baseGapX * scale;
        final double gapY = baseGapY * scale;
        final double cellWidth = baseCellWidth * scale;
        final double cellHeight = baseCellHeight * scale;
        final double headerRowHeight = baseHeaderRowHeight * scale;
        final double headerToGridGap = baseHeaderToGridGap * scale;
        final double gridWidth =
            (dayHeader.length * cellWidth) + ((dayHeader.length - 1) * gapX);
        final double remainingWidth =
            max(0.0, constraints.maxWidth - gridWidth - gapX);
        // Aim for ~70% of previous right padding by biasing space to the left gutter.
        final double gutterWidth = max(monthLabelWidth, remainingWidth * 0.65);
        final EnteColorScheme colorScheme = getEnteColorScheme(context);
        final BorderRadius pillRadius = BorderRadius.circular(cellHeight);
        final TextStyle headerStyle = TextStyle(
          color: colorScheme.textMuted.withValues(alpha: 0.45),
          fontSize: (compact ? 6.2 : 6.834) * scale.clamp(0.8, 1.0),
          fontWeight: FontWeight.w600,
          height: compact ? 2.2 : 2.45,
          fontFamily: "Inter",
          decoration: TextDecoration.none,
        );

        final List<Widget> dayHeaderRow = [];
        for (int i = 0; i < dayHeader.length; i++) {
          dayHeaderRow.add(
            SizedBox(
              width: cellWidth,
              height: 16,
              child: Center(
                child: Text(
                  dayHeader[i],
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
          if (i != dayHeader.length - 1) {
            dayHeaderRow.add(SizedBox(width: gapX));
          }
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: gutterWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: headerRowHeight + headerToGridGap + (8 * scale),
                  ),
                  child: Column(
                    children: weeks.asMap().entries.map((entry) {
                      final isLast = entry.key == weeks.length - 1;
                      return SizedBox(
                        height: cellHeight + (isLast ? 0 : gapY),
                        width: gutterWidth,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              monthLabels[entry.key] ?? "",
                              style: headerStyle.copyWith(
                                fontSize: 8.542 * scale.clamp(0.8, 1.0),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(width: gapX),
              SizedBox(
                width: gridWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8 * scale),
                    Row(children: dayHeaderRow),
                    SizedBox(height: headerToGridGap),
                    ...weeks.asMap().entries.map(
                      (entry) {
                        final isLast = entry.key == weeks.length - 1;
                        final week = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : gapY),
                          child: Row(
                            children: week.asMap().entries.map((cell) {
                              final isLastCell =
                                  cell.key == dayHeader.length - 1;
                              final Color activeColor = colorScheme.primary500;
                              final Color inactiveColor = colorScheme.primary500
                                  .withValues(alpha: 0.28);
                              final color = cell.value == null
                                  ? Colors.transparent
                                  : cell.value!.hasActivity
                                      ? activeColor
                                      : inactiveColor;
                              return Row(
                                children: [
                                  Container(
                                    width: cellWidth,
                                    height: cellHeight,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: pillRadius,
                                    ),
                                  ),
                                  if (!isLastCell) SizedBox(width: gapX),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }

  String _monthLabel(int month) {
    const labels = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return labels[month - 1];
  }

  String _monthKey(DateTime date) => "${date.year}-${date.month}";
}
