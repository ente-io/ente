import "dart:async";

import "package:flutter/material.dart";
import "package:native_video_player/native_video_player.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/debouncer.dart";

class SeekBar extends StatefulWidget {
  final NativeVideoPlayerController controller;
  final int? duration;
  final ValueNotifier<bool> isSeeking;
  const SeekBar(this.controller, this.duration, this.isSeeking, {super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  double _prevPositionFraction = 0.0;
  final _debouncer = Debouncer(
    const Duration(milliseconds: 100),
    executionInterval: const Duration(milliseconds: 325),
  );
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      value: 0,
    );

    widget.controller.onPlaybackStatusChanged.addListener(
      _onPlaybackStatusChanged,
    );
    widget.controller.onPlaybackPositionChanged.addListener(
      _onPlaybackPositionChanged,
    );

    _startMovingSeekbar();
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.controller.onPlaybackStatusChanged.removeListener(
      _onPlaybackStatusChanged,
    );
    widget.controller.onPlaybackPositionChanged.removeListener(
      _onPlaybackPositionChanged,
    );
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 1.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: colorScheme.primary300,
            inactiveTrackColor: fillMutedDark,
            thumbColor: backgroundElevatedLight,
            overlayColor: fillMutedDark,
          ),
          child: Slider(
            min: 0.0,
            max: 1.0,
            value: _animationController.value,
            onChangeStart: (value) {
              widget.isSeeking.value = true;
            },
            onChanged: (value) {
              setState(() {
                _animationController.value = value;
              });
              _seekTo(value);
            },
            divisions: 4500,
            onChangeEnd: (value) {
              setState(() {
                _animationController.value = value;
              });
              _seekTo(value);
              widget.isSeeking.value = false;
            },
            allowedInteraction: SliderInteraction.tapAndSlide,
          ),
        );
      },
    );
  }

  void _seekTo(double value) {
    _debouncer.run(() async {
      unawaited(
        widget.controller.seekTo((value * widget.duration!).round()),
      );
    });
  }

  void _startMovingSeekbar() {
    //Video starts playing after a slight delay. This delay is to ensure that
    //the seek bar animation starts after the video starts playing.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (widget.duration != null) {
        unawaited(
          _animationController.animateTo(
            (1 / widget.duration!),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        unawaited(
          _animationController.animateTo(
            0,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _onPlaybackStatusChanged() {
    if (widget.controller.playbackInfo?.status == PlaybackStatus.paused) {
      _animationController.stop();
    }
  }

  void _onPlaybackPositionChanged() async {
    if (widget.controller.playbackInfo?.status == PlaybackStatus.paused) {
      return;
    }
    final target = widget.controller.playbackInfo?.positionFraction ?? 0;

    //To immediately set the position to 0 when the ends when playing in loop
    if (_prevPositionFraction == 1.0 && target == 0.0) {
      setState(() {
        _animationController.value = 0;
      });
    }

    //There is a slight delay (around 350 ms) for the event being listened to
    //by this listener on the next target (target that comes after 0). Adding
    //this buffer to keep the seek bar animation smooth.
    if (target == 0) {
      await Future.delayed(const Duration(milliseconds: 450));
    }

    if (widget.duration != null) {
      unawaited(
        _animationController.animateTo(
          target + (1 / widget.duration!),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      unawaited(
        _animationController.animateTo(
          target,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    _prevPositionFraction = target;
  }
}
