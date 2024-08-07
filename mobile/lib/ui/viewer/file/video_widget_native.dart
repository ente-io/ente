import "dart:async";
import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:native_video_player/native_video_player.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/file_swipe_lock_event.dart";
// import "package:photos/events/pause_video_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/files_service.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/toast_util.dart";

class VideoWidgetNative extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  const VideoWidgetNative(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    super.key,
  });

  @override
  State<VideoWidgetNative> createState() => _VideoWidgetNativeState();
}

class _VideoWidgetNativeState extends State<VideoWidgetNative>
    with WidgetsBindingObserver {
  final Logger _logger = Logger("VideoWidgetNew");
  static const verticalMargin = 72.0;
  // late final player = Player();
  // VideoController? controller;
  final _progressNotifier = ValueNotifier<double?>(null);
  // late StreamSubscription<bool> playingStreamSubscription;
  bool _isAppInFG = true;
  // late StreamSubscription<PauseVideoEvent> pauseVideoSubscription;
  bool _isFileSwipeLocked = false;
  late final StreamSubscription<FileSwipeLockEvent>
      _fileSwipeLockEventSubscription;

  NativeVideoPlayerController? _controller;
  String? _filePath;

  ///Duration in seconds
  int? duration;
  double? aspectRatio;
  final _isControllerInitialized = ValueNotifier(false);

  @override
  void initState() {
    _logger.info(
      'initState for ${widget.file.generatedID} with tag ${widget.file.tag} and name ${widget.file.displayName}',
    );
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.file.isRemoteFile) {
      _loadNetworkVideo();
      _setFileSizeIfNull();
    } else if (widget.file.isSharedMediaToAppSandbox) {
      final localFile = File(getSharedMediaFilePath(widget.file));
      if (localFile.existsSync()) {
        _setFilePathForNativePlayer(localFile.path);
      } else if (widget.file.uploadedFileID != null) {
        _loadNetworkVideo();
      }
    } else {
      widget.file.getAsset.then((asset) async {
        if (asset == null || !(await asset.exists)) {
          if (widget.file.uploadedFileID != null) {
            _loadNetworkVideo();
          }
        } else {
          // ignore: unawaited_futures
          getFile(widget.file, isOrigin: true).then((file) {
            _setFilePathForNativePlayer(file!.path);
            file.delete();
          });
        }
      });
    }
    // playingStreamSubscription = player.stream.playing.listen((event) {
    //   if (widget.playbackCallback != null && mounted) {
    //     widget.playbackCallback!(event);
    //   }
    // });

    // pauseVideoSubscription = Bus.instance.on<PauseVideoEvent>().listen((event) {
    //   player.pause();
    // });
    _fileSwipeLockEventSubscription =
        Bus.instance.on<FileSwipeLockEvent>().listen((event) {
      setState(() {
        _isFileSwipeLocked = event.shouldSwipeLock;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInFG = true;
    } else {
      _isAppInFG = false;
    }
  }

  @override
  void dispose() {
    _fileSwipeLockEventSubscription.cancel();
    // pauseVideoSubscription.cancel();
    removeCallBack(widget.file);
    _progressNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // playingStreamSubscription.cancel();
    // player.dispose();

    _controller?.onPlaybackEnded.removeListener(_onPlaybackEnded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tagPrefix! + widget.file.tag,
      child: GestureDetector(
        onVerticalDragUpdate: _isFileSwipeLocked
            ? null
            : (d) => {
                  if (d.delta.dy > dragSensitivity)
                    {
                      Navigator.of(context).pop(),
                    }
                  else if (d.delta.dy < (dragSensitivity * -1))
                    {
                      showDetailsSheet(context, widget.file),
                    },
                },
        child: _filePath == null
            ? _getLoadingWidget()
            : Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio ?? 1,
                      child: NativeVideoPlayerView(
                        onViewReady: _initializeController,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ValueListenableBuilder(
                        builder: (BuildContext context, bool value, _) {
                          return value
                              ? PlayPauseButton(_controller)
                              : const SizedBox();
                        },
                        valueListenable: _isControllerInitialized,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: verticalMargin,
                    right: 0,
                    left: 0,
                    child: ValueListenableBuilder(
                      builder: (BuildContext context, bool value, _) {
                        return value
                            ? _SeekBar(_controller!, duration)
                            : const SizedBox();
                      },
                      valueListenable: _isControllerInitialized,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  int? _durationToSeconds(String? duration) {
    if (duration == null) {
      _logger.warning("Duration is null");
      return null;
    }
    final parts = duration.split(':');
    int seconds = 0;

    if (parts.length == 3) {
      // Format: "h:mm:ss"
      seconds += int.parse(parts[0]) * 3600; // Hours to seconds
      seconds += int.parse(parts[1]) * 60; // Minutes to seconds
      seconds += int.parse(parts[2]); // Seconds
    } else if (parts.length == 2) {
      // Format: "m:ss"
      seconds += int.parse(parts[0]) * 60; // Minutes to seconds
      seconds += int.parse(parts[1]); // Seconds
    } else {
      throw FormatException('Invalid duration format: $duration');
    }

    return seconds;
  }

  Future<void> _initializeController(
    NativeVideoPlayerController controller,
  ) async {
    _controller = controller;

    controller.onPlaybackEnded.addListener(_onPlaybackEnded);

    final videoSource = await VideoSource.init(
      path: _filePath!,
      type: VideoSourceType.file,
    );
    await controller.loadVideoSource(videoSource);
    await controller.play();
    _isControllerInitialized.value = true;
  }

  void _onPlaybackEnded() {
    _controller?.play();
  }

  void _loadNetworkVideo() {
    getFileFromServer(
      widget.file,
      progressCallback: (count, total) {
        if (!mounted) {
          return;
        }
        _progressNotifier.value = count / (widget.file.fileSize ?? total);
        if (_progressNotifier.value == 1) {
          if (mounted) {
            showShortToast(context, S.of(context).decryptingVideo);
          }
        }
      },
    ).then((file) {
      if (file != null) {
        _setFilePathForNativePlayer(file.path);
      }
    }).onError((error, stackTrace) {
      showErrorDialog(context, "Error", S.of(context).failedToDownloadVideo);
    });
  }

  void _setFileSizeIfNull() {
    if (widget.file.fileSize == null && widget.file.canEditMetaInfo) {
      FilesService.instance
          .getFileSize(widget.file.uploadedFileID!)
          .then((value) {
        widget.file.fileSize = value;
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Widget _getLoadingWidget() {
    return Stack(
      children: [
        _getThumbnail(),
        Container(
          color: Colors.black12,
          constraints: const BoxConstraints.expand(),
        ),
        Center(
          child: SizedBox.fromSize(
            size: const Size.square(20),
            child: ValueListenableBuilder(
              valueListenable: _progressNotifier,
              builder: (BuildContext context, double? progress, _) {
                return progress == null || progress == 1
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                      )
                    : CircularProgressIndicator(
                        backgroundColor: Colors.black,
                        value: progress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(45, 194, 98, 1.0),
                        ),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _getThumbnail() {
    return Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: ThumbnailWidget(
        widget.file,
        fit: BoxFit.contain,
      ),
    );
  }

  void _setFilePathForNativePlayer(String url) {
    if (mounted) {
      setState(() {
        _filePath = url;
      });
      _setAspectRatioFromVideoProps().then((_) {
        setState(() {});
      });
    }
  }

  Future<void> _setAspectRatioFromVideoProps() async {
    final videoProps = await getVideoPropsAsync(File(_filePath!));
    if (videoProps != null) {
      duration = _durationToSeconds(videoProps.propData?["duration"]);

      if (videoProps.width != null && videoProps.height != null) {
        if (videoProps.width != null && videoProps.height != 0) {
          aspectRatio = videoProps.width! / videoProps.height!;
        } else {
          _logger.info("Video props height or width is 0");
          aspectRatio = 1;
        }
      } else {
        _logger.info("Video props width and height are null");
        aspectRatio = 1;
      }
    } else {
      _logger.info("Video props are null");
      aspectRatio = 1;
    }
  }
}

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

class _SeekBar extends StatefulWidget {
  final NativeVideoPlayerController controller;
  final int? duration;
  const _SeekBar(this.controller, this.duration);

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  double _prevPositionFraction = 0.0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.grey,
            thumbColor: Colors.red,
            overlayColor: Colors.red.withOpacity(0.4),
          ),
          child: Slider(
            min: 0.0,
            max: 1.0,
            value: _animationController.value,
            onChanged: (value) {},
            divisions: 4500,
            onChangeEnd: (value) {
              widget.controller.seekTo((value * widget.duration!).round());
              _animationController.animateTo(
                value,
                duration: const Duration(microseconds: 0),
              );
            },
            allowedInteraction: SliderInteraction.tapAndSlide,
          ),
        );
      },
    );
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
      unawaited(
        _animationController.animateTo(0, duration: const Duration(seconds: 0)),
      );
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
