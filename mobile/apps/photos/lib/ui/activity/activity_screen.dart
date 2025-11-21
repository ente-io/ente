import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/activity/activity_banner.dart";
import "package:photos/ui/notification/toast.dart";

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photos taken"),
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
                  const ActivityBanner(),
                  _ActivityHeatmapCard(summary: summary),
                  _AchievementsRow(summary: summary),
                  _RitualsSection(
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

class _ActivityHeatmapCard extends StatelessWidget {
  const _ActivityHeatmapCard({required this.summary});

  final ActivitySummary? summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final last365 = summary?.last365Days ??
        List.generate(
          365,
          (i) => ActivityDay(
            date: DateTime.now().subtract(Duration(days: 364 - i)),
            hasActivity: false,
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Past year",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (summary != null)
                  Text(
                    "${summary!.currentStreak}d streak",
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colorScheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Heatmap(days: last365),
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<ActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final dayHeader = ["S", "M", "T", "W", "T", "F", "S"];
    final weeks = <List<ActivityDay>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.skip(i).take(7).toList());
    }

    final monthLabels = <int, String>{};
    for (final day in days) {
      if (day.date.day == 1) {
        monthLabels[weeks.indexWhere(
          (week) => week.any(
            (d) =>
                d.date.year == day.date.year &&
                d.date.month == day.date.month &&
                d.date.day == day.date.day,
          ),
        )] = _monthLabel(day.date.month);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              ...weeks.asMap().entries.map(
                    (entry) => SizedBox(
                      height: 16,
                      width: 28,
                      child: Center(
                        child: Text(
                          monthLabels[entry.key] ?? "",
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.black
                                        .withAlpha((0.25 * 255).round()),
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: dayHeader
                    .map(
                      (d) => SizedBox(
                        width: 18,
                        child: Center(
                          child: Text(
                            d,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.black
                                      .withAlpha((0.25 * 255).round()),
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              ...weeks.map(
                (week) => Row(
                  children: week
                      .map(
                        (day) => Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 1,
                          ),
                          width: 18,
                          height: 12,
                          decoration: BoxDecoration(
                            color: day.hasActivity
                                ? const Color(0xFF1DB954)
                                : const Color(0xFFDFF3E4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthLabel(int month) {
    const labels = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return labels[month - 1];
  }
}

class _AchievementsRow extends StatelessWidget {
  const _AchievementsRow({required this.summary});

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

class _RitualsSection extends StatelessWidget {
  const _RitualsSection({
    required this.rituals,
    required this.progress,
  });

  final List<Ritual> rituals;
  final Map<String, RitualProgress> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Activity",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await _showRitualEditor(context, ritual: null);
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rituals.isEmpty)
            Text(
              "Create a ritual to get daily reminders.",
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: rituals
                  .map(
                    (ritual) => _RitualCard(
                      ritual: ritual,
                      completedToday:
                          progress[ritual.id]?.hasCompleted(DateTime.now()) ??
                              false,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.ritual,
    required this.completedToday,
  });

  final Ritual ritual;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Text(
            ritual.icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(ritual.title.isEmpty ? "Untitled ritual" : ritual.title),
        subtitle: Text(
          [
            _daysLabel(ritual.daysOfWeek),
            if (ritual.albumName != null) ritual.albumName!,
          ].join(" • "),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (completedToday)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1DB954),
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case "edit":
                    await _showRitualEditor(context, ritual: ritual);
                    break;
                  case "delete":
                    await activityService.deleteRitual(ritual.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: "edit", child: Text("Edit")),
                const PopupMenuItem(
                  value: "delete",
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysLabel(List<bool> days) {
    const labels = ["S", "M", "T", "W", "T", "F", "S"];
    final selected = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) selected.add(labels[i]);
    }
    if (selected.length == 7) return "Every day";
    return selected.join(" ");
  }
}

Future<void> _showRitualEditor(BuildContext context, {Ritual? ritual}) async {
  final controller = TextEditingController(text: ritual?.title ?? "");
  final days = [...(ritual?.daysOfWeek ?? List<bool>.filled(7, true))];
  final selectedAlbumName = ValueNotifier<String?>(ritual?.albumName);
  int? selectedAlbumId = ritual?.albumId;
  TimeOfDay selectedTime =
      ritual?.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
  final String icon = ritual?.icon ?? "📸";
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        ritual == null ? "New ritual" : "Edit ritual",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Description",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter a description";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Days"),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: List.generate(
                            days.length,
                            (index) => ChoiceChip(
                              label: Text(_weekLabel(index)),
                              selected: days[index],
                              onSelected: (value) {
                                setState(() {
                                  days[index] = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Time"),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (result != null) {
                            setState(() {
                              selectedTime = result;
                            });
                          }
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          selectedTime.format(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String?>(
                    valueListenable: selectedAlbumName,
                    builder: (context, value, _) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Album"),
                        subtitle: Text(value ?? "Select album"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await _pickAlbum(context);
                          if (result != null) {
                            selectedAlbumId = result.id;
                            selectedAlbumName.value = result.displayName;
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedAlbumId == null) {
                          showToast(context, "Please select an album");
                          return;
                        }
                        final updated =
                            (ritual ?? activityService.createEmptyRitual())
                                .copyWith(
                          title: controller.text.trim(),
                          daysOfWeek: days,
                          timeOfDay: selectedTime,
                          albumId: selectedAlbumId,
                          albumName: selectedAlbumName.value,
                          icon: icon,
                        );
                        await activityService.saveRitual(updated);
                        Navigator.of(context).pop();
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _weekLabel(int index) {
  const labels = ["S", "M", "T", "W", "T", "F", "S"];
  return labels[index];
}

Future<Collection?> _pickAlbum(BuildContext context) async {
  final service = CollectionsService.instance;
  final albums = await service.getCollectionForWidgetSelection();
  Collection? selected;
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text("Select album"),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: "Create new album",
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) return;
                    final created = await service.createAlbum(value.trim());
                    albums.insert(0, created);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        title: Text(album.displayName),
                        onTap: () {
                          selected = album;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return selected;
}
