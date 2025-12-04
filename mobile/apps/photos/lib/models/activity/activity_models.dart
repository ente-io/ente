import "package:flutter/material.dart";
import "package:photos/models/base/id.dart";

class ActivityDay {
  final DateTime date;
  final bool hasActivity;

  const ActivityDay({
    required this.date,
    required this.hasActivity,
  });
}

class ActivitySummary {
  final List<ActivityDay> last365Days;
  final List<ActivityDay> last7Days;
  final int currentStreak;
  final int longestStreak;
  final Map<int, bool> badgesUnlocked;
  final Map<String, RitualProgress> ritualProgress;
  final DateTime generatedAt;
  final Map<String, int> ritualLongestStreaks;

  const ActivitySummary({
    required this.last365Days,
    required this.last7Days,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgesUnlocked,
    required this.ritualProgress,
    required this.generatedAt,
    required this.ritualLongestStreaks,
  });

  bool get hasSevenDayFire => last7Days.every((d) => d.hasActivity);
}

class Ritual {
  Ritual({
    required this.id,
    required this.title,
    required this.daysOfWeek, // Sunday-first ordering of length 7
    required this.timeOfDay,
    required this.albumId,
    required this.albumName,
    required this.icon,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<bool> daysOfWeek;
  final TimeOfDay timeOfDay;
  final int? albumId;
  final String? albumName;
  final String icon;
  final DateTime createdAt;

  Ritual copyWith({
    String? id,
    String? title,
    List<bool>? daysOfWeek,
    TimeOfDay? timeOfDay,
    int? albumId,
    String? albumName,
    String? icon,
    DateTime? createdAt,
  }) {
    return Ritual(
      id: id ?? this.id,
      title: title ?? this.title,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "daysOfWeek": daysOfWeek,
      "hour": timeOfDay.hour,
      "minute": timeOfDay.minute,
      "albumId": albumId,
      "albumName": albumName,
      "icon": icon,
      "createdAt": createdAt.millisecondsSinceEpoch,
    };
  }

  factory Ritual.fromJson(Map<String, dynamic> json) {
    return Ritual(
      id: json["id"] as String? ?? newID("ritual"),
      title: json["title"] as String? ?? "",
      daysOfWeek: List<bool>.from(
        (json["daysOfWeek"] as List<dynamic>? ?? List<bool>.filled(7, false)),
      ),
      timeOfDay: TimeOfDay(
        hour: (json["hour"] as num?)?.toInt() ?? 9,
        minute: (json["minute"] as num?)?.toInt() ?? 0,
      ),
      albumId: (json["albumId"] as num?)?.toInt(),
      albumName: json["albumName"] as String?,
      icon: json["icon"] as String? ?? "📸",
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json["createdAt"] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class RitualProgress {
  final String ritualId;
  final Set<DateTime> completedDays;

  const RitualProgress({
    required this.ritualId,
    required this.completedDays,
  });

  bool hasCompleted(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return completedDays.any(
      (d) =>
          d.year == dayKey.year &&
          d.month == dayKey.month &&
          d.day == dayKey.day,
    );
  }
}

class ActivityState {
  final bool loading;
  final ActivitySummary? summary;
  final List<Ritual> rituals;
  final String? error;
  final RitualBadgeUnlock? pendingBadge;

  const ActivityState({
    required this.loading,
    required this.summary,
    required this.rituals,
    required this.error,
    required this.pendingBadge,
  });

  factory ActivityState.loading() => const ActivityState(
        loading: true,
        summary: null,
        rituals: [],
        error: null,
        pendingBadge: null,
      );

  ActivityState copyWith({
    bool? loading,
    ActivitySummary? summary,
    List<Ritual>? rituals,
    String? error,
    RitualBadgeUnlock? pendingBadge,
  }) {
    return ActivityState(
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      rituals: rituals ?? this.rituals,
      error: error,
      pendingBadge: pendingBadge,
    );
  }
}

class RitualBadgeUnlock {
  const RitualBadgeUnlock({
    required this.ritual,
    required this.days,
    required this.generatedAt,
  });

  final Ritual ritual;
  final int days;
  final DateTime generatedAt;
}
