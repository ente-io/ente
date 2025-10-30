part of 'package:photos/services/wrapped/candidate_builders.dart';

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
    cards.add(_buildTotalsCard(context, snapshot));

    final WrappedCard? rhythmCard = _buildRhythmCard(context, snapshot);
    if (rhythmCard != null) {
      cards.add(rhythmCard);
    }

    final WrappedCard? busiestDayCard = _buildBusiestDayCard(context, snapshot);
    if (busiestDayCard != null) {
      cards.add(busiestDayCard);
    }

    cards.addAll(_buildHeatmapCards(snapshot));

    return cards;
  }

  WrappedCard _buildTotalsCard(
    WrappedEngineContext context,
    _StatsSnapshot snapshot,
  ) {
    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateFormat fullDateFormat = DateFormat("MMMM d");

    final int stillPhotoCount =
        math.max(snapshot.photoCount - snapshot.livePhotoCount, 0);
    final List<String> detailChips = <String>[];
    if (stillPhotoCount > 0) {
      detailChips.add(
        "${numberFormat.format(stillPhotoCount)} ${stillPhotoCount == 1 ? 'photo' : 'photos'}",
      );
    }
    if (snapshot.livePhotoCount > 0) {
      detailChips.add(
        "${numberFormat.format(snapshot.livePhotoCount)} live ${snapshot.livePhotoCount == 1 ? 'photo' : 'photos'}",
      );
    }
    if (snapshot.videoCount > 0) {
      detailChips.add(
        "${numberFormat.format(snapshot.videoCount)} ${snapshot.videoCount == 1 ? 'video' : 'videos'}",
      );
    }
    if (snapshot.storageBytes > 0) {
      detailChips.add("${formatBytes(snapshot.storageBytes, 1)} captured");
    }

    final String title =
        "You bottled ${numberFormat.format(snapshot.totalCount)} memories";
    final String subtitle = snapshot.videoCount > 0
        ? "That’s ${numberFormat.format(snapshot.photoCount)} photos and "
            "${numberFormat.format(snapshot.videoCount)} videos ready to relive."
        : "That’s ${numberFormat.format(snapshot.photoCount)} photos you kept close this year.";

    final List<int> heroIds = _collectUniqueIds(
      <List<int>>[
        snapshot.firstCaptureUploadedIDs,
        snapshot.busiestDayMediaUploadedIDs,
        snapshot.lastCaptureUploadedIDs,
      ],
      selectionTarget: 6,
    );

    final List<MediaRef> media = WrappedMediaSelector.selectMediaRefs(
      context: context,
      candidateUploadedFileIDs: heroIds,
      maxCount: 6,
      preferNamedPeople: true,
      minimumSpacing: const Duration(days: 45),
    );

    final String? firstCaptureLine = snapshot.firstCaptureDay != null
        ? "First frame: ${fullDateFormat.format(snapshot.firstCaptureDay!)}"
        : null;

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
      "detailChips": detailChips,
      if (firstCaptureLine != null) "firstCaptureLine": firstCaptureLine,
      "displayDurationMillis": 9000,
    };

    return WrappedCard(
      type: WrappedCardType.statsTotals,
      title: title,
      subtitle: subtitle,
      media: media,
      meta: meta
        ..addAll(
          <String, Object?>{
            if (media.isNotEmpty)
              "uploadedFileIDs": media
                  .map((MediaRef ref) => ref.uploadedFileID)
                  .toList(growable: false),
          },
        ),
    );
  }

  WrappedCard? _buildRhythmCard(
    WrappedEngineContext context,
    _StatsSnapshot snapshot,
  ) {
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

    final List<String> chips = <String>[
      "${numberFormat.format(snapshot.daysWithCaptures)} active days",
      if (snapshot.longestStreakDays >= 3)
        "Longest streak: ${numberFormat.format(snapshot.longestStreakDays)} days",
      if (snapshot.longestGapDays >= 2)
        "Longest breather: ${numberFormat.format(snapshot.longestGapDays)} days",
    ];

    final List<int> rhythmIds = _collectUniqueIds(
      <List<int>>[
        snapshot.streakStartUploadedIDs,
        snapshot.busiestMonthHighlightUploadedIDs,
        snapshot.breakReturnUploadedIDs,
      ],
      selectionTarget: 6,
    );

    final List<MediaRef> media = WrappedMediaSelector.selectMediaRefs(
      context: context,
      candidateUploadedFileIDs: rhythmIds,
      maxCount: 6,
      preferNamedPeople: true,
      minimumSpacing: const Duration(days: 21),
    );

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
      "detailChips": chips,
      if (snapshot.longestStreakStart != null)
        "longestStreakStart": snapshot.longestStreakStart!.toIso8601String(),
      if (snapshot.longestStreakEnd != null)
        "longestStreakEnd": snapshot.longestStreakEnd!.toIso8601String(),
      "longestStreakDays": snapshot.longestStreakDays,
      "longestGapDays": snapshot.longestGapDays,
      if (snapshot.longestGapStart != null)
        "longestGapStart": snapshot.longestGapStart!.toIso8601String(),
      if (snapshot.longestGapEnd != null)
        "longestGapEnd": snapshot.longestGapEnd!.toIso8601String(),
    };

    return WrappedCard(
      type: WrappedCardType.statsVelocity,
      title: title,
      subtitle: subtitleParts.join(" · "),
      media: media,
      meta: meta
        ..addAll(
          <String, Object?>{
            if (media.isNotEmpty)
              "uploadedFileIDs": media
                  .map((MediaRef ref) => ref.uploadedFileID)
                  .toList(growable: false),
          },
        ),
    );
  }

  WrappedCard? _buildBusiestDayCard(
    WrappedEngineContext context,
    _StatsSnapshot snapshot,
  ) {
    if (snapshot.busiestDay == null || snapshot.busiestDayCount == 0) {
      return null;
    }

    final DateFormat longDateFormat = DateFormat("MMMM d, yyyy");
    final DateFormat weekdayFormat = DateFormat("EEEE");
    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final DateTime day = snapshot.busiestDay!;

    final List<MediaRef> mediaRefs = WrappedMediaSelector.selectMediaRefs(
      context: context,
      candidateUploadedFileIDs: snapshot.busiestDayMediaUploadedIDs,
      maxCount: 6,
      preferNamedPeople: true,
    );

    final Map<String, Object?> meta = <String, Object?>{
      "date": day.toIso8601String(),
      "weekday": weekdayFormat.format(day),
      "count": snapshot.busiestDayCount,
      "detailChips": <String>[
        "${numberFormat.format(snapshot.busiestDayCount)} memories in 24 hours",
        weekdayFormat.format(day),
      ],
      if (mediaRefs.isNotEmpty)
        "uploadedFileIDs": mediaRefs
            .map((MediaRef ref) => ref.uploadedFileID)
            .toList(growable: false),
    };

    return WrappedCard(
      type: WrappedCardType.busiestDay,
      title: "${longDateFormat.format(day)} went off",
      subtitle:
          "${numberFormat.format(snapshot.busiestDayCount)} memories captured in a single day.",
      media: mediaRefs,
      meta: meta,
    );
  }

  List<WrappedCard> _buildHeatmapCards(_StatsSnapshot snapshot) {
    if (snapshot.heatmapRows.isEmpty) {
      return const <WrappedCard>[];
    }

    final List<Map<String, Object?>> quarterBlocks =
        _QuarterHeatmapData.fromSnapshot(snapshot);
    if (quarterBlocks.isEmpty) {
      return const <WrappedCard>[];
    }

    final NumberFormat numberFormat = NumberFormat.decimalPattern();
    final Map<String, Object?> meta = <String, Object?>{
      "weekdayLabels": snapshot.heatmapWeekdayLabels,
      "quarters": quarterBlocks,
      "maxCount": snapshot.heatmapMaxCount,
      "detailChips": <String>[
        if (snapshot.busiestMonthName != null)
          "Peak month: ${snapshot.busiestMonthName}",
        "${numberFormat.format(snapshot.totalCount)} captures this year",
      ],
    };

    return <WrappedCard>[
      WrappedCard(
        type: WrappedCardType.statsHeatmap,
        title: "Seasons of snapshots",
        subtitle: "Your year, one quarter at a time.",
        meta: meta,
      ),
    ];
  }

  List<int> _collectUniqueIds(
    List<List<int>> sources, {
    required int selectionTarget,
  }) {
    final Set<int> seen = <int>{};
    final List<int> result = <int>[];
    final int poolTarget = math.max(selectionTarget * 4, selectionTarget + 6);
    for (final List<int> source in sources) {
      for (final int id in source) {
        if (id <= 0) continue;
        if (seen.add(id)) {
          result.add(id);
        }
        if (result.length >= poolTarget) {
          return result;
        }
      }
    }
    return result;
  }
}

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
    required this.busiestMonthName,
    required this.busiestDay,
    required this.busiestDayCount,
    required this.busiestDayMediaUploadedIDs,
    required this.longestStreakDays,
    required this.longestStreakStart,
    required this.longestStreakEnd,
    required this.streakStartUploadedIDs,
    required this.longestGapDays,
    required this.longestGapStart,
    required this.longestGapEnd,
    required this.breakReturnUploadedIDs,
    required this.firstCaptureDay,
    required this.firstCaptureUploadedIDs,
    required this.lastCaptureDay,
    required this.lastCaptureUploadedIDs,
    required this.busiestMonthHighlightUploadedIDs,
    required this.periodEndDay,
    required this.heatmapStart,
    required this.heatmapEnd,
    required this.heatmapRows,
    required this.heatmapWeekLabels,
    required this.heatmapWeekdayLabels,
    required this.heatmapWeekStartDates,
    required this.heatmapMaxCount,
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
  final String? busiestMonthName;
  final DateTime? busiestDay;
  final int busiestDayCount;
  final List<int> busiestDayMediaUploadedIDs;
  final int longestStreakDays;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;
  final List<int> streakStartUploadedIDs;
  final int longestGapDays;
  final DateTime? longestGapStart;
  final DateTime? longestGapEnd;
  final List<int> breakReturnUploadedIDs;
  final DateTime? firstCaptureDay;
  final List<int> firstCaptureUploadedIDs;
  final DateTime? lastCaptureDay;
  final List<int> lastCaptureUploadedIDs;
  final List<int> busiestMonthHighlightUploadedIDs;
  final DateTime periodEndDay;
  final DateTime heatmapStart;
  final DateTime heatmapEnd;
  final List<List<int>> heatmapRows;
  final List<String> heatmapWeekLabels;
  final List<String> heatmapWeekdayLabels;
  final List<DateTime> heatmapWeekStartDates;
  final int heatmapMaxCount;

  static _StatsSnapshot fromContext(WrappedEngineContext context) {
    final int year = context.year;
    final DateTime startOfYear = DateTime(year, 1, 1);
    final DateTime periodEndDay = _resolvePeriodEndDay(context.now, year);
    final DateFormat monthNameFormat = DateFormat("MMMM");
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

    final List<_DayAggregate> sortedAggregates = dayAggregates.values
        .toList(growable: false)
      ..sort((a, b) => a.day.compareTo(b.day));

    final int daysWithCaptures = sortedAggregates.length;
    final Map<String, int> dailyCounts = <String, int>{
      for (final _DayAggregate aggregate in sortedAggregates)
        aggregate.day.toIso8601String(): aggregate.count,
    };

    final DateTime? firstCaptureDay =
        sortedAggregates.isEmpty ? null : sortedAggregates.first.day;
    final List<int> firstCaptureUploadedIDs = firstCaptureDay == null
        ? const <int>[]
        : List<int>.unmodifiable(sortedAggregates.first.uploadedFileIDs);
    final DateTime? lastCaptureDay =
        sortedAggregates.isEmpty ? null : sortedAggregates.last.day;
    final List<int> lastCaptureUploadedIDs = lastCaptureDay == null
        ? const <int>[]
        : List<int>.unmodifiable(sortedAggregates.last.uploadedFileIDs);

    int? busiestMonth;
    int busiestMonthCount = 0;
    String? busiestMonthName;
    monthCounts.forEach((int month, int count) {
      if (count > busiestMonthCount ||
          (count == busiestMonthCount &&
              (busiestMonth == null || month < busiestMonth!))) {
        busiestMonth = month;
        busiestMonthCount = count;
        busiestMonthName = monthNameFormat.format(DateTime(year, month, 1));
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

    final List<int> busiestMonthHighlightUploadedIDs;
    if (busiestMonth == null) {
      busiestMonthHighlightUploadedIDs = const <int>[];
    } else {
      _DayAggregate? bestInMonth;
      for (final _DayAggregate aggregate in sortedAggregates) {
        if (aggregate.day.month != busiestMonth) {
          continue;
        }
        if (bestInMonth == null ||
            aggregate.count > bestInMonth.count ||
            (aggregate.count == bestInMonth.count &&
                aggregate.day.isBefore(bestInMonth.day))) {
          bestInMonth = aggregate;
        }
      }
      busiestMonthHighlightUploadedIDs = bestInMonth == null
          ? const <int>[]
          : List<int>.unmodifiable(bestInMonth.uploadedFileIDs);
    }

    final _StreakResult streakResult =
        _calculateLongestStreak(sortedAggregates);
    final _GapResult gapResult =
        _calculateLongestGap(sortedAggregates, startOfYear, periodEndDay);

    final List<int> streakStartUploadedIDs =
        _uploadedIDsForDay(dayAggregates, streakResult.start);

    List<int> breakReturnUploadedIDs = const <int>[];
    if (gapResult.length > 0 && gapResult.end != null) {
      final DateTime resumeDay = gapResult.end!.add(const Duration(days: 1));
      if (resumeDay.year == year) {
        breakReturnUploadedIDs = _uploadedIDsForDay(dayAggregates, resumeDay);
      }
    }

    int rawElapsedDays = periodEndDay.difference(startOfYear).inDays;
    if (rawElapsedDays < 0) rawElapsedDays = 0;
    final int elapsedDays = math.max(1, math.min(rawElapsedDays + 1, 366));

    final double averagePerDay =
        elapsedDays > 0 ? totalCount / elapsedDays : 0.0;
    final double averagePerActiveDay =
        daysWithCaptures > 0 ? totalCount / daysWithCaptures : 0.0;

    final DateTime? busiestDay = busiestDayAggregate?.day;
    final int busiestDayCount = busiestDayAggregate?.count ?? 0;
    final List<int> busiestDayMediaUploadedIDs = busiestDayAggregate == null ||
            busiestDayAggregate.uploadedFileIDs.isEmpty
        ? const <int>[]
        : List<int>.unmodifiable(busiestDayAggregate.uploadedFileIDs);

    final DateTime heatmapStart =
        _atLocalMidnight(_alignToMonday(DateTime(year, 1, 1)));
    final DateTime heatmapEnd =
        _atLocalMidnight(_alignToSunday(DateTime(year, 12, 31)));
    final int heatmapDayCount = heatmapEnd.difference(heatmapStart).inDays + 1;
    final int heatmapWeekCount = heatmapDayCount ~/ 7;
    final List<List<int>> heatmapRows = List<List<int>>.generate(
      heatmapWeekCount,
      (_) => List<int>.filled(7, 0),
      growable: false,
    );
    final List<DateTime> heatmapWeekStartDates =
        List<DateTime>.filled(heatmapWeekCount, heatmapStart, growable: false);
    int heatmapMaxCount = 0;
    DateTime weekCursor = heatmapStart;
    for (int weekIndex = 0; weekIndex < heatmapWeekCount; weekIndex += 1) {
      final DateTime weekStart = _atLocalMidnight(weekCursor);
      heatmapWeekStartDates[weekIndex] = weekStart;
      for (int dayOffset = 0; dayOffset < 7; dayOffset += 1) {
        final DateTime day = _atLocalMidnight(
          weekStart.add(Duration(days: dayOffset)),
        );
        final int count = dailyCounts[day.toIso8601String()] ?? 0;
        heatmapRows[weekIndex][dayOffset] = count;
        if (count > heatmapMaxCount) {
          heatmapMaxCount = count;
        }
      }
      weekCursor = _atLocalMidnight(
        weekCursor.add(const Duration(days: 7)),
      );
    }

    final DateFormat monthAbbrevFormat = DateFormat("MMM");
    final List<String> heatmapWeekLabels =
        List<String>.filled(heatmapWeekCount, "", growable: false);
    int? lastLabeledMonth;
    for (int row = 0; row < heatmapWeekCount; row += 1) {
      final DateTime weekStart = heatmapWeekStartDates[row];
      final DateTime weekEnd = weekStart.add(const Duration(days: 6));
      final int representativeMonth = weekEnd.month;
      if (row == 0 || representativeMonth != lastLabeledMonth) {
        heatmapWeekLabels[row] = monthAbbrevFormat.format(weekEnd);
        lastLabeledMonth = representativeMonth;
      }
    }

    const List<String> heatmapWeekdayLabels = <String>[
      "M",
      "T",
      "W",
      "T",
      "F",
      "S",
      "S",
    ];

    final List<List<int>> normalizedHeatmapRows = heatmapRows
        .map((List<int> row) => List<int>.unmodifiable(row))
        .toList(growable: false);
    final List<String> normalizedWeekLabels =
        List<String>.unmodifiable(heatmapWeekLabels);
    final List<String> normalizedWeekdayLabels =
        List<String>.unmodifiable(heatmapWeekdayLabels);
    final List<DateTime> normalizedWeekStartDates =
        List<DateTime>.unmodifiable(heatmapWeekStartDates);

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
      busiestMonthName: busiestMonthName,
      busiestDay: busiestDay,
      busiestDayCount: busiestDayCount,
      busiestDayMediaUploadedIDs: busiestDayMediaUploadedIDs,
      longestStreakDays: streakResult.length,
      longestStreakStart: streakResult.start,
      longestStreakEnd: streakResult.end,
      streakStartUploadedIDs: streakStartUploadedIDs,
      longestGapDays: gapResult.length,
      longestGapStart: gapResult.start,
      longestGapEnd: gapResult.end,
      breakReturnUploadedIDs: breakReturnUploadedIDs,
      firstCaptureDay: firstCaptureDay,
      firstCaptureUploadedIDs: firstCaptureUploadedIDs,
      lastCaptureDay: lastCaptureDay,
      lastCaptureUploadedIDs: lastCaptureUploadedIDs,
      busiestMonthHighlightUploadedIDs: busiestMonthHighlightUploadedIDs,
      periodEndDay: periodEndDay,
      heatmapStart: heatmapStart,
      heatmapEnd: heatmapEnd,
      heatmapRows: normalizedHeatmapRows,
      heatmapWeekLabels: normalizedWeekLabels,
      heatmapWeekdayLabels: normalizedWeekdayLabels,
      heatmapWeekStartDates: normalizedWeekStartDates,
      heatmapMaxCount: heatmapMaxCount,
    );
  }
}

class _DayAggregate {
  _DayAggregate(this.day);

  final DateTime day;
  int count = 0;
  final List<int> uploadedFileIDs = <int>[];
}

class _QuarterHeatmapData {
  static List<Map<String, Object?>> fromSnapshot(_StatsSnapshot snapshot) {
    if (snapshot.heatmapRows.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    final DateFormat monthFormat = DateFormat("MMM");
    final DateTime lastVisibleDay = _atLocalMidnight(
      snapshot.periodEndDay.isBefore(snapshot.heatmapEnd)
          ? snapshot.periodEndDay
          : snapshot.heatmapEnd,
    );
    final List<List<List<int>>> quarterWeeks =
        List<List<List<int>>>.generate(4, (_) => <List<int>>[]);
    final List<List<DateTime>> quarterWeekDates =
        List<List<DateTime>>.generate(4, (_) => <DateTime>[]);

    for (int index = 0;
        index < snapshot.heatmapRows.length &&
            index < snapshot.heatmapWeekStartDates.length;
        index += 1) {
      final DateTime weekStart =
          _atLocalMidnight(snapshot.heatmapWeekStartDates[index]);
      final int quarterIndex = ((weekStart.month - 1) ~/ 3).clamp(0, 3);
      final List<int> counts = snapshot.heatmapRows[index];
      final List<int> sanitized = List<int>.filled(7, 0);
      final DateTime yearStart = DateTime(snapshot.year, 1, 1);
      for (int dayOffset = 0; dayOffset < 7; dayOffset += 1) {
        final DateTime day = _atLocalMidnight(
          weekStart.add(Duration(days: dayOffset)),
        );
        if (day.isAfter(lastVisibleDay)) {
          sanitized[dayOffset] = kWrappedHeatmapFutureValue;
        } else if (day.isBefore(yearStart)) {
          sanitized[dayOffset] = kWrappedHeatmapPaddedValue;
        } else {
          sanitized[dayOffset] =
              dayOffset < counts.length ? counts[dayOffset] : 0;
        }
      }
      quarterWeeks[quarterIndex].add(sanitized);
      quarterWeekDates[quarterIndex].add(weekStart);
    }

    final List<Map<String, Object?>> blocks = <Map<String, Object?>>[];
    for (int quarter = 0; quarter < quarterWeeks.length; quarter += 1) {
      final List<List<int>> weeks = quarterWeeks[quarter];
      if (weeks.isEmpty) {
        continue;
      }
      final List<List<int>> grid = _transposeWeeks(weeks);
      final List<String> columnLabels =
          _buildColumnLabels(quarterWeekDates[quarter], monthFormat);
      blocks.add(<String, Object?>{
        "label": _quarterLabel(quarter),
        "grid": grid
            .map((List<int> row) => List<int>.unmodifiable(row))
            .toList(growable: false),
        "columnLabels": columnLabels,
      });
    }
    return blocks;
  }

  static List<List<int>> _transposeWeeks(List<List<int>> weeks) {
    if (weeks.isEmpty) {
      return List<List<int>>.generate(
        7,
        (_) => const <int>[],
        growable: false,
      );
    }
    final int columnCount = weeks.length;
    final int rowCount = weeks.first.length;
    return List<List<int>>.generate(
      rowCount,
      (int dayIndex) => List<int>.generate(
        columnCount,
        (int columnIndex) => weeks[columnIndex][dayIndex],
        growable: false,
      ),
      growable: false,
    );
  }

  static List<String> _buildColumnLabels(
    List<DateTime> weekStarts,
    DateFormat monthFormat,
  ) {
    final List<String> labels = <String>[];
    int? lastMonth;
    for (final DateTime start in weekStarts) {
      final int month = start.month;
      final bool isNewMonth = labels.isEmpty || month != lastMonth;
      final bool isQuarterStart = start.day <= 7;
      if (isNewMonth && isQuarterStart) {
        final String monthLabel = monthFormat.format(start);
        final String singleChar =
            monthLabel.isEmpty ? "" : monthLabel.substring(0, 1);
        labels.add(singleChar.toUpperCase());
        lastMonth = month;
      } else {
        labels.add("");
      }
    }
    return List<String>.unmodifiable(labels);
  }

  static String _quarterLabel(int index) {
    switch (index) {
      case 0:
        return "Jan – Mar";
      case 1:
        return "Apr – Jun";
      case 2:
        return "Jul – Sep";
      case 3:
      default:
        return "Oct – Dec";
    }
  }
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

List<int> _uploadedIDsForDay(
  Map<int, _DayAggregate> aggregates,
  DateTime? day,
) {
  if (day == null) {
    return const <int>[];
  }
  final DateTime normalized = DateTime(day.year, day.month, day.day);
  final _DayAggregate? aggregate =
      aggregates[normalized.microsecondsSinceEpoch];
  if (aggregate == null || aggregate.uploadedFileIDs.isEmpty) {
    return const <int>[];
  }
  return List<int>.unmodifiable(aggregate.uploadedFileIDs);
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

DateTime _atLocalMidnight(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _alignToMonday(DateTime date) {
  int delta = date.weekday - DateTime.monday;
  if (delta < 0) {
    delta += 7;
  }
  return _atLocalMidnight(DateTime(date.year, date.month, date.day - delta));
}

DateTime _alignToSunday(DateTime date) {
  int delta = DateTime.sunday - date.weekday;
  if (delta < 0) {
    delta += 7;
  }
  return _atLocalMidnight(DateTime(date.year, date.month, date.day + delta));
}
