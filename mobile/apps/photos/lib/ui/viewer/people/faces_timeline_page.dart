import "dart:async";
import "dart:typed_data";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/faces_timeline/faces_timeline_models.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/faces_timeline/faces_timeline_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
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
      _frames
        ..clear()
        ..addAll(frames);
      _currentIndex = 0;
      _frameViewVersion = 0;
      _currentCaptionValue = frames.first.captionValue;
      _previousCaptionValue = _currentCaptionValue;
      _currentCaptionType = frames.first.captionType;
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

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _showNextFrame() {
    if (_frames.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _frames.length;
    _setCurrentFrame(nextIndex);
  }

  void _showPreviousFrame() {
    if (_frames.isEmpty) return;
    final previousIndex = (_currentIndex - 1 + _frames.length) % _frames.length;
    _setCurrentFrame(previousIndex);
  }

  void _setCurrentFrame(int index) {
    if (index < 0 || index >= _frames.length || index == _currentIndex) {
      return;
    }
    final frame = _frames[index];
    setState(() {
      _previousCaptionValue = _currentCaptionValue;
      _currentCaptionValue = frame.captionValue;
      _currentCaptionType = frame.captionType;
      _currentIndex = index;
      _frameViewVersion++;
    });
  }

  void _onSharePressed() {
    _logger.info("share_attempt person=${widget.person.remoteID}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.facesTimelineShareComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.facesTimelineAppBarTitle(
      name: widget.person.data.name,
    );
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _onSharePressed,
            icon: const Icon(Icons.ios_share),
            tooltip: context.l10n.facesTimelineShareComingSoon,
          ),
        ],
      ),
      body: FutureBuilder<List<_TimelineFrame>>(
        future: _framesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _logger.severe(
              "Faces timeline failed to load",
              snapshot.error,
              snapshot.stackTrace,
            );
            return Center(child: Text(context.l10n.facesTimelineUnavailable));
          }
          final frames = snapshot.data ?? [];
          if (frames.isEmpty) {
            return Center(child: Text(context.l10n.facesTimelineUnavailable));
          }
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: context.l10n.facesTimelinePlaybackPrevious,
          child: IconButtonWidget(
            icon: Icons.skip_previous,
            iconButtonType: IconButtonType.primary,
            onTap: _frames.isEmpty ? null : _showPreviousFrame,
            iconColor: colorScheme.strokeBase,
            defaultColor: colorScheme.fillFaint,
            pressedColor: colorScheme.fillMuted,
            size: 24,
            roundedIcon: true,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: _isPlaying
              ? context.l10n.facesTimelinePlaybackPause
              : context.l10n.facesTimelinePlaybackPlay,
          child: IconButtonWidget(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            iconButtonType: IconButtonType.primary,
            onTap: _frames.isEmpty ? null : _togglePlayback,
            iconColor: colorScheme.strokeBase,
            defaultColor: colorScheme.fillFaint,
            pressedColor: colorScheme.fillMuted,
            size: 28,
            roundedIcon: true,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: context.l10n.facesTimelinePlaybackNext,
          child: IconButtonWidget(
            icon: Icons.skip_next,
            iconButtonType: IconButtonType.primary,
            onTap: _frames.isEmpty ? null : _showNextFrame,
            iconColor: colorScheme.strokeBase,
            defaultColor: colorScheme.fillFaint,
            pressedColor: colorScheme.fillMuted,
            size: 24,
            roundedIcon: true,
          ),
        ),
      ],
    );
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
