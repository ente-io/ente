import "dart:async";

import "package:flutter/material.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:photos/models/file/file.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/preview_status_widget.dart";
import "package:photos/utils/standalone/date_time.dart";
import "package:photos/utils/standalone/debouncer.dart";

class VideoWidget extends StatefulWidget {
  final EnteFile file;
  final VideoController controller;
  final Function(bool)? playbackCallback;
  final bool isFromMemories;
  final void Function() onStreamChange;
  final bool isPreviewPlayer;

  const VideoWidget(
    this.file,
    this.controller,
    this.playbackCallback, {
    super.key,
    required this.isFromMemories,
    // ignore: unused_element
    required this.onStreamChange,
    required this.isPreviewPlayer,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final showControlsNotifier = ValueNotifier<bool>(true);
  static const double verticalMargin = 64;
  final _hideControlsDebouncer = Debouncer(
    const Duration(milliseconds: 2000),
  );
  final _isSeekingNotifier = ValueNotifier<bool>(false);
  late final StreamSubscription<bool> _isPlayingStreamSubscription;

  @override
  void initState() {
    super.initState();
    _isPlayingStreamSubscription =
        widget.controller.player.stream.playing.listen((isPlaying) {
      if (isPlaying && !_isSeekingNotifier.value) {
        _hideControlsDebouncer.run(() async {
          showControlsNotifier.value = false;
          widget.playbackCallback?.call(true);
        });
      }
    });

    _isSeekingNotifier.addListener(isSeekingListener);
  }

  @override
  void dispose() {
    showControlsNotifier.dispose();
    _isPlayingStreamSubscription.cancel();
    _hideControlsDebouncer.cancelDebounceTimer();
    _isSeekingNotifier.removeListener(isSeekingListener);
    _isSeekingNotifier.dispose();
    super.dispose();
  }

  void isSeekingListener() {
    if (_isSeekingNotifier.value) {
      _hideControlsDebouncer.cancelDebounceTimer();
    } else {
      if (widget.controller.player.state.playing) {
        _hideControlsDebouncer.run(() async {
          showControlsNotifier.value = false;
          widget.playbackCallback?.call(true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: widget.controller,
      controls: (state) {
        return ValueListenableBuilder(
          valueListenable: showControlsNotifier,
          builder: (context, value, _) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 1 : 0,
              curve: Curves.easeInOutQuad,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showControlsNotifier.value = !showControlsNotifier.value;
                      if (widget.playbackCallback != null) {
                        widget.playbackCallback!(
                          !showControlsNotifier.value,
                        );
                      }
                    },
                    child: Container(
                      constraints: const BoxConstraints.expand(),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: !value,
                    child: PlayPauseButtonMediaKit(widget.controller),
                  ),
                  Positioned(
                    bottom: verticalMargin,
                    right: 0,
                    left: 0,
                    child: IgnorePointer(
                      ignoring: !value,
                      child: SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: widget.isFromMemories ? 32 : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PreviewStatusWidget(
                                showControls: value,
                                file: widget.file,
                                isPreviewPlayer: widget.isPreviewPlayer,
                                onStreamChange: widget.onStreamChange,
                              ),
                              SeekBarAndDuration(
                                controller: widget.controller,
                                isSeekingNotifier: _isSeekingNotifier,
                                file: widget.file,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PlayPauseButtonMediaKit extends StatefulWidget {
  final VideoController? controller;
  const PlayPauseButtonMediaKit(
    this.controller, {
    super.key,
  });

  @override
  State<PlayPauseButtonMediaKit> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButtonMediaKit> {
  bool _isPlaying = true;
  late final StreamSubscription<bool>? isPlayingStreamSubscription;
  late StreamSubscription<bool>? _bufferStateSubscription;
  late var buffering = widget.controller?.player.state.buffering ?? true;

  @override
  void initState() {
    super.initState();

    isPlayingStreamSubscription =
        widget.controller?.player.stream.playing.listen((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    });

    _bufferStateSubscription =
        widget.controller?.player.stream.buffering.listen(
      (event) => setState(() => buffering = event),
    );
  }

  @override
  void dispose() {
    isPlayingStreamSubscription?.cancel();
    _bufferStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (buffering) return const EnteLoadingWidget();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.controller?.player.state.playing ?? false) {
          widget.controller?.player.pause();
        } else {
          widget.controller?.player.play();
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
}

class SeekBarAndDuration extends StatelessWidget {
  final VideoController? controller;
  final ValueNotifier<bool> isSeekingNotifier;
  final EnteFile file;

  const SeekBarAndDuration({
    super.key,
    required this.controller,
    required this.isSeekingNotifier,
    required this.file,
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
        child: Column(
          children: [
            file.caption != null && file.caption!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      8,
                      0,
                      12,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showDetailsSheet(context, file);
                      },
                      child: Text(
                        file.caption!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: getEnteTextTheme(context)
                            .mini
                            .copyWith(color: textBaseDark),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Row(
              children: [
                StreamBuilder(
                  stream: controller?.player.stream.position,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return Text(
                        "0:00",
                        style: getEnteTextTheme(
                          context,
                        ).mini.copyWith(
                              color: textBaseDark,
                            ),
                      );
                    }
                    return Text(
                      secondsToDuration(snapshot.data!.inSeconds),
                      style: getEnteTextTheme(
                        context,
                      ).mini.copyWith(
                            color: textBaseDark,
                          ),
                    );
                  },
                ),
                Expanded(
                  child: SeekBar(
                    controller!,
                    isSeekingNotifier,
                  ),
                ),
                Text(
                  _secondsToDuration(
                    controller!.player.state.duration.inSeconds,
                  ),
                  style: getEnteTextTheme(
                    context,
                  ).mini.copyWith(
                        color: textBaseDark,
                      ),
                ),
              ],
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

class SeekBar extends StatefulWidget {
  final VideoController controller;
  final ValueNotifier<bool> isSeekingNotifier;
  const SeekBar(
    this.controller,
    this.isSeekingNotifier, {
    super.key,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _sliderValue = 0.0;
  late final StreamSubscription<Duration> _positionStreamSubscription;
  final _debouncer = Debouncer(
    const Duration(milliseconds: 300),
    executionInterval: const Duration(milliseconds: 300),
  );
  @override
  void initState() {
    super.initState();
    _positionStreamSubscription =
        widget.controller.player.stream.position.listen((event) {
      if (widget.isSeekingNotifier.value) return;
      if (mounted) {
        setState(() {
          _sliderValue = event.inMilliseconds /
              widget.controller.player.state.duration.inMilliseconds;
          if (_sliderValue.isNaN) {
            _sliderValue = 0.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    _debouncer.cancelDebounceTimer();
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
        max: 1.0,
        value: _sliderValue,
        onChangeStart: (value) {
          if (mounted) {
            setState(() {
              widget.isSeekingNotifier.value = true;
            });
          }
        },
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _sliderValue = value;
            });
          }

          _debouncer.run(() async {
            await widget.controller.player.seek(
              Duration(
                milliseconds: (value *
                        widget.controller.player.state.duration.inMilliseconds)
                    .round(),
              ),
            );
          });
        },
        divisions: 4500,
        onChangeEnd: (value) async {
          await widget.controller.player.seek(
            Duration(
              milliseconds: (value *
                      widget.controller.player.state.duration.inMilliseconds)
                  .round(),
            ),
          );
          if (mounted) {
            setState(() {
              widget.isSeekingNotifier.value = false;
            });
          }
        },
        allowedInteraction: SliderInteraction.tapAndSlide,
      ),
    );
  }
}
