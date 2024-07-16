import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/viewer/file/vid_exif_dialog.dart";
import "package:photos/utils/toast_util.dart";

class VideoExifRowItem extends StatefulWidget {
  final EnteFile file;
  final Map<String, dynamic>? exif;
  const VideoExifRowItem(
    this.file,
    this.exif, {
    super.key,
  });

  @override
  State<VideoExifRowItem> createState() => _VideoProbeInfoState();
}

class _VideoProbeInfoState extends State<VideoExifRowItem> {
  VoidCallback? _onTap;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      leadingIcon: Icons.text_snippet_outlined,
      title: S.of(context).exif,
      subtitleSection: _exifButton(context, widget.file, widget.exif),
      onTap: _onTap,
    );
  }

  Future<List<Widget>> _exifButton(
    BuildContext context,
    EnteFile file,
    Map<String, dynamic>? exif,
  ) async {
    late final String label;
    late final VoidCallback? onTap;
    final Map<String, dynamic> data = {};
    if (exif != null) {
      for (final key in exif.keys) {
        if (exif[key] != null) {
          data[key] = exif[key];
        }
      }
    }
    if (exif == null) {
      label = S.of(context).loadingExifData;
      onTap = null;
    } else if (exif.isNotEmpty) {
      label = S.of(context).viewAllExifData;
      onTap = () => showBarModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return VideoExifDialog(
                probeData: data,
              );
            },
            shape: const RoundedRectangleBorder(
              side: BorderSide(width: 0),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
            topControl: const SizedBox.shrink(),
            backgroundColor: getEnteColorScheme(context).backgroundElevated,
            barrierColor: backdropFaintDark,
            enableDrag: false,
          );
    } else {
      label = S.of(context).noExifData;
      onTap =
          () => showShortToast(context, S.of(context).thisImageHasNoExifData);
    }
    setState(() {
      _onTap = onTap;
    });
    return Future.value([
      Text(label, style: getEnteTextTheme(context).miniBoldMuted),
    ]);
  }
}
