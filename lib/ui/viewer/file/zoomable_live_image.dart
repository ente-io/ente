import 'dart:io' as io;

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/file/zoomable_image.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class ZoomableLiveImage extends StatefulWidget {
  final File file;
  final Function(bool)? shouldDisableScroll;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;

  const ZoomableLiveImage(
    this.file, {
    Key? key,
    this.shouldDisableScroll,
    required this.tagPrefix,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  State<ZoomableLiveImage> createState() => _ZoomableLiveImageState();
}

class _ZoomableLiveImageState extends State<ZoomableLiveImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableLiveImage");
  late File _file;
  bool _showVideo = false;
  bool _isLoadingVideoPlayer = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    _file = widget.file;
    _showLivePhotoToast();
    super.initState();
  }

  void _onLongPressEvent(bool isPressed) {
    if (_videoPlayerController != null && isPressed == false) {
      // stop playing video
      _videoPlayerController!.pause();
    }
    if (mounted) {
      setState(() {
        _showVideo = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    // check is long press is selected but videoPlayer is not configured yet
    if (_showVideo && _videoPlayerController == null) {
      _loadLiveVideo();
    }

    if (_showVideo && _videoPlayerController != null) {
      content = _getVideoPlayer();
    } else {
      content = ZoomableImage(
        _file,
        tagPrefix: widget.tagPrefix,
        shouldDisableScroll: widget.shouldDisableScroll,
        backgroundDecoration: widget.backgroundDecoration,
      );
    }
    return GestureDetector(
      onLongPressStart: (_) => {_onLongPressEvent(true)},
      onLongPressEnd: (_) => {_onLongPressEvent(false)},
      child: content,
    );
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.pause();
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    super.dispose();
  }

  Widget _getVideoPlayer() {
    _videoPlayerController!.seekTo(Duration.zero);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: true,
      autoInitialize: true,
      looping: true,
      allowFullScreen: false,
      showControls: false,
    );
    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!), // same for both theme
    );
  }

  Future<void> _loadLiveVideo() async {
    // do nothing is already loading or loaded
    if (_isLoadingVideoPlayer || _videoPlayerController != null) {
      return;
    }
    _isLoadingVideoPlayer = true;
    if (_file!.isRemoteFile && !(await isFileCached(_file!, liveVideo: true))) {
      showShortToast(context, "Downloading...");
    }

    io.File? videoFile = await getFile(widget.file, liveVideo: true)
        .timeout(const Duration(seconds: 15))
        .onError((dynamic e, s) {
      _logger.info("getFile failed ${_file!.tag}", e);
      return null;
    });

    // FixMe: Here, we are fetching video directly when getFile failed
    // getFile with liveVideo as true can fail for file with localID when
    // the live photo was downloaded from remote.
    if ((videoFile == null || !videoFile.existsSync()) &&
        _file!.uploadedFileID != null) {
      videoFile = await getFileFromServer(widget.file, liveVideo: true)
          .timeout(const Duration(seconds: 15))
          .onError((dynamic e, s) {
        _logger.info("getRemoteFile failed ${_file!.tag}", e);
        return null;
      });
    }

    if (videoFile != null && videoFile.existsSync()) {
      _setVideoPlayerController(file: videoFile);
    } else {
      showShortToast(context, "Download failed");
    }
    _isLoadingVideoPlayer = false;
  }

  VideoPlayerController _setVideoPlayerController({required io.File file}) {
    final videoPlayerController = VideoPlayerController.file(file);
    return _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {
            _showVideo = true;
          });
        }
      });
  }

  void _showLivePhotoToast() async {
    final preferences = await SharedPreferences.getInstance();
    final int promptTillNow = preferences.getInt(livePhotoToastCounterKey) ?? 0;
    if (promptTillNow < maxLivePhotoToastCount && mounted) {
      showToast(context, "Press and hold to play video");
      preferences.setInt(livePhotoToastCounterKey, promptTillNow + 1);
    }
  }
}
