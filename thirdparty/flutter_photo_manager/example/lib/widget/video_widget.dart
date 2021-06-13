import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    Key? key,
    required this.mediaUrl,
    this.isAudio = false,
  }) : super(key: key);

  final String mediaUrl;
  final bool isAudio;

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late final VideoPlayerController _controller =
      VideoPlayerController.network(widget.mediaUrl)
        ..initialize().then((_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    print(widget.isAudio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: widget.isAudio ? 1 : _controller.value.aspectRatio,
            child: GestureDetector(
              child: buildVideoPlayer(),
              onTap: () {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
                setState(() {});
              },
            ),
          )
        : Container();
  }

  buildVideoPlayer() {
    Widget contentWidget;

    if (!widget.isAudio) {
      contentWidget = VideoPlayer(_controller);
    } else {
      contentWidget = Container(
        color: Colors.white,
        child: Center(
          child: Icon(
            Icons.audiotrack,
            size: 200,
            color: Colors.grey,
          ),
        ),
      );
    }

    var children = <Widget>[contentWidget];

    if (!_controller.value.isPlaying) {
      children.add(
        IgnorePointer(
          child: Center(
              child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
            ),
          )),
        ),
      );
    }

    return Stack(
      children: children,
    );
  }
}
