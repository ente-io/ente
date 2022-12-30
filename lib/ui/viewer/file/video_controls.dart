

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:video_player/video_player.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({Key? key}) : super(key: key);

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

  final barHeight = 120.0;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? chewieController;

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
              Column(
                children: [
                  _latestValue != null &&
                              !_latestValue!.isPlaying &&
                              _latestValue!.duration == null ||
                          _latestValue!.isBuffering
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _buildHitArea(),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomBar(context),
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
    final iconColor = Theme.of(context).textTheme.button!.color;

    return Container(
      padding: const EdgeInsets.only(bottom: 60),
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          child: Row(
            children: <Widget>[
              _buildCurrentPosition(iconColor),
              chewieController!.isLive ? const SizedBox() : _buildProgressBar(),
              _buildTotalDuration(iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
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
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_hideStuff && !_dragging ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _playPause,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    _latestValue!.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, // same for both themes
                    size: 64.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPosition(Color? iconColor) {
    final position = _latestValue != null && _latestValue!.position != null
        ? _latestValue!.position
        : Duration.zero;

    return Container(
      margin: const EdgeInsets.only(left: 20.0, right: 16.0),
      child: Text(
        formatDuration(position),
        style: const TextStyle(
          fontSize: 12.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTotalDuration(Color? iconColor) {
    final duration = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Text(
        formatDuration(duration),
        style: const TextStyle(
          fontSize: 12.0,
          color: Colors.white,
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
  }

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController!.autoPlay) {
      _startHideTimer();
    }

    if (chewieController!.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
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
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController!.materialProgressColors ??
              ChewieProgressColors(
                playedColor: Theme.of(context).colorScheme.greenAlternative,
                handleColor: Colors.white,
                bufferedColor: Colors.white,
                backgroundColor: Theme.of(context).disabledColor,
              ),
        ),
      ),
    );
  }
}
