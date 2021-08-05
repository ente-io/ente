import 'dart:io' as io;
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/thumbnail_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:video_player/video_player.dart';

class ZoomableLiveImage extends StatefulWidget {
  final File photo;
  final Function(bool) shouldDisableScroll;
  final String tagPrefix;
  final Decoration backgroundDecoration;

  ZoomableLiveImage(
    this.photo, {
    Key key,
    this.shouldDisableScroll,
    @required this.tagPrefix,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  _ZoomableLiveImageState createState() => _ZoomableLiveImageState();
}

class _ZoomableLiveImageState extends State<ZoomableLiveImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableLiveImage");
  File _livePhoto;
  bool _loadLivePhotoVideo = false;

  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  @override
  void initState() {
    _livePhoto = widget.photo;
    _loadLiveVideo();
    super.initState();
  }

  void _onLongPressEvent(bool isPressed) {
    if (_videoPlayerController != null && isPressed == false) {
      // stop playing video
      _videoPlayerController.pause();
    }
    if (mounted) {
      setState(() {
        _loadLivePhotoVideo = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loadLivePhotoVideo && _videoPlayerController != null) {
      content = _getVideoPlayer();
    } else {
      content = ZoomableImage(_livePhoto,
          tagPrefix: widget.tagPrefix,
          shouldDisableScroll: widget.shouldDisableScroll,
          backgroundDecoration: widget.backgroundDecoration);
    }
    return GestureDetector(
        onLongPressStart: (_) => {_onLongPressEvent(true)},
        onLongPressEnd: (_) => {_onLongPressEvent(false)},
        child: content);
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController.pause();
      _videoPlayerController.dispose();
    }
    if (_chewieController != null) {
      _chewieController.dispose();
    }
    super.dispose();
  }

  Widget _getVideoPlayer() {
    _videoPlayerController.seekTo(Duration.zero);
    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        autoInitialize: true,
        looping: false,
        allowFullScreen: false,
        showControls: false);
    return Chewie(controller: _chewieController);
  }

  void _loadLiveVideo() {
    // todo: add wrapper to download file from server if local is missing
    getFile(widget.photo, liveVideo: true).then((file) {
      if (file != null && file.existsSync()) {
        _logger.fine("loading  from local");
        _setVideoPlayerController(file: file);
      } else if (widget.photo.uploadedFileID != null) {
        _logger.fine("loading from remote");
        getFileFromServer(widget.photo, liveVideo: true).then((file) {
          if (file != null && file.existsSync()) {
            _setVideoPlayerController(file: file);
          } else {
            _logger.warning("failed to load from remote" + widget.photo.tag());
          }
        });
      }
    });
  }

  VideoPlayerController _setVideoPlayerController({io.File file}) {
    var videoPlayerController = VideoPlayerController.file(file);
    return _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      });
  }
}
