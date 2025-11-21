import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/activity/achievements_row.dart";
import "package:photos/ui/activity/activity_heatmap_card.dart";
import "package:photos/ui/activity/rituals_section.dart";

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity"),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {},
            tooltip: "Share (coming soon)",
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<ActivityState>(
          valueListenable: activityService.stateNotifier,
          builder: (context, state, _) {
            final summary = state.summary;
            return RefreshIndicator(
              onRefresh: activityService.refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  ActivityHeatmapCard(summary: summary),
                  AchievementsRow(summary: summary),
                  RitualsSection(
                    rituals: state.rituals,
                    progress: summary?.ritualProgress ?? const {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
