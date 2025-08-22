import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/video_exif_dialog.dart";

class VideoExifRowItem extends StatefulWidget {
  final EnteFile file;
  final FFProbeProps? props;
  const VideoExifRowItem(
    this.file,
    this.props, {
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
      title: AppLocalizations.of(context).videoInfo,
      subtitleSection: _exifButton(context, widget.file, widget.props),
      onTap: _onTap,
    );
  }

  Future<List<Widget>> _exifButton(
    BuildContext context,
    EnteFile file,
    FFProbeProps? props,
  ) async {
    late final String label;
    late final VoidCallback? onTap;
    if (props?.propData == null) {
      label = AppLocalizations.of(context).loadingExifData;
      onTap = null;
    } else if (props!.propData!.isNotEmpty) {
      label = "${widget.props?.videoInfo ?? ''} ..";
      onTap = () => showBarModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return VideoExifDialog(
                props: props,
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
            enableDrag: true,
          );
    } else {
      label = AppLocalizations.of(context).noExifData;
      onTap = () => showShortToast(
            context,
            AppLocalizations.of(context).thisImageHasNoExifData,
          );
    }
    setState(() {
      _onTap = onTap;
    });
    return Future.value([
      Text(label, style: getEnteTextTheme(context).miniBoldMuted),
    ]);
  }
}
