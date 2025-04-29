import "package:flutter/material.dart";
import 'package:path/path.dart' as path;
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/magic_util.dart";
import "package:photos/utils/standalone/data.dart";
import "package:photos/utils/standalone/date_time.dart";

class FilePropertiesItemWidget extends StatefulWidget {
  final EnteFile file;
  final bool isImage;
  final Map<String, dynamic> exifData;
  final int currentUserID;
  const FilePropertiesItemWidget(
    this.file,
    this.isImage,
    this.exifData,
    this.currentUserID, {
    super.key,
  });
  @override
  State<FilePropertiesItemWidget> createState() =>
      _FilePropertiesItemWidgetState();
}

class _FilePropertiesItemWidgetState extends State<FilePropertiesItemWidget> {
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
    final textStyle = getEnteTextTheme(context).miniMuted;
    final StringBuffer dimString = StringBuffer();
    if (widget.exifData["resolution"] != null &&
        widget.exifData["megaPixels"] != null) {
      dimString.write('${widget.exifData["megaPixels"]}MP   ');
      dimString.write('${widget.exifData["resolution"]}');
    } else if (widget.file.hasDimensions) {
      final double megaPixels =
          (widget.file.width * widget.file.height) / 1000000;
      final double roundedMegaPixels = (megaPixels * 10).round() / 10.0;
      dimString.write('${roundedMegaPixels.toStringAsFixed(1)}MP   ');
      dimString.write('${widget.file.width} x ${widget.file.height}');
    }
    final subSectionWidgets = <Widget>[];

    if (dimString.isNotEmpty) {
      subSectionWidgets.add(
        Text(
          dimString.toString(),
          style: textStyle,
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
        formatBytes(fileSize),
        style: textStyle,
      ),
    );

    if ((widget.file.fileType == FileType.video) &&
        (widget.file.localID != null || widget.file.duration != 0)) {
      if (widget.file.duration != 0) {
        subSectionWidgets.add(
          Text(
            secondsToHHMMSS(widget.file.duration!),
            style: textStyle,
          ),
        );
      } else {
        final asset = await widget.file.getAsset;
        subSectionWidgets.add(
          Text(
            asset?.videoDuration.toString().split(".")[0] ?? "",
            style: textStyle,
          ),
        );
      }
    }

    return Future.value(subSectionWidgets);
  }
}
