import "package:flutter/material.dart";
import "package:native_video_player/native_video_player.dart";
import "package:photos/theme/ente_theme.dart";

class PlayPauseButton extends StatefulWidget {
  final NativeVideoPlayerController? controller;
  const PlayPauseButton(this.controller, {super.key});

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  bool _isPlaying = true;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_playbackStatus == PlaybackStatus.playing) {
          widget.controller?.pause();
          setState(() {
            _isPlaying = false;
          });
        } else {
          widget.controller?.play();
          setState(() {
            _isPlaying = true;
          });
        }
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: getEnteColorScheme(context).strokeFaint,
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
                )
              : const Icon(
                  Icons.play_arrow,
                  size: 36,
                  key: ValueKey("play"),
                ),
        ),
      ),
    );
  }

  PlaybackStatus? get _playbackStatus =>
      widget.controller?.playbackInfo?.status;
}
