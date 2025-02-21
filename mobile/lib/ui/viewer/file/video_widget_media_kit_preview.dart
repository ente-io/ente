import "dart:async";

import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/events/pause_video_event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/preview_video_store.dart";
import "package:photos/theme/colors.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/video_widget_media_kit_common.dart"
    as common;
import "package:photos/utils/data_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/toast_util.dart";

class VideoWidgetMediaKitPreview extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;
  final bool isFromMemories;
  final void Function() onStreamChange;

  const VideoWidgetMediaKitPreview(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    this.isFromMemories = false,
    required this.onStreamChange,
    super.key,
  });

  @override
  State<VideoWidgetMediaKitPreview> createState() =>
      _VideoWidgetMediaKitPreviewState();
}

class _VideoWidgetMediaKitPreviewState extends State<VideoWidgetMediaKitPreview>
    with WidgetsBindingObserver {
  final Logger _logger = Logger("VideoWidgetMediaKitNew");
  late final player = Player();
  VideoController? controller;
  final _progressNotifier = ValueNotifier<double?>(null);
  bool _isAppInFG = true;
  late StreamSubscription<PauseVideoEvent> pauseVideoSubscription;
  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  bool _isGuestView = false;

  @override
  void initState() {
    _logger.info(
      'initState for ${widget.file.generatedID} with tag ${widget.file.tag} and name ${widget.file.displayName}',
    );
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForPreview();

    pauseVideoSubscription = Bus.instance.on<PauseVideoEvent>().listen((event) {
      player.pause();
    });
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        _isGuestView = event.isGuestView;
      });
    });
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
      _setVideoController(data.preview.path);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInFG = true;
    } else {
      _isAppInFG = false;
    }
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    pauseVideoSubscription.cancel();
    removeCallBack(widget.file);
    _progressNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _isGuestView
          ? null
          : (d) => {
                if (d.delta.dy > dragSensitivity)
                  {
                    Navigator.of(context).pop(),
                  }
                else if (d.delta.dy < (dragSensitivity * -1))
                  {
                    showDetailsSheet(context, widget.file),
                  },
              },
      child: Center(
        child: controller != null
            ? common.VideoWidget(
                widget.file,
                controller!,
                widget.playbackCallback,
                isFromMemories: widget.isFromMemories,
                onStreamChange: widget.onStreamChange,
                isPreviewPlayer: true,
              )
            : const Center(
                child: EnteLoadingWidget(
                  size: 32,
                  color: fillBaseDark,
                  padding: 0,
                ),
              ),
      ),
    );
  }

  void _setVideoController(String url) {
    if (mounted) {
      setState(() {
        player.setPlaylistMode(PlaylistMode.single);
        controller = VideoController(player);
        player.open(Media(url), play: _isAppInFG);
      });
    }
  }
}
