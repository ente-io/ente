import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import 'package:path/path.dart' as path;
import "package:photo_manager/photo_manager.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/magic_util.dart";

class FilePropertiesWidget extends StatefulWidget {
  final File file;
  final bool isImage;
  final Map<String, dynamic> exifData;
  final int currentUserID;
  const FilePropertiesWidget(
    this.file,
    this.isImage,
    this.exifData,
    this.currentUserID, {
    super.key,
  });
  @override
  State<FilePropertiesWidget> createState() => _FilePropertiesWidgetState();
}

class _FilePropertiesWidgetState extends State<FilePropertiesWidget> {
  @override
  Widget build(BuildContext context) {
    final bool showDimension = widget.exifData["resolution"] != null &&
        widget.exifData["megaPixels"] != null;
    return InfoItemWidget(
      key: const ValueKey("File properties"),
      leadingIcon: widget.isImage
          ? Icons.photo_outlined
          : Icons.video_camera_back_outlined,
      title: path.basenameWithoutExtension(widget.file.displayName) +
          path.extension(widget.file.displayName).toUpperCase(),
      subtitleSection: Future.value([
        if (showDimension)
          Text(
            "${widget.exifData["megaPixels"]}MP  "
            "${widget.exifData["resolution"]}  ",
            style: getEnteTextTheme(context).smallMuted,
          ),
        _getFileSize(),
        if ((widget.file.fileType == FileType.video) &&
            (widget.file.localID != null || widget.file.duration != 0))
          _getVideoDuration(),
      ]),
      editOnTap: widget.file.uploadedFileID == null ||
              widget.file.ownerID != widget.currentUserID
          ? null
          : () async {
              await editFilename(context, widget.file);
              setState(() {});
            },
    );
  }

  Widget _getFileSize() {
    Future<int> fileSizeFuture;
    if (widget.file.fileSize != null) {
      fileSizeFuture = Future.value(widget.file.fileSize);
    } else {
      fileSizeFuture = getFile(widget.file).then((f) => f!.length());
    }
    return FutureBuilder<int>(
      future: fileSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data! / (1024 * 1024)).toStringAsFixed(2) + " MB",
            style: getEnteTextTheme(context).smallMuted,
          );
        } else {
          return SizedBox.fromSize(
            size: const Size.square(16),
            child: EnteLoadingWidget(
              padding: 3,
              color: getEnteColorScheme(context).strokeMuted,
            ),
          );
        }
      },
    );
  }

  Widget _getVideoDuration() {
    if (widget.file.duration != 0) {
      return Text(
        secondsToHHMMSS(widget.file.duration!),
        style: getEnteTextTheme(context).smallMuted,
      );
    }
    return FutureBuilder<AssetEntity?>(
      future: widget.file.getAsset,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!.videoDuration.toString().split(".")[0],
            style: getEnteTextTheme(context).smallMuted,
          );
        } else {
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(24),
              child: const CupertinoActivityIndicator(
                radius: 8,
              ),
            ),
          );
        }
      },
    );
  }
}
