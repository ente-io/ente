import "package:flutter/material.dart";
import "package:native_video_player/native_video_player.dart";
import "package:photos/theme/colors.dart";

class PlayPauseButton extends StatefulWidget {
  final NativeVideoPlayerController? controller;
  const PlayPauseButton(this.controller, {super.key});

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    widget.controller?.onPlaybackStatusChanged
        .addListener(_onPlaybackStatusChanged);
  }

  _onPlaybackStatusChanged() {
    if (_playbackStatus == PlaybackStatus.playing) {
      setState(() {
        _isPlaying = true;
      });
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.onPlaybackStatusChanged
        .removeListener(_onPlaybackStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_playbackStatus == PlaybackStatus.playing) {
          widget.controller?.pause();
        } else {
          widget.controller?.play();
        }
      },
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          switchInCurve: Curves.easeInOutQuart,
          switchOutCurve: Curves.easeInOutQuart,
          child: _isPlaying
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

  PlaybackStatus? get _playbackStatus =>
      widget.controller?.playbackInfo?.status;
}
