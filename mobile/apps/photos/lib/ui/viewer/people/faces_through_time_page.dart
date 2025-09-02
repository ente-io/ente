import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/models/faces_through_time/face_timeline.dart';
import 'package:photos/services/faces_through_time_service.dart';
import 'package:photos/services/faces_through_time_video_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';

class FacesThroughTimePage extends StatefulWidget {
  final String personId;
  final String personName;

  const FacesThroughTimePage({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<FacesThroughTimePage> createState() => _FacesThroughTimePageState();
}

class _FacesThroughTimePageState extends State<FacesThroughTimePage> {
  static const _slideshowInterval = Duration(seconds: 2);

  FaceTimeline? _timeline;
  int _currentIndex = 0;
  Timer? _autoAdvanceTimer;
  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    final service = FacesThroughTimeService();
    final timeline = await service.getTimeline(widget.personId);

    if (timeline != null && mounted) {
      setState(() {
        _timeline = timeline;
        _isLoading = false;
      });

      await service.markAsViewed(widget.personId);
      _startAutoAdvance();
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!_isPaused && _timeline != null) {
      _autoAdvanceTimer = Timer.periodic(_slideshowInterval, (_) {
        if (_currentIndex < _timeline!.entries.length - 1) {
          if (mounted) {
            setState(() {
              _currentIndex++;
            });
          }
        } else {
          _autoAdvanceTimer?.cancel();
        }
      });
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _autoAdvanceTimer?.cancel();
    } else {
      _startAutoAdvance();
    }
  }

  void _navigateTo(int index) {
    if (index >= 0 && index < _timeline!.entries.length) {
      setState(() {
        _currentIndex = index;
      });
      _startAutoAdvance();
    }
  }

  Future<void> _shareVideo() async {
    if (_timeline == null) return;

    setState(() {
      _isPaused = true;
    });
    _autoAdvanceTimer?.cancel();

    try {
      final videoService = FacesThroughTimeVideoService();
      await videoService.generateAndShareVideo(_timeline!.entries);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaused = false;
        });
        _startAutoAdvance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundElevated,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_timeline == null || _timeline!.entries.isEmpty) {
      return Scaffold(
        backgroundColor: theme.backgroundElevated,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No timeline available',
            style: TextStyle(color: theme.textMuted),
          ),
        ),
      );
    }

    final currentEntry = _timeline!.entries[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          final tapX = details.globalPosition.dx;

          if (tapX < width * 0.3) {
            // Tap on left - previous
            _navigateTo(_currentIndex - 1);
          } else if (tapX > width * 0.7) {
            // Tap on right - next
            _navigateTo(_currentIndex + 1);
          } else {
            // Tap in center - pause/resume
            _togglePause();
          }
        },
        onLongPressStart: (_) {
          setState(() {
            _isPaused = true;
          });
          _autoAdvanceTimer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPaused = false;
          });
          _startAutoAdvance();
        },
        child: Stack(
          children: [
            // Face display - placeholder for now
            Center(
              child: currentEntry.hasThumbnail && currentEntry.thumbnail != null
                  ? Image.memory(
                      currentEntry.thumbnail!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.fillFaint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: theme.textMuted,
                      ),
                    ),
            ),

            // Top controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButtonWidget(
                    icon: Icons.close,
                    iconButtonType: IconButtonType.primary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  IconButtonWidget(
                    icon: Icons.share,
                    iconButtonType: IconButtonType.primary,
                    onTap: _shareVideo,
                  ),
                ],
              ),
            ),

            // Bottom info
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    currentEntry.displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Progress indicator
            Positioned(
              bottom: 50,
              left: 24,
              right: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _timeline!.entries.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            ),

            // Pause indicator
            if (_isPaused)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

            // Navigation hints (subtle)
            if (_currentIndex > 0)
              const Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.white30,
                    size: 32,
                  ),
                ),
              ),
            if (_currentIndex < _timeline!.entries.length - 1)
              const Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white30,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}