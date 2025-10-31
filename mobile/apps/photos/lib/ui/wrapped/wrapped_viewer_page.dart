import "dart:async";
import "dart:math" as math;
import "dart:ui" as ui;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
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

part "cards/story_card.dart";
part "cards/stats_card_content.dart";
part "cards/people_card_content.dart";
part "cards/places_card_content.dart";
part "cards/aesthetics_card_content.dart";
part "cards/curation_card_content.dart";
part "cards/narrative_card_content.dart";
part "cards/badge_card_content.dart";
part "cards/shared_widgets.dart";

/// Basic viewer for the stats-only Ente Rewind experience.
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
  bool _suppressNextTapUp = false;
  bool _longPressActive = false;
  bool _wasPausedBeforeLongPress = false;
  double _verticalDragDistance = 0;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _cards = _buildCards(_state.result?.cards);
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
    final int cardCount = _cards.length;
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
      _cards = _buildCards(next.result?.cards);
    });
    final int newCardCount = _cards.length;
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

  List<WrappedCard> _buildCards(List<WrappedCard>? source) {
    if (source == null || source.isEmpty) {
      return <WrappedCard>[];
    }
    final List<WrappedCard> cards = List<WrappedCard>.from(source);
    if (kReleaseMode) {
      return cards;
    }

    WrappedCard? badgeCard;
    for (final WrappedCard card in cards) {
      if (card.type == WrappedCardType.badge) {
        badgeCard = card;
        break;
      }
    }
    if (badgeCard == null) {
      return cards;
    }

    final Object? rawCandidates = badgeCard.meta["candidates"];
    if (rawCandidates is! List || rawCandidates.isEmpty) {
      return cards;
    }

    final List<Map<String, Object?>> candidates = rawCandidates
        .whereType<Map>()
        .map((Map<dynamic, dynamic> entry) => entry.cast<String, Object?>())
        .toList(growable: false);
    if (candidates.isEmpty) {
      return cards;
    }

    cards.add(
      WrappedCard(
        type: WrappedCardType.badgeDebug,
        title: "Badge candidates (debug)",
        meta: <String, Object?>{
          "candidates": candidates,
          "badgeKey": badgeCard.meta["badgeKey"],
          "displayDurationMillis": 12000,
        },
      ),
    );

    return cards;
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
    _pendingRestart = false;
    _updateCurrentIndex(index, restartProgress: true);
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

  void _handleTap(
    Offset localPosition,
    BoxConstraints constraints,
  ) {
    final double dx = localPosition.dx;
    final double width = constraints.maxWidth;
    final double leftZoneBoundary = width * 0.25;
    final double rightZoneBoundary = width * 0.75;
    _triggerLightHaptic();
    if (dx < leftZoneBoundary) {
      if (_progressController.value > 0.1) {
        _configureForCurrentCard(restartProgress: true);
      } else {
        unawaited(
          _goToIndex(
            _currentIndex - 1,
            animate: false,
          ),
        );
      }
    } else if (dx > rightZoneBoundary) {
      unawaited(
        _goToIndex(
          _currentIndex + 1,
          animate: false,
        ),
      );
    } else {
      _togglePause();
      setState(() {});
    }
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) {
    if (_suppressNextTapUp) {
      _suppressNextTapUp = false;
      return;
    }
    _handleTap(details.localPosition, constraints);
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _verticalDragDistance = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isClosing) {
      return;
    }
    final double? delta = details.primaryDelta;
    if (delta == null || delta <= 0) {
      return;
    }
    _verticalDragDistance += delta;
    if (_verticalDragDistance >= 100) {
      _closeViewer();
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isClosing) {
      return;
    }
    final double velocity = details.primaryVelocity ?? 0;
    if (_verticalDragDistance >= 60 || velocity > 800) {
      _closeViewer();
    }
    _verticalDragDistance = 0;
  }

  void _handleVerticalDragCancel() {
    _verticalDragDistance = 0;
  }

  void _closeViewer() {
    if (_isClosing || !mounted) {
      return;
    }
    _isClosing = true;
    Navigator.of(context).maybePop().then((bool didPop) {
      if (!didPop && mounted) {
        _isClosing = false;
      }
    });
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (_longPressActive) {
      return;
    }
    _longPressActive = true;
    _suppressNextTapUp = true;
    _wasPausedBeforeLongPress = _isPaused;
    _triggerLightHaptic();
    _pauseAutoplay();
    setState(() {});
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_longPressActive) {
      return;
    }
    _longPressActive = false;
    if (!_wasPausedBeforeLongPress) {
      _resumeAutoplay();
    }
    _wasPausedBeforeLongPress = false;
    _scheduleTapUpReset();
    setState(() {});
  }

  void _handleLongPressCancel() {
    if (!_longPressActive) {
      return;
    }
    _longPressActive = false;
    if (!_wasPausedBeforeLongPress) {
      _resumeAutoplay();
    }
    _wasPausedBeforeLongPress = false;
    _scheduleTapUpReset();
    setState(() {});
  }

  void _scheduleTapUpReset() {
    scheduleMicrotask(() {
      _suppressNextTapUp = false;
    });
  }

  void _triggerLightHaptic() {
    unawaited(HapticFeedback.lightImpact());
  }

  @override
  Widget build(BuildContext context) {
    final WrappedResult? result = _state.result;
    final int cardCount = _cards.length;
    if (result == null || cardCount == 0) {
      scheduleMicrotask(() {
        if (mounted) {
          showShortToast(context, "Ente Rewind data not available");
          Navigator.of(context).maybePop();
        }
      });
      return const SizedBox.shrink();
    }

    return Theme(
      data: darkThemeData,
      child: Builder(
        builder: (BuildContext context) {
          final enteColorScheme = getEnteColorScheme(context);
          final textTheme = getEnteTextTheme(context);
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          final double bottomPadding = mediaQuery.padding.bottom;

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (bool didPop, Object? result) {
              if (!didPop) {
                return;
              }
              wrappedService.updateResumeIndex(_currentIndex);
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                leading: BackButton(
                  onPressed: _closeViewer,
                ),
                title: Text(
                  "Ente Rewind",
                  style: textTheme.largeBold,
                ),
                backgroundColor: Colors.black,
                foregroundColor: enteColorScheme.textBase,
                elevation: 0,
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (BuildContext context, _) {
                              final List<double> segments =
                                  List<double>.generate(cardCount, (int index) {
                                if (index < _currentIndex) {
                                  return 1.0;
                                }
                                if (index > _currentIndex) {
                                  return 0.0;
                                }
                                return _progressController.value
                                    .clamp(0.0, 1.0);
                              });
                              return _StoryProgressBar(
                                progressValues: segments,
                                colorScheme: enteColorScheme,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (TapUpDetails details) =>
                                  _handleTapUp(details, constraints),
                              onTapCancel: () {
                                _suppressNextTapUp = false;
                              },
                              onLongPressStart: _handleLongPressStart,
                              onLongPressEnd: _handleLongPressEnd,
                              onLongPressCancel: _handleLongPressCancel,
                              onVerticalDragStart: _handleVerticalDragStart,
                              onVerticalDragUpdate: _handleVerticalDragUpdate,
                              onVerticalDragEnd: _handleVerticalDragEnd,
                              onVerticalDragCancel: _handleVerticalDragCancel,
                              child: RepaintBoundary(
                                key: _cardBoundaryKey,
                                child: PageView.builder(
                                  physics: const PageScrollPhysics(),
                                  controller: _pageController,
                                  onPageChanged: _handlePageChanged,
                                  itemCount: cardCount,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final WrappedCard card = _cards[index];
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
                    bottom: bottomPadding + 24,
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
                          color:
                              enteColorScheme.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              name: "ente_rewind_${_currentIndex + 1}.png",
              mimeType: "image/png",
            ),
          ],
          sharePositionOrigin: shareButtonRect(context, _shareButtonKey),
        ),
      );
    } catch (error, stackTrace) {
      _logger.severe("Failed to share Ente Rewind card", error, stackTrace);
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
