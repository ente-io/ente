import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/data_util.dart";

class PreviewPropertiesItemWidget extends StatefulWidget {
  final EnteFile file;
  final bool isImage;
  final Map<String, dynamic> exifData;
  final int currentUserID;
  const PreviewPropertiesItemWidget(
    this.file,
    this.isImage,
    this.exifData,
    this.currentUserID, {
    super.key,
  });
  @override
  State<PreviewPropertiesItemWidget> createState() =>
      _PreviewPropertiesItemWidgetState();
}

class _PreviewPropertiesItemWidgetState
    extends State<PreviewPropertiesItemWidget> {
  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      key: const ValueKey("Stream properties"),
      leadingIcon: Icons.play_circle_outline,
      title: S.of(context).streamDetails,
      subtitleSection: _subTitleSection(),
    );
  }

  Future<List<Widget>> _subTitleSection() async {
    final textStyle = getEnteTextTheme(context).miniMuted;
    final subSectionWidgets = <Widget>[];

    if (widget.file.pubMagicMetadata?.previewWidth != null &&
        widget.file.pubMagicMetadata?.previewHeight != null) {
      subSectionWidgets.add(
        Text(
          "${widget.file.pubMagicMetadata?.previewWidth}x${widget.file.pubMagicMetadata?.previewHeight}",
          style: textStyle,
        ),
      );
    }

    if (widget.file.pubMagicMetadata?.previewSize != null) {
      subSectionWidgets.add(
        Text(
          formatBytes(widget.file.pubMagicMetadata!.previewSize!),
          style: textStyle,
        ),
      );
    }

    if ((widget.file.fileType == FileType.video) &&
        (widget.file.localID != null || widget.file.duration != 0) &&
        widget.file.pubMagicMetadata!.previewSize != null) {
      // show bitrate, i.e. size * 8 / duration formatted
      final result = FFProbeProps.formatBitrate(
        widget.file.pubMagicMetadata!.previewSize! * 8 / widget.file.duration!,
        "b/s",
      );
      if (result != null) {
        subSectionWidgets.add(
          Text(
            result,
            style: textStyle,
          ),
        );
      }
    }

    return Future.value(subSectionWidgets);
  }
}
