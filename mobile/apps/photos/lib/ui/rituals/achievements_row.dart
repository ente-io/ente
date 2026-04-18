import "package:flutter/material.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/rituals/ritual_models.dart";

class AchievementsRow extends StatelessWidget {
  const AchievementsRow({
    required this.progress,
    this.onBadgeTap,
    super.key,
  });

  final RitualProgress? progress;
  final void Function(int days)? onBadgeTap;

  static const Map<int, String> _badgeAssets = {
    7: "assets/rituals/7_badge.png",
    14: "assets/rituals/14_badge.png",
    30: "assets/rituals/30_badge.png",
  };

  @override
  Widget build(BuildContext context) {
    final longest = progress?.longestStreakOverall ?? 0;
    final unlocked =
        _badgeAssets.keys.where((days) => longest >= days).toList();

    if (unlocked.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ritualStreaksLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: unlocked
                  .map(
                    (days) => _BadgeTile(
                      days: days,
                      onTap:
                          onBadgeTap != null ? () => onBadgeTap!(days) : null,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final asset = AchievementsRow._badgeAssets[days];
    if (asset == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Image.asset(
          asset,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
