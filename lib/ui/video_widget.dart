import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/video_controls.dart';
import 'package:video_player/video_player.dart';

import 'loading_widget.dart';

class VideoWidget extends StatefulWidget {
  final File file;
  final bool autoPlay;
  VideoWidget(this.file, {this.autoPlay = false, Key key}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.file.localId == null) {
      _setVideoPlayerController(widget.file.getRemoteUrl());
    } else {
      widget.file.getAsset().then((asset) {
        asset.getMediaUrl().then((url) {
          _setVideoPlayerController(url);
        });
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    if (_chewieController != null) {
      _chewieController.dispose();
    }
    super.dispose();
  }

  VideoPlayerController _setVideoPlayerController(String url) {
    return _videoPlayerController = VideoPlayerController.network(url)
      ..initialize().whenComplete(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    final content = _videoPlayerController != null &&
            _videoPlayerController.value.initialized
        ? _getVideoPlayer()
        : _getLoadingWidget();
    return Hero(
      tag: widget.file.tag(),
      child: content,
    );
  }

  Widget _getLoadingWidget() {
    return Stack(children: [
      _getThumbnail(),
      Container(
        color: Colors.black12,
        constraints: BoxConstraints.expand(),
      ),
      loadWidget,
    ]);
  }

  Widget _getThumbnail() {
    final thumbnail = widget.file.localId == null
        ? CachedNetworkImage(
            imageUrl: widget.file.getThumbnailUrl(),
            fit: BoxFit.contain,
          )
        : Image.memory(
            ThumbnailLruCache.get(widget.file, THUMBNAIL_SMALL_SIZE),
            fit: BoxFit.contain,
          );
    return Container(
      child: thumbnail,
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
