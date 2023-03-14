import "package:exif/exif.dart";
import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/inline_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/viewer/file/exif_info_dialog.dart";
import "package:photos/utils/toast_util.dart";

class BasicExifItemWidget extends StatelessWidget {
  final Map<String, dynamic> exifData;
  const BasicExifItemWidget(this.exifData, {super.key});

  @override
  Widget build(BuildContext context) {
    final subtitleTextTheme = getEnteTextTheme(context).smallMuted;
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

class AllExifItemWidget extends StatelessWidget {
  final File file;
  final Map<String, IfdTag>? exif;
  const AllExifItemWidget(
    this.file,
    this.exif, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      leadingIcon: Icons.text_snippet_outlined,
      title: "EXIF",
      subtitleSection: _exifButton(context, file, exif),
    );
  }

  Future<List<InlineButtonWidget>> _exifButton(
    BuildContext context,
    File file,
    Map<String, IfdTag>? exif,
  ) {
    late final String label;
    late final VoidCallback? onTap;
    if (exif == null) {
      label = "Loading EXIF data...";
      onTap = null;
    } else if (exif.isNotEmpty) {
      label = "View all EXIF data";
      onTap = () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return ExifInfoDialog(file);
            },
            barrierColor: backdropFaintDark,
          );
    } else {
      label = "No EXIF data";
      onTap = () => showShortToast(context, "This image has no exif data");
    }
    return Future.value([
      InlineButtonWidget(
        label,
        onTap,
      )
    ]);
  }
}
