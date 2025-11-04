import "dart:async";
import "dart:typed_data";

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
  static const _frameInterval = Duration(milliseconds: 1000);

  final Logger _logger = Logger("FacesTimelinePage");
  int _frameViewVersion = 0;

  late Future<List<_TimelineFrame>> _framesFuture;
  final List<_TimelineFrame> _frames = [];

  Timer? _playTimer;
  bool _isPlaying = false;
  bool _loggedPlaybackStart = false;

  int _currentIndex = 0;
  double _sliderValue = 0;
  double _previousCaptionValue = 0;
  double _currentCaptionValue = 0;
  _CaptionType _currentCaptionType = _CaptionType.yearsAgo;

  @override
  void initState() {
    super.initState();
    _framesFuture = _loadFrames();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
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
        _frameViewVersion = 0;
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
    if (_frames.isEmpty) return;
    if (_currentIndex >= _frames.length - 1) {
      _pausePlayback();
      return;
    }
    final nextIndex = _currentIndex + 1;
    _setCurrentFrame(nextIndex);
  }

  void _setCurrentFrame(int index) {
    if (index < 0 || index >= _frames.length) {
      return;
    }
    final frame = _frames[index];
    setState(() {
      if (_currentIndex != index) {
        _previousCaptionValue = _currentCaptionValue;
        _currentCaptionValue = frame.captionValue;
        _currentCaptionType = frame.captionType;
        _currentIndex = index;
        _frameViewVersion++;
      }
      _sliderValue = index.toDouble();
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
                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AnimatedSwitcher(
                              duration: _isPlaying
                                  ? const Duration(milliseconds: 400)
                                  : Duration.zero,
                              reverseDuration: _isPlaying
                                  ? const Duration(milliseconds: 400)
                                  : Duration.zero,
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (child, animation) {
                                if (!_isPlaying) {
                                  return child;
                                }
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: _buildFrameView(colorScheme),
                            ),
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
                                  _frames[_currentIndex].entry.year.toString(),
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

  Widget _buildFrameView(EnteColorScheme colorScheme) {
    if (_frames.isEmpty) {
      return Container(color: colorScheme.backgroundBase);
    }
    final frame = _frames[_currentIndex];
    final key = ValueKey<int>(_frameViewVersion);
    if (frame.image != null) {
      return Container(
        key: key,
        color: colorScheme.backgroundBase,
        child: Image(
          image: frame.image!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
        ),
      );
    }
    return Container(
      key: key,
      color: colorScheme.backgroundElevated2,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 72,
        color: colorScheme.strokeMuted,
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
            divisions: frameCount > 1 ? frameCount - 1 : null,
            onChangeStart: frameCount > 1 ? (value) => _pausePlayback() : null,
            onChanged: frameCount > 1
                ? (value) {
                    final index =
                        value.round().clamp(0, frameCount - 1).toInt();
                    _setCurrentFrame(index);
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

enum _CaptionType { age, yearsAgo }

double _yearsBetween(DateTime start, DateTime end) {
  final days = end.difference(start).inDays;
  return days / 365.25;
}
