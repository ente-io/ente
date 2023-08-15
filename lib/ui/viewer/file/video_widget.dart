import 'dart:async';
import 'dart:io' as io;

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file.dart';
import "package:photos/services/feature_flag_service.dart";
import 'package:photos/services/files_service.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/video_controls.dart';
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock/wakelock.dart';

class VideoWidget extends StatefulWidget {
  final File file;
  final bool? autoPlay;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;

  const VideoWidget(
    this.file, {
    this.autoPlay = false,
    this.tagPrefix,
    this.playbackCallback,
    Key? key,
  }) : super(key: key);

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final _logger = Logger("VideoWidget");
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final _progressNotifier = ValueNotifier<double?>(null);
  bool _isPlaying = false;
  bool _wakeLockEnabledHere = false;

  @override
  void initState() {
    super.initState();
    if (widget.file.isRemoteFile) {
      _loadNetworkVideo();
      _setFileSizeIfNull();
    } else if (widget.file.isSharedMediaToAppSandbox) {
      final localFile = io.File(getSharedMediaFilePath(widget.file));
      if (localFile.existsSync()) {
        _logger.fine("loading from app cache");
        _setVideoPlayerController(file: localFile);
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
          asset.getMediaUrl().then((url) {
            _setVideoPlayerController(url: url);
          });
        }
      });
    }
  }

  void _setFileSizeIfNull() {
    if (widget.file.fileSize == null &&
        widget.file.ownerID == Configuration.instance.getUserID()) {
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

  void _loadNetworkVideo() {
    getFileFromServer(
      widget.file,
      progressCallback: (count, total) {
        _progressNotifier.value = count / (widget.file.fileSize ?? total);
        if (_progressNotifier.value == 1) {
          if (mounted) {
            showShortToast(context, S.of(context).decryptingVideo);
          }
        }
      },
    ).then((file) {
      if (file != null) {
        _setVideoPlayerController(file: file);
      }
    }).onError((error, stackTrace) {
      showErrorDialog(context, "Error", S.of(context).failedToDownloadVideo);
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    if (_wakeLockEnabledHere) {
      unawaited(
        Wakelock.enabled.then((isEnabled) {
          isEnabled ? Wakelock.disable() : null;
        }),
      );
    }
    super.dispose();
  }

  VideoPlayerController _setVideoPlayerController({
    String? url,
    io.File? file,
  }) {
    VideoPlayerController videoPlayerController;
    if (url != null) {
      videoPlayerController = VideoPlayerController.network(url);
    } else {
      videoPlayerController = VideoPlayerController.file(file!);
    }

    debugPrint("videoPlayerController: $videoPlayerController");
    _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      }).onError(
        (error, stackTrace) {
          if (mounted &&
              FeatureFlagService.instance.isInternalUserOrDebugBuild()) {
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
    return videoPlayerController;
  }

  @override
  Widget build(BuildContext context) {
    final content = _videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized
        ? _getVideoPlayer()
        : _getLoadingWidget();
    final contentWithDetector = GestureDetector(
      child: content,
      onVerticalDragUpdate: (d) => {
        if (d.delta.dy > dragSensitivity) {Navigator.of(context).pop()}
      },
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
      return Wakelock.enabled.then((value) {
        if (value == false) {
          Wakelock.enable();
          //wakeLockEnabledHere will not be set to true if wakeLock is already enabled from settings on iOS.
          //We shouldn't disable when video is not playing if it was enabled manually by the user from ente settings by user.
          _wakeLockEnabledHere = true;
        }
      });
    }
    if (_wakeLockEnabledHere && !isPlaying) {
      return Wakelock.disable();
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
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: widget.autoPlay!,
      autoInitialize: true,
      looping: true,
      allowMuting: true,
      allowFullScreen: false,
      customControls: const VideoControls(),
    );
    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!),
    );
  }
}
