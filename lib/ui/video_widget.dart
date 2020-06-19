import 'package:chewie/chewie.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:video_player/video_player.dart';

import 'loading_widget.dart';

class VideoWidget extends StatefulWidget {
  final File file;
  VideoWidget(this.file, {Key key}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  ChewieController _chewieController;
  VideoPlayerController _videoPlayerController;
  Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _initVideoPlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadWidget;
        }
        return Chewie(
          controller: _chewieController,
        );
      },
    );
  }

  Future<void> _initVideoPlayer() async {
    final url = widget.file.localId == null
        ? widget.file.getRemoteUrl()
        : await (await widget.file.getAsset()).getMediaUrl();
    _videoPlayerController = VideoPlayerController.network(url);
    await _videoPlayerController.initialize();
    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        autoInitialize: true,
      );
    });
  }
}
