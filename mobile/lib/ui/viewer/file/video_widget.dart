import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/use_media_kit_for_video.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/preview_video_store.dart";
import "package:photos/theme/colors.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/video_widget_media_kit_new.dart";
import "package:photos/ui/viewer/file/video_widget_native.dart";
import "package:photos/utils/data_util.dart";
import "package:photos/utils/toast_util.dart";

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
  late bool selectPreviewForPlay = widget.file.localID == null;
  File? preview;
  final player1 = GlobalKey();
  final player2 = GlobalKey();
  final player3 = GlobalKey();
  final player4 = GlobalKey();

  bool isPreviewLoadable = true;

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
    _checkForPreview();
  }

  @override
  void dispose() {
    useMediaKitForVideoSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkForPreview() async {
    widget.playbackCallback?.call(false);
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
            "[i] Preview OG Size ($size), previewSize: ${formatBytes(d.objectSize)}",
          );
        } else {
          showShortToast(context, "Playing preview");
        }
      }
      preview = data.preview;
    } else {
      isPreviewLoadable = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPreviewVideoPlayable = isPreviewLoadable &&
        PreviewVideoStore.instance.isVideoStreamingEnabled &&
        widget.file.isUploaded &&
        (FileDataService.instance.previewIds
                ?.containsKey(widget.file.uploadedFileID!) ??
            false);
    if (isPreviewVideoPlayable && selectPreviewForPlay) {
      if (preview == null) {
        return Center(
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.3),
              border: Border.all(
                color: strokeFaintDark,
                width: 1,
              ),
            ),
            child: const EnteLoadingWidget(
              size: 32,
              color: fillBaseDark,
              padding: 0,
            ),
          ),
        );
      }
      if (Platform.isAndroid) {
        return VideoWidgetNative(
          widget.file,
          key: player1,
          preview: preview,
          tagPrefix: widget.tagPrefix,
          playbackCallback: widget.playbackCallback,
          onStreamChange: () {
            setState(() {
              selectPreviewForPlay = false;
            });
          },
        );
      }
      return VideoWidgetMediaKitNew(
        widget.file,
        key: player2,
        preview: preview,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
        onStreamChange: () {
          setState(() {
            selectPreviewForPlay = false;
          });
        },
      );
    }

    if (useNativeVideoPlayer) {
      return VideoWidgetNative(
        widget.file,
        key: player3,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
        onStreamChange: () {
          setState(() {
            selectPreviewForPlay = true;
          });
        },
      );
    } else {
      return VideoWidgetMediaKitNew(
        widget.file,
        key: player4,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
        onStreamChange: () {
          setState(() {
            selectPreviewForPlay = true;
          });
        },
      );
    }
  }
}
