import "dart:io";

import "package:flutter/material.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/files_service.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";

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
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    if (widget.file.isRemoteFile) {
      _loadNetworkVideo();
      _setFileSizeIfNull();
    } else if (widget.file.isSharedMediaToAppSandbox) {
      final localFile = File(getSharedMediaFilePath(widget.file));
      if (localFile.existsSync()) {
        player.open(
          Media(
            localFile.path,
          ),
        );
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
            player.open(
              Media(
                //falling back to a default video to know when url is null
                url ??
                    'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
              ),
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        child: Video(controller: controller),
      ),
    );
  }

  void _loadNetworkVideo() {
    getFileFromServer(
      widget.file,
    ).then((file) {
      if (file != null) {
        player.open(Media(file.path));
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
}
