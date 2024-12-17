import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/use_media_kit_for_video.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/video_widget_media_kit_new.dart";
import "package:photos/ui/viewer/file/video_widget_native.dart";

class VideoWidget extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  const VideoWidget(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    super.key,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final _logger = Logger("VideoWidget");
  bool useNativeVideoPlayer = true;
  late final StreamSubscription<UseMediaKitForVideo>
      useMediaKitForVideoSubscription;

  @override
  void initState() {
    super.initState();
    useMediaKitForVideoSubscription =
        Bus.instance.on<UseMediaKitForVideo>().listen((event) {
      _logger.info("Switching to MediaKit for video playback");
      setState(() {
        useNativeVideoPlayer = false;
      });
    });
  }

  @override
  void dispose() {
    useMediaKitForVideoSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (useNativeVideoPlayer) {
      return VideoWidgetNative(
        widget.file,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
      );
    } else {
      return VideoWidgetMediaKitNew(
        widget.file,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
      );
    }
  }
}
