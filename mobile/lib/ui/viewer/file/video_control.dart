import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import "package:photos/models/file/file.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/preview_status_widget.dart";
import "package:photos/utils/debouncer.dart";
import 'package:video_player/video_player.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.file,
    required this.onStreamChange,
    required this.playbackCallback,
  });
  final EnteFile file;
  final void Function()? onStreamChange;
  final void Function(bool)? playbackCallback;

  @override
  State<StatefulWidget> createState() {
    return _VideoControlsState();
  }
}

class _VideoControlsState extends State<VideoControls> {
  VideoPlayerValue? _latestValue;
  bool _hideStuff = true;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 120.0;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? chewieController;

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue!.hasError) {
      return chewieController!.errorBuilder != null
          ? chewieController!.errorBuilder!(
              context,
              chewieController!.videoPlayerController.value.errorDescription!,
            )
          : Center(
              child: Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.onSurface,
                size: 42,
              ),
            );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Stack(
            children: <Widget>[
              if (_latestValue != null &&
                      !_latestValue!.isPlaying &&
                      _latestValue!.isBuffering ||
                  _displayBufferingIndicator)
                const Align(
                  alignment: Alignment.center,
                  child: Center(
                    child: EnteLoadingWidget(
                      size: 32,
                      color: fillBaseDark,
                      padding: 0,
                    ),
                  ),
                )
              else
                Positioned.fill(child: _buildHitArea()),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PreviewStatusWidget(
                        showControls: !_hideStuff,
                        file: widget.file,
                        isPreviewPlayer: true,
                        onStreamChange: widget.onStreamChange,
                      ),
                      _buildBottomBar(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController!.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildBottomBar(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 60),
      height: 100,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: _SeekBarAndDuration(
          controller: controller,
          latestValue: _latestValue,
          updateDragging: (bool value) {
            setState(() {
              _dragging = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    return GestureDetector(
      onTap: () {
        if (_latestValue != null) {
          if (_displayTapped) {
            setState(() {
              _hideStuff = !_hideStuff;
            });
          } else {
            _cancelAndRestartTimer();
          }
        } else {
          _playPause();

          setState(() {
            _hideStuff = true;
          });
        }
        widget.playbackCallback?.call(_hideStuff);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _latestValue != null && !_hideStuff && !_dragging ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: _PlayPauseButton(
            _playPause,
            _latestValue!.isPlaying,
          ),
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
    widget.playbackCallback?.call(_hideStuff);
  }

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value.isPlaying) || chewieController!.autoPlay) {
      _startHideTimer();
    }

    if (chewieController!.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
        widget.playbackCallback?.call(_hideStuff);
      });
    }
  }

  void _playPause() {
    final bool isFinished = _latestValue!.position >= _latestValue!.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(const Duration(seconds: 0));
          }
          controller.play();
        }
      }
      widget.playbackCallback?.call(_hideStuff);
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _hideStuff = true;
      });
      widget.playbackCallback?.call(_hideStuff);
    });
  }

  void _updateState() {
    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController?.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController!.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.value.isBuffering;
    }
    setState(() {
      _latestValue = controller.value;
    });
  }
}

class _SeekBarAndDuration extends StatelessWidget {
  final VideoPlayerController? controller;
  final VideoPlayerValue? latestValue;
  final Function(bool) updateDragging;

  const _SeekBarAndDuration({
    required this.controller,
    required this.latestValue,
    required this.updateDragging,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          4,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
          border: Border.all(
            color: strokeFaintDark,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (latestValue?.position == null)
              Text(
                "0:00",
                style: getEnteTextTheme(
                  context,
                ).mini.copyWith(
                      color: textBaseDark,
                    ),
              )
            else
              Text(
                _secondsToDuration(latestValue!.position.inSeconds),
                style: getEnteTextTheme(
                  context,
                ).mini.copyWith(
                      color: textBaseDark,
                    ),
              ),
            Expanded(
              child: _SeekBar(controller!, updateDragging),
            ),
            Text(
              _secondsToDuration(
                latestValue?.duration.inSeconds ?? 0,
              ),
              style: getEnteTextTheme(
                context,
              ).mini.copyWith(
                    color: textBaseDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the duration in the format "h:mm:ss" or "m:ss".
  String _secondsToDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class _SeekBar extends StatefulWidget {
  final VideoPlayerController controller;
  final Function(bool) updateDragging;
  const _SeekBar(
    this.controller,
    this.updateDragging,
  );

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double _sliderValue = 0.0;
  final _debouncer = Debouncer(
    const Duration(milliseconds: 300),
    executionInterval: const Duration(milliseconds: 300),
  );
  bool _controllerWasPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(updateSlider);
  }

  void updateSlider() {
    if (widget.controller.value.isInitialized) {
      setState(() {
        _sliderValue = widget.controller.value.position.inSeconds.toDouble();
      });
    }
  }

  @override
  void dispose() {
    _debouncer.cancelDebounceTimer();
    widget.controller.removeListener(updateSlider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
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
        max: widget.controller.value.duration.inSeconds.toDouble(),
        value: _sliderValue,
        onChangeStart: (value) async {
          widget.updateDragging(true);
          _controllerWasPlaying = widget.controller.value.isPlaying;
          if (_controllerWasPlaying) {
            await widget.controller.pause();
          }
        },
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _sliderValue = value;
            });
          }

          _debouncer.run(() async {
            await widget.controller.seekTo(Duration(seconds: value.toInt()));
          });
        },
        divisions: 4500,
        onChangeEnd: (value) async {
          await widget.controller.seekTo(Duration(seconds: value.toInt()));

          if (_controllerWasPlaying) {
            await widget.controller.play();
          }
          widget.updateDragging(false);
        },
        allowedInteraction: SliderInteraction.tapAndSlide,
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final void Function() playPause;
  final bool isPlaying;
  const _PlayPauseButton(
    this.playPause,
    this.isPlaying,
  );

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: strokeFaintDark,
          width: 1,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.playPause,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          switchInCurve: Curves.easeInOutQuart,
          switchOutCurve: Curves.easeInOutQuart,
          child: widget.isPlaying
              ? const Icon(
                  Icons.pause,
                  size: 32,
                  key: ValueKey("pause"),
                  color: Colors.white,
                )
              : const Icon(
                  Icons.play_arrow,
                  size: 36,
                  key: ValueKey("play"),
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
