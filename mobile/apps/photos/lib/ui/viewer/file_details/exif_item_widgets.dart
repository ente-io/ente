import "package:exif_reader/exif_reader.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/exif_info_dialog.dart";

class BasicExifItemWidget extends StatelessWidget {
  final Map<String, dynamic> exifData;
  const BasicExifItemWidget(this.exifData, {super.key});

  @override
  Widget build(BuildContext context) {
    final subtitleTextTheme = getEnteTextTheme(context).miniMuted;
    return InfoItemWidget(
      key: const ValueKey("Basic EXIF"),
      leadingIcon: Icons.camera_outlined,
      title: exifData["takenOnDevice"] ?? "--",
      subtitleSection: Future.value([
        if (exifData["fNumber"] != null)
          Text(
            'ƒ/' + exifData["fNumber"].toString(),
            style: subtitleTextTheme,
          ),
        if (exifData["exposureTime"] != null)
          Text(
            exifData["exposureTime"],
            style: subtitleTextTheme,
          ),
        if (exifData["focalLength"] != null)
          Text(
            exifData["focalLength"].toString() + "mm",
            style: subtitleTextTheme,
          ),
        if (exifData["ISO"] != null)
          Text(
            "ISO" + exifData["ISO"].toString(),
            style: subtitleTextTheme,
          ),
      ]),
    );
  }
}

class AllExifItemWidget extends StatefulWidget {
  final EnteFile file;
  final Map<String, IfdTag>? exif;
  const AllExifItemWidget(
    this.file,
    this.exif, {
    super.key,
  });

  @override
  State<AllExifItemWidget> createState() => _AllExifItemWidgetState();
}

class _AllExifItemWidgetState extends State<AllExifItemWidget> {
  VoidCallback? _onTap;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      leadingIcon: Icons.text_snippet_outlined,
      title: AppLocalizations.of(context).exif,
      subtitleSection: _exifButton(context, widget.file, widget.exif),
      onTap: _onTap,
    );
  }

  Future<List<Widget>> _exifButton(
    BuildContext context,
    EnteFile file,
    Map<String, IfdTag>? exif,
  ) async {
    late final String label;
    late final VoidCallback? onTap;
    if (exif == null) {
      label = AppLocalizations.of(context).loadingExifData;
      onTap = null;
    } else if (exif.isNotEmpty) {
      label = AppLocalizations.of(context).viewAllExifData;
      onTap = () => showDialog(
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) {
              return ExifInfoDialog(file);
            },
            barrierColor: backdropFaintDark,
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
