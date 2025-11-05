import "dart:async";
import "dart:math" as math;
import "dart:typed_data";
import "dart:ui" as ui;

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/faces_timeline/faces_timeline_models.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/faces_timeline/faces_timeline_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

class FacesTimelinePage extends StatefulWidget {
  final PersonEntity person;

  const FacesTimelinePage({required this.person, super.key});

  @override
  State<FacesTimelinePage> createState() => _FacesTimelinePageState();
}

const LinearGradient _facesTimelineBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF03010A),
    Color(0xFF16103C),
    Color(0xFF401963),
    Color(0xFF241348),
    Color(0xFF03010A),
  ],
  stops: [0.0, 0.3, 0.52, 0.74, 1.0],
);

class _FacesTimelinePageState extends State<FacesTimelinePage>
    with TickerProviderStateMixin {
  static const _frameInterval = Duration(milliseconds: 800);
  static const _cardTransitionDuration = Duration(milliseconds: 520);
  static const double _frameWidthFactor = 0.82;
  static const double _frameHeightFactor = 0.78;
  static const double _controlsDesiredGapToCard = 24;
  static const double _cardGapUpdateTolerance = 0.5;
  static const double _controlsHeightUpdateTolerance = 0.5;
  static const double _controlsHeightFallback = 140;

  final Logger _logger = Logger("FacesTimelinePage");
  late final AnimationController _cardTransitionController;
  double _stackProgress = 0;
  double _animationStartProgress = 0;
  int _targetIndex = 0;
  bool _isAnimatingCard = false;

  late Future<List<_TimelineFrame>> _framesFuture;
  final List<_TimelineFrame> _frames = [];

  Timer? _playTimer;
  bool _isPlaying = false;
  bool _loggedPlaybackStart = false;

  int _currentIndex = 0;
  double _cardGap = 0;
  double _controlsHeight = 0;
  final GlobalKey _controlsKey = GlobalKey();
  bool _isScrubbing = false;
  double _sliderValue = 0;
  double _previousCaptionValue = 0;
  double _currentCaptionValue = 0;
  _CaptionType _currentCaptionType = _CaptionType.yearsAgo;
  int _maxCaptionDigits = 1;

  @override
  void initState() {
    super.initState();
    _cardTransitionController = AnimationController(
      vsync: this,
      duration: _cardTransitionDuration,
    )
      ..addListener(_onCardAnimationTick)
      ..addStatusListener(_onCardAnimationStatusChanged);
    _framesFuture = _loadFrames();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _cardTransitionController
      ..removeListener(_onCardAnimationTick)
      ..removeStatusListener(_onCardAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  Future<List<_TimelineFrame>> _loadFrames() async {
    final timeline = await FacesTimelineService.instance.getTimeline(
      widget.person.remoteID,
    );
    if (timeline == null || !timeline.isReady || timeline.entries.isEmpty) {
      return <_TimelineFrame>[];
    }
    final frames = <_TimelineFrame>[];
    for (final entry in timeline.entries) {
      frames.add(await _buildFrame(entry));
    }
    if (frames.isNotEmpty && mounted) {
      int maxRounded = 0;
      for (final frame in frames) {
        maxRounded = math.max(maxRounded, frame.captionValue.round());
      }
      final int digitCount = math.max(1, maxRounded.toString().length);
      setState(() {
        _frames
          ..clear()
          ..addAll(frames);
        _currentIndex = 0;
        _sliderValue = 0;
        _stackProgress = 0;
        _animationStartProgress = 0;
        _targetIndex = 0;
        _isAnimatingCard = false;
        _cardTransitionController.value = 0;
        _currentCaptionValue = frames.first.captionValue;
        _previousCaptionValue = _currentCaptionValue;
        _currentCaptionType = frames.first.captionType;
        _maxCaptionDigits = digitCount;
      });
      _startPlayback();
      _logPlaybackStart(frames.length);
    }
    return frames;
  }

  Future<_TimelineFrame> _buildFrame(FacesTimelineEntry entry) async {
    final file = await FilesDB.instance.getAnyUploadedFile(entry.fileId);
    MemoryImage? image;
    if (file != null) {
      final faces = await MLDataDB.instance.getFacesForGivenFileID(
        entry.fileId,
      );
      final Face? face = faces?.firstWhereOrNull(
        (element) => element.faceID == entry.faceId,
      );
      if (face != null) {
        try {
          final cropMap = await getCachedFaceCrops(
            file,
            [face],
            useFullFile: true,
            personOrClusterID: widget.person.remoteID,
            useTempCache: false,
          );
          final Uint8List? bytes = cropMap?[face.faceID];
          if (bytes != null && bytes.isNotEmpty) {
            image = MemoryImage(bytes);
          }
        } catch (error, stackTrace) {
          _logger.warning(
            "Failed to fetch face crop for ${entry.faceId}",
            error,
            stackTrace,
          );
        }
      }
    }
    final creationDate = DateTime.fromMicrosecondsSinceEpoch(
      entry.creationTimeMicros,
    );
    final captionType = widget.person.data.birthDate != null
        ? _CaptionType.age
        : _CaptionType.yearsAgo;
    double captionValue;
    if (captionType == _CaptionType.age) {
      final birthDateString = widget.person.data.birthDate!;
      final birthDate = DateTime.tryParse(birthDateString);
      if (birthDate == null) {
        captionValue = _yearsBetween(creationDate, DateTime.now());
      } else {
        captionValue = _yearsBetween(birthDate, creationDate);
      }
    } else {
      captionValue = _yearsBetween(creationDate, DateTime.now());
    }
    captionValue = captionValue.clamp(0, double.infinity);
    return _TimelineFrame(
      entry: entry,
      image: image,
      creationDate: creationDate,
      captionType: captionType,
      captionValue: captionValue,
    );
  }

  void _scheduleCardGapUpdate(double candidateGap) {
    if ((_cardGap - candidateGap).abs() <= _cardGapUpdateTolerance) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if ((_cardGap - candidateGap).abs() <= _cardGapUpdateTolerance) {
        return;
      }
      setState(() {
        _cardGap = candidateGap;
      });
    });
  }

  void _scheduleControlsHeightUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final context = _controlsKey.currentContext;
      if (context == null) {
        return;
      }
      final Size? size = context.size;
      if (size == null) {
        return;
      }
      final double height = size.height;
      if ((_controlsHeight - height).abs() <= _controlsHeightUpdateTolerance) {
        return;
      }
      setState(() {
        _controlsHeight = height;
      });
    });
  }

  void _logPlaybackStart(int frameCount) {
    if (_loggedPlaybackStart) return;
    _logger.info(
      "playback_start person=${widget.person.remoteID} frames=$frameCount",
    );
    _loggedPlaybackStart = true;
  }

  void _startPlayback() {
    _playTimer?.cancel();
    if (_frames.isEmpty) return;
    _playTimer = Timer.periodic(_frameInterval, (_) {
      if (!mounted || !_isPlaying || _frames.isEmpty) return;
      _showNextFrame();
    });
    setState(() {
      _isPlaying = true;
    });
  }

  void _pausePlayback() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _showNextFrame() {
    if (_frames.isEmpty || _isAnimatingCard) return;
    if (_currentIndex >= _frames.length - 1) {
      _pausePlayback();
      return;
    }
    final nextIndex = _currentIndex + 1;
    _setCurrentFrame(nextIndex);
  }

  void _setCurrentFrame(int index) {
    _animateToIndex(index);
  }

  void _animateToIndex(int index) {
    if (_frames.isEmpty) {
      return;
    }
    final clamped = index.clamp(0, _frames.length - 1);
    final targetProgress = clamped.toDouble();
    if (!_isAnimatingCard && clamped == _currentIndex) {
      setState(() {
        _sliderValue = targetProgress;
      });
      return;
    }

    if (_isAnimatingCard && _targetIndex == clamped) {
      return;
    }

    _animationStartProgress = _stackProgress;
    _targetIndex = clamped;
    _isAnimatingCard = true;
    final distance = (targetProgress - _animationStartProgress).abs();
    final multiplier = distance.clamp(1.0, 4.0);
    _cardTransitionController.duration = Duration(
      milliseconds:
          (_cardTransitionDuration.inMilliseconds * multiplier).round(),
    );
    _cardTransitionController
      ..reset()
      ..forward();
    setState(() {
      _sliderValue = targetProgress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkThemeData,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final title = l10n.facesTimelineAppBarTitle;
          final colorScheme = getEnteColorScheme(context);
          final textTheme = getEnteTextTheme(context);
          final titleStyle = textTheme.h2Bold.copyWith(
            letterSpacing: -2,
          );
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: _facesTimelineBackgroundGradient,
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: colorScheme.textBase,
                title: Text(
                  title,
                  style: titleStyle,
                ),
              ),
              body: FutureBuilder<List<_TimelineFrame>>(
                future: _framesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary500,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    _logger.severe(
                      "Faces timeline failed to load",
                      snapshot.error,
                      snapshot.stackTrace,
                    );
                    return Center(
                      child: Text(
                        l10n.facesTimelineUnavailable,
                        style: textTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final frames = snapshot.data ?? [];
                  if (frames.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.facesTimelineUnavailable,
                        style: textTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final viewPadding = MediaQuery.of(context).viewPadding;
                      final double bottomInset = viewPadding.bottom;
                      final double bottomPadding = math.max(12, bottomInset);
                      const double topPadding = 12;
                      final double gapToTop = _cardGap + topPadding;
                      const double desiredGap = _controlsDesiredGapToCard;
                      final double overlap = math.max(0, gapToTop - desiredGap);
                      final double controlsHeight = _controlsHeight > 0
                          ? _controlsHeight
                          : _controlsHeightFallback;
                      final double reservedHeight =
                          topPadding + bottomPadding + controlsHeight;
                      final Widget controlsContent = KeyedSubtree(
                        key: _controlsKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCaption(context),
                            const SizedBox(height: 16),
                            _buildControls(context),
                          ],
                        ),
                      );
                      _scheduleControlsHeightUpdate();
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: _buildFrameView(context),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: reservedHeight),
                            ],
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: bottomPadding + overlap,
                            child: controlsContent,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameView(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    if (_frames.isEmpty) {
      return Center(
        key: const ValueKey<String>("faces_timeline_empty"),
        child: FractionallySizedBox(
          widthFactor: _frameWidthFactor,
          heightFactor: _frameHeightFactor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated,
              borderRadius: BorderRadius.circular(28),
              boxShadow: (Theme.of(context).brightness == Brightness.dark)
                  ? shadowFloatDark
                  : shadowFloatLight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ColoredBox(
                color: colorScheme.backgroundElevated2,
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 72,
                    color: colorScheme.strokeMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final stackProgress = _stackProgress.clamp(
      0.0,
      (_frames.length - 1).toDouble(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<_CardSlice> slices = [];
    final startIndex = math.max(0, stackProgress.floor() - 3);
    final endIndex = math.min(_frames.length - 1, stackProgress.ceil() + 4);

    for (int i = startIndex; i <= endIndex; i++) {
      final distance = i - stackProgress;
      if (distance < -4.5 || distance > 5.5) {
        continue;
      }
      slices.add(_CardSlice(index: i, distance: distance));
    }

    final futureSlices = slices.where((slice) => slice.distance >= 0).toList()
      ..sort(
        (a, b) => b.distance.compareTo(a.distance),
      );
    final presentAndPastSlices =
        slices.where((slice) => slice.distance < 0).toList()
          ..sort(
            (a, b) => a.distance.compareTo(b.distance),
          );

    return Center(
      child: FractionallySizedBox(
        widthFactor: _frameWidthFactor,
        heightFactor: _frameHeightFactor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : constraints.biggest.height;
            if (cardHeight > 0) {
              final double parentHeight = cardHeight / _frameHeightFactor;
              final double gap = math.max(0, (parentHeight - cardHeight) / 2);
              _scheduleCardGapUpdate(gap);
            }
            final orderedSlices = <_CardSlice>[
              ...futureSlices,
              ...presentAndPastSlices,
            ];
            final children = orderedSlices.isEmpty
                ? [
                    _FacesTimelineCard(
                      key: ValueKey<int>(_currentIndex),
                      frame: _frames[_currentIndex],
                      distance: 0,
                      isDarkMode: isDark,
                      colorScheme: colorScheme,
                      cardHeight: cardHeight,
                      blurEnabled: !_isScrubbing,
                    ),
                  ]
                : orderedSlices
                    .map(
                      (slice) => _FacesTimelineCard(
                        key: ValueKey<int>(slice.index),
                        frame: _frames[slice.index],
                        distance: slice.distance,
                        isDarkMode: isDark,
                        colorScheme: colorScheme,
                        cardHeight: cardHeight,
                        blurEnabled: !_isScrubbing,
                      ),
                    )
                    .toList();
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: children,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;
    final captionType = _currentCaptionType;
    final isPlaying = _isPlaying;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final localeName = l10n.localeName;
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final int currentRounded =
        _currentCaptionValue.round().clamp(0, 1000).toInt();
    final int previousRounded =
        _previousCaptionValue.round().clamp(0, 1000).toInt();
    final TextStyle baseStyle = textTheme.bodyMuted.copyWith(
      color: isDark
          ? colorScheme.textMuted
          : colorScheme.textBase.withValues(alpha: 0.72),
    );
    final TextStyle numberStyle = textTheme.body.copyWith(
      color: colorScheme.fillBase,
      fontWeight: FontWeight.w600,
    );
    final int digits = math.max(3, _maxCaptionDigits);
    final int slotSampleValue = _maxValueForDigits(digits);
    final String sampleString = numberFormat.format(slotSampleValue);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextPainter samplePainter = TextPainter(
      text: TextSpan(text: sampleString, style: numberStyle),
      textDirection: ui.TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final double slotWidth = samplePainter.width;
    final double slotHeight = samplePainter.height;
    final String formattedCurrent = numberFormat.format(currentRounded);
    final String fullText = captionType == _CaptionType.age
        ? l10n.facesTimelineCaptionYearsOld(
            name: widget.person.data.name,
            count: currentRounded,
          )
        : l10n.facesTimelineCaptionYearsAgo(count: currentRounded);
    final int insertionIndex = fullText.indexOf(formattedCurrent);
    final InlineSpan captionSpan;
    if (insertionIndex == -1) {
      captionSpan = TextSpan(
        text: fullText,
        style: baseStyle,
      );
    } else {
      final String prefix = fullText.substring(0, insertionIndex);
      final String suffix = fullText.substring(
        insertionIndex + formattedCurrent.length,
      );
      captionSpan = TextSpan(
        children: [
          TextSpan(text: prefix, style: baseStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(
              width: slotWidth,
              height: slotHeight,
              child: Center(
                child: _RollingCounter(
                  value: currentRounded,
                  previousValue: previousRounded,
                  textStyle: numberStyle,
                  numberFormat: numberFormat,
                ),
              ),
            ),
          ),
          TextSpan(text: suffix, style: baseStyle),
        ],
      );
    }
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: isPlaying
                ? l10n.facesTimelinePlaybackPause
                : l10n.facesTimelinePlaybackPlay,
            child: IconButton(
              onPressed: _frames.isEmpty ? null : _togglePlayback,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.fillFaint,
                foregroundColor: isDark
                    ? colorScheme.textMuted
                    : colorScheme.textBase.withValues(alpha: 0.72),
                minimumSize: const Size(40, 40),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: captionSpan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final frameCount = _frames.length;
    final maxValue = frameCount > 1 ? (frameCount - 1).toDouble() : 0.0;
    final sliderValue =
        frameCount > 1 ? _sliderValue.clamp(0.0, maxValue) : 0.0;
    final Color activeTrackColor = Colors.white;
    final Color inactiveTrackColor =
        (isDark ? colorScheme.fillBaseGrey : colorScheme.strokeMuted)
            .withOpacity(isDark ? 0.55 : 0.48);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: inactiveTrackColor,
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const _FacesTimelineSliderThumbShape(),
          ),
          child: Slider(
            value: sliderValue.toDouble(),
            min: 0.0,
            max: frameCount > 1 ? maxValue : 0.0,
            divisions: frameCount > 1 ? (frameCount - 1) * 4 : null,
            onChangeStart: frameCount > 1
                ? (value) {
                    _pausePlayback();
                    _isAnimatingCard = false;
                    _cardTransitionController.stop();
                    setState(() {
                      _isScrubbing = true;
                    });
                  }
                : null,
            onChanged: frameCount > 1
                ? (value) {
                    final clamped = value.clamp(0.0, maxValue);
                    setState(() {
                      _sliderValue = clamped;
                      _stackProgress = clamped;
                      _currentIndex = clamped.round().clamp(0, frameCount - 1);
                      final frame = _frames[_currentIndex];
                      _previousCaptionValue = _currentCaptionValue;
                      _currentCaptionValue = frame.captionValue;
                      _currentCaptionType = frame.captionType;
                      _isScrubbing = true;
                    });
                  }
                : null,
            onChangeEnd: frameCount > 1
                ? (value) {
                    final target =
                        value.round().clamp(0, frameCount - 1).toInt();
                    setState(() {
                      _currentIndex = target;
                      _sliderValue = target.toDouble();
                      _stackProgress = _sliderValue;
                      _isScrubbing = false;
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }

  void _togglePlayback() {
    if (_frames.isEmpty) {
      return;
    }
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _resumeAutoPlay();
    }
  }

  void _resumeAutoPlay() {
    if (_frames.isEmpty) {
      return;
    }
    if (_currentIndex >= _frames.length - 1) {
      _setCurrentFrame(0);
    }
    _startPlayback();
  }

  void _onCardAnimationTick() {
    if (!_cardTransitionController.isAnimating && !_isAnimatingCard) {
      return;
    }
    final eased =
        Curves.easeInOutCubic.transform(_cardTransitionController.value);
    final progress = ui.lerpDouble(
      _animationStartProgress,
      _targetIndex.toDouble(),
      eased,
    );
    if (progress == null) {
      return;
    }
    setState(() {
      _stackProgress = progress;
    });
  }

  void _onCardAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    if (_frames.isEmpty) {
      setState(() {
        _isAnimatingCard = false;
        _stackProgress = 0;
      });
      return;
    }
    final clampedIndex = _targetIndex.clamp(0, _frames.length - 1);
    setState(() {
      _isAnimatingCard = false;
      _currentIndex = clampedIndex;
      _stackProgress = clampedIndex.toDouble();
      final frame = _frames[clampedIndex];
      _previousCaptionValue = _currentCaptionValue;
      _currentCaptionValue = frame.captionValue;
      _currentCaptionType = frame.captionType;
      _sliderValue = clampedIndex.toDouble();
    });
  }
}

class _TimelineFrame {
  final FacesTimelineEntry entry;
  final MemoryImage? image;
  final DateTime creationDate;
  final _CaptionType captionType;
  final double captionValue;

  _TimelineFrame({
    required this.entry,
    required this.image,
    required this.creationDate,
    required this.captionType,
    required this.captionValue,
  });
}

class _CardSlice {
  final int index;
  final double distance;

  const _CardSlice({
    required this.index,
    required this.distance,
  });
}

class _FacesTimelineCard extends StatelessWidget {
  static const double _cardRadius = 28;

  final _TimelineFrame frame;
  final double distance;
  final bool isDarkMode;
  final EnteColorScheme colorScheme;
  final double cardHeight;
  final bool blurEnabled;

  const _FacesTimelineCard({
    required this.frame,
    required this.distance,
    required this.isDarkMode,
    required this.colorScheme,
    required this.cardHeight,
    required this.blurEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _calculateScale(distance);
    final yOffset = _calculateYOffset(distance);
    final opacity = _calculateOpacity(distance);
    final blurSigma = blurEnabled ? _calculateBlur(distance) : 0.0;
    final rotation = _calculateRotation(distance);
    final overlayOpacity =
        distance > 0 ? math.min(0.45, 0.12 + distance * 0.12) : 0.0;

    final cardShadow = _shadowForCard(distance);
    // Emphasize the active card by delaying the date reveal until the card is
    // nearly centered; keeps background cards calm while the primary one lifts.
    final double emphasisDistance = distance.abs();
    final double activation =
        (1 - (emphasisDistance * 1.8)).clamp(0.0, 1.0); // hide until near front
    final double emphasis = Curves.easeOutQuad.transform(activation);
    final double dateOpacity = emphasis;
    final double gradientAlpha = 0.6 * emphasis;
    final double textShadowAlpha = 0.5 * emphasis;
    final double dateYOffset = ui.lerpDouble(28, 0, emphasis) ?? 0;
    final double dateScale = ui.lerpDouble(0.94, 1, emphasis) ?? 1;
    final String localeTag = Localizations.localeOf(context).toLanguageTag();
    final String formattedDate = DateFormat(
      "d MMM yyyy",
      localeTag,
    ).format(frame.creationDate.toLocal());
    final textTheme = getEnteTextTheme(context);

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(blurSigma),
          if (overlayOpacity > 0)
            Container(
              color:
                  colorScheme.backgroundBase.withValues(alpha: overlayOpacity),
            ),
          if (frame.image == null)
            Center(
              child: Icon(
                Icons.person_outline,
                size: 72,
                color: colorScheme.strokeMuted,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: dateOpacity,
              child: Transform.translate(
                offset: Offset(0, dateYOffset),
                child: Transform.scale(
                  scale: dateScale,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.backgroundBase.withValues(
                            alpha: gradientAlpha,
                          ),
                          colorScheme.backgroundBase.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                    child: Text(
                      formattedDate,
                      textAlign: TextAlign.center,
                      style: textTheme.smallMuted.copyWith(
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(textShadowAlpha),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_cardRadius),
                    boxShadow: cardShadow,
                  ),
                  child: cardContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double blurSigma) {
    final Widget base = frame.image != null
        ? Image(
            image: frame.image!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          )
        : ColoredBox(
            color: colorScheme.backgroundElevated2,
          );
    if (blurSigma <= 0) {
      return base;
    }
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
      ),
      child: base,
    );
  }

  List<BoxShadow> _shadowForCard(double distance) {
    final double baseOpacity = isDarkMode ? 0.55 : 0.3;
    if (distance > 0) {
      return [
        BoxShadow(
          color: Colors.black
              .withValues(alpha: math.max(0.0, baseOpacity - distance * 0.12)),
          blurRadius: 38,
          offset: const Offset(0, 26),
          spreadRadius: -6,
        ),
      ];
    }
    final dampening = math.max(0.2, 1 - distance.abs() * 0.25);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: baseOpacity * dampening),
        blurRadius: 34,
        offset: const Offset(0, 24),
        spreadRadius: -12,
      ),
    ];
  }

  double _calculateScale(double distance) {
    if (distance >= 0) {
      return math.max(0.84, 1.0 - distance * 0.05);
    }
    final falling = 1.0 - distance.abs() * 0.02;
    return falling.clamp(0.82, 1.02);
  }

  double _calculateYOffset(double distance) {
    if (distance >= 0) {
      final compression = math.pow(0.72, distance).toDouble();
      return -cardHeight * 0.14 * distance * compression;
    }
    final downward = distance.abs();
    final easedComponent = math.pow(downward, 1.45).toDouble();
    final travel = downward * (2.8 + 1.8 * downward);
    return cardHeight * (travel + easedComponent * 0.65);
  }

  double _calculateBlur(double distance) {
    if (distance <= 0) {
      return 0;
    }
    return math.min(20, (distance + 0.3) * 6);
  }

  double _calculateRotation(double distance) {
    if (distance <= 0) {
      return 0;
    }
    final clamped = distance.clamp(0.0, 3.0);
    const double base = 0.035; // ~2 degrees
    final falloff = math.max(0.2, 1 - clamped * 0.18);
    return base * clamped * falloff;
  }

  double _calculateOpacity(double distance) {
    if (distance >= 0) {
      return math.max(0.35, 1 - distance * 0.22);
    }
    final drop = distance.abs();
    const fadeStart = 0.9;
    if (drop <= fadeStart) {
      return 1.0;
    }
    const double fadeRange = 0.55;
    final t = ((drop - fadeStart) / fadeRange).clamp(0.0, 1.0);
    return math.max(0.0, 1.0 - t);
  }
}

enum _CaptionType { age, yearsAgo }

double _yearsBetween(DateTime start, DateTime end) {
  final days = end.difference(start).inDays;
  return days / 365.25;
}

class _FacesTimelineSliderThumbShape extends SliderComponentShape {
  const _FacesTimelineSliderThumbShape();

  static const double _thumbRadius = 12;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_thumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required ui.TextDirection textDirection,
    required double textScaleFactor,
    required double value,
    required Size sizeWithOverflow,
  }) {
    final Color color =
        sliderTheme.thumbColor ?? sliderTheme.activeTrackColor ?? Colors.white;
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(0, 1), _thumbRadius, shadowPaint);
    final paint = Paint()..color = color;
    canvas.drawCircle(center, _thumbRadius, paint);
  }
}

class _RollingCounter extends StatelessWidget {
  const _RollingCounter({
    required this.value,
    required this.previousValue,
    required this.textStyle,
    required this.numberFormat,
  });

  final int value;
  final int previousValue;
  final TextStyle textStyle;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final ValueKey<int> currentKey = ValueKey<int>(value);
    final double direction = value >= previousValue ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) {
        final bool isCurrent = child.key == currentKey;
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: isCurrent ? Curves.easeOutCubic : Curves.easeInCubic,
        );
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            if (child == null) {
              return const SizedBox.shrink();
            }
            final double progress = isCurrent ? curved.value : 1 - curved.value;
            final double offsetY =
                isCurrent ? direction * (1 - progress) : -direction * progress;
            return ClipRect(
              child: FractionalTranslation(
                translation: Offset(0, offsetY),
                child: child,
              ),
            );
          },
        );
      },
      child: Align(
        key: currentKey,
        alignment: Alignment.center,
        child: Text(
          numberFormat.format(value),
          style: textStyle,
        ),
      ),
    );
  }
}

int _maxValueForDigits(int digits) {
  if (digits <= 0) {
    return 0;
  }
  int value = 0;
  for (int i = 0; i < digits; i++) {
    value = (value * 10) + 9;
  }
  return value;
}
