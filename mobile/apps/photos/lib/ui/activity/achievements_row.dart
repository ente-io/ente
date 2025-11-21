import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";

class AchievementsRow extends StatelessWidget {
  const AchievementsRow({required this.summary, super.key});

  final ActivitySummary? summary;

  @override
  Widget build(BuildContext context) {
    final badges = summary?.badgesUnlocked ??
        {
          7: false,
          14: false,
          30: false,
          90: false,
          180: false,
          365: false,
        };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Achievements",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: badges.entries
                  .map(
                    (entry) => _BadgePill(
                      label: "${entry.key}d",
                      unlocked: entry.value,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? const Color(0xFF1DB954) : Colors.grey.shade300;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: const Text("🏅", style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: unlocked ? Colors.black : Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
