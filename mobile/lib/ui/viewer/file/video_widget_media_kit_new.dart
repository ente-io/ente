import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/events/pause_video_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/files_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/viewer/file/preview_status_widget.dart";
import "package:photos/utils/debouncer.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/toast_util.dart";

class VideoWidgetMediaKitNew extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  final bool isFromMemories;
  final void Function()? onStreamChange;

  const VideoWidgetMediaKitNew(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    this.isFromMemories = false,
    this.onStreamChange,
    super.key,
  });

  @override
  State<VideoWidgetMediaKitNew> createState() => _VideoWidgetMediaKitNewState();
}

class _VideoWidgetMediaKitNewState extends State<VideoWidgetMediaKitNew>
    with WidgetsBindingObserver {
  final Logger _logger = Logger("VideoWidgetMediaKitNew");
  late final player = Player();
  VideoController? controller;
  final _progressNotifier = ValueNotifier<double?>(null);
  bool _isAppInFG = true;
  late StreamSubscription<PauseVideoEvent> pauseVideoSubscription;
  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  bool _isGuestView = false;

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
        _setVideoController(localFile.path);
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
          asset.getMediaUrl().then((url) {
            _setVideoController(
              url ??
                  'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
            );
          });
        }
      });
    }

    pauseVideoSubscription = Bus.instance.on<PauseVideoEvent>().listen((event) {
      player.pause();
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
    if (state == AppLifecycleState.resumed) {
      _isAppInFG = true;
    } else {
      _isAppInFG = false;
    }
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    pauseVideoSubscription.cancel();
    removeCallBack(widget.file);
    _progressNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Center(
        child: controller != null
            ? _VideoWidget(
                widget.file,
                controller!,
                widget.playbackCallback,
                isFromMemories: widget.isFromMemories,
              )
            // : Stack(
            //     children: [
            //       _getThumbnail(),
            //       Container(
            //         color: Colors.black12,
            //         constraints: const BoxConstraints.expand(),
            //       ),
            //       Center(
            //         child: SizedBox.fromSize(
            //           size: const Size.square(20),
            //           child: ValueListenableBuilder(
            //             valueListenable: _progressNotifier,
            //             builder: (BuildContext context, double? progress, _) {
            //               return progress == null || progress == 1
            //                   ? const CupertinoActivityIndicator(
            //                       color: Colors.white,
            //                     )
            //                   : CircularProgressIndicator(
            //                       backgroundColor: Colors.black,
            //                       value: progress,
            //                       valueColor:
            //                           const AlwaysStoppedAnimation<Color>(
            //                         Color.fromRGBO(45, 194, 98, 1.0),
            //                       ),
            //                     );
            //             },
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            : const SizedBox.shrink(),
      ),
    );
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
        _setVideoController(file.path);
      }
    }).onError((error, stackTrace) {
      showErrorDialog(
        context,
        S.of(context).error,
        S.of(context).failedToDownloadVideo,
      );
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

  void _setVideoController(String url) {
    if (mounted) {
      setState(() {
        player.setPlaylistMode(PlaylistMode.single);
        controller = VideoController(player);
        player.open(Media(url), play: _isAppInFG);
      });
    }
  }
}

class _VideoWidget extends StatefulWidget {
  final EnteFile file;
  final VideoController controller;
  final Function(bool)? playbackCallback;
  final bool isFromMemories;
  final void Function()? onStreamChange;

  const _VideoWidget(
    this.file,
    this.controller,
    this.playbackCallback, {
    required this.isFromMemories,
    // ignore: unused_element
    this.onStreamChange,
  });

  @override
  State<_VideoWidget> createState() => __VideoWidgetState();
}

class __VideoWidgetState extends State<_VideoWidget> {
  final showControlsNotifier = ValueNotifier<bool>(true);
  static const verticalMargin = 72.0;
  final _hideControlsDebouncer = Debouncer(
    const Duration(milliseconds: 2000),
  );
  final _isSeekingNotifier = ValueNotifier<bool>(false);
  late final StreamSubscription<bool> _isPlayingStreamSubscription;

  @override
  void initState() {
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
    super.initState();
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
          widget.playbackCallback?.call(false);
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
                              widget.file.caption != null
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        8,
                                      ),
                                      child: Text(
                                        widget.file.caption!,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: getEnteTextTheme(context)
                                            .mini
                                            .copyWith(
                                              color: textBaseDark,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              ValueListenableBuilder(
                                valueListenable: showControlsNotifier,
                                builder: (context, value, _) {
                                  return PreviewStatusWidget(
                                    showControls: value,
                                    file: widget.file,
                                    onStreamChange: widget.onStreamChange,
                                  );
                                },
                              ),
                              _SeekBarAndDuration(
                                controller: widget.controller,
                                isSeekingNotifier: _isSeekingNotifier,
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

  @override
  void initState() {
    super.initState();

    isPlayingStreamSubscription =
        widget.controller?.player.stream.playing.listen((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    });
  }

  @override
  void dispose() {
    isPlayingStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

class _SeekBarAndDuration extends StatelessWidget {
  final VideoController? controller;
  final ValueNotifier<bool> isSeekingNotifier;

  const _SeekBarAndDuration({
    required this.controller,
    required this.isSeekingNotifier,
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
                  _secondsToDuration(snapshot.data!.inSeconds),
                  style: getEnteTextTheme(
                    context,
                  ).mini.copyWith(
                        color: textBaseDark,
                      ),
                );
              },
            ),
            Expanded(
              child: _SeekBar(
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
  final VideoController controller;
  final ValueNotifier<bool> isSeekingNotifier;
  const _SeekBar(
    this.controller,
    this.isSeekingNotifier,
  );

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
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
