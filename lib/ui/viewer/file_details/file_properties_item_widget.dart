import "package:flutter/material.dart";
import 'package:path/path.dart' as path;
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import "package:photos/theme/ente_theme.dart";
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
    return InfoItemWidget(
      key: const ValueKey("File properties"),
      leadingIcon: widget.isImage
          ? Icons.photo_outlined
          : Icons.video_camera_back_outlined,
      title: path.basenameWithoutExtension(widget.file.displayName) +
          path.extension(widget.file.displayName).toUpperCase(),
      subtitleSection: _subTitleSection(),
      editOnTap: widget.file.uploadedFileID == null ||
              widget.file.ownerID != widget.currentUserID
          ? null
          : () async {
              await editFilename(context, widget.file);
              setState(() {});
            },
    );
  }

  Future<List<Widget>> _subTitleSection() async {
    final bool showDimension = widget.exifData["resolution"] != null &&
        widget.exifData["megaPixels"] != null;
    final subSectionWidgets = <Widget>[];

    if (showDimension) {
      subSectionWidgets.add(
        Text(
          "${widget.exifData["megaPixels"]}MP  "
          "${widget.exifData["resolution"]}  ",
          style: getEnteTextTheme(context).smallMuted,
        ),
      );
    }

    int fileSize;
    if (widget.file.fileSize != null) {
      fileSize = widget.file.fileSize!;
    } else {
      fileSize = await getFile(widget.file).then((f) => f!.length());
    }
    subSectionWidgets.add(
      Text(
        (fileSize / (1024 * 1024)).toStringAsFixed(2) + " MB",
        style: getEnteTextTheme(context).smallMuted,
      ),
    );

    if ((widget.file.fileType == FileType.video) &&
        (widget.file.localID != null || widget.file.duration != 0)) {
      if (widget.file.duration != 0) {
        subSectionWidgets.add(
          Text(
            secondsToHHMMSS(widget.file.duration!),
            style: getEnteTextTheme(context).smallMuted,
          ),
        );
      } else {
        final asset = await widget.file.getAsset;
        subSectionWidgets.add(
          Text(
            asset!.videoDuration.toString().split(".")[0],
            style: getEnteTextTheme(context).smallMuted,
          ),
        );
      }
    }

    return Future.value(subSectionWidgets);
  }
}
