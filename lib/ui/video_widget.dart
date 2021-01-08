import 'dart:io' as io;
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/ui/video_controls.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoWidget extends StatefulWidget {
  final File file;
  final bool autoPlay;
  final String tagPrefix;
  VideoWidget(
    this.file, {
    this.autoPlay = false,
    this.tagPrefix,
    Key key,
  }) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  Logger _logger = Logger("VideoWidget");
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  double _progress;

  @override
  void initState() {
    super.initState();
    if (widget.file.localID == null) {
      _loadNetworkVideo();
    } else {
      widget.file.getAsset().then((asset) async {
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

  void _loadNetworkVideo() {
    if (!widget.file.isEncrypted) {
      _setVideoPlayerController(url: widget.file.getStreamUrl());
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          _logger.warning(_videoPlayerController.value.errorDescription);
          showToast(
              "the video has not been processed yet. downloading the original one...",
              toastLength: Toast.LENGTH_SHORT);
          _setVideoPlayerController(url: widget.file.getDownloadUrl());
        }
      });
    } else {
      getFileFromServer(
        widget.file,
        progressCallback: (count, total) {
          setState(() {
            _progress = count / total;
            if (_progress == 1) {
              showToast("decrypting video...", toastLength: Toast.LENGTH_SHORT);
            }
          });
        },
      ).then((file) {
        _setVideoPlayerController(file: file);
      });
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController.dispose();
    }
    if (_chewieController != null) {
      _chewieController.dispose();
    }
    super.dispose();
  }

  VideoPlayerController _setVideoPlayerController({String url, io.File file}) {
    var videoPlayerController;
    if (url != null) {
      videoPlayerController = VideoPlayerController.network(url);
    } else {
      videoPlayerController = VideoPlayerController.file(file);
    }
    return _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final content = _videoPlayerController != null &&
            _videoPlayerController.value.initialized
        ? _getVideoPlayer()
        : _getLoadingWidget();
    return VisibilityDetector(
      key: Key(widget.file.tag()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 1) {
          if (mounted && _chewieController != null) {
            _chewieController.pause();
          }
        }
      },
      child: Hero(
        tag: widget.tagPrefix + widget.file.tag(),
        child: content,
      ),
    );
  }

  Widget _getLoadingWidget() {
    return Stack(children: [
      _getThumbnail(),
      Container(
        color: Colors.black12,
        constraints: BoxConstraints.expand(),
      ),
      Center(
        child: SizedBox.fromSize(
          size: Size.square(30),
          child: _progress == null || _progress == 1
              ? CupertinoActivityIndicator()
              : CircularProgressIndicator(value: _progress),
        ),
      ),
    ]);
  }

  Widget _getThumbnail() {
    return Container(
      child: ThumbnailWidget(
        widget.file,
        fit: BoxFit.contain,
      ),
      constraints: BoxConstraints.expand(),
    );
  }

  Widget _getVideoPlayer() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: widget.autoPlay,
      autoInitialize: true,
      looping: true,
      allowFullScreen: false,
      customControls: VideoControls(),
    );
    return Chewie(controller: _chewieController);
  }
}
