import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:native_video_player/native_video_player.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/events/pause_video_event.dart";
// import "package:photos/events/pause_video_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/files_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/native_video_player_controls/play_pause_button.dart";
import "package:photos/ui/viewer/file/native_video_player_controls/seek_bar.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/debouncer.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:visibility_detector/visibility_detector.dart";

class VideoWidgetNative extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  final bool isFromMemories;
  const VideoWidgetNative(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    this.isFromMemories = false,
    super.key,
  });

  @override
  State<VideoWidgetNative> createState() => _VideoWidgetNativeState();
}

class _VideoWidgetNativeState extends State<VideoWidgetNative>
    with WidgetsBindingObserver {
  final Logger _logger = Logger("VideoWidgetNative");
  static const verticalMargin = 64.0;
  final _progressNotifier = ValueNotifier<double?>(null);
  late StreamSubscription<PauseVideoEvent> pauseVideoSubscription;
  bool _isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  NativeVideoPlayerController? _controller;
  String? _filePath;
  String? duration;
  double? aspectRatio;
  final _isPlaybackReady = ValueNotifier(false);
  bool _shouldClearCache = false;
  bool _isCompletelyVisible = false;
  final _showControls = ValueNotifier(true);
  final _isSeeking = ValueNotifier(false);
  final _debouncer = Debouncer(const Duration(milliseconds: 2000));

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
            if (Platform.isIOS) {
              _shouldClearCache = true;
            }
          });
        }
      });
    }

    pauseVideoSubscription = Bus.instance.on<PauseVideoEvent>().listen((event) {
      _controller?.pause();
    });
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        _isGuestView = event.isGuestView;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_controller?.playbackInfo?.status == PlaybackStatus.playing) {
        _controller?.pause();
      }
    }
  }

  @override
  void dispose() {
    //https://github.com/fluttercandies/flutter_photo_manager/blob/8afba2745ebaac6af8af75de9cbded9157bc2690/README.md#clear-caches
    if (_shouldClearCache) {
      _logger.info("Clearing cache");
      File(_filePath!).delete().then(
        (value) {
          _logger.info("Cache cleared");
        },
      );
    }
    _guestViewEventSubscription.cancel();
    pauseVideoSubscription.cancel();
    removeCallBack(widget.file);
    _progressNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.onPlaybackEnded.removeListener(_onPlaybackEnded);
    _controller?.onPlaybackReady.removeListener(_onPlaybackReady);
    _controller?.onError.removeListener(_onError);
    _controller?.onPlaybackStatusChanged
        .removeListener(_onPlaybackStatusChanged);
    _isPlaybackReady.dispose();
    _showControls.dispose();
    _isSeeking.removeListener(_seekListener);
    _isSeeking.dispose();
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tagPrefix! + widget.file.tag,
      child: VisibilityDetector(
        key: Key(widget.file.generatedID.toString()),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1) {
            setState(() {
              _isCompletelyVisible = true;
            });
          }
        },
        child: GestureDetector(
          onVerticalDragUpdate: _isGuestView
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 750),
            switchOutCurve: Curves.easeOutExpo,
            switchInCurve: Curves.easeInExpo,
            //Loading two high-res potrait videos together causes one to
            //go blank. So only loading video when it is completely visible.
            child: !_isCompletelyVisible || _filePath == null
                ? _getLoadingWidget()
                : Stack(
                    key: const ValueKey("video_ready"),
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: aspectRatio ?? 1,
                          child: NativeVideoPlayerView(
                            onViewReady: _initializeController,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _showControls.value = !_showControls.value;
                          widget.playbackCallback!(!_showControls.value);
                        },
                        child: Container(
                          constraints: const BoxConstraints.expand(),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: ValueListenableBuilder(
                            builder: (BuildContext context, bool value, _) {
                              return value
                                  ? ValueListenableBuilder(
                                      builder: (context, bool value, _) {
                                        return AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          opacity: value ? 1 : 0,
                                          curve: Curves.easeInOutQuad,
                                          child: IgnorePointer(
                                            ignoring: !value,
                                            child: PlayPauseButton(_controller),
                                          ),
                                        );
                                      },
                                      valueListenable: _showControls,
                                    )
                                  : const SizedBox();
                            },
                            valueListenable: _isPlaybackReady,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: verticalMargin,
                        right: 0,
                        left: 0,
                        child: SafeArea(
                          top: false,
                          left: false,
                          right: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: widget.isFromMemories ? 32 : 0,
                            ),
                            child: ValueListenableBuilder(
                              valueListenable: _isPlaybackReady,
                              builder: (BuildContext context, bool value, _) {
                                return value
                                    ? _SeekBarAndDuration(
                                        controller: _controller,
                                        duration: duration,
                                        showControls: _showControls,
                                        isSeeking: _isSeeking,
                                      )
                                    : const SizedBox();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeController(
    NativeVideoPlayerController controller,
  ) async {
    try {
      _logger.info(
        "Initializing native video player controller for file gen id: ${widget.file.generatedID}",
      );
      _controller = controller;

      controller.onError.addListener(_onError);
      controller.onPlaybackEnded.addListener(_onPlaybackEnded);
      controller.onPlaybackReady.addListener(_onPlaybackReady);
      controller.onPlaybackStatusChanged.addListener(_onPlaybackStatusChanged);
      _isSeeking.addListener(_seekListener);

      final videoSource = await VideoSource.init(
        path: _filePath!,
        type: VideoSourceType.file,
      );
      await controller.loadVideoSource(videoSource);
    } catch (e) {
      _logger.severe(
        "Error initializing native video player controller for file gen id: ${widget.file.generatedID}",
        e,
      );
    }
  }

  void _seekListener() {
    if (!_isSeeking.value &&
        _controller?.playbackInfo?.status == PlaybackStatus.playing) {
      _debouncer.run(() async {
        if (mounted) {
          if (_isSeeking.value ||
              _controller?.playbackInfo?.status != PlaybackStatus.playing) {
            return;
          }
          _showControls.value = false;
          widget.playbackCallback!(true);
        }
      });
    }
  }

  void _onPlaybackStatusChanged() {
    if (_isSeeking.value || _controller?.playbackInfo?.positionFraction == 1) {
      return;
    }
    if (_controller!.playbackInfo?.status == PlaybackStatus.playing) {
      if (widget.playbackCallback != null && mounted) {
        _debouncer.run(() async {
          if (mounted) {
            if (_isSeeking.value ||
                _controller!.playbackInfo?.status != PlaybackStatus.playing) {
              return;
            }
            _showControls.value = false;
            widget.playbackCallback!(true);
          }
        });
      }
    } else {
      if (widget.playbackCallback != null && mounted) {
        widget.playbackCallback!(false);
      }
    }
  }

  void _onError() {
    //This doesn't work all the time
    _logger.severe(
      "Error in native video player controller for file gen id: ${widget.file.generatedID}",
    );
    _logger.severe(_controller!.onError.value);
  }

  Future<void> _onPlaybackReady() async {
    await _controller!.play();
    unawaited(_controller!.setVolume(1));
    _isPlaybackReady.value = true;
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
      key: const ValueKey("video_loading"),
      children: [
        _getThumbnail(),
        Container(
          color: Colors.black12,
          constraints: const BoxConstraints.expand(),
        ),
        Center(
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(
                color: strokeFaintDark,
                width: 1,
              ),
            ),
            child: ValueListenableBuilder(
              valueListenable: _progressNotifier,
              builder: (BuildContext context, double? progress, _) {
                return progress == null || progress == 1
                    ? const EnteLoadingWidget(
                        size: 32,
                        color: fillBaseDark,
                        padding: 0,
                      )
                    : CircularProgressIndicator(
                        backgroundColor: Colors.transparent,
                        value: progress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(45, 194, 98, 1.0),
                        ),
                        strokeWidth: 2,
                        strokeCap: StrokeCap.round,
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
        shouldShowVideoOverlayIcon: false,
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
      duration = videoProps.propData?["duration"];

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

class _SeekBarAndDuration extends StatelessWidget {
  final NativeVideoPlayerController? controller;
  final String? duration;
  final ValueNotifier<bool> showControls;
  final ValueNotifier<bool> isSeeking;

  const _SeekBarAndDuration({
    required this.controller,
    required this.duration,
    required this.showControls,
    required this.isSeeking,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: showControls,
      builder: (
        BuildContext context,
        bool value,
        _,
      ) {
        return AnimatedOpacity(
          duration: const Duration(
            milliseconds: 200,
          ),
          curve: Curves.easeInQuad,
          opacity: value ? 1 : 0,
          child: IgnorePointer(
            ignoring: !value,
            child: Padding(
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
                    AnimatedSize(
                      duration: const Duration(
                        seconds: 5,
                      ),
                      curve: Curves.easeInOut,
                      child: ValueListenableBuilder(
                        valueListenable: controller!.onPlaybackPositionChanged,
                        builder: (
                          BuildContext context,
                          int value,
                          _,
                        ) {
                          return Text(
                            _secondsToDuration(
                              value,
                            ),
                            style: getEnteTextTheme(
                              context,
                            ).mini.copyWith(
                                  color: textBaseDark,
                                ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: SeekBar(
                        controller!,
                        _durationToSeconds(
                          duration,
                        ),
                        isSeeking,
                      ),
                    ),
                    Text(
                      duration ?? "0:00",
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
          ),
        );
      },
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

  /// Returns the duration in seconds from the format "h:mm:ss" or "m:ss".
  int? _durationToSeconds(String? duration) {
    if (duration == null) {
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
}
