import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/standalone/data.dart";

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
  Widget? child;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _getSection());
  }

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox();
  }

  Future<void> _getSection() async {
    final textStyle = getEnteTextTheme(context).miniMuted;
    final subSectionWidgets = <Widget>[];

    final data = await VideoPreviewService.instance
        .getPlaylist(widget.file)
        .onError((error, stackTrace) {
      if (!mounted) return;
      return null;
    });

    if (data!.width != null && data.height != null) {
      subSectionWidgets.add(
        Text(
          "${data.width!}x${data.height!}",
          style: textStyle,
        ),
      );
    }

    if (data.size != null) {
      subSectionWidgets.add(
        Text(
          formatBytes(data.size!),
          style: textStyle,
        ),
      );
    }

    if ((widget.file.fileType == FileType.video) &&
        (widget.file.localID != null || widget.file.duration != 0) &&
        data.size != null) {
      // show bitrate, i.e. size * 8 / duration formatted
      final result = FFProbeProps.formatBitrate(
        data.size! * 8 / widget.file.duration!,
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

    if (subSectionWidgets.isEmpty) return;

    child = InfoItemWidget(
      key: const ValueKey("Stream properties"),
      leadingIcon: Icons.play_circle_outline,
      title: AppLocalizations.of(context).streamDetails,
      subtitleSection: Future.value(subSectionWidgets),
    );
    if (mounted) {
      setState(() {});
    }
  }
}
