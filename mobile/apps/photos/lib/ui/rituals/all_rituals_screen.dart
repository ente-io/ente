import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/rituals/delete_ritual_confirmation_sheet.dart";
import "package:photos/ui/rituals/ritual_camera_page.dart";
import "package:photos/ui/rituals/ritual_day_thumbnail.dart";
import "package:photos/ui/rituals/ritual_editor_dialog.dart";
import "package:photos/ui/rituals/ritual_emoji_icon.dart";
import "package:photos/ui/rituals/ritual_page.dart";
import "package:photos/ui/rituals/start_new_ritual_card.dart";
import "package:photos/utils/navigation_util.dart";

class AllRitualsScreen extends StatelessWidget {
  const AllRitualsScreen({super.key, this.ritual});

  // Legacy param; retained for call sites that pass it.
  final Ritual? ritual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ritualsEnabled = flagService.ritualsFlag;
    if (!ritualsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ritualsTitle), centerTitle: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Rituals are currently limited to internal users.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ritualsTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                size: 24,
                color: Colors.white,
              ),
              onPressed: () async {
                await showRitualEditor(context, ritual: null);
              },
              tooltip: l10n.ritualAddTooltip,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<RitualsState>(
          valueListenable: ritualsService.stateNotifier,
          builder: (context, state, _) {
            final rituals = state.rituals;
            final summary = state.summary;
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              children: [
                if (rituals.isEmpty)
                  StartNewRitualCard(
                    variant: StartNewRitualCardVariant.wide,
                    onTap: () async {
                      await showRitualEditor(context, ritual: null);
                    },
                  )
                else
                  ...rituals.map(
                    (ritual) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RitualOverviewCard(
                        ritual: ritual,
                        progress: summary?.ritualProgress[ritual.id],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RitualOverviewCard extends StatelessWidget {
  const _RitualOverviewCard({required this.ritual, required this.progress});

  final Ritual ritual;
  final RitualProgress? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _lastScheduledDaysInclusive(
      ritual: ritual,
      todayMidnight: today,
      count: 5,
    );
    final completions = [
      for (final day in days) progress?.hasCompleted(day) ?? false,
    ];

    return GestureDetector(
      onTap: () {
        routeToPage(
          context,
          RitualPage(ritualId: ritual.id),
        );
      },
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _RitualActionsSheet(ritual: ritual),
        );
        switch (action) {
          case "edit":
            if (!context.mounted) return;
            await showRitualEditor(context, ritual: ritual);
            break;
          case "delete":
            if (!context.mounted) return;
            final confirmed = await showDeleteRitualConfirmationSheet(context);
            if (!context.mounted || !confirmed) return;
            await ritualsService.deleteRitual(ritual.id);
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.backgroundElevated2
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.strokeFaint
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colorScheme.backgroundElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: RitualEmojiIcon(
                      ritual.icon,
                      style: textTheme.bodyBold.copyWith(height: 1),
                      textHeightBehavior: _tightTextHeightBehavior,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ritual.title.isEmpty
                        ? context.l10n.ritualUntitled
                        : ritual.title,
                    style: textTheme.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: _tightTextHeightBehavior,
                  ),
                ),
                const SizedBox(width: 8),
                _StreakChip(streak: progress?.currentStreak ?? 0),
              ],
            ),
            const SizedBox(height: 16),
            if (days.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 16.0;
                  final available =
                      constraints.maxWidth - (spacing * (days.length - 1));
                  final tileWidth = available / days.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (index, day) in days.indexed) ...[
                        if (index != 0) const SizedBox(width: spacing),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: _buildDayThumbnail(
                              context: context,
                              ritual: ritual,
                              day: day,
                              tileWidth: tileWidth,
                              completed: completions[index],
                              nextCompleted: index == days.length - 1
                                  ? null
                                  : completions[index + 1],
                              index: index,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayThumbnail({
    required BuildContext context,
    required Ritual ritual,
    required DateTime day,
    required double tileWidth,
    required bool completed,
    required bool? nextCompleted,
    required int index,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final file = progress?.recentFilesByDay[dayKey];
    final count =
        progress?.recentFileCountsByDay[dayKey] ?? (completed ? 1 : 0);
    final fadePhoto = completed && nextCompleted == false;
    final isToday = _isSameDay(day, today);
    final rotation = switch (index % 4) {
      0 => -0.05,
      1 => 0.10,
      2 => -0.08,
      _ => 0.08,
    };

    final variant = completed
        ? RitualDayThumbnailVariant.photo
        : (isToday
            ? RitualDayThumbnailVariant.camera
            : RitualDayThumbnailVariant.empty);

    return RitualDayThumbnail(
      day: day,
      variant: variant,
      width: tileWidth,
      photoFile: file,
      photoCount: count,
      fadePhoto: fadePhoto,
      rotation: rotation,
      onCameraTap: isToday && !completed
          ? () => openRitualCamera(context, ritual)
          : null,
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$streak",
            style: textTheme.small
                .copyWith(color: colorScheme.textMuted, height: 1),
            textHeightBehavior: _tightTextHeightBehavior,
          ),
          const SizedBox(width: 4),
          const Icon(
            EnteIcons.lightningFilled,
            size: 14,
            color: Color(0xFFFFBC03),
          ),
        ],
      ),
    );
  }
}

class _RitualActionsSheet extends StatelessWidget {
  const _RitualActionsSheet({required this.ritual});

  final Ritual ritual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.strokeFaint, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.l10n.edit, style: textTheme.body),
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  color: colorScheme.textBase,
                  size: 22,
                ),
                onTap: () => Navigator.of(context).pop("edit"),
              ),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: colorScheme.strokeFaint,
              ),
              ListTile(
                title: Text(
                  context.l10n.delete,
                  style: textTheme.body.copyWith(color: Colors.red),
                ),
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: Colors.red,
                  size: 22,
                ),
                onTap: () => Navigator.of(context).pop("delete"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<DateTime> _lastScheduledDaysInclusive({
  required Ritual ritual,
  required DateTime todayMidnight,
  required int count,
}) {
  final daysOfWeek = ritual.daysOfWeek;
  if (daysOfWeek.length != 7 || !daysOfWeek.any((enabled) => enabled)) {
    return const [];
  }

  final result = <DateTime>[];
  for (int offset = 0; result.length < count && offset < 366; offset++) {
    final day = todayMidnight.subtract(Duration(days: offset));
    final weekdayIndex = day.weekday % 7; // Sunday-first
    if (!daysOfWeek[weekdayIndex]) continue;
    result.add(day);
  }
  return result.reversed.toList(growable: false);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const _tightTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
