import 'dart:convert';
import "dart:io";

import "package:chewie/chewie.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:media_extension/media_extension_action_types.dart";
import "package:photo_view/photo_view.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:photos/utils/exif_util.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";
import "package:video_player/video_player.dart";

class FileViewer extends StatefulWidget {
  final SharedMediaFile? sharedMediaFile;
  const FileViewer({super.key, this.sharedMediaFile});

  @override
  State<StatefulWidget> createState() {
    return FileViewerState();
  }
}

class FileViewerState extends State<FileViewer> {
  final action = AppLifecycleService.instance.mediaExtensionAction;
  ChewieController? controller;
  VideoPlayerController? videoController;
  final Logger _logger = Logger("FileViewer");
  double? aspectRatio;

  @override
  void initState() {
    _logger.info("Initializing FileViewer");
    super.initState();
    if (action.type == MediaType.video ||
        widget.sharedMediaFile?.type == SharedMediaType.video) {
      _initializeVideoController();
    }
  }

  Future<void> _initializeVideoController() async {
    await _fetchAspectRatio();
    initController();
  }

  Future<void> _fetchAspectRatio() async {
    try {
      final videoPath = widget.sharedMediaFile?.path ?? action.data;
      if (videoPath == null) {
        _logger.warning("Video path is null, using default aspect ratio");
        aspectRatio = 16 / 9;
        return;
      }

      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        _logger
            .warning("Video file does not exist, using default aspect ratio");
        aspectRatio = 16 / 9;
        return;
      }

      final videoProps = await getVideoPropsAsync(videoFile);
      if (videoProps != null &&
          videoProps.width != null &&
          videoProps.height != null &&
          videoProps.height != 0) {
        aspectRatio = videoProps.width! / videoProps.height!;
        _logger.info("Fetched video aspect ratio: $aspectRatio");
      } else {
        _logger.warning(
          "Could not get video dimensions, using default aspect ratio",
        );
        aspectRatio = 16 / 9;
      }
    } catch (e) {
      _logger.severe("Error fetching video aspect ratio: $e");
      aspectRatio = 16 / 9;
    }
  }

  @override
  void dispose() {
    videoController?.dispose();
    controller?.dispose();
    super.dispose();
  }

  void initController() async {
    videoController = VideoPlayerController.contentUri(
      widget.sharedMediaFile?.path != null
          ? Uri.parse(widget.sharedMediaFile!.path)
          : Uri.parse(action.data!),
    );
    controller = ChewieController(
      videoPlayerController: videoController!,
      autoInitialize: true,
      aspectRatio: aspectRatio ?? 16 / 9,
      autoPlay: true,
      looping: true,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color.fromRGBO(45, 194, 98, 1.0),
        handleColor: Colors.white,
        bufferedColor: Colors.white,
      ),
    );
    controller!.addListener(() {
      if (!controller!.isFullScreen) {
        SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp],
        );
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building FileViewer");
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: (() {
                if (action.type == MediaType.image ||
                    widget.sharedMediaFile?.type == SharedMediaType.image) {
                  return PhotoView(
                    imageProvider: widget.sharedMediaFile?.path != null
                        ? Image.file(File(widget.sharedMediaFile!.path)).image
                        : MemoryImage(base64Decode(action.data!)),
                  );
                } else if (action.type == MediaType.video ||
                    widget.sharedMediaFile?.type == SharedMediaType.video) {
                  return controller != null
                      ? Chewie(controller: controller!)
                      : const CircularProgressIndicator();
                } else {
                  _logger.severe(
                    'unsupported file type ${action.type} or ${widget.sharedMediaFile?.type}',
                  );
                  return const Icon(Icons.error);
                }
              })(),
            ),
          ),
        ],
      ),
    );
  }
}
