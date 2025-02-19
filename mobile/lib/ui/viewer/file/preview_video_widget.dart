import 'dart:async';
import "dart:io";

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import 'package:photos/core/constants.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/preview_video_store.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import "package:photos/ui/viewer/file/video_control.dart";
import "package:photos/utils/data_util.dart";
// import 'package:photos/ui/viewer/file/video_controls.dart';
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import "package:photos/utils/wakelock_util.dart";
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PreviewVideoWidget extends StatefulWidget {
  final EnteFile file;
  final bool? autoPlay;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  final void Function()? onStreamChange;

  const PreviewVideoWidget(
    this.file, {
    this.autoPlay = true,
    this.tagPrefix,
    this.playbackCallback,
    this.onStreamChange,
    super.key,
  });

  @override
  State<PreviewVideoWidget> createState() => _PreviewVideoWidgetState();
}

class _PreviewVideoWidgetState extends State<PreviewVideoWidget> {
  final _logger = Logger("PreviewVideoWidget");
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final _progressNotifier = ValueNotifier<double?>(null);
  bool _isPlaying = false;
  final EnteWakeLock _wakeLock = EnteWakeLock();
  bool _isFileSwipeLocked = false;
  late final StreamSubscription<GuestViewEvent> _fileSwipeLockEventSubscription;
  File? previewFile;

  @override
  void initState() {
    super.initState();

    _checkForPreview();
    _fileSwipeLockEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        _isFileSwipeLocked = event.swipeLocked;
      });
    });
  }

  @override
  void dispose() {
    _fileSwipeLockEventSubscription.cancel();
    removeCallBack(widget.file);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _progressNotifier.dispose();
    _wakeLock.dispose();
    super.dispose();
  }

  Future<void> _checkForPreview() async {
    final data = await PreviewVideoStore.instance
        .getPlaylist(widget.file)
        .onError((error, stackTrace) {
      if (!mounted) return;
      _logger.warning("Failed to download preview video", error, stackTrace);
      Fluttertoast.showToast(msg: "Failed to download preview!");
      return null;
    });
    if (!mounted) return;
    if (data != null) {
      if (flagService.internalUser) {
        final d =
            FileDataService.instance.previewIds?[widget.file.uploadedFileID!];
        if (d != null && widget.file.fileSize != null) {
          // show toast with human readable size
          final size = formatBytes(widget.file.fileSize!);
          showToast(
            context,
            "Preview OG Size ($size), previewSize: ${formatBytes(d.objectSize)}",
          );
        } else {
          showShortToast(context, "Playing preview");
        }
      }
      previewFile = data.preview;
      _setVideoPlayerController();
    }
  }

  void _setVideoPlayerController() {
    if (!mounted) {
      // Note: Do not initiale video player if widget is not mounted.
      // On Android, if multiple instance of ExoPlayer is created, it will start
      // resulting in playback errors for videos. See https://github.com/google/ExoPlayer/issues/6168
      return;
    }
    VideoPlayerController videoPlayerController;
    videoPlayerController = VideoPlayerController.file(previewFile!);

    debugPrint("videoPlayerController: $videoPlayerController");
    _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      }).onError(
        (error, stackTrace) {
          if (mounted && flagService.internalUser) {
            if (error is Exception) {
              showErrorDialogForException(
                context: context,
                exception: error,
                message: "Failed to play video\n ${error.toString()}",
              );
            } else {
              showToast(context, "Failed to play video");
            }
          }
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    final content = _videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized
        ? _getVideoPlayer()
        : _getLoadingWidget();
    final contentWithDetector = GestureDetector(
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
      child: content,
    );
    return VisibilityDetector(
      key: Key(widget.file.tag),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 1) {
          if (mounted && _chewieController != null) {
            _chewieController!.pause();
          }
        }
      },
      child: Hero(
        tag: widget.tagPrefix! + widget.file.tag,
        child: contentWithDetector,
      ),
    );
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

  Future<void> _keepScreenAliveOnPlaying(bool isPlaying) async {
    if (isPlaying) {
      _wakeLock.enable();
    }
    if (!isPlaying) {
      _wakeLock.disable();
    }
  }

  Widget _getVideoPlayer() {
    _videoPlayerController!.addListener(() {
      if (_isPlaying != _videoPlayerController!.value.isPlaying) {
        _isPlaying = _videoPlayerController!.value.isPlaying;
        if (widget.playbackCallback != null) {
          widget.playbackCallback!(_isPlaying);
        }
        unawaited(_keepScreenAliveOnPlaying(_isPlaying));
      }
    });
    _chewieController = ChewieController(
      progressIndicatorDelay: const Duration(milliseconds: 200),
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: widget.autoPlay!,
      autoInitialize: true,
      looping: true,
      allowMuting: true,
      allowFullScreen: false,
      customControls: VideoControls(
        file: widget.file,
        onStreamChange: widget.onStreamChange,
        playbackCallback: widget.playbackCallback,
      ),
    );
    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!),
    );
  }
}
