import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";

class ActivityHeatmapCard extends StatelessWidget {
  const ActivityHeatmapCard({required this.summary, super.key});

  final ActivitySummary? summary;

  @override
  Widget build(BuildContext context) {
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
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: _Heatmap(days: last365),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<ActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final renderDays =
        days.length > 365 ? days.sublist(days.length - 365) : days;
    final dayHeader = ["S", "M", "T", "W", "Th", "F", "Sa"];
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
      builder: (context, _) {
        const double monthLabelWidth = 32;
        const double gapX = 4;
        const double gapY = 3;
        const double cellWidth = 38.31;
        const double cellHeight = 9.82;
        final double totalCellsWidth =
            (dayHeader.length * cellWidth) + ((dayHeader.length - 1) * gapX);
        final double totalWidth = monthLabelWidth + gapX + totalCellsWidth;
        final BorderRadius pillRadius = BorderRadius.circular(cellHeight);
        const TextStyle headerStyle = TextStyle(
          color: Color(0x36000000),
          fontSize: 6.834,
          fontWeight: FontWeight.w600,
          height: 2.45,
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
            dayHeaderRow.add(const SizedBox(width: gapX));
          }
        }

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: totalWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ...weeks.asMap().entries.map((entry) {
                      final isLast = entry.key == weeks.length - 1;
                      return SizedBox(
                        height: cellHeight + (isLast ? 0 : gapY),
                        width: monthLabelWidth,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              monthLabels[entry.key] ?? "",
                              style: headerStyle.copyWith(
                                fontSize: 8.542,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(width: gapX),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: dayHeaderRow),
                    const SizedBox(height: 4),
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
                              final color = cell.value == null
                                  ? Colors.transparent
                                  : cell.value!.hasActivity
                                      ? const Color(0xFF1DB954)
                                      : const Color(0xFF1DB954).withValues(
                                          alpha: 0.25,
                                        );
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
                                  if (!isLastCell) const SizedBox(width: gapX),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
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
