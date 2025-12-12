import "dart:io";
import "dart:math";
import "dart:ui" as ui;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/share_util.dart";
import "package:share_plus/share_plus.dart";

class RitualHeatmapCard extends StatelessWidget {
  const RitualHeatmapCard({
    required this.summary,
    this.compact = false,
    this.allowHorizontalScroll = false,
    this.headerTitle,
    this.headerEmoji,
    super.key,
  });

  final RitualsSummary? summary;
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
          (i) => RitualDay(
            date: DateTime.now().subtract(Duration(days: 371 - i)),
            isCompleted: false,
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

  final List<RitualDay> days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final renderDays =
        days.length > 365 ? days.sublist(days.length - 365) : days;
    final materialLocalizations = MaterialLocalizations.of(context);
    final dayHeader = [
      "",
      materialLocalizations.narrowWeekdays[1],
      "",
      materialLocalizations.narrowWeekdays[3],
      "",
      materialLocalizations.narrowWeekdays[5],
      "",
    ];
    final monthFormatter =
        DateFormat.MMM(Localizations.localeOf(context).toString());
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final DateTime firstDay = renderDays.isNotEmpty
        ? DateTime(
            renderDays.first.date.year,
            renderDays.first.date.month,
            renderDays.first.date.day,
          )
        : todayMidnight.subtract(const Duration(days: 364));

    final normalizedDayMap = <int, RitualDay>{
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

    final List<RitualDay?> gridDays = List.generate(totalDays, (index) {
      final date = gridStart.add(Duration(days: index));
      // Leading days before the 365-day window can still be active if present
      // in the extended map (we fetched extra days), otherwise remain empty.
      final key =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final dayEntry = normalizedDayMap[key];
      if (date.isBefore(firstDay)) {
        return dayEntry ??
            RitualDay(
              date: date,
              isCompleted: false,
            );
      }
      return dayEntry ??
          RitualDay(
            date: date,
            isCompleted: false,
          );
    });

    final weeks = <List<RitualDay?>>[];
    for (int i = 0; i < gridDays.length; i += 7) {
      final slice = gridDays.skip(i).take(7).toList();
      while (slice.length < 7) {
        slice.add(null); // pad last row to full width
      }
      weeks.add(slice);
    }

    final monthLabels = <int, String>{};
    final seenMonths = <String>{};

    for (final day in gridDays.whereType<RitualDay>()) {
      if (day.date.day != 1) continue;
      final daysSinceStart = day.date.difference(gridStart).inDays;
      final rowIndex = daysSinceStart ~/ 7;
      final key = _monthKey(day.date);
      if (seenMonths.contains(key)) continue;
      monthLabels[rowIndex] = _monthLabel(monthFormatter, day.date.month);
      seenMonths.add(key);
    }

    if (monthLabels.isEmpty) {
      final rowIndex = firstDay.difference(gridStart).inDays ~/ 7;
      monthLabels[rowIndex] = _monthLabel(monthFormatter, firstDay.month);
    }

    final String? bottomMonthLabel = monthLabels[weeks.length - 1];
    if (bottomMonthLabel != null) {
      for (final int rowIndex in [0, 1]) {
        if (rowIndex < weeks.length &&
            monthLabels[rowIndex] == bottomMonthLabel) {
          monthLabels.remove(rowIndex);
        }
      }
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
                                  : cell.value!.isCompleted
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

  String _monthLabel(DateFormat formatter, int month) {
    return formatter.format(DateTime(2024, month));
  }

  String _monthKey(DateTime date) => "${date.year}-${date.month}";
}

RitualsSummary ritualSummaryForRitual(
  RitualsSummary summary,
  Ritual ritual,
) {
  final ritualProgress = summary.ritualProgress[ritual.id];
  final Set<int> dayKeys = ritualProgress == null
      ? <int>{}
      : ritualProgress.completedDays
          .map(
            (d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch,
          )
          .toSet();

  final last365Days = summary.last365Days
      .map(
        (day) => RitualDay(
          date: day.date,
          isCompleted: _isRitualDayEnabled(ritual.daysOfWeek, day.date) &&
              dayKeys.contains(
                DateTime(
                  day.date.year,
                  day.date.month,
                  day.date.day,
                ).millisecondsSinceEpoch,
              ),
        ),
      )
      .toList();
  final last7Days = last365Days.length >= 7
      ? last365Days.sublist(last365Days.length - 7)
      : List<RitualDay>.from(last365Days);

  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final (currentStreak, longestStreak) =
      _scheduledStreaks(dayKeys, ritual.daysOfWeek, todayMidnight);

  final unlockedBadges = <int, bool>{
    for (final entry in summary.badgesUnlocked.keys)
      entry: longestStreak >= entry,
  };

  return RitualsSummary(
    last365Days: last365Days,
    last7Days: last7Days,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    badgesUnlocked: unlockedBadges,
    ritualProgress: {
      ritual.id: RitualProgress(
        ritualId: ritual.id,
        completedDays: ritualProgress?.completedDays ?? <DateTime>{},
      ),
    },
    generatedAt: summary.generatedAt,
    ritualLongestStreaks: {ritual.id: longestStreak},
  );
}

bool _isRitualDayEnabled(List<bool> daysOfWeek, DateTime day) {
  if (daysOfWeek.length != 7) return false;
  final dayIndex = day.weekday % 7; // Sunday -> 0
  return daysOfWeek[dayIndex];
}

// Streaks are computed only on days enabled by the ritual (Sunday-first).
// A streak increments by 1 per enabled day that has at least one photo, and
// breaks on the first enabled day that has no photo.
(int current, int longest) _scheduledStreaks(
  Set<int> completedDayKeys,
  List<bool> daysOfWeek,
  DateTime todayMidnight,
) {
  if (completedDayKeys.isEmpty) return (0, 0);
  if (!_hasAnyEnabledRitualDays(daysOfWeek)) return (0, 0);

  final start = _streakStartDateFromDayKeys(completedDayKeys, todayMidnight);

  int longest = 0;
  int rolling = 0;
  for (var day = start; !day.isAfter(todayMidnight); day = _nextDay(day)) {
    final dayIndex = day.weekday % 7; // Sunday -> 0
    if (!daysOfWeek[dayIndex]) continue;

    final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    if (completedDayKeys.contains(key)) {
      rolling += 1;
      if (rolling > longest) longest = rolling;
    } else {
      rolling = 0;
    }
  }

  int current = 0;
  for (var day = todayMidnight; !day.isBefore(start); day = _prevDay(day)) {
    final dayIndex = day.weekday % 7; // Sunday -> 0
    if (!daysOfWeek[dayIndex]) continue;

    final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    if (completedDayKeys.contains(key)) {
      current += 1;
    } else {
      break;
    }
  }

  return (current, longest);
}

DateTime _streakStartDateFromDayKeys(Set<int> dayKeys, DateTime todayMidnight) {
  final minKey = dayKeys.reduce(min);
  final minDay = DateTime.fromMillisecondsSinceEpoch(minKey);
  final start = DateTime(minDay.year, minDay.month, minDay.day);
  return start.isAfter(todayMidnight) ? todayMidnight : start;
}

bool _hasAnyEnabledRitualDays(List<bool> daysOfWeek) {
  if (daysOfWeek.length != 7) return false;
  for (final enabled in daysOfWeek) {
    if (enabled) return true;
  }
  return false;
}

DateTime _nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

DateTime _prevDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

class RitualHeatmapLegacy {
  RitualHeatmapLegacy._();

  static final Logger _logger = Logger("RitualHeatmapLegacy");
  static final GlobalKey _shareButtonKey = GlobalKey();

  // TODO: lau: remove dead code?
  // ignore: unused_element
  static List<Widget> buildHeatmapSection({
    required BuildContext context,
    required RitualsSummary? summary,
    required Ritual? selectedRitual,
  }) {
    final displaySummary = summary != null && selectedRitual != null
        ? ritualSummaryForRitual(summary, selectedRitual)
        : summary;
    final summaryToShare = displaySummary;
    final iconColor = Theme.of(context).iconTheme.color;
    final colorScheme = getEnteColorScheme(context);
    final l10n = context.l10n;
    final String heatmapTitle = selectedRitual == null
        ? l10n.ritualDefaultHeatmapTitle
        : (selectedRitual.title.isEmpty
            ? l10n.ritualUntitled
            : selectedRitual.title);
    final String heatmapEmoji =
        selectedRitual?.icon ?? (selectedRitual == null ? "📸" : "");
    final bool shareEnabled = summaryToShare != null;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Text(
                l10n.ritualActivityHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  key: _shareButtonKey,
                  color: colorScheme.fillFaint,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: summaryToShare != null
                        ? () => _shareRitualSummary(
                              context: context,
                              summary: summaryToShare,
                              title: heatmapTitle,
                              emoji: heatmapEmoji,
                            )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedShare08,
                          size: 24,
                          color: shareEnabled
                              ? iconColor
                              : Theme.of(context)
                                  .disabledColor
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      RitualHeatmapCard(
        summary: displaySummary,
        headerTitle: heatmapTitle,
        headerEmoji: heatmapEmoji,
      ),
    ];
  }

  static Future<void> _shareRitualSummary({
    required BuildContext context,
    required RitualsSummary summary,
    required String title,
    String? emoji,
  }) async {
    _logger.info("Ritual share: start");
    _logger.fine("Ritual share: precache assets begin");
    await _precacheRitualShareAssets(context);
    _logger.fine("Ritual share: precache assets done");
    OverlayEntry? entry;
    final prevPaintSize = debugPaintSizeEnabled;
    final prevPaintBaselines = debugPaintBaselinesEnabled;
    final prevPaintPointers = debugPaintPointersEnabled;
    final prevRepaintRainbow = debugRepaintRainbowEnabled;
    try {
      debugPaintSizeEnabled = false;
      debugPaintBaselinesEnabled = false;
      debugPaintPointersEnabled = false;
      debugRepaintRainbowEnabled = false;

      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) {
        throw StateError("Overlay not available for sharing");
      }
      final key = GlobalKey();
      entry = OverlayEntry(
        builder: (context) {
          return Center(
            child: Material(
              type: MaterialType.transparency,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: RepaintBoundary(
                    key: key,
                    child: _RitualShareCard(
                      summary: summary,
                      title: title,
                      emoji: emoji,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(entry);
      _logger.fine("Ritual share: overlay inserted, waiting for boundary");
      final boundary = await _waitForBoundaryReady(repaintKey: key);
      bool needsPaint = false;
      assert(() {
        needsPaint = boundary.debugNeedsPaint;
        return true;
      }());
      _logger.fine(
        "Ritual share: boundary ready, size=${boundary.size}, needsPaint=$needsPaint",
      );
      final double pixelRatio =
          (MediaQuery.of(context).devicePixelRatio * 1.6).clamp(2.0, 3.5);
      late final ui.Image image;
      try {
        image = await boundary.toImage(pixelRatio: pixelRatio.toDouble());
      } catch (e, s) {
        _logger.warning("Ritual share: toImage failed", e, s);
        rethrow;
      }
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } catch (e, s) {
        _logger.warning("Ritual share: toByteData failed", e, s);
        rethrow;
      }
      final data = byteData?.buffer.asUint8List();
      if (data == null || data.isEmpty) {
        throw StateError("Ritual share image encoding produced no data");
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/ritual_share_${DateTime.now().millisecondsSinceEpoch}.png",
      );
      await file.writeAsBytes(data, flush: true);
      _logger.info(
        "Ritual share: file written (${data.length} bytes) -> ${file.path}",
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: shareButtonRect(context, _shareButtonKey),
        ),
      );
      _logger.info("Ritual share: SharePlus invoked");
    } catch (e, s) {
      _logger.warning("Failed to share ritual summary", e, s);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ritualShareUnavailable)),
      );
    } finally {
      debugPaintSizeEnabled = prevPaintSize;
      debugPaintBaselinesEnabled = prevPaintBaselines;
      debugPaintPointersEnabled = prevPaintPointers;
      debugRepaintRainbowEnabled = prevRepaintRainbow;
      entry?.remove();
    }
  }

  static Future<void> _precacheRitualShareAssets(BuildContext context) async {
    const assets = [
      "assets/rituals/ente_io_black_white.png",
      "assets/splash-screen-icon.png",
    ];
    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e, s) {
        _logger.warning(
          "Ritual share: failed to precache asset $asset",
          e,
          s,
        );
      }
    }
  }

  static Future<RenderRepaintBoundary> _waitForBoundaryReady({
    required GlobalKey repaintKey,
  }) async {
    const int maxAttempts = 8;
    const Duration attemptDelay = Duration(milliseconds: 40);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      bool needsPaint = false;
      assert(() {
        needsPaint = boundary?.debugNeedsPaint ?? false;
        return true;
      }());
      if (boundary == null) {
        _logger.fine(
          "Ritual share boundary missing (attempt ${attempt + 1})",
        );
      } else if (boundary.size.isEmpty) {
        _logger.fine(
          "Ritual share boundary has zero size (attempt ${attempt + 1})",
        );
      } else if (needsPaint) {
        _logger.fine(
          "Ritual share boundary needs paint (attempt ${attempt + 1}), waiting",
        );
      } else {
        return boundary;
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(attemptDelay);
    }

    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError("Render boundary unavailable");
    }
    if (boundary.size.isEmpty) {
      throw StateError("Render boundary has zero size");
    }
    bool needsPaint = false;
    assert(() {
      needsPaint = boundary.debugNeedsPaint;
      return true;
    }());
    if (needsPaint) {
      throw StateError("Render boundary not ready to paint");
    }
    return boundary;
  }
}

class _RitualShareCard extends StatelessWidget {
  const _RitualShareCard({
    required this.summary,
    required this.title,
    this.emoji,
  });

  final RitualsSummary summary;
  final String title;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    const Color shareBackgroundColor = Color(0xFF08C225);
    final String shareHeaderTitle =
        (emoji ?? "").isNotEmpty ? "${emoji!} $title" : title;
    final double maxWidth =
        min(max(MediaQuery.of(context).size.width - 32, 360), 440).toDouble();
    return Align(
      alignment: Alignment.topCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: shareBackgroundColor,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            brightness: Brightness.light,
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  brightness: Brightness.light,
                                ),
                          ),
                          child: RitualHeatmapCard(
                            summary: summary,
                            compact: true,
                            allowHorizontalScroll: false,
                            headerTitle: shareHeaderTitle,
                            headerEmoji: null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        "assets/rituals/ente_io_black_white.png",
                        width: 62,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  "assets/splash-screen-icon.png",
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
