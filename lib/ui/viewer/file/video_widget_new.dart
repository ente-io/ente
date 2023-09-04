import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/files_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/toast_util.dart";

class VideoWidgetNew extends StatefulWidget {
  final EnteFile file;
  const VideoWidgetNew(this.file, {super.key});

  @override
  State<VideoWidgetNew> createState() => _VideoWidgetNewState();
}

class _VideoWidgetNewState extends State<VideoWidgetNew> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  VideoController? controller;
  final _progressNotifier = ValueNotifier<double?>(null);

  @override
  void initState() {
    super.initState();
    if (widget.file.isRemoteFile) {
      _loadNetworkVideo();
      _setFileSizeIfNull();
    } else if (widget.file.isSharedMediaToAppSandbox) {
      final localFile = File(getSharedMediaFilePath(widget.file));
      if (localFile.existsSync()) {
        _setVideoController(localFile.path);
      } else if (widget.file.uploadedFileID != null) {
        _loadNetworkVideo();
      }
    } else {
      widget.file.getAsset.then((asset) async {
        if (asset == null || !(await asset.exists)) {
          if (widget.file.uploadedFileID != null) {
            _loadNetworkVideo();
          }
        } else {
          asset.getMediaUrl().then((url) {
            _setVideoController(
              url ??
                  'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    // _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return MaterialVideoControlsTheme(
      normal: MaterialVideoControlsThemeData(
        seekBarMargin: const EdgeInsets.only(bottom: 100),
        bottomButtonBarMargin: const EdgeInsets.only(bottom: 112),
        controlsHoverDuration: const Duration(seconds: 100),
        seekBarHeight: 4,
        seekBarBufferColor: Colors.transparent,
        seekBarThumbColor: backgroundElevatedLight,
        seekBarColor: fillMutedDark,
        seekBarPositionColor: colorScheme.primary300.withOpacity(0.8),
        bottomButtonBar: [
          const Spacer(),
          GestureDetector(
            onTap: () => controller!.player.playOrPause(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: strokeFaintDark,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  StreamBuilder(
                    builder: (context, snapshot) {
                      final bool isPlaying = snapshot.data ?? false;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeInOutExpo,
                        switchOutCurve: Curves.easeInOutExpo,
                        child: Icon(
                          key: ValueKey(
                            isPlaying ? "pause_button" : "play_button",
                          ),
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: backdropBaseLight,
                        ),
                      );
                    },
                    initialData: true,
                    stream: controller!.player.stream.playing,
                  ),
                  const SizedBox(width: 8),
                  MaterialPositionIndicator(
                    style: getEnteTextTheme(context).mini,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
        primaryButtonBar: [],
      ),
      fullscreen: const MaterialVideoControlsThemeData(),
      child: Center(
        child: controller != null
            ? Video(
                controller: controller!,
              )
            : _getLoadingWidget(),
      ),
    );
  }

  void _loadNetworkVideo() {
    getFileFromServer(
      widget.file,
      progressCallback: (count, total) {
        _progressNotifier.value = count / (widget.file.fileSize ?? total);
        if (_progressNotifier.value == 1) {
          if (mounted) {
            showShortToast(context, S.of(context).decryptingVideo);
          }
        }
      },
    ).then((file) {
      if (file != null) {
        _setVideoController(file.path);
      }
    }).onError((error, stackTrace) {
      showErrorDialog(context, "Error", S.of(context).failedToDownloadVideo);
    });
  }

  void _setFileSizeIfNull() {
    if (widget.file.fileSize == null && widget.file.canEditMetaInfo) {
      FilesService.instance
          .getFileSize(widget.file.uploadedFileID!)
          .then((value) {
        widget.file.fileSize = value;
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Widget _getLoadingWidget() {
    return Stack(
      children: [
        _getThumbnail(),
        Container(
          color: Colors.black12,
          constraints: const BoxConstraints.expand(),
        ),
        Center(
          child: SizedBox.fromSize(
            size: const Size.square(20),
            child: ValueListenableBuilder(
              valueListenable: _progressNotifier,
              builder: (BuildContext context, double? progress, _) {
                return progress == null || progress == 1
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                      )
                    : CircularProgressIndicator(
                        backgroundColor: Colors.black,
                        value: progress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(45, 194, 98, 1.0),
                        ),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _getThumbnail() {
    return Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: ThumbnailWidget(
        widget.file,
        fit: BoxFit.contain,
      ),
    );
  }

  void _setVideoController(String url) {
    if (mounted) {
      setState(() {
        controller = VideoController(player);
        player.open(Media(url));
      });
    }
  }
}
