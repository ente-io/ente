import "dart:async";
import "dart:math" as math;
import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/share_util.dart";
import "package:share_plus/share_plus.dart";

/// Basic viewer for the stats-only Ente Wrapped experience.
class WrappedViewerPage extends StatefulWidget {
  const WrappedViewerPage({
    required this.initialState,
    super.key,
  });

  final WrappedEntryState initialState;

  @override
  State<WrappedViewerPage> createState() => _WrappedViewerPageState();
}

class _WrappedViewerPageState extends State<WrappedViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late WrappedEntryState _state;
  late List<WrappedCard> _cards;
  late int _currentIndex;
  bool _isPaused = false;
  VoidCallback? _stateListener;
  final GlobalKey _shareButtonKey = GlobalKey();
  final GlobalKey _cardBoundaryKey = GlobalKey();
  final Logger _logger = Logger("WrappedViewerPage");
  bool _pendingRestart = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _cards = _state.result?.cards ?? const <WrappedCard>[];
    final int initialPage = _initialPageForState(_state);
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _progressController = AnimationController(
      vsync: this,
      duration: _durationForCard(_currentIndex),
    )..addStatusListener(_handleProgressStatus);
    if (_cards.isNotEmpty) {
      _progressController.forward();
    }
    _stateListener = () => _handleServiceUpdate(wrappedService.state);
    wrappedService.stateListenable.addListener(_stateListener!);
  }

  @override
  void dispose() {
    if (_stateListener != null) {
      wrappedService.stateListenable.removeListener(_stateListener!);
    }
    _progressController.removeStatusListener(_handleProgressStatus);
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _initialPageForState(WrappedEntryState state) {
    final int cardCount = state.result?.cards.length ?? 0;
    if (cardCount <= 1) {
      return 0;
    }
    return state.resumeIndex.clamp(0, cardCount - 1);
  }

  void _handleServiceUpdate(WrappedEntryState next) {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = next;
      _cards = next.result?.cards ?? const <WrappedCard>[];
    });
    final int newCardCount = next.result?.cards.length ?? 0;
    if (newCardCount == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_currentIndex >= newCardCount) {
      unawaited(
        _goToIndex(
          newCardCount - 1,
          restartProgress: false,
          animate: false,
        ),
      );
    } else {
      _configureForCurrentCard(restartProgress: false);
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    if (_currentIndex >= _cards.length - 1) {
      wrappedService.markComplete();
      _pauseAutoplay();
      return;
    }
    unawaited(_goToIndex(_currentIndex + 1));
  }

  Duration _durationForCard(int index) {
    if (_cards.isEmpty || index < 0 || index >= _cards.length) {
      return const Duration(seconds: 5);
    }
    final WrappedCard card = _cards[index];
    final Object? durationMeta = card.meta["displayDurationMillis"];
    final int durationMillis =
        durationMeta is num ? durationMeta.clamp(1500, 20000).toInt() : 6000;
    return Duration(milliseconds: durationMillis);
  }

  void _configureForCurrentCard({required bool restartProgress}) {
    _progressController.duration = _durationForCard(_currentIndex);
    if (restartProgress) {
      _progressController
        ..stop()
        ..reset();
      if (!_isPaused) {
        _progressController.forward();
      }
    }
  }

  Future<void> _goToIndex(
    int index, {
    bool restartProgress = true,
    bool animate = true,
  }) async {
    if (index < 0 || index >= _cards.length) {
      return;
    }
    _pendingRestart = restartProgress;
    if (!_pageController.hasClients) {
      _pendingRestart = false;
      _updateCurrentIndex(index, restartProgress: restartProgress);
      return;
    }
    if (animate) {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
    if (!_pendingRestart) {
      // If no restart requested, ensure service sync still happens.
      _updateCurrentIndex(index, restartProgress: false);
    }
  }

  void _handlePageChanged(int index) {
    final bool restart = _pendingRestart;
    _pendingRestart = false;
    _updateCurrentIndex(index, restartProgress: restart);
  }

  void _updateCurrentIndex(int index, {required bool restartProgress}) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
    wrappedService.updateResumeIndex(index);
    final int lastIndex = _cards.length - 1;
    if (index == lastIndex) {
      wrappedService.markComplete();
    }
    _configureForCurrentCard(restartProgress: restartProgress);
  }

  void _pauseAutoplay() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
  }

  void _resumeAutoplay() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
  }

  void _togglePause() {
    if (_isPaused) {
      _resumeAutoplay();
    } else {
      _pauseAutoplay();
    }
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final double dx = details.localPosition.dx;
    final double width = constraints.maxWidth;
    final double leftZone = width / 3;
    final double rightZone = width * 2 / 3;
    if (dx < leftZone) {
      if (_progressController.value > 0.1) {
        _configureForCurrentCard(restartProgress: true);
      } else {
        unawaited(_goToIndex(_currentIndex - 1));
      }
    } else if (dx > rightZone) {
      unawaited(_goToIndex(_currentIndex + 1));
    } else {
      _togglePause();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final WrappedResult? result = _state.result;
    final int cardCount = result?.cards.length ?? 0;
    if (result == null || cardCount == 0) {
      scheduleMicrotask(() {
        if (mounted) {
          showShortToast(context, "Wrapped data not available");
          Navigator.of(context).maybePop();
        }
      });
      return const SizedBox.shrink();
    }

    final enteColorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          return;
        }
        wrappedService.updateResumeIndex(_currentIndex);
      },
      child: Scaffold(
        backgroundColor: enteColorScheme.backgroundBase,
        appBar: AppBar(
          title: Text(
            "Wrapped ${result.year}",
            style: textTheme.largeBold,
          ),
          backgroundColor: enteColorScheme.backgroundBase,
          foregroundColor: enteColorScheme.textBase,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (BuildContext context, _) {
                      final List<double> segments =
                          List<double>.generate(cardCount, (int index) {
                        if (index < _currentIndex) return 1.0;
                        if (index > _currentIndex) return 0.0;
                        return _progressController.value.clamp(0.0, 1.0);
                      });
                      return _StoryProgressBar(
                        progressValues: segments,
                        colorScheme: enteColorScheme,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (TapDownDetails details) =>
                            _handleTapDown(details, constraints),
                        child: RepaintBoundary(
                          key: _cardBoundaryKey,
                          child: PageView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _pageController,
                            onPageChanged: _handlePageChanged,
                            itemCount: cardCount,
                            itemBuilder: (BuildContext context, int index) {
                              final WrappedCard card = result.cards[index];
                              return _StoryCard(
                                card: card,
                                colorScheme: enteColorScheme,
                                textTheme: textTheme,
                                isActive: index == _currentIndex,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 24,
              child: GestureDetector(
                key: _shareButtonKey,
                behavior: HitTestBehavior.translucent,
                onTap: _handleShare,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.share,
                    size: 28,
                    color: enteColorScheme.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_cards.isEmpty) {
      showShortToast(context, "Nothing to share yet");
      return;
    }
    final bool wasPaused = _isPaused;
    _pauseAutoplay();
    try {
      final Uint8List? bytes = await _captureCurrentCard();
      if (bytes == null) {
        showShortToast(context, "Unable to prepare share");
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              bytes,
              name: "ente_wrapped_${_currentIndex + 1}.png",
              mimeType: "image/png",
            ),
          ],
          sharePositionOrigin: shareButtonRect(context, _shareButtonKey),
        ),
      );
    } catch (error, stackTrace) {
      _logger.severe("Failed to share Wrapped card", error, stackTrace);
      if (mounted) {
        showShortToast(context, "Share failed");
      }
    } finally {
      if (!wasPaused) {
        _resumeAutoplay();
      }
    }
  }

  Future<Uint8List?> _captureCurrentCard() async {
    await Future<void>.delayed(Duration.zero);
    final RenderRepaintBoundary? boundary = _cardBoundaryKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final double width = boundary.size.width;
    if (width <= 0) {
      return null;
    }
    final double pixelRatio = (1080 / width).clamp(1.0, 6.0);
    final ui.Image image =
        await boundary.toImage(pixelRatio: pixelRatio.toDouble());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
    required this.isActive,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Material(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: _CardContent(
              card: card,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    switch (card.type) {
      case WrappedCardType.statsTotals:
        return _TotalsCardContent(
          card: card,
          colorScheme: colorScheme,
          textTheme: textTheme,
        );
      case WrappedCardType.statsVelocity:
        return _RhythmCardContent(
          card: card,
          colorScheme: colorScheme,
          textTheme: textTheme,
        );
      case WrappedCardType.busiestDay:
        return _BusiestDayCardContent(
          card: card,
          colorScheme: colorScheme,
          textTheme: textTheme,
        );
      case WrappedCardType.statsHeatmap:
        return _HeatmapCardContent(
          card: card,
          colorScheme: colorScheme,
          textTheme: textTheme,
        );
      default:
        return _GenericCardContent(
          card: card,
          textTheme: textTheme,
        );
    }
  }
}

class _TotalsCardContent extends StatelessWidget {
  const _TotalsCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");
    final String? firstCaptureLine = card.meta["firstCaptureLine"] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroMediaCollage(
          media: card.media,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        if (firstCaptureLine != null) ...[
          const SizedBox(height: 16),
          Text(
            firstCaptureLine,
            style: textTheme.smallMuted,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _RhythmCardContent extends StatelessWidget {
  const _RhythmCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 18),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        if (card.media.isNotEmpty) ...[
          const SizedBox(height: 22),
          _MediaRow(
            media: card.media.take(3).toList(growable: false),
            colorScheme: colorScheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _BusiestDayCardContent extends StatelessWidget {
  const _BusiestDayCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 18),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const SizedBox(height: 22),
        _MediaGrid(
          media: card.media.take(6).toList(growable: false),
          colorScheme: colorScheme,
        ),
        const Spacer(),
      ],
    );
  }
}

class _HeatmapCardContent extends StatelessWidget {
  const _HeatmapCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");
    final List<dynamic> rawQuarters =
        card.meta["quarters"] as List<dynamic>? ?? const <dynamic>[];
    final List<_QuarterBlock> quarters = rawQuarters
        .map(
          (dynamic entry) => _QuarterBlock.fromJson(
            (entry as Map).cast<String, Object?>(),
          ),
        )
        .where((_QuarterBlock block) => block.grid.isNotEmpty)
        .toList(growable: false);
    final List<String> weekdayLabels =
        (card.meta["weekdayLabels"] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    final int maxCount = (card.meta["maxCount"] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        const SizedBox(height: 18),
        if (quarters.isEmpty)
          _MediaPlaceholder(
            height: 180,
            colorScheme: colorScheme,
          )
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxWidth = constraints.maxWidth;
              final int columns =
                  quarters.length <= 1 ? 1 : (maxWidth >= 280 ? 2 : 1);
              final double spacing = columns > 1 ? 18 : 0;
              final double itemWidth = columns > 1
                  ? (maxWidth - ((columns - 1) * spacing)) / columns
                  : maxWidth;
              final int maxColumnCount = quarters
                  .map(
                    (_QuarterBlock block) =>
                        block.grid.isNotEmpty ? block.grid.first.length : 0,
                  )
                  .fold(0, math.max);
              const double labelColumnWidth = 20;
              const double cellSpacing = 1.5;
              const double fallbackCellSize = 6;
              const double maxCellWidth = 18;
              const double maxCellHeight = 12;

              double computeCellWidth(double availableWidth) {
                if (maxColumnCount <= 0) {
                  return fallbackCellSize;
                }
                final double usable = math.max(
                  0,
                  availableWidth -
                      cellSpacing * math.max(0, maxColumnCount - 1),
                );
                final double raw = usable / math.max(1, maxColumnCount);
                return raw.clamp(fallbackCellSize, maxCellWidth);
              }

              final double cellWidthWithLabels =
                  computeCellWidth(itemWidth - labelColumnWidth);
              final double cellWidthWithoutLabels = computeCellWidth(itemWidth);
              final double cellWidth =
                  math.min(cellWidthWithLabels, cellWidthWithoutLabels);
              final double cellHeight = math.min(
                maxCellHeight,
                cellWidth.clamp(fallbackCellSize, maxCellHeight),
              );
              return Wrap(
                spacing: spacing,
                runSpacing: 18,
                children: <Widget>[
                  for (final (int index, _QuarterBlock block)
                      in quarters.indexed)
                    SizedBox(
                      width: itemWidth,
                      child: _QuarterHeatmap(
                        block: block,
                        weekdayLabels: weekdayLabels,
                        maxCount: maxCount,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        showDayLabels: columns == 1 || index % columns == 0,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        cellSpacing: cellSpacing,
                        labelColumnWidth: labelColumnWidth,
                      ),
                    ),
                ],
              );
            },
          ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _GenericCardContent extends StatelessWidget {
  const _GenericCardContent({
    required this.card,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        const Spacer(),
      ],
    );
  }
}

class _QuarterBlock {
  _QuarterBlock({
    required this.label,
    required this.grid,
    required this.columnLabels,
  });

  final String label;
  final List<List<int>> grid;
  final List<String> columnLabels;

  static _QuarterBlock fromJson(Map<String, Object?> json) {
    final List<List<int>> grid =
        (json["grid"] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (dynamic row) => (row as List<dynamic>)
                  .map((dynamic value) => (value as num).toInt())
                  .toList(growable: false),
            )
            .toList(growable: false);
    final List<String> columnLabels =
        (json["columnLabels"] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    return _QuarterBlock(
      label: json["label"] as String? ?? "",
      grid: grid,
      columnLabels: columnLabels,
    );
  }
}

class _QuarterHeatmap extends StatelessWidget {
  const _QuarterHeatmap({
    required this.block,
    required this.weekdayLabels,
    required this.maxCount,
    required this.colorScheme,
    required this.textTheme,
    required this.showDayLabels,
    required this.cellWidth,
    required this.cellHeight,
    required this.cellSpacing,
    required this.labelColumnWidth,
  });

  final _QuarterBlock block;
  final List<String> weekdayLabels;
  final int maxCount;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool showDayLabels;
  final double cellWidth;
  final double cellHeight;
  final double cellSpacing;
  final double labelColumnWidth;

  @override
  Widget build(BuildContext context) {
    final int columnCount = block.grid.isEmpty ? 0 : block.grid.first.length;
    if (columnCount == 0) {
      return _MediaPlaceholder(
        height: 120,
        colorScheme: colorScheme,
      );
    }

    final TextStyle axisStyle =
        textTheme.tinyMuted.copyWith(fontSize: 8.5, height: 1.15);
    final List<String> headerLabels = List<String>.generate(
      columnCount,
      (int index) =>
          index < block.columnLabels.length ? block.columnLabels[index] : "",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.label,
          style: textTheme.smallBold,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(width: labelColumnWidth),
            for (int columnIndex = 0;
                columnIndex < headerLabels.length;
                columnIndex += 1) ...[
              SizedBox(
                width: cellWidth,
                child: Text(
                  headerLabels[columnIndex],
                  style: axisStyle,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              SizedBox(
                width: columnIndex == headerLabels.length - 1 ? 0 : cellSpacing,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Column(
          children: List<Widget>.generate(weekdayLabels.length, (int dayIndex) {
            final List<int> row = block.grid.length > dayIndex
                ? block.grid[dayIndex]
                : const <int>[];
            final String dayLabel =
                dayIndex < weekdayLabels.length ? weekdayLabels[dayIndex] : "";
            return Padding(
              padding: EdgeInsets.only(
                bottom: dayIndex == weekdayLabels.length - 1 ? 0 : cellSpacing,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: labelColumnWidth,
                    child: Visibility(
                      visible: showDayLabels,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text(
                        dayLabel,
                        style: axisStyle,
                      ),
                    ),
                  ),
                  for (int columnIndex = 0;
                      columnIndex < columnCount;
                      columnIndex += 1) ...[
                    _HeatmapCell(
                      value: columnIndex < row.length ? row[columnIndex] : -1,
                      width: cellWidth,
                      height: cellHeight,
                      colorScheme: colorScheme,
                      maxCount: maxCount,
                    ),
                    SizedBox(
                      width: columnIndex == columnCount - 1 ? 0 : cellSpacing,
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.value,
    required this.width,
    required this.height,
    required this.colorScheme,
    required this.maxCount,
  });

  final int value;
  final double width;
  final double height;
  final EnteColorScheme colorScheme;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (value == kWrappedHeatmapFutureValue) {
      return SizedBox(width: width, height: height);
    }
    if (value == kWrappedHeatmapPaddedValue) {
      final Color base = colorScheme.fillFaint;
      final double placeholderAlpha = (base.a * 0.4).clamp(0.0, 1.0).toDouble();
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: placeholderAlpha),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _heatmapColorForValue(value, maxCount, colorScheme),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DetailChips extends StatelessWidget {
  const _DetailChips({
    required this.chips,
    required this.colorScheme,
    required this.textTheme,
  });

  final List<String> chips;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: chips
          .map(
            (String chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                chip,
                style: textTheme.smallMuted,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeroMediaCollage extends StatelessWidget {
  const _HeroMediaCollage({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return _MediaPlaceholder(
        height: 220,
        colorScheme: colorScheme,
        borderRadius: 24,
      );
    }

    final List<MediaRef> trimmed = media.take(3).toList(growable: false);
    final MediaRef primary = trimmed.first;
    final List<MediaRef> side = trimmed.skip(1).toList(growable: false);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _MediaTile(
              mediaRef: primary,
              borderRadius: 24,
              aspectRatio: 3 / 4,
            ),
          ),
          if (side.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: List<Widget>.generate(
                  2,
                  (int index) {
                    final MediaRef? ref =
                        index < side.length ? side[index] : null;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index == 0 ? 12 : 0,
                        ),
                        child: ref != null
                            ? _MediaTile(
                                mediaRef: ref,
                                borderRadius: 20,
                              )
                            : _MediaPlaceholder(
                                colorScheme: colorScheme,
                                borderRadius: 20,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          for (final (int index, MediaRef ref) in media.indexed) ...[
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == media.length - 1 ? 0 : 12),
                child: _MediaTile(
                  mediaRef: ref,
                  borderRadius: 18,
                ),
              ),
            ),
          ],
          if (media.isEmpty)
            Expanded(
              child: _MediaPlaceholder(
                colorScheme: colorScheme,
                borderRadius: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return _MediaPlaceholder(
        height: 200,
        colorScheme: colorScheme,
      );
    }
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Column(
        children: List<Widget>.generate(3, (int row) {
          return Expanded(
            child: Row(
              children: List<Widget>.generate(2, (int column) {
                final int index = row * 2 + column;
                final MediaRef? ref =
                    index < media.length ? media[index] : null;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: column == 1 ? 0 : 10,
                      bottom: row == 2 ? 0 : 10,
                    ),
                    child: ref != null
                        ? _MediaTile(
                            mediaRef: ref,
                            borderRadius: 16,
                          )
                        : _MediaPlaceholder(
                            colorScheme: colorScheme,
                            borderRadius: 16,
                          ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.mediaRef,
    required this.borderRadius,
    this.aspectRatio,
  });

  final MediaRef mediaRef;
  final double borderRadius;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.expand(
        child: _MediaThumb(
          ref: mediaRef,
        ),
      ),
    );
    if (aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: aspectRatio!,
        child: content,
      );
    }
    return content;
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.colorScheme,
    this.height,
    this.borderRadius = 20,
  });

  final EnteColorScheme colorScheme;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      decoration: BoxDecoration(
        color: colorScheme.primary400.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    if (height != null) {
      return SizedBox(
        height: height,
        child: child,
      );
    }
    return child;
  }
}

class _MediaThumb extends StatefulWidget {
  const _MediaThumb({required this.ref});

  final MediaRef ref;

  @override
  State<_MediaThumb> createState() => _MediaThumbState();
}

class _MediaThumbState extends State<_MediaThumb> {
  late Future<EnteFile?> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = FilesDB.instance.getAnyUploadedFile(
      widget.ref.uploadedFileID,
    );
  }

  @override
  void didUpdateWidget(covariant _MediaThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ref.uploadedFileID != widget.ref.uploadedFileID) {
      _fileFuture = FilesDB.instance.getAnyUploadedFile(
        widget.ref.uploadedFileID,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return FutureBuilder<EnteFile?>(
      future: _fileFuture,
      builder: (BuildContext context, AsyncSnapshot<EnteFile?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: colorScheme.fillFaint,
          );
        }
        final EnteFile? file = snapshot.data;
        if (file == null) {
          return Container(
            color: colorScheme.fillFaint,
          );
        }
        return ThumbnailWidget(
          file,
          fit: BoxFit.cover,
          rawThumbnail: true,
          shouldShowSyncStatus: false,
          shouldShowArchiveStatus: false,
          shouldShowPinIcon: false,
          shouldShowOwnerAvatar: false,
          shouldShowFavoriteIcon: false,
          shouldShowVideoDuration: false,
          shouldShowVideoOverlayIcon: false,
        );
      },
    );
  }
}

Color _heatmapColorForValue(
  int value,
  int maxValue,
  EnteColorScheme scheme,
) {
  if (value <= 0 || maxValue <= 0) {
    return scheme.fillFaint;
  }
  final double t = (value / maxValue).clamp(0.0, 1.0);
  return Color.lerp(
        scheme.primary400.withValues(alpha: 0.25),
        scheme.primary500,
        t,
      ) ??
      scheme.primary500;
}

List<String> _stringListFromMeta(
  Map<String, Object?> meta,
  String key,
) {
  final Object? raw = meta[key];
  if (raw is List) {
    return raw.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.progressValues,
    required this.colorScheme,
  });

  final List<double> progressValues;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (int index, double value)
            in progressValues.indexed) ...<Widget>[
          Expanded(
            child: _ProgressSegment(
              progress: value,
              colorScheme: colorScheme,
            ),
          ),
          if (index != progressValues.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.progress,
    required this.colorScheme,
  });

  final double progress;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(
            height: 4,
            color: colorScheme.fillFaint,
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 4,
              color: colorScheme.primary500,
            ),
          ),
        ],
      ),
    );
  }
}
