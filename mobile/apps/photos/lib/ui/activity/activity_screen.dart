import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/column_item.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

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
          372,
          (i) => ActivityDay(
            date: DateTime.now().subtract(Duration(days: 371 - i)),
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
    final renderDays =
        days.length > 365 ? days.sublist(days.length - 365) : days;
    final dayHeader = ["S", "M", "T", "W", "Th", "F", "Sa"];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final DateTime firstDay = renderDays.isNotEmpty
        ? DateTime(
            renderDays.first.date.year,
            renderDays.first.date.month,
            renderDays.first.date.day,
          )
        : todayMidnight.subtract(const Duration(days: 364));

    final normalizedDayMap = <int, ActivityDay>{
      for (final d in days)
        DateTime(d.date.year, d.date.month, d.date.day).millisecondsSinceEpoch:
            d,
    };

    // Always start on the Sunday before/including the first day to render
    final int startOffset = firstDay.weekday % 7;
    final DateTime gridStart =
        firstDay.subtract(Duration(days: startOffset)); // Sunday-aligned
    // End exactly on today; last row can be partial
    final DateTime gridEnd = todayMidnight;
    final int totalDays =
        gridEnd.difference(gridStart).inDays + 1; // inclusive of gridEnd

    final List<ActivityDay?> gridDays = List.generate(totalDays, (index) {
      final date = gridStart.add(Duration(days: index));
      // Leading days before the 365-day window can still be active if present
      // in the extended map (we fetched extra days), otherwise remain empty.
      final key =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final activity = normalizedDayMap[key];
      if (date.isBefore(firstDay)) {
        return activity ??
            ActivityDay(
              date: date,
              hasActivity: false,
            );
      }
      return activity ??
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
                    const SizedBox(height: 8),
                    ...weeks.asMap().entries.map((entry) {
                      final isLast = entry.key == weeks.length - 1;
                      return SizedBox(
                        height: cellHeight + (isLast ? 0 : gapY),
                        width: monthLabelWidth,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              monthLabels[entry.key] ?? "",
                              style: headerStyle.copyWith(
                                fontSize: 8.542,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
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
                                      : const Color(0xFF1DB954).withValues(
                                          alpha: 0.25,
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
                                  if (!isLastCell) const SizedBox(width: gapX),
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
  });

  final Ritual ritual;

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
        subtitle: ritual.albumName == null || ritual.albumName!.isEmpty
            ? Text(
                "Album not set",
                style: getEnteTextTheme(context).smallMuted,
              )
            : Text(
                ritual.albumName!,
                style: getEnteTextTheme(context).smallMuted,
              ),
        trailing: PopupMenuButton<String>(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color.fromRGBO(0, 0, 0, 0.09),
              width: 0.5,
            ),
          ),
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
            const PopupMenuItem(
              value: "edit",
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
                        SizedBox(width: 10),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Color.fromRGBO(0, 0, 0, 0.09),
                    indent: 0,
                    endIndent: 0,
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: "delete",
              padding: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showRitualEditor(BuildContext context, {Ritual? ritual}) async {
  final controller = TextEditingController(text: ritual?.title ?? "");
  final days = [...(ritual?.daysOfWeek ?? List<bool>.filled(7, true))];
  Collection? selectedAlbum = ritual?.albumId != null
      ? CollectionsService.instance.getCollectionByID(ritual!.albumId!)
      : null;
  String? selectedAlbumName = selectedAlbum?.displayName ?? ritual?.albumName;
  int? selectedAlbumId = selectedAlbum?.id ?? ritual?.albumId;
  TimeOfDay selectedTime =
      ritual?.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
  String selectedEmoji = ritual?.icon ?? "📸";
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final colorScheme = getEnteColorScheme(context);
      final textTheme = getEnteTextTheme(context);
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 12,
                right: 12,
                top: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.backgroundElevated,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ritual == null ? "New ritual" : "Edit ritual",
                              style: textTheme.largeBold,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: colorScheme.fillFaintPressed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      selectedEmoji,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Material(
                                    color: colorScheme.backgroundElevated,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () async {
                                        final emoji = await _pickEmoji(
                                          context,
                                          selectedEmoji,
                                        );
                                        if (emoji != null) {
                                          setState(() {
                                            selectedEmoji = emoji;
                                          });
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: "Enter your task",
                                  filled: true,
                                  fillColor: colorScheme.fillFaint,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: colorScheme.strokeFaint,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: colorScheme.strokeFaint,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter a description";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(context, "Day"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.fillFaint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              days.length,
                              (index) => _DayCircle(
                                label: _weekLabel(index),
                                selected: days[index],
                                colorScheme: colorScheme,
                                onTap: () {
                                  setState(() {
                                    days[index] = !days[index];
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(context, "Time"),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.fillFaint,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colorScheme.strokeFaint,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedTime.format(context),
                                    style: textTheme.h3Bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.backgroundElevated2,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.schedule,
                                    color: colorScheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(context, "Album"),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final result = await _pickAlbum(context);
                            if (result != null) {
                              setState(() {
                                selectedAlbum = result;
                                selectedAlbumId = result.id;
                                selectedAlbumName = result.displayName;
                              });
                            }
                          },
                          child: _AlbumPreviewTile(
                            album: selectedAlbum,
                            fallbackName: selectedAlbumName,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary500,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              if (selectedAlbumId == null) {
                                showToast(context, "Please select an album");
                                return;
                              }
                              final updated = (ritual ??
                                      activityService.createEmptyRitual())
                                  .copyWith(
                                title: controller.text.trim(),
                                daysOfWeek: days,
                                timeOfDay: selectedTime,
                                albumId: selectedAlbumId,
                                albumName: selectedAlbumName,
                                icon: selectedEmoji,
                              );
                              await activityService.saveRitual(updated);
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              ritual == null ? "Save ritual" : "Update ritual",
                              style: textTheme.bodyBold
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final albums =
      List<Collection>.from(await service.getCollectionForWidgetSelection());
  Collection? selected;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colorScheme = getEnteColorScheme(context);
      final textTheme = getEnteTextTheme(context);
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.backgroundElevated,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                      child: Row(
                        children: [
                          Text(
                            "Select album",
                            style: textTheme.bodyBold,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Create new album",
                          prefixIcon: const Icon(Icons.add_rounded),
                          filled: true,
                          fillColor: colorScheme.fillFaint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.strokeFaint,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colorScheme.strokeFaint,
                            ),
                          ),
                        ),
                        onSubmitted: (value) async {
                          final trimmed = value.trim();
                          if (trimmed.isEmpty) return;
                          final created = await service.createAlbum(trimmed);
                          controller.clear();
                          albums.insert(0, created);
                          setState(() {});
                        },
                      ),
                    ),
                    Flexible(
                      child: SizedBox(
                        height: 360,
                        child: albums.isEmpty
                            ? Center(
                                child: Text(
                                  "No albums yet",
                                  style: textTheme.small
                                      .copyWith(color: colorScheme.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemBuilder: (context, index) {
                                  final album = albums[index];
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      selected = album;
                                      Navigator.of(context).pop();
                                    },
                                    child: AlbumColumnItemWidget(
                                      album,
                                      selectedCollections: selected == album
                                          ? <Collection>[album]
                                          : const <Collection>[],
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemCount: albums.length,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  return selected;
}

class _AlbumPreviewTile extends StatelessWidget {
  const _AlbumPreviewTile({required this.album, required this.fallbackName});

  final Collection? album;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.strokeFaint),
      ),
      child: Row(
        children: [
          _AlbumThumbnail(album: album),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Album",
                  style: textTheme.miniMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  album?.displayName ?? fallbackName ?? "Select album",
                  style: textTheme.smallBold,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.textMuted,
          ),
        ],
      ),
    );
  }
}

class _AlbumThumbnail extends StatelessWidget {
  const _AlbumThumbnail({required this.album});

  final Collection? album;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    if (album == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.fillFaintPressed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.photo_album_outlined,
          color: colorScheme.textMuted,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        height: 60,
        child: FutureBuilder<EnteFile?>(
          future: CollectionsService.instance.getCover(album!),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ThumbnailWidget(
                snapshot.data!,
                showFavForAlbumOnly: true,
                shouldShowOwnerAvatar: false,
              );
            }
            return Container(
              color: colorScheme.fillFaintPressed,
            );
          },
        ),
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final EnteColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary500 : colorScheme.fillFaintPressed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary500.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colorScheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String label) {
  final textTheme = getEnteTextTheme(context);
  final colorScheme = getEnteColorScheme(context);
  return Text(
    label,
    style: textTheme.smallBold.copyWith(color: colorScheme.textMuted),
  );
}

Future<String?> _pickEmoji(BuildContext context, String current) async {
  const emojiOptions = [
    "📸",
    "😊",
    "🌿",
    "☕️",
    "🌅",
    "🏃",
    "🧘",
    "📚",
    "🎧",
    "🍳",
    "🎨",
    "🥾",
    "🌙",
    "📝",
    "🧠",
    "🧹",
    "🌻",
    "🧩",
  ];
  String? selected;
  final colorScheme = getEnteColorScheme(context);
  await showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.backgroundElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pick an emoji",
                style: getEnteTextTheme(context).bodyBold,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 6,
                childAspectRatio: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: emojiOptions.map((emoji) {
                  final isActive = emoji == current;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      selected = emoji;
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary500.withValues(alpha: 0.1)
                            : colorScheme.fillFaint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? colorScheme.primary500
                              : colorScheme.strokeFaint,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Use keyboard emoji"),
              ),
            ],
          ),
        ),
      );
    },
  );
  return selected;
}
