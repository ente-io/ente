import "dart:async";
import "dart:convert";
import "dart:math";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/base/id.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/notification_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class ActivityService {
  static final ActivityService instance = ActivityService._privateConstructor();

  ActivityService._privateConstructor();

  static const _notificationLookaheadDays = 60;
  static const _maxScheduledNotificationsPerRitual = 30;
  final Logger _logger = Logger("ActivityService");
  final ValueNotifier<ActivityState> stateNotifier =
      ValueNotifier<ActivityState>(ActivityState.loading());
  late SharedPreferences _preferences;
  Timer? _debounce;
  StreamSubscription<FilesUpdatedEvent>? _filesUpdatedSubscription;

  static const _ritualsPrefsKey = "activity_rituals_v1";
  static const _badgeThresholds = [7, 14, 30];

  Future<void> init() async {
    _preferences = ServiceLocator.instance.prefs;
    if (!flagService.ritualsFlag) {
      stateNotifier.value = const ActivityState(
        loading: false,
        summary: null,
        rituals: [],
        error: null,
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
      stateNotifier.value = const ActivityState(
        loading: false,
        summary: null,
        rituals: [],
        error: null,
      );
      return;
    }
    try {
      stateNotifier.value = stateNotifier.value.copyWith(
        loading: true,
        error: null,
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
      stateNotifier.value = ActivityState(
        loading: false,
        summary: summary,
        rituals: rituals,
        error: null,
      );
    } catch (e, s) {
      _logger.severe("Failed to refresh activity", e, s);
      stateNotifier.value = stateNotifier.value.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<ActivitySummary> _buildSummary(List<Ritual> rituals) async {
    final userId = Configuration.instance.getUserID();
    if (userId == null) {
      return ActivitySummary(
        last365Days: _emptyDays(),
        last7Days: _emptyDays().sublist(_emptyDays().length - 7),
        currentStreak: 0,
        longestStreak: 0,
        badgesUnlocked: _badgeStates(0),
        ritualProgress: {},
        generatedAt: DateTime.now(),
      );
    }
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final cutoffDate = todayMidnight.subtract(const Duration(days: 371));
    final endOfToday = todayMidnight.add(
      const Duration(
        hours: 23,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
      ),
    );
    final startMicros = cutoffDate.microsecondsSinceEpoch;
    final endMicros = endOfToday.microsecondsSinceEpoch;
    final durations = <List<int>>[
      [startMicros, endMicros + 1],
    ];
    final files = await FilesDB.instance.getFilesCreatedWithinDurations(
      durations,
      <int>{},
      order: 'ASC',
    );

    final Set<int> dayKeys = <int>{};
    final Map<int, Set<int>> collectionActivity = {};

    for (final EnteFile file in files) {
      final bool ownerMatches =
          file.ownerID == null ? true : file.ownerID == userId;
      final bool uploaded =
          file.uploadedFileID != null && file.uploadedFileID != -1;
      if (!(ownerMatches && uploaded)) {
        continue;
      }
      if (file.creationTime == null) continue;
      final date =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!).toLocal();
      final bucket = DateTime(date.year, date.month, date.day);
      final dayKey = bucket.millisecondsSinceEpoch;
      if (bucket.isBefore(cutoffDate) || bucket.isAfter(todayMidnight)) {
        continue;
      }
      dayKeys.add(dayKey);
      if (file.collectionID != null && file.collectionID! > 0) {
        collectionActivity
            .putIfAbsent(file.collectionID!, () => <int>{})
            .add(dayKey);
      }
    }

    final List<ActivityDay> last365Days = List.generate(372, (index) {
      final day = cutoffDate.add(Duration(days: index));
      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      return ActivityDay(date: day, hasActivity: dayKeys.contains(key));
    });
    final List<ActivityDay> last7Days =
        last365Days.sublist(last365Days.length - 7);

    int longestStreak = 0;
    int rolling = 0;
    for (final day in last365Days) {
      if (day.hasActivity) {
        rolling += 1;
        longestStreak = max(longestStreak, rolling);
      } else {
        rolling = 0;
      }
    }
    int currentStreak = 0;
    for (int i = last365Days.length - 1; i >= 0; i--) {
      if (last365Days[i].hasActivity) {
        currentStreak += 1;
      } else {
        break;
      }
    }

    final ritualProgress = <String, RitualProgress>{};
    for (final ritual in rituals) {
      if (ritual.albumId == null) continue;
      final dates = collectionActivity[ritual.albumId] ?? <int>{};
      ritualProgress[ritual.id] = RitualProgress(
        ritualId: ritual.id,
        completedDays: dates
            .map((millis) => DateTime.fromMillisecondsSinceEpoch(millis))
            .toSet(),
      );
    }

    return ActivitySummary(
      last365Days: last365Days,
      last7Days: last7Days,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      badgesUnlocked: _badgeStates(longestStreak),
      ritualProgress: ritualProgress,
      generatedAt: DateTime.now(),
    );
  }

  List<ActivityDay> _emptyDays() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final cutoffDate = todayMidnight.subtract(const Duration(days: 371));
    return List.generate(
      372,
      (index) => ActivityDay(
        date: cutoffDate.add(Duration(days: index)),
        hasActivity: false,
      ),
    );
  }

  Map<int, bool> _badgeStates(int streak) {
    return {
      for (final t in _badgeThresholds) t: streak >= t,
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
    await _persistRituals(rituals);
    unawaited(_scheduleRitualNotifications(ritual));

    if (isNew || albumChanged) {
      await refresh();
    } else {
      // No activity data changes; just update rituals in state.
      stateNotifier.value = stateNotifier.value.copyWith(
        rituals: rituals,
        loading: false,
        error: null,
      );
    }
  }

  Future<void> deleteRitual(String id) async {
    final rituals = await _loadRituals();
    rituals.removeWhere((r) => r.id == id);
    await _persistRituals(rituals);
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
        message: "Take a photo now",
        id: baseId + scheduled,
        channelID: "ritual_reminders",
        channelName: "Rituals",
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
