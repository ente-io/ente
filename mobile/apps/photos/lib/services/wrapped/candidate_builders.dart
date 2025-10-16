import "dart:math" as math;

import "package:flutter/foundation.dart" show immutable;
import "package:intl/intl.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/utils/standalone/data.dart";

/// Provides basic context details for candidate builders.
@immutable
class WrappedEngineContext {
  WrappedEngineContext({
    required this.year,
    required this.now,
    required List<EnteFile> files,
  }) : files = List<EnteFile>.unmodifiable(files);

  final int year;
  final DateTime now;
  final List<EnteFile> files;
}

/// Contract for producing Wrapped candidate cards for a specific domain.
abstract class WrappedCandidateBuilder {
  const WrappedCandidateBuilder();

  String get debugLabel;

  Future<List<WrappedCard>> build(WrappedEngineContext context);
}

class StatsCandidateBuilder extends WrappedCandidateBuilder {
  const StatsCandidateBuilder();

  @override
  String get debugLabel => "stats";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    final _StatsSnapshot snapshot = _StatsSnapshot.fromContext(context);
    if (snapshot.totalCount == 0) {
      return <WrappedCard>[];
    }

    final List<WrappedCard> cards = <WrappedCard>[];
    cards.add(_buildTotalsCard(snapshot));

    final WrappedCard? velocityCard = _buildVelocityCard(snapshot);
    if (velocityCard != null) {
      cards.add(velocityCard);
    }

    final WrappedCard? busiestDayCard = _buildBusiestDayCard(snapshot);
    if (busiestDayCard != null) {
      cards.add(busiestDayCard);
    }

    final WrappedCard? streakCard = _buildLongestStreakCard(snapshot);
    if (streakCard != null) {
      cards.add(streakCard);
    }

    final WrappedCard? gapCard = _buildLongestGapCard(snapshot);
    if (gapCard != null) {
      cards.add(gapCard);
    }

    return cards;
  }

  WrappedCard _buildTotalsCard(_StatsSnapshot snapshot) {
    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final int stillPhotoCount =
        math.max(snapshot.photoCount - snapshot.livePhotoCount, 0);
    final List<String> detailParts = <String>[];
    if (stillPhotoCount > 0) {
      detailParts
          .add("${numberFormat.format(stillPhotoCount)} ${stillPhotoCount == 1 ? 'photo' : 'photos'}");
    }
    if (snapshot.livePhotoCount > 0) {
      detailParts.add(
        "${numberFormat.format(snapshot.livePhotoCount)} live ${snapshot.livePhotoCount == 1 ? 'photo' : 'photos'}",
      );
    }
    if (snapshot.videoCount > 0) {
      detailParts
          .add("${numberFormat.format(snapshot.videoCount)} ${snapshot.videoCount == 1 ? 'video' : 'videos'}");
    }
    if (snapshot.otherCount > 0) {
      detailParts.add(
        "${numberFormat.format(snapshot.otherCount)} other ${snapshot.otherCount == 1 ? 'item' : 'items'}",
      );
    }
    if (snapshot.storageBytes > 0) {
      detailParts.add("${formatBytes(snapshot.storageBytes, 1)} captured");
    }

    final String title =
        "You captured ${numberFormat.format(snapshot.totalCount)} moments";
    final Map<String, Object?> meta = <String, Object?>{
      "year": snapshot.year,
      "totalCount": snapshot.totalCount,
      "photoCount": snapshot.photoCount,
      "videoCount": snapshot.videoCount,
      "livePhotoCount": snapshot.livePhotoCount,
      "otherCount": snapshot.otherCount,
      "storageBytes": snapshot.storageBytes,
      "storageReadable": snapshot.storageBytes > 0
          ? formatBytes(snapshot.storageBytes, 1)
          : "0 bytes",
      "daysWithCaptures": snapshot.daysWithCaptures,
      "elapsedDays": snapshot.elapsedDays,
    };

    return WrappedCard(
      type: WrappedCardType.statsTotals,
      title: title,
      subtitle: detailParts.isEmpty ? null : detailParts.join(" · "),
      meta: meta,
    );
  }

  WrappedCard? _buildVelocityCard(_StatsSnapshot snapshot) {
    if (snapshot.elapsedDays <= 0) {
      return null;
    }

    final NumberFormat averageFormat = NumberFormat("0.#");
    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateFormat monthFormat = DateFormat("MMMM");

    final String title =
        "${averageFormat.format(snapshot.averagePerDay)} memories per day";
    final List<String> subtitleParts = <String>[];
    String? busiestMonthName;
    if (snapshot.busiestMonth != null && snapshot.busiestMonthCount > 0) {
      busiestMonthName = monthFormat
          .format(DateTime(snapshot.year, snapshot.busiestMonth!, 1));
      subtitleParts.add(
        "$busiestMonthName peaked at ${numberFormat.format(snapshot.busiestMonthCount)}",
      );
    }
    subtitleParts.add(
      "${numberFormat.format(snapshot.daysWithCaptures)} active days",
    );
    if (snapshot.daysWithCaptures > 0 &&
        snapshot.averagePerActiveDay > snapshot.averagePerDay) {
      subtitleParts.add(
        "${averageFormat.format(snapshot.averagePerActiveDay)} on shooting days",
      );
    }

    final Map<String, Object?> meta = <String, Object?>{
      "year": snapshot.year,
      "averagePerDay": snapshot.averagePerDay,
      "averagePerActiveDay": snapshot.averagePerActiveDay,
      "elapsedDays": snapshot.elapsedDays,
      "daysWithCaptures": snapshot.daysWithCaptures,
      "busiestMonth": snapshot.busiestMonth,
      "busiestMonthName": busiestMonthName,
      "busiestMonthCount": snapshot.busiestMonthCount,
      "monthCounts": <String, int>{
        for (final MapEntry<int, int> entry in snapshot.monthCounts.entries)
          entry.key.toString(): entry.value,
      },
      "dailyCounts": snapshot.dailyCounts,
    };

    return WrappedCard(
      type: WrappedCardType.statsVelocity,
      title: title,
      subtitle: subtitleParts.join(" · "),
      meta: meta,
    );
  }

  WrappedCard? _buildBusiestDayCard(_StatsSnapshot snapshot) {
    if (snapshot.busiestDay == null || snapshot.busiestDayCount == 0) {
      return null;
    }

    final DateFormat longDateFormat = DateFormat("MMMM d, yyyy");
    final DateFormat weekdayFormat = DateFormat("EEEE");
    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateTime day = snapshot.busiestDay!;

    final List<MediaRef> mediaRefs = snapshot.busiestDayMediaUploadedIDs
        .take(4)
        .map(MediaRef.new)
        .toList(growable: false);

    final Map<String, Object?> meta = <String, Object?>{
      "date": day.toIso8601String(),
      "weekday": weekdayFormat.format(day),
      "count": snapshot.busiestDayCount,
      if (mediaRefs.isNotEmpty)
        "uploadedFileIDs": snapshot.busiestDayMediaUploadedIDs,
    };

    return WrappedCard(
      type: WrappedCardType.busiestDay,
      title: "${longDateFormat.format(day)} was your biggest day",
      subtitle:
          "${numberFormat.format(snapshot.busiestDayCount)} memories captured",
      media: mediaRefs,
      meta: meta,
    );
  }

  WrappedCard? _buildLongestStreakCard(_StatsSnapshot snapshot) {
    if (snapshot.longestStreakDays < 2 ||
        snapshot.longestStreakStart == null ||
        snapshot.longestStreakEnd == null) {
      return null;
    }

    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateFormat shortFormat = DateFormat("MMM d");
    final DateFormat longFormat = DateFormat("MMM d, yyyy");

    final DateTime start = snapshot.longestStreakStart!;
    final DateTime end = snapshot.longestStreakEnd!;
    final bool singleDay = start.isAtSameMomentAs(end);

    final String subtitle = singleDay
        ? longFormat.format(start)
        : "${start.year == end.year ? shortFormat.format(start) : longFormat.format(start)} – ${longFormat.format(end)}";

    return WrappedCard(
      type: WrappedCardType.longestStreak,
      title:
          "Longest streak: ${numberFormat.format(snapshot.longestStreakDays)} days",
      subtitle: subtitle,
      meta: <String, Object?>{
        "length": snapshot.longestStreakDays,
        "start": start.toIso8601String(),
        "end": end.toIso8601String(),
      },
    );
  }

  WrappedCard? _buildLongestGapCard(_StatsSnapshot snapshot) {
    if (snapshot.longestGapDays <= 0 ||
        snapshot.longestGapStart == null ||
        snapshot.longestGapEnd == null) {
      return null;
    }

    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateFormat longFormat = DateFormat("MMM d, yyyy");
    final DateTime start = snapshot.longestGapStart!;
    final DateTime end = snapshot.longestGapEnd!;

    final String subtitle = start.isAtSameMomentAs(end)
        ? longFormat.format(start)
        : "${longFormat.format(start)} – ${longFormat.format(end)}";

    return WrappedCard(
      type: WrappedCardType.longestGap,
      title:
          "Longest break: ${numberFormat.format(snapshot.longestGapDays)} days",
      subtitle: subtitle,
      meta: <String, Object?>{
        "length": snapshot.longestGapDays,
        "start": start.toIso8601String(),
        "end": end.toIso8601String(),
      },
    );
  }
}

class PeopleCandidateBuilder extends WrappedCandidateBuilder {
  const PeopleCandidateBuilder();

  @override
  String get debugLabel => "people";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class PlacesCandidateBuilder extends WrappedCandidateBuilder {
  const PlacesCandidateBuilder();

  @override
  String get debugLabel => "places";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class AestheticsCandidateBuilder extends WrappedCandidateBuilder {
  const AestheticsCandidateBuilder();

  @override
  String get debugLabel => "aesthetics";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class CurationCandidateBuilder extends WrappedCandidateBuilder {
  const CurationCandidateBuilder();

  @override
  String get debugLabel => "curation";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

class NarrativeCandidateBuilder extends WrappedCandidateBuilder {
  const NarrativeCandidateBuilder();

  @override
  String get debugLabel => "narrative";

  @override
  Future<List<WrappedCard>> build(WrappedEngineContext context) async {
    return <WrappedCard>[];
  }
}

/// Registry of all candidate builders invoked by the engine.
const List<WrappedCandidateBuilder> wrappedCandidateBuilders =
    <WrappedCandidateBuilder>[
  StatsCandidateBuilder(),
  PeopleCandidateBuilder(),
  PlacesCandidateBuilder(),
  AestheticsCandidateBuilder(),
  CurationCandidateBuilder(),
  NarrativeCandidateBuilder(),
];

class _StatsSnapshot {
  _StatsSnapshot({
    required this.year,
    required this.totalCount,
    required this.photoCount,
    required this.videoCount,
    required this.livePhotoCount,
    required this.otherCount,
    required this.storageBytes,
    required this.monthCounts,
    required this.dailyCounts,
    required this.elapsedDays,
    required this.daysWithCaptures,
    required this.averagePerDay,
    required this.averagePerActiveDay,
    required this.busiestMonth,
    required this.busiestMonthCount,
    required this.busiestDay,
    required this.busiestDayCount,
    required this.busiestDayMediaUploadedIDs,
    required this.longestStreakDays,
    required this.longestStreakStart,
    required this.longestStreakEnd,
    required this.longestGapDays,
    required this.longestGapStart,
    required this.longestGapEnd,
  });

  final int year;
  final int totalCount;
  final int photoCount;
  final int videoCount;
  final int livePhotoCount;
  final int otherCount;
  final int storageBytes;
  final Map<int, int> monthCounts;
  final Map<String, int> dailyCounts;
  final int elapsedDays;
  final int daysWithCaptures;
  final double averagePerDay;
  final double averagePerActiveDay;
  final int? busiestMonth;
  final int busiestMonthCount;
  final DateTime? busiestDay;
  final int busiestDayCount;
  final List<int> busiestDayMediaUploadedIDs;
  final int longestStreakDays;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;
  final int longestGapDays;
  final DateTime? longestGapStart;
  final DateTime? longestGapEnd;

  static _StatsSnapshot fromContext(WrappedEngineContext context) {
    final int year = context.year;
    final DateTime startOfYear = DateTime(year, 1, 1);
    final DateTime periodEndDay = _resolvePeriodEndDay(context.now, year);
    final Map<int, int> monthCounts = <int, int>{
      for (int month = 1; month <= 12; month += 1) month: 0,
    };
    final Map<int, _DayAggregate> dayAggregates = <int, _DayAggregate>{};

    int totalCount = 0;
    int photoCount = 0;
    int videoCount = 0;
    int livePhotoCount = 0;
    int otherCount = 0;
    int storageBytes = 0;

    for (final EnteFile file in context.files) {
      final int? creationTime = file.creationTime;
      if (creationTime == null) continue;

      final DateTime captured =
          DateTime.fromMicrosecondsSinceEpoch(creationTime);
      if (captured.year != year) continue;

      totalCount += 1;

      switch (file.fileType) {
        case FileType.video:
          videoCount += 1;
          break;
        case FileType.livePhoto:
          livePhotoCount += 1;
          photoCount += 1;
          break;
        case FileType.image:
          photoCount += 1;
          break;
        default:
          otherCount += 1;
      }

      if (file.fileSize != null && file.fileSize! > 0) {
        storageBytes += file.fileSize!;
      }

      monthCounts[captured.month] = (monthCounts[captured.month] ?? 0) + 1;

      final DateTime day =
          DateTime(captured.year, captured.month, captured.day);
      final int dayKey = day.microsecondsSinceEpoch;
      final _DayAggregate aggregate =
          dayAggregates.putIfAbsent(dayKey, () => _DayAggregate(day));
      aggregate.count += 1;
      final int? uploadedId = file.uploadedFileID;
      if (uploadedId != null && aggregate.uploadedFileIDs.length < 9) {
        aggregate.uploadedFileIDs.add(uploadedId);
      }
    }

    final List<_DayAggregate> sortedAggregates =
        dayAggregates.values.toList(growable: false)
          ..sort((a, b) => a.day.compareTo(b.day));

    final int daysWithCaptures = sortedAggregates.length;
    final Map<String, int> dailyCounts = <String, int>{
      for (final _DayAggregate aggregate in sortedAggregates)
        aggregate.day.toIso8601String(): aggregate.count,
    };

    int? busiestMonth;
    int busiestMonthCount = 0;
    monthCounts.forEach((int month, int count) {
      if (count > busiestMonthCount ||
          (count == busiestMonthCount &&
              (busiestMonth == null || month < busiestMonth!))) {
        busiestMonth = month;
        busiestMonthCount = count;
      }
    });

    _DayAggregate? busiestDayAggregate;
    for (final _DayAggregate candidate in sortedAggregates) {
      if (busiestDayAggregate == null ||
          candidate.count > busiestDayAggregate.count ||
          (candidate.count == busiestDayAggregate.count &&
              candidate.day.isBefore(busiestDayAggregate.day))) {
        busiestDayAggregate = candidate;
      }
    }

    final _StreakResult streakResult =
        _calculateLongestStreak(sortedAggregates);
    final _GapResult gapResult =
        _calculateLongestGap(sortedAggregates, startOfYear, periodEndDay);

    int rawElapsedDays = periodEndDay.difference(startOfYear).inDays;
    if (rawElapsedDays < 0) rawElapsedDays = 0;
    final int elapsedDays =
        math.max(1, math.min(rawElapsedDays + 1, 366));

    final double averagePerDay =
        elapsedDays > 0 ? totalCount / elapsedDays : 0.0;
    final double averagePerActiveDay =
        daysWithCaptures > 0 ? totalCount / daysWithCaptures : 0.0;

    final DateTime? busiestDay = busiestDayAggregate?.day;
    final int busiestDayCount = busiestDayAggregate?.count ?? 0;
    final List<int> busiestDayMediaUploadedIDs =
        busiestDayAggregate == null || busiestDayAggregate.uploadedFileIDs.isEmpty
            ? const <int>[]
            : List<int>.unmodifiable(busiestDayAggregate.uploadedFileIDs);

    return _StatsSnapshot(
      year: year,
      totalCount: totalCount,
      photoCount: photoCount,
      videoCount: videoCount,
      livePhotoCount: livePhotoCount,
      otherCount: otherCount,
      storageBytes: storageBytes,
      monthCounts: Map<int, int>.unmodifiable(monthCounts),
      dailyCounts: Map<String, int>.unmodifiable(dailyCounts),
      elapsedDays: elapsedDays,
      daysWithCaptures: daysWithCaptures,
      averagePerDay: averagePerDay,
      averagePerActiveDay: averagePerActiveDay,
      busiestMonth: busiestMonth,
      busiestMonthCount: busiestMonthCount,
      busiestDay: busiestDay,
      busiestDayCount: busiestDayCount,
      busiestDayMediaUploadedIDs: busiestDayMediaUploadedIDs,
      longestStreakDays: streakResult.length,
      longestStreakStart: streakResult.start,
      longestStreakEnd: streakResult.end,
      longestGapDays: gapResult.length,
      longestGapStart: gapResult.start,
      longestGapEnd: gapResult.end,
    );
  }
}

class _DayAggregate {
  _DayAggregate(this.day);

  final DateTime day;
  int count = 0;
  final List<int> uploadedFileIDs = <int>[];
}

class _StreakResult {
  const _StreakResult({
    required this.length,
    this.start,
    this.end,
  });

  final int length;
  final DateTime? start;
  final DateTime? end;
}

_StreakResult _calculateLongestStreak(List<_DayAggregate> aggregates) {
  if (aggregates.isEmpty) {
    return const _StreakResult(length: 0);
  }

  int longest = 1;
  int current = 0;
  DateTime? currentStart;
  DateTime? bestStart = aggregates.first.day;
  DateTime? bestEnd = aggregates.first.day;
  DateTime? previousDay;

  for (final _DayAggregate aggregate in aggregates) {
    final DateTime day = aggregate.day;
    if (previousDay == null || day.difference(previousDay).inDays > 1) {
      current = 1;
      currentStart = day;
    } else {
      current += 1;
    }

    if (current > longest ||
        (current == longest &&
            currentStart != null &&
            bestStart != null &&
            currentStart.isBefore(bestStart))) {
      longest = current;
      bestStart = currentStart ?? day;
      bestEnd = day;
    }

    previousDay = day;
  }

  return _StreakResult(
    length: longest,
    start: bestStart,
    end: bestEnd,
  );
}

class _GapResult {
  const _GapResult({
    required this.length,
    this.start,
    this.end,
  });

  final int length;
  final DateTime? start;
  final DateTime? end;
}

_GapResult _calculateLongestGap(
  List<_DayAggregate> aggregates,
  DateTime startOfYear,
  DateTime periodEndDay,
) {
  if (aggregates.isEmpty) {
    final int fullSpan =
        math.max(0, periodEndDay.difference(startOfYear).inDays + 1);
    return _GapResult(length: fullSpan, start: startOfYear, end: periodEndDay);
  }

  int longest = 0;
  DateTime? gapStart;
  DateTime? gapEnd;

  final DateTime firstDay = aggregates.first.day;
  final int leadingGap = firstDay.difference(startOfYear).inDays;
  if (leadingGap > longest) {
    longest = leadingGap;
    if (leadingGap > 0) {
      gapStart = startOfYear;
      gapEnd = firstDay.subtract(const Duration(days: 1));
    }
  }

  for (int i = 1; i < aggregates.length; i += 1) {
    final DateTime prev = aggregates[i - 1].day;
    final DateTime current = aggregates[i].day;
    final int gap = current.difference(prev).inDays - 1;
    if (gap > longest) {
      longest = gap;
      gapStart = prev.add(const Duration(days: 1));
      gapEnd = current.subtract(const Duration(days: 1));
    }
  }

  final DateTime lastDay = aggregates.last.day;
  final int trailingGap = periodEndDay.difference(lastDay).inDays;
  if (trailingGap > longest) {
    longest = trailingGap;
    if (trailingGap > 0) {
      gapStart = lastDay.add(const Duration(days: 1));
      gapEnd = periodEndDay;
    }
  }

  if (longest <= 0 || gapStart == null || gapEnd == null) {
    return const _GapResult(length: 0);
  }

  return _GapResult(length: longest, start: gapStart, end: gapEnd);
}

DateTime _resolvePeriodEndDay(DateTime now, int year) {
  if (now.year < year) {
    return DateTime(year, 12, 31);
  }
  if (now.year > year) {
    return DateTime(year, 12, 31);
  }
  return DateTime(year, now.month, now.day);
}
