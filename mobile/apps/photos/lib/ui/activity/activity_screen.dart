import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: _Heatmap(days: last365),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<ActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final dayHeader = ["S", "M", "T", "W", "Th", "F", "Sa"];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final firstDay = todayMidnight.subtract(const Duration(days: 364));

    final normalizedDayMap = <int, ActivityDay>{
      for (final d in days)
        DateTime(d.date.year, d.date.month, d.date.day)
            .millisecondsSinceEpoch: d,
    };

    final int startOffset = firstDay.weekday % 7; // days since previous Sunday
    final DateTime gridStart =
        firstDay.subtract(Duration(days: startOffset)); // Sunday-aligned
    final int totalDays =
        todayMidnight.difference(gridStart).inDays + 1; // inclusive of today

    final List<ActivityDay?> gridDays = List.generate(totalDays, (index) {
      final date = gridStart.add(Duration(days: index));
      if (date.isBefore(firstDay)) {
        return null; // top padding
      }
      final key = DateTime(date.year, date.month, date.day)
          .millisecondsSinceEpoch;
      return normalizedDayMap[key] ??
          ActivityDay(
            date: date,
            hasActivity: false,
          );
    });

    final weeks = <List<ActivityDay?>>[];
    for (int i = 0; i < gridDays.length; i += 7) {
      final slice = gridDays.skip(i).take(7).toList();
      while (slice.length < 7) {
        slice.add(null); // pad last row to full width
      }
      weeks.add(slice);
    }

    final monthLabels = <int, String>{};
    final seenMonths = <String>{};

    for (final day in gridDays.whereType<ActivityDay>()) {
      if (day.date.day != 1) continue;
      final daysSinceStart = day.date.difference(gridStart).inDays;
      final rowIndex = daysSinceStart ~/ 7;
      final key = _monthKey(day.date);
      if (seenMonths.contains(key)) continue;
      monthLabels[rowIndex] = _monthLabel(day.date.month);
      seenMonths.add(key);
    }

    if (monthLabels.isEmpty) {
      final rowIndex = firstDay.difference(gridStart).inDays ~/ 7;
      monthLabels[rowIndex] = _monthLabel(firstDay.month);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double monthLabelWidth = 32;
        const double gapX = 4;
        const double gapY = 3;
        const double cellWidth = 38.31;
        const double cellHeight = 9.82;
        final double totalCellsWidth =
            (dayHeader.length * cellWidth) + ((dayHeader.length - 1) * gapX);
        final double totalWidth = monthLabelWidth + gapX + totalCellsWidth;
        final BorderRadius pillRadius = BorderRadius.circular(cellHeight);
        const TextStyle headerStyle = TextStyle(
          color: Color(0x36000000),
          fontSize: 6.834,
          fontWeight: FontWeight.w600,
          height: 2.45,
          fontFamily: "Inter",
          decoration: TextDecoration.none,
        );

        final List<Widget> dayHeaderRow = [];
        for (int i = 0; i < dayHeader.length; i++) {
          dayHeaderRow.add(
            SizedBox(
              width: cellWidth,
              height: 16,
              child: Center(
                child: Text(
                  dayHeader[i],
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
          if (i != dayHeader.length - 1) {
            dayHeaderRow.add(const SizedBox(width: gapX));
          }
        }

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: totalWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ...weeks.asMap().entries.map(
                      (entry) {
                        final isLast = entry.key == weeks.length - 1;
                        return SizedBox(
                          height: cellHeight + (isLast ? 0 : gapY),
                          width: monthLabelWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              monthLabels[entry.key] ?? "",
                              style: headerStyle.copyWith(
                                fontSize: 8.542,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: gapX),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: dayHeaderRow),
                    const SizedBox(height: 4),
                    ...weeks.asMap().entries.map(
                      (entry) {
                        final isLast = entry.key == weeks.length - 1;
                        final week = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : gapY),
                          child: Row(
                            children: week.asMap().entries.map((cell) {
                              final isLastCell =
                                  cell.key == dayHeader.length - 1;
                              final color = cell.value == null
                                  ? Colors.transparent
                                  : cell.value!.hasActivity
                                      ? const Color(0xFF1DB954)
                                      : const Color(0xFF1DB954).withOpacity(
                                          0.25,
                                        );
                              return Row(
                                children: [
                                  Container(
                                    width: cellWidth,
                                    height: cellHeight,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: pillRadius,
                                    ),
                                  ),
                                  if (!isLastCell)
                                    const SizedBox(width: gapX),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  String _monthKey(DateTime date) => "${date.year}-${date.month}";
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
