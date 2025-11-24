import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/activity/achievements_row.dart";
import "package:photos/ui/activity/activity_heatmap_card.dart";
import "package:photos/ui/activity/rituals_section.dart";

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, this.ritual});

  final Ritual? ritual;

  @override
  Widget build(BuildContext context) {
    final ritualTitle =
        ritual == null ? null : (ritual!.title.isEmpty ? "Ritual" : ritual!.title);
    final String titleText =
        ritualTitle == null ? "Rituals" : "$ritualTitle activity";
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        centerTitle: false,
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 12),
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await showRitualEditor(context, ritual: null);
            },
            tooltip: "Add ritual",
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<ActivityState>(
          valueListenable: activityService.stateNotifier,
          builder: (context, state, _) {
            final summary = state.summary;
            final displaySummary = summary != null && ritual != null
                ? _summaryForRitual(summary, ritual!)
                : summary;
            final iconColor = Theme.of(context).iconTheme.color;
            return RefreshIndicator(
              onRefresh: activityService.refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  RitualsSection(
                    rituals: state.rituals,
                    progress: summary?.ritualProgress ?? const {},
                    showHeader: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Text(
                            "Activity",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {},
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.share_outlined,
                                  size: 22,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (ritual != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        "Showing activity for ${ritualTitle ?? "Ritual"}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ActivityHeatmapCard(summary: displaySummary),
                  AchievementsRow(summary: displaySummary),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ActivitySummary _summaryForRitual(
    ActivitySummary summary,
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
          (day) => ActivityDay(
            date: day.date,
            hasActivity: dayKeys.contains(
              DateTime(day.date.year, day.date.month, day.date.day)
                  .millisecondsSinceEpoch,
            ),
          ),
        )
        .toList();
    final last7Days = last365Days.length >= 7
        ? last365Days.sublist(last365Days.length - 7)
        : List<ActivityDay>.from(last365Days);

    int longestStreak = 0;
    int rolling = 0;
    for (final day in last365Days) {
      if (day.hasActivity) {
        rolling += 1;
        if (rolling > longestStreak) {
          longestStreak = rolling;
        }
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

    final unlockedBadges = <int, bool>{
      for (final entry in summary.badgesUnlocked.keys)
        entry: longestStreak >= entry,
    };

    return ActivitySummary(
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
    );
  }
}
