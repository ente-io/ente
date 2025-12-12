import "dart:async";
import "dart:convert";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/language_service.dart";
import "package:photos/services/notification_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class RitualsService {
  static final RitualsService instance = RitualsService._privateConstructor();

  RitualsService._privateConstructor();

  static const _notificationLookaheadDays = 60;
  static const _maxScheduledNotificationsPerRitual = 30;
  final Logger _logger = Logger("RitualsService");
  final ValueNotifier<RitualsState> stateNotifier =
      ValueNotifier<RitualsState>(RitualsState.loading());
  late SharedPreferences _preferences;
  Timer? _debounce;
  StreamSubscription<FilesUpdatedEvent>? _filesUpdatedSubscription;
  Map<String, Set<int>> _seenRitualBadges = {};
  final Set<String> _recentlyAddedRitualIds = <String>{};

  static const _ritualsPrefsKey = "activity_rituals_v1";
  static const _ritualBadgesPrefsKey = "activity_seen_ritual_badges_v1";
  static const _badgeThresholds = [7, 14, 30];

  Future<void> init() async {
    _preferences = ServiceLocator.instance.prefs;
    _seenRitualBadges = _loadSeenRitualBadges();
    if (!flagService.ritualsFlag) {
      stateNotifier.value = const RitualsState(
        loading: false,
        summary: null,
        rituals: [],
        error: null,
        pendingBadge: null,
      );
      return;
    }
    _filesUpdatedSubscription =
        Bus.instance.on<FilesUpdatedEvent>().listen((event) {
      _scheduleRefresh();
    });
    _scheduleRefresh(initial: true, scheduleAllRituals: true);
  }

  void dispose() {
    _filesUpdatedSubscription?.cancel();
    _debounce?.cancel();
  }

  void _scheduleRefresh({
    bool initial = false,
    bool scheduleAllRituals = false,
  }) {
    _debounce?.cancel();
    _debounce = Timer(
      initial ? const Duration(seconds: 5) : const Duration(seconds: 1),
      () => unawaited(refresh(scheduleAllRituals: scheduleAllRituals)),
    );
  }

  Future<void> refresh({bool scheduleAllRituals = false}) async {
    if (!flagService.ritualsFlag) {
      stateNotifier.value = const RitualsState(
        loading: false,
        summary: null,
        rituals: [],
        error: null,
        pendingBadge: null,
      );
      return;
    }
    try {
      stateNotifier.value = stateNotifier.value.copyWith(
        loading: true,
        error: null,
        pendingBadge: stateNotifier.value.pendingBadge,
      );
      final rituals = await _loadRituals();
      if (scheduleAllRituals) {
        _logger.info(
          "Scheduling ritual reminders for ${rituals.length} rituals (startup refresh)",
        );
        for (final ritual in rituals) {
          await _scheduleRitualNotifications(ritual);
        }
      }
      final summary = await _buildSummary(rituals);
      final pendingBadge =
          _resolvePendingBadge(rituals, summary.ritualProgress);
      stateNotifier.value = RitualsState(
        loading: false,
        summary: summary,
        rituals: rituals,
        error: null,
        pendingBadge: pendingBadge,
      );
    } catch (e, s) {
      _logger.severe("Failed to refresh rituals", e, s);
      stateNotifier.value = stateNotifier.value.copyWith(
        loading: false,
        error: e.toString(),
        pendingBadge: null,
      );
    }
  }

  Future<RitualsSummary> _buildSummary(
    List<Ritual> rituals,
  ) async {
    final userId = Configuration.instance.getUserID();
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthEndInclusive =
        lastDayOfMonth.isAfter(todayMidnight) ? todayMidnight : lastDayOfMonth;
    if (userId == null) {
      return RitualsSummary(
        ritualProgress: {},
        generatedAt: DateTime.now(),
      );
    }
    final ritualAlbumIds = rituals
        .map((r) => r.albumId)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();

    final Map<int, Set<int>> collectionDayKeys = {};
    final Map<int, Map<int, EnteFile>> collectionRecentFilesByDay = {};

    if (ritualAlbumIds.isEmpty) {
      return RitualsSummary(
        ritualProgress: const {},
        generatedAt: DateTime.now(),
      );
    }

    final files = await FilesDB.instance.getAllFilesFromCollections(
      ritualAlbumIds,
    );
    final recentStart = DateTime(
      todayMidnight.year,
      todayMidnight.month,
      todayMidnight.day - 4,
    );
    for (final EnteFile file in files) {
      final bool ownerMatches =
          file.ownerID == null ? true : file.ownerID == userId;
      final bool uploaded =
          file.uploadedFileID != null && file.uploadedFileID != -1;
      if (!(ownerMatches && uploaded)) {
        continue;
      }
      if (file.creationTime == null) continue;
      final int? collectionId = file.collectionID;
      if (collectionId == null || collectionId <= 0) continue;
      if (!ritualAlbumIds.contains(collectionId)) continue;

      final date =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!).toLocal();
      final bucket = DateTime(date.year, date.month, date.day);
      if (bucket.isAfter(todayMidnight)) continue;
      final dayKey = bucket.millisecondsSinceEpoch;
      collectionDayKeys.putIfAbsent(collectionId, () => <int>{}).add(dayKey);

      if (bucket.isBefore(recentStart)) continue;
      final byDay =
          collectionRecentFilesByDay.putIfAbsent(collectionId, () => {});
      final existing = byDay[dayKey];
      if (existing == null) {
        byDay[dayKey] = file;
        continue;
      }
      if ((existing.creationTime ?? -1) < (file.creationTime ?? -1)) {
        byDay[dayKey] = file;
      }
    }

    final ritualProgress = <String, RitualProgress>{};
    for (final ritual in rituals) {
      final albumId = ritual.albumId;
      if (albumId == null || albumId <= 0) continue;
      final dates = collectionDayKeys[albumId] ?? <int>{};
      final ritualLongestOverall = _longestScheduledStreakFromDayKeys(
        dates,
        ritual.daysOfWeek,
        todayMidnight: todayMidnight,
      );
      final ritualCurrent = _currentScheduledStreakFromDayKeys(
        dates,
        ritual.daysOfWeek,
        todayMidnight: todayMidnight,
      );
      final ritualLongestThisMonth = _longestScheduledStreakInRangeFromDayKeys(
        dates,
        ritual.daysOfWeek,
        startDay: monthStart,
        endDayInclusive: monthEndInclusive,
      );

      ritualProgress[ritual.id] = RitualProgress(
        ritualId: ritual.id,
        completedDayKeys: dates,
        recentFilesByDay: collectionRecentFilesByDay[albumId] ?? const {},
        currentStreak: ritualCurrent,
        longestStreakOverall: ritualLongestOverall,
        longestStreakThisMonth: ritualLongestThisMonth,
      );
    }

    return RitualsSummary(
      ritualProgress: ritualProgress,
      generatedAt: DateTime.now(),
    );
  }

  Set<int> _normalizeBadgeSet(Set<int> seen) {
    if (seen.isEmpty) return <int>{};
    final valid =
        seen.where((value) => _badgeThresholds.contains(value)).toSet();
    if (valid.isEmpty) return <int>{};
    final highest = valid.reduce(max);
    return {
      for (final threshold in _badgeThresholds)
        if (threshold <= highest) threshold,
    };
  }

  Future<List<Ritual>> _loadRituals() async {
    final raw = _preferences.getStringList(_ritualsPrefsKey) ?? [];
    return raw
        .map(
          (str) => Ritual.fromJson(
            Map<String, dynamic>.from(_decode(str)),
          ),
        )
        .where((element) => element.id.isNotEmpty)
        .toList(growable: true);
  }

  Map<String, dynamic> _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _encode(Ritual ritual) => jsonEncode(ritual.toJson());

  Future<void> saveRitual(Ritual ritual) async {
    final rituals = await _loadRituals();
    final existingIndex = rituals.indexWhere((r) => r.id == ritual.id);
    final bool isNew = existingIndex == -1;
    final Ritual? previous = isNew ? null : rituals[existingIndex];
    final bool albumChanged = previous?.albumId != ritual.albumId;
    if (isNew) {
      rituals.add(ritual);
    } else {
      rituals[existingIndex] = ritual;
    }
    if (isNew || albumChanged) {
      _recentlyAddedRitualIds.add(ritual.id);
    }
    await _persistRituals(rituals);
    unawaited(_scheduleRitualNotifications(ritual));

    if (isNew || albumChanged) {
      await refresh();
    } else {
      // No ritual completion data changes; just update rituals in state.
      stateNotifier.value = stateNotifier.value.copyWith(
        rituals: rituals,
        loading: false,
        error: null,
        pendingBadge: stateNotifier.value.pendingBadge,
      );
    }
  }

  Future<void> deleteRitual(String id) async {
    final rituals = await _loadRituals();
    rituals.removeWhere((r) => r.id == id);
    await _persistRituals(rituals);
    if (_seenRitualBadges.remove(id) != null) {
      unawaited(_persistSeenRitualBadges());
    }
    _logger.info("Clearing scheduled notifications for ritual $id (delete)");
    await NotificationService.instance.clearAllScheduledNotifications(
      containingPayload: "ritualId=$id",
      logLines: false,
    );
    await refresh();
  }

  Future<void> _persistRituals(List<Ritual> rituals) async {
    final encoded = rituals.map(_encode).toList();
    await _preferences.setStringList(_ritualsPrefsKey, encoded);
  }

  Future<void> _scheduleRitualNotifications(Ritual ritual) async {
    _logger.info(
      "Clearing scheduled notifications for ritual ${ritual.id} (save path)",
    );
    _logger.info(
      "Scheduling ritual reminders for ritual ${ritual.id} (save path)",
    );
    await NotificationService.instance.clearAllScheduledNotifications(
      containingPayload: ritual.id,
      logLines: false,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final baseId = ritual.id.hashCode & 0x7fffffff;
    final l10n = await LanguageService.locals;
    int scheduled = 0;
    for (int offset = 0;
        offset < _notificationLookaheadDays &&
            scheduled < _maxScheduledNotificationsPerRitual;
        offset++) {
      final targetDate = today.add(Duration(days: offset));
      final dayIndex = targetDate.weekday % 7; // Sunday -> 0
      if (!ritual.daysOfWeek[dayIndex]) continue;
      final icon = ritual.icon.isEmpty ? "📸" : ritual.icon;
      final title =
          ritual.title.trim().isEmpty ? icon : "$icon ${ritual.title.trim()}";
      final scheduledDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        ritual.timeOfDay.hour,
        ritual.timeOfDay.minute,
      );
      if (scheduledDate.isBefore(now)) {
        continue;
      }
      await NotificationService.instance.scheduleNotification(
        title,
        message: l10n.ritualNotificationMessage,
        id: baseId + scheduled,
        channelID: "ritual_reminders",
        channelName: l10n.ritualsTitle,
        payload: Uri(
          scheme: "ente",
          host: "camera",
          queryParameters: {
            "ritualId": ritual.id,
            "albumId": ritual.albumId?.toString() ?? "",
          },
        ).toString(),
        dateTime: scheduledDate,
        logSchedule: false,
      );
      scheduled += 1;
    }
  }

  Map<String, Set<int>> _loadSeenRitualBadges() {
    final raw = _preferences.getString(_ritualBadgesPrefsKey);
    if (raw == null || raw.isEmpty) {
      return <String, Set<int>>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Set<int>>{};
      final Map<String, Set<int>> result = {};
      bool changed = false;
      for (final entry in decoded.entries) {
        final rawSet = Set<int>.from(
          (entry.value as List<dynamic>? ?? const <int>[]).map(
            (e) => (e as num).toInt(),
          ),
        );
        final normalized = _normalizeBadgeSet(rawSet);
        result[entry.key as String] = normalized;
        if (!setEquals(rawSet, normalized)) {
          changed = true;
        }
      }
      if (changed) {
        _seenRitualBadges = result;
        unawaited(_persistSeenRitualBadges());
      }
      return result;
    } catch (e, s) {
      _logger.warning("Failed to decode ritual badge prefs", e, s);
      return <String, Set<int>>{};
    }
  }

  Future<void> _persistSeenRitualBadges() async {
    final encoded = _seenRitualBadges.map(
      (key, value) => MapEntry(key, value.toList()),
    );
    await _preferences.setString(
      _ritualBadgesPrefsKey,
      jsonEncode(encoded),
    );
  }

  RitualBadgeUnlock? _resolvePendingBadge(
    List<Ritual> rituals,
    Map<String, RitualProgress> ritualProgress,
  ) {
    _seedSeenBadgesForNewRituals(ritualProgress);
    RitualBadgeUnlock? unlock;
    for (final ritual in rituals) {
      final longest = ritualProgress[ritual.id]?.longestStreakOverall ?? 0;
      final seen = _seenRitualBadges[ritual.id] ?? <int>{};
      final newlyUnlocked = _badgeThresholds
          .where((t) => longest >= t && !seen.contains(t))
          .toList();
      if (newlyUnlocked.isEmpty) continue;
      final highest = newlyUnlocked.reduce(max);
      if (unlock == null || highest > unlock.days) {
        unlock = RitualBadgeUnlock(
          ritual: ritual,
          days: highest,
          generatedAt: DateTime.now(),
        );
      }
    }
    return unlock;
  }

  Future<void> markRitualBadgeSeen(String ritualId, int days) async {
    final seen = _seenRitualBadges[ritualId] ?? <int>{};
    final thresholdsToMark =
        _badgeThresholds.where((threshold) => threshold <= days);
    final updated = _normalizeBadgeSet({...seen, ...thresholdsToMark});
    if (!setEquals(updated, seen)) {
      _seenRitualBadges[ritualId] = updated;
      await _persistSeenRitualBadges();
    }
    final state = stateNotifier.value;
    final pending = state.pendingBadge;
    if (pending != null &&
        pending.ritual.id == ritualId &&
        pending.days == days) {
      stateNotifier.value = state.copyWith(
        pendingBadge: null,
      );
    }
  }

  int _currentScheduledStreakFromDayKeys(
    Set<int> dayKeys,
    List<bool> daysOfWeek, {
    required DateTime todayMidnight,
  }) {
    if (dayKeys.isEmpty) return 0;
    if (!_hasAnyEnabledRitualDays(daysOfWeek)) return 0;

    final start = _streakStartDateFromDayKeys(dayKeys, todayMidnight);
    int current = 0;
    for (var day = todayMidnight; !day.isBefore(start); day = _prevDay(day)) {
      final dayIndex = day.weekday % 7; // Sunday -> 0
      if (!daysOfWeek[dayIndex]) continue;

      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      if (dayKeys.contains(key)) {
        current += 1;
      } else {
        break;
      }
    }
    return current;
  }

  int _longestScheduledStreakFromDayKeys(
    Set<int> dayKeys,
    List<bool> daysOfWeek, {
    required DateTime todayMidnight,
  }) {
    if (dayKeys.isEmpty) return 0;
    if (!_hasAnyEnabledRitualDays(daysOfWeek)) return 0;

    final start = _streakStartDateFromDayKeys(dayKeys, todayMidnight);
    int longest = 0;
    int rolling = 0;
    for (var day = start; !day.isAfter(todayMidnight); day = _nextDay(day)) {
      final dayIndex = day.weekday % 7; // Sunday -> 0
      if (!daysOfWeek[dayIndex]) continue;

      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      if (dayKeys.contains(key)) {
        rolling += 1;
        longest = max(longest, rolling);
      } else {
        rolling = 0;
      }
    }
    return longest;
  }

  int _longestScheduledStreakInRangeFromDayKeys(
    Set<int> dayKeys,
    List<bool> daysOfWeek, {
    required DateTime startDay,
    required DateTime endDayInclusive,
  }) {
    if (dayKeys.isEmpty) return 0;
    if (!_hasAnyEnabledRitualDays(daysOfWeek)) return 0;
    if (endDayInclusive.isBefore(startDay)) return 0;

    int longest = 0;
    int rolling = 0;
    for (var day = startDay;
        !day.isAfter(endDayInclusive);
        day = _nextDay(day)) {
      final dayIndex = day.weekday % 7; // Sunday -> 0
      if (!daysOfWeek[dayIndex]) continue;

      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      if (dayKeys.contains(key)) {
        rolling += 1;
        longest = max(longest, rolling);
      } else {
        rolling = 0;
      }
    }
    return longest;
  }

  DateTime _streakStartDateFromDayKeys(
    Set<int> dayKeys,
    DateTime todayMidnight,
  ) {
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

  void _seedSeenBadgesForNewRituals(
    Map<String, RitualProgress> ritualProgress,
  ) {
    if (_recentlyAddedRitualIds.isEmpty) return;
    bool changed = false;
    for (final ritualId in _recentlyAddedRitualIds) {
      final longest = ritualProgress[ritualId]?.longestStreakOverall ?? 0;
      if (longest <= 0) continue;
      final thresholds =
          _badgeThresholds.where((threshold) => longest >= threshold);
      if (thresholds.isEmpty) continue;
      final seen = _seenRitualBadges[ritualId] ?? <int>{};
      final updated = _normalizeBadgeSet({...seen, ...thresholds});
      if (!setEquals(updated, seen)) {
        _seenRitualBadges[ritualId] = updated;
        changed = true;
      }
    }
    _recentlyAddedRitualIds.clear();
    if (changed) {
      unawaited(_persistSeenRitualBadges());
    }
  }

  Ritual createEmptyRitual() {
    return Ritual(
      id: newID("ritual"),
      title: "",
      daysOfWeek: List<bool>.filled(7, true),
      timeOfDay: const TimeOfDay(hour: 9, minute: 0),
      albumId: null,
      albumName: null,
      icon: "📸",
      createdAt: DateTime.now(),
    );
  }
}
