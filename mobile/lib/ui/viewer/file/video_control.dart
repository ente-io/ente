// ignore_for_file: implementation_imports

import 'dart:async';

import "package:chewie/chewie.dart";
import "package:chewie/src/helpers/utils.dart";
import "package:chewie/src/notifiers/index.dart";
import 'package:flutter/material.dart';
import "package:photos/models/file/file.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/preview_status_widget.dart";
import "package:photos/ui/viewer/file/video_control/custom_progress_bar.dart";
import 'package:provider/provider.dart';
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

class _VideoControlsState extends State<VideoControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          Center(
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
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (_displayBufferingIndicator)
                _chewieController?.bufferingBuilder?.call(context) ??
                    const Center(
                      child: EnteLoadingWidget(
                        size: 32,
                        color: fillBaseDark,
                        padding: 0,
                      ),
                    )
              else
                _buildHitArea(),
              SafeArea(
                top: false,
                left: false,
                right: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    PreviewStatusWidget(
                      showControls: !notifier.hideStuff,
                      file: widget.file,
                      isPreviewPlayer: true,
                      onStreamChange: widget.onStreamChange,
                    ),
                    if (!chewieController.isLive) _buildBottomBar(context),
                  ],
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
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 60),
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
              Text(
                formatDuration(_latestValue.position),
                style: getEnteTextTheme(
                  context,
                ).mini.copyWith(
                      color: textBaseDark,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(),
              ),
              const SizedBox(width: 16),
              Text(
                formatDuration(
                  _latestValue.duration,
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
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;
    final bool showPlayButton = true && !_dragging && !notifier.hideStuff;

    return GestureDetector(
      onTap: () {
        if (_latestValue.isPlaying) {
          if (_displayTapped) {
            setState(() {
              notifier.hideStuff = true;
            });
          } else {
            _cancelAndRestartTimer();
          }
        } else {
          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
        }
        widget.playbackCallback?.call(notifier.hideStuff);
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors
            .transparent, // The Gesture Detector doesn't expand to the full size of the container without this; Not sure why!
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: marginSize,
              ),
              child: CenterPlayButton(
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                isFinished: isFinished,
                isPlaying: controller.value.isPlaying,
                show: showPlayButton,
                onPressed: _playPause,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
    widget.playbackCallback?.call(notifier.hideStuff);
  }

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
        widget.playbackCallback?.call(notifier.hideStuff);
      });
    }
  }

  void _playPause() {
    final bool isFinished = (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        widget.playbackCallback?.call(notifier.hideStuff);
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
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
        widget.playbackCallback?.call(notifier.hideStuff);
      });
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
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

  Widget _buildProgressBar() {
    final colorScheme = getEnteColorScheme(context);
    return Expanded(
      child: CustomProgressBar(
        controller,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragUpdate: () {
          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });

          _startHideTimer();
        },
        colors: ChewieProgressColors(
          playedColor: colorScheme.primary300,
          handleColor: backgroundElevatedLight,
          bufferedColor: backgroundElevatedLight.withOpacity(0.5),
          backgroundColor: fillMutedDark,
        ),
        draggableProgressBar: chewieController.draggableProgressBar,
      ),
    );
  }
}

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    super.key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  });

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying;
  final bool isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
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
          onTap: onPressed,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            switchInCurve: Curves.easeInOutQuart,
            switchOutCurve: Curves.easeInOutQuart,
            child: isPlaying
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
      ),
    );
  }
}
