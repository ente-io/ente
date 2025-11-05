import "dart:async";
import "dart:math" as math;
import "dart:typed_data";
import "dart:ui";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
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

class _FacesTimelinePageState extends State<FacesTimelinePage>
    with TickerProviderStateMixin {
  static const _frameInterval = Duration(milliseconds: 800);
  static const _cardTransitionDuration = Duration(milliseconds: 520);

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
  bool _isScrubbing = false;
  double _sliderValue = 0;
  double _previousCaptionValue = 0;
  double _currentCaptionValue = 0;
  _CaptionType _currentCaptionType = _CaptionType.yearsAgo;

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

  void _onSharePressed(BuildContext context) {
    _logger.info("share_attempt person=${widget.person.remoteID}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.facesTimelineShareComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkThemeData,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final title = l10n.facesTimelineAppBarTitle(
            name: widget.person.data.name,
          );
          final colorScheme = getEnteColorScheme(context);
          final textTheme = getEnteTextTheme(context);
          return Scaffold(
            backgroundColor: colorScheme.backgroundBase,
            appBar: AppBar(
              backgroundColor: colorScheme.backgroundBase,
              foregroundColor: colorScheme.textBase,
              title: Text(title),
              actions: [
                IconButton(
                  onPressed: () => _onSharePressed(context),
                  icon: const Icon(Icons.ios_share),
                  tooltip: l10n.facesTimelineShareComingSoon,
                ),
              ],
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
                final displayIndex =
                    _stackProgress.round().clamp(0, frames.length - 1);
                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildFrameView(context),
                          ),
                          Positioned(
                            top: 24,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.fillFaint,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _frames[displayIndex].entry.year.toString(),
                                  style: getEnteTextTheme(context).bodyMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          _buildCaption(context),
                          const SizedBox(height: 20),
                          _buildControls(context),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
          widthFactor: 0.82,
          heightFactor: 0.78,
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
        widthFactor: 0.82,
        heightFactor: 0.78,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : constraints.biggest.height;
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
    final textTheme = getEnteTextTheme(context);
    final captionType = _currentCaptionType;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(_currentIndex),
      tween: Tween<double>(
        begin: _previousCaptionValue,
        end: _currentCaptionValue,
      ),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        final rounded = value.round().clamp(0, 1000);
        final text = captionType == _CaptionType.age
            ? context.l10n.facesTimelineCaptionYearsOld(
                name: widget.person.data.name,
                count: rounded,
              )
            : context.l10n.facesTimelineCaptionYearsAgo(count: rounded);
        return Text(text, style: textTheme.body, textAlign: TextAlign.center);
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final frameCount = _frames.length;
    final maxValue = frameCount > 1 ? (frameCount - 1).toDouble() : 0.0;
    final sliderValue =
        frameCount > 1 ? _sliderValue.clamp(0.0, maxValue) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary500,
            thumbColor: colorScheme.primary500,
            inactiveTrackColor: colorScheme.fillMuted,
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
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: context.l10n.facesTimelinePlaybackPlay,
            child: TextButton.icon(
              onPressed: _frames.isEmpty || _isPlaying ? null : _resumeAutoPlay,
              icon: const Icon(Icons.play_arrow),
              label: Text(context.l10n.facesTimelinePlaybackPlay),
            ),
          ),
        ),
      ],
    );
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
    final progress = lerpDouble(
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
      imageFilter: ImageFilter.blur(
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
