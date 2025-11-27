import "dart:io";
import "dart:math" as math;
import "dart:ui" as ui;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/activity/achievements_row.dart";
import "package:photos/ui/activity/activity_heatmap_card.dart";
import "package:photos/ui/activity/ritual_camera_page.dart";
import "package:photos/ui/activity/rituals_section.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";
import "package:share_plus/share_plus.dart";

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.ritual});

  final Ritual? ritual;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Ritual? _selectedRitual;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedRitual = widget.ritual;
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ritual != widget.ritual) {
      _selectedRitual = widget.ritual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final ritualsEnabled = flagService.ritualsFlag;
    if (!ritualsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Rituals"),
          centerTitle: false,
        ),
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
        title: const Text("Rituals"),
        centerTitle: false,
        actions: [
          if (_selectedRitual != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.fillFaint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: _selectedRitual != null
                    ? () => _openRitualCamera(_selectedRitual!)
                    : null,
                tooltip: "Open ritual camera",
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.fillFaint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: () async {
                await showRitualEditor(context, ritual: null);
              },
              tooltip: "Add ritual",
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<ActivityState>(
          valueListenable: activityService.stateNotifier,
          builder: (context, state, _) {
            final summary = state.summary;
            Ritual? selectedRitual = _selectedRitual;
            if (selectedRitual != null) {
              final match = state.rituals
                  .where((ritual) => ritual.id == selectedRitual!.id);
              if (match.isNotEmpty) {
                selectedRitual = match.first;
              } else {
                selectedRitual = null;
              }
            }
            final displaySummary = summary != null && selectedRitual != null
                ? _summaryForRitual(summary, selectedRitual)
                : summary;
            final summaryToShare = displaySummary;
            final iconColor = Theme.of(context).iconTheme.color;
            final String heatmapTitle = selectedRitual == null
                ? "Take a photo every day"
                : (selectedRitual.title.isEmpty
                    ? "Untitled ritual"
                    : selectedRitual.title);
            final String heatmapEmoji =
                selectedRitual?.icon ?? (selectedRitual == null ? "📸" : "");
            final String shareTitle = heatmapTitle;
            final bool shareEnabled = summaryToShare != null;
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                RitualsSection(
                  rituals: state.rituals,
                  progress: summary?.ritualProgress ?? const {},
                  showHeader: false,
                  selectedRitualId: selectedRitual?.id,
                  onSelectionChanged: (ritual) {
                    setState(() {
                      _selectedRitual = ritual;
                    });
                  },
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
                          key: _shareButtonKey,
                          customBorder: const CircleBorder(),
                          onTap: summaryToShare != null
                              ? () => _shareActivity(
                                    summaryToShare,
                                    shareTitle,
                                    emoji: selectedRitual?.icon,
                                  )
                              : null,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.fillFaint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.share_outlined,
                                    size: 22,
                                    color: shareEnabled
                                        ? iconColor
                                        : Theme.of(context)
                                            .disabledColor
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ActivityHeatmapCard(
                  summary: displaySummary,
                  headerTitle: heatmapTitle,
                  headerEmoji: heatmapEmoji,
                ),
                if (selectedRitual != null)
                  AchievementsRow(summary: displaySummary),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareActivity(
    ActivitySummary summary,
    String title, {
    String? emoji,
  }) async {
    OverlayEntry? entry;
    final prevPaintSize = debugPaintSizeEnabled;
    final prevPaintBaselines = debugPaintBaselinesEnabled;
    final prevPaintPointers = debugPaintPointersEnabled;
    final prevRepaintRainbow = debugRepaintRainbowEnabled;
    try {
      debugPaintSizeEnabled = false;
      debugPaintBaselinesEnabled = false;
      debugPaintPointersEnabled = false;
      debugRepaintRainbowEnabled = false;

      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) {
        throw StateError("Overlay not available for sharing");
      }
      final key = GlobalKey();
      entry = OverlayEntry(
        builder: (context) {
          return Center(
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: key,
                child: _ActivityShareCard(
                  summary: summary,
                  title: title,
                  emoji: emoji,
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 40));
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError("Render boundary unavailable");
      }
      if (boundary.size.isEmpty) {
        throw StateError("Render boundary has zero size");
      }
      if (boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 24));
      }
      if (boundary.debugNeedsPaint) {
        throw StateError("Render boundary not ready to paint");
      }
      final double pixelRatio =
          (MediaQuery.of(context).devicePixelRatio * 1.6).clamp(2.0, 3.5);
      final ui.Image image =
          await boundary.toImage(pixelRatio: pixelRatio.toDouble());
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final data = byteData?.buffer.asUint8List();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/activity_share_${DateTime.now().millisecondsSinceEpoch}.png",
      );
      await file.writeAsBytes(data, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: shareButtonRect(context, _shareButtonKey),
        ),
      );
    } catch (e, s) {
      debugPrint("Failed to share activity: $e\n$s");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to share right now. Please try again."),
        ),
      );
    } finally {
      debugPaintSizeEnabled = prevPaintSize;
      debugPaintBaselinesEnabled = prevPaintBaselines;
      debugPaintPointersEnabled = prevPaintPointers;
      debugRepaintRainbowEnabled = prevRepaintRainbow;
      entry?.remove();
    }
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

  void _openRitualCamera(Ritual ritual) {
    final albumId = ritual.albumId;
    if (albumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Set an album for this ritual to launch the camera."),
        ),
      );
      return;
    }
    routeToPage(
      context,
      RitualCameraPage(
        ritualId: ritual.id,
        albumId: albumId,
      ),
    );
  }
}

class _ActivityShareCard extends StatelessWidget {
  const _ActivityShareCard({
    required this.summary,
    required this.title,
    this.emoji,
  });

  final ActivitySummary summary;
  final String title;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final double maxWidth = math
        .min(
          math.max(MediaQuery.of(context).size.width - 32, 360),
          440,
        )
        .toDouble();
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyBold.copyWith(
                        fontSize: 20,
                        height: 1.2,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ActivityHeatmapCard(
                      summary: summary,
                      compact: true,
                      allowHorizontalScroll: false,
                      headerTitle: title,
                      headerEmoji: emoji,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Image.asset(
                          "assets/ente_io_green.png",
                          width: 116,
                          height: 27,
                          fit: BoxFit.contain,
                        ),
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
  }
}
