import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/preview_video_store.dart";
import "package:photos/ui/viewer/file/preview_video_widget.dart";
import "package:photos/ui/viewer/file/video_widget.dart";
import "package:photos/ui/viewer/file/zoomable_live_image_new.dart";

class FileWidget extends StatelessWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? shouldDisableScroll;
  final Function(bool)? playbackCallback;
  final BoxDecoration? backgroundDecoration;
  final bool? autoPlay;

  const FileWidget(
    this.file, {
    this.autoPlay,
    this.shouldDisableScroll,
    this.playbackCallback,
    this.tagPrefix,
    this.backgroundDecoration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Specify key to ensure that the widget is rebuilt when the file changes
    // Before changing this, ensure that file deletes are handled properly

    final String fileKey =
        "file_genID_${file.generatedID}___file_id_${file.uploadedFileID}";
    if (file.fileType == FileType.livePhoto ||
        file.fileType == FileType.image) {
      return ZoomableLiveImageNew(
        file,
        shouldDisableScroll: shouldDisableScroll,
        tagPrefix: tagPrefix,
        backgroundDecoration: backgroundDecoration,
        key: key ?? ValueKey(fileKey),
      );
    } else if (file.fileType == FileType.video) {
      if (file.isUploaded &&
          file.localID == null &&
          PreviewVideoStore.instance.isVideoStreamingEnabled &&
          (FileDataService.instance.previewIds
                  ?.containsKey(file.uploadedFileID!) ??
              false)) {
        return PreviewVideoWidget(
          file,
          tagPrefix: tagPrefix,
          playbackCallback: playbackCallback,
          key: key ?? ValueKey(fileKey),
        );
      }

      // use old video widget on iOS simulator as the new one crashes while
      // playing certain videos on iOS simulator
      // if (kDebugMode && Platform.isIOS) {
      //   return VideoWidgetChewie(
      //     file,
      //     tagPrefix: tagPrefix,
      //     playbackCallback: playbackCallback,
      //   );
      // }

      return VideoWidget(
        file,
        tagPrefix: tagPrefix,
        playbackCallback: playbackCallback,
        key: key ?? ValueKey(fileKey),
      );
    } else {
      Logger('FileWidget').severe('unsupported file type ${file.fileType}');
      return const Icon(Icons.error);
    }
  }
}
