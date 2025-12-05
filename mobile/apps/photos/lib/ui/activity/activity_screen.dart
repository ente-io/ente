import "dart:io";
import "dart:math" as math;
import "dart:ui" as ui;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/activity/achievements_row.dart";
import "package:photos/ui/activity/activity_heatmap_card.dart";
import "package:photos/ui/activity/ritual_badge_popup.dart";
import "package:photos/ui/activity/rituals_section.dart";
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
  static final Logger _logger = Logger("ActivityScreen");

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
                backgroundColor: colorScheme.fillFaint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                size: 24,
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
        child: ValueListenableBuilder<ActivityState>(
          valueListenable: activityService.stateNotifier,
          builder: (context, state, _) {
            final summary = state.summary;
            Ritual? selectedRitual = _selectedRitual;
            if (selectedRitual != null) {
              final match = state.rituals.where(
                (ritual) => ritual.id == selectedRitual!.id,
              );
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
                ? l10n.ritualDefaultHeatmapTitle
                : (selectedRitual.title.isEmpty
                    ? l10n.ritualUntitled
                    : selectedRitual.title);
            final String heatmapEmoji =
                selectedRitual?.icon ?? (selectedRitual == null ? "📸" : "");
            final String shareTitle = heatmapTitle;
            final String shareEmoji = heatmapEmoji;
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
                          l10n.ritualActivityHeading,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Material(
                            key: _shareButtonKey,
                            color: colorScheme.fillFaint,
                            borderRadius: BorderRadius.circular(10),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: summaryToShare != null
                                  ? () => _shareActivity(
                                        summaryToShare,
                                        shareTitle,
                                        emoji: shareEmoji,
                                      )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedShare08,
                                    size: 24,
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
                  AchievementsRow(
                    summary: displaySummary,
                    onBadgeTap: (days) =>
                        _showDebugBadge(selectedRitual!, days),
                  ),
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
    _logger.info("Activity share: start");
    _logger.fine("Activity share: precache assets begin");
    await _precacheActivityShareAssets();
    _logger.fine("Activity share: precache assets done");
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
              child: IgnorePointer(
                child: Opacity(
                  // Keep the share card invisible while still allowing it to paint.
                  opacity: 0.01,
                  child: RepaintBoundary(
                    key: key,
                    child: _ActivityShareCard(
                      summary: summary,
                      title: title,
                      emoji: emoji,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(entry);
      _logger.fine("Activity share: overlay inserted, waiting for boundary");
      final boundary = await _waitForBoundaryReady(repaintKey: key);
      bool needsPaint = false;
      assert(() {
        needsPaint = boundary.debugNeedsPaint;
        return true;
      }());
      _logger.fine(
        "Activity share: boundary ready, size=${boundary.size}, needsPaint=$needsPaint",
      );
      final double pixelRatio =
          (MediaQuery.of(context).devicePixelRatio * 1.6).clamp(2.0, 3.5);
      late final ui.Image image;
      try {
        image = await boundary.toImage(pixelRatio: pixelRatio.toDouble());
      } catch (e, s) {
        _logger.warning("Activity share: toImage failed", e, s);
        rethrow;
      }
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } catch (e, s) {
        _logger.warning("Activity share: toByteData failed", e, s);
        rethrow;
      }
      final data = byteData?.buffer.asUint8List();
      if (data == null || data.isEmpty) {
        throw StateError("Activity share image encoding produced no data");
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/activity_share_${DateTime.now().millisecondsSinceEpoch}.png",
      );
      await file.writeAsBytes(data, flush: true);
      _logger.info(
        "Activity share: file written (${data.length} bytes) -> ${file.path}",
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: shareButtonRect(context, _shareButtonKey),
        ),
      );
      _logger.info("Activity share: SharePlus invoked");
    } catch (e, s) {
      _logger.warning("Failed to share activity", e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ritualShareUnavailable)),
      );
    } finally {
      debugPaintSizeEnabled = prevPaintSize;
      debugPaintBaselinesEnabled = prevPaintBaselines;
      debugPaintPointersEnabled = prevPaintPointers;
      debugRepaintRainbowEnabled = prevRepaintRainbow;
      entry?.remove();
    }
  }

  Future<void> _precacheActivityShareAssets() async {
    const assets = [
      "assets/rituals/ente_io_black_white.png",
      "assets/splash-screen-icon.png",
    ];
    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e, s) {
        _logger.warning(
          "Activity share: failed to precache asset $asset",
          e,
          s,
        );
      }
    }
  }

  Future<RenderRepaintBoundary> _waitForBoundaryReady({
    required GlobalKey repaintKey,
  }) async {
    const int maxAttempts = 8;
    const Duration attemptDelay = Duration(milliseconds: 40);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      bool needsPaint = false;
      assert(() {
        needsPaint = boundary?.debugNeedsPaint ?? false;
        return true;
      }());
      if (boundary == null) {
        _logger.fine(
          "Activity share boundary missing (attempt ${attempt + 1})",
        );
      } else if (boundary.size.isEmpty) {
        _logger.fine(
          "Activity share boundary has zero size (attempt ${attempt + 1})",
        );
      } else if (needsPaint) {
        _logger.fine(
          "Activity share boundary needs paint (attempt ${attempt + 1}), waiting",
        );
      } else {
        return boundary;
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(attemptDelay);
    }

    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError("Render boundary unavailable");
    }
    if (boundary.size.isEmpty) {
      throw StateError("Render boundary has zero size");
    }
    bool needsPaint = false;
    assert(() {
      needsPaint = boundary.debugNeedsPaint;
      return true;
    }());
    if (needsPaint) {
      throw StateError("Render boundary not ready to paint");
    }
    return boundary;
  }

  ActivitySummary _summaryForRitual(ActivitySummary summary, Ritual ritual) {
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
              DateTime(
                day.date.year,
                day.date.month,
                day.date.day,
              ).millisecondsSinceEpoch,
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
      ritualLongestStreaks: {ritual.id: longestStreak},
    );
  }

  Future<void> _showDebugBadge(Ritual ritual, int days) async {
    if (!kDebugMode) return;
    final badge = RitualBadgeUnlock(
      ritual: ritual,
      days: days,
      generatedAt: DateTime.now(),
    );
    await showRitualBadgePopup(context, badge: badge);
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
    const Color shareBackgroundColor = Color(0xFF08C225);
    final String shareHeaderTitle =
        (emoji ?? "").isNotEmpty ? "${emoji!} $title" : title;
    final double maxWidth = math
        .min(math.max(MediaQuery.of(context).size.width - 32, 360), 440)
        .toDouble();
    return Align(
      alignment: Alignment.topCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: shareBackgroundColor,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            brightness: Brightness.light,
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  brightness: Brightness.light,
                                ),
                          ),
                          child: ActivityHeatmapCard(
                            summary: summary,
                            compact: true,
                            allowHorizontalScroll: false,
                            headerTitle: shareHeaderTitle,
                            headerEmoji: null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        "assets/rituals/ente_io_black_white.png",
                        width: 62,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  "assets/splash-screen-icon.png",
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
