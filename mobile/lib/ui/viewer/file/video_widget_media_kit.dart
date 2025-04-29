import "dart:async";
import "dart:io";

import "package:flutter/cupertino.dart";
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
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";

class VideoWidgetMediaKit extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  const VideoWidgetMediaKit(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    super.key,
  });

  @override
  State<VideoWidgetMediaKit> createState() => _VideoWidgetMediaKitState();
}

class _VideoWidgetMediaKitState extends State<VideoWidgetMediaKit>
    with WidgetsBindingObserver {
  final Logger _logger = Logger("VideoWidgetMediaKit");
  static const verticalMargin = 72.0;
  late final player = Player();
  VideoController? controller;
  final _progressNotifier = ValueNotifier<double?>(null);
  late StreamSubscription<bool> playingStreamSubscription;
  bool _isAppInFG = true;
  late StreamSubscription<PauseVideoEvent> pauseVideoSubscription;
  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;

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
    playingStreamSubscription = player.stream.playing.listen((event) {
      if (widget.playbackCallback != null && mounted) {
        widget.playbackCallback!(event);
      }
    });

    pauseVideoSubscription = Bus.instance.on<PauseVideoEvent>().listen((event) {
      player.pause();
    });
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
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
    playingStreamSubscription.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Hero(
      tag: widget.tagPrefix! + widget.file.tag,
      child: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(
          backdropColor: null,
          automaticallyImplySkipNextButton: false,
          automaticallyImplySkipPreviousButton: false,
          seekOnDoubleTap: false,
          displaySeekBar: true,
          seekBarMargin: const EdgeInsets.only(bottom: verticalMargin),
          bottomButtonBarMargin: const EdgeInsets.only(bottom: 112),
          controlsHoverDuration: const Duration(seconds: 3),
          seekBarHeight: 2,
          seekBarThumbSize: 16,
          seekBarBufferColor: Colors.transparent,
          seekBarThumbColor: backgroundElevatedLight,
          seekBarColor: fillMutedDark,
          seekBarPositionColor: colorScheme.primary300,
          seekBarContainerHeight: 56,
          seekBarAlignment: Alignment.center,

          ///topButtonBarMargin is needed for keeping the buffering loading
          ///indicator to be center aligned
          topButtonBarMargin: const EdgeInsets.only(top: verticalMargin),
          bottomButtonBar: [
            const Spacer(),
            PausePlayAndDuration(controller?.player),
            const Spacer(),
          ],
          primaryButtonBar: [],
        ),
        fullscreen: const MaterialVideoControlsThemeData(),
        child: GestureDetector(
          onVerticalDragUpdate: isGuestView
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
                ? Video(
                    controller: controller!,
                  )
                : _getLoadingWidget(),
          ),
        ),
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

class PausePlayAndDuration extends StatefulWidget {
  final Player? player;
  const PausePlayAndDuration(this.player, {super.key});

  @override
  State<PausePlayAndDuration> createState() => _PausePlayAndDurationState();
}

class _PausePlayAndDurationState extends State<PausePlayAndDuration> {
  Color backgroundColor = fillStrongLight;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          backgroundColor = fillMutedDark;
        });
      },
      onTapUp: (details) {
        Future.delayed(const Duration(milliseconds: 175), () {
          if (mounted) {
            setState(() {
              backgroundColor = fillStrongLight;
            });
          }
        });
      },
      onTapCancel: () {
        Future.delayed(const Duration(milliseconds: 175), () {
          if (mounted) {
            setState(() {
              backgroundColor = fillStrongLight;
            });
          }
        });
      },
      onTap: () => widget.player!.playOrPause(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInBack,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: strokeFaintDark,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedSize(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOutExpo,
          child: Row(
            children: [
              StreamBuilder(
                builder: (context, snapshot) {
                  final bool isPlaying = snapshot.data ?? false;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeInOutCirc,
                    switchOutCurve: Curves.easeInOutCirc,
                    child: Icon(
                      key: ValueKey(
                        isPlaying ? "pause_button" : "play_button",
                      ),
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: backdropBaseLight,
                      size: 24,
                    ),
                  );
                },
                initialData: widget.player?.state.playing,
                stream: widget.player?.stream.playing,
              ),
              const SizedBox(width: 8),
              MaterialPositionIndicator(
                style: getEnteTextTheme(context).tiny.copyWith(
                      color: textBaseDark,
                    ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
