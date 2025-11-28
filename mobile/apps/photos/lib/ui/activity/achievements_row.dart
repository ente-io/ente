import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";

class AchievementsRow extends StatelessWidget {
  const AchievementsRow({required this.summary, super.key});

  final ActivitySummary? summary;

  static const Map<int, String> _badgeAssets = {
    7: "assets/rituals/7_badge.png",
    14: "assets/rituals/14_badge.png",
    30: "assets/rituals/30_badge.png",
  };

  @override
  Widget build(BuildContext context) {
    final badges = summary?.badgesUnlocked ?? const <int, bool>{};
    final unlocked = badges.entries
        .where((entry) => entry.value && _badgeAssets.containsKey(entry.key))
        .map((entry) => entry.key)
        .toList();

    if (unlocked.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Streaks",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: unlocked
                  .map((days) => _BadgeTile(days: days))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final asset = AchievementsRow._badgeAssets[days];
    if (asset == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Image.asset(
        asset,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
      ),
    );
  }
}
